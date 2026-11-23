"""Commands the app can send. Each `cmd_<name>` handles {"cmd": "<name>"}."""

from __future__ import annotations

import asyncio
import json
import logging
import time
from typing import Awaitable, Callable

from alexapy import AlexaAPI

from . import PROTOCOL_VERSION, http, parsing, paths, sequences, session
from .errors import (
    BAD_REQUEST, CANCELLED, NEED_LOGIN, NO_ECHO, RATE_LIMITED, TIMEOUT, UNREACHABLE, ServiceError,
)

log = logging.getLogger("alexabar.service")

ENTITIES_URI = "/api/behaviors/entities?skillId=amzn1.ask.1p.smarthome"
STATE_URI = "/api/phoenix/state"
PREVIEW_URI = "/api/behaviors/preview"
VOLUMES_URI = "/api/devices/deviceType/dsn/audio/v1/allDeviceVolumes"

SIGN_IN_TIMEOUT_S = 600
SAVE_EVERY_S = 15 * 60

Emit = Callable[[dict], None]


class Service:
    def __init__(self, emit: Emit) -> None:
        self.emit = emit
        self.login = None
        self.email = ""
        self.domain = ""
        self.auth_lock = asyncio.Lock()
        self.speakers: list[dict] = []
        self.sign_in_cancel: asyncio.Event | None = None
        self.last_save = 0.0
        # "latest wins" coalescing for rapid repeats (sliders)
        self._key_locks: dict[str, asyncio.Lock] = {}
        self._key_latest: dict[str, int] = {}
        self._ticket = 0

    # ------------------------------------------------------------ helpers
    @property
    def locale(self) -> str:
        return parsing.LOCALES.get(self.domain, "en-US")

    def _new_login(self, email: str, domain: str) -> None:
        state = session.load_state()
        if state.get("email") != email or state.get("domain") != domain:
            state = {}
        self.email, self.domain = email, domain
        self.login = session.make_login(email, domain, state)

    async def _close_login(self) -> None:
        if self.login is not None:
            try:
                await self.login.close()
            except Exception:  # noqa: BLE001
                pass
        self.login = None

    def _save(self) -> None:
        if self.login is not None and self.email:
            try:
                session.save_state(self.login, self.email, self.domain)
                self.last_save = time.time()
            except OSError as ex:
                log.warning("could not save session: %r", ex)

    def _require_login(self):
        if self.login is None or not (self.login.status or {}).get("login_successful"):
            raise ServiceError("Please sign in to Amazon.", NEED_LOGIN)
        return self.login

    async def _call(self, method: str, uri: str, data=None, smart_home: bool = False):
        """One Amazon request; re-logs in silently once if the session expired."""
        fn = http.smart_home_call if smart_home else http.raw_call
        try:
            status, text = await fn(self._require_login(), method, uri, data)
            if status == 401:
                log.info("HTTP 401, trying silent re-login")
                async with self.auth_lock:
                    ok = await session.silent_login(self.login)
                if not ok:
                    raise ServiceError("Your Amazon session expired. Please sign in again.", NEED_LOGIN)
                self._save()
                status, text = await fn(self.login, method, uri, data)
        except http.RateLimited as ex:
            raise ServiceError(
                "Amazon is limiting requests right now. Wait a few seconds and try again.", RATE_LIMITED
            ) from ex
        if time.time() - self.last_save > SAVE_EVERY_S:
            self._save()
        return status, text

    async def _coalesced(self, key: str, work: Callable[[], Awaitable[dict]]) -> dict:
        """Run `work` unless a newer request with the same key arrived meanwhile.

        Dragging a slider can fire many commands; only the newest one that is
        still waiting gets sent, which keeps us under Amazon's rate limit.
        """
        self._ticket += 1
        mine = self._ticket
        self._key_latest[key] = mine
        lock = self._key_locks.setdefault(key, asyncio.Lock())
        async with lock:
            if self._key_latest.get(key) != mine:
                return {"skipped": True}
            return await work()

    async def _ensure_speakers(self) -> None:
        if self.speakers:
            return
        try:
            raw = await AlexaAPI.get_devices(self._require_login()) or []
            self.speakers = [parsing.normalize_speaker(d) for d in raw if parsing.is_speaker(d)]
        except ServiceError:
            raise
        except Exception as ex:  # noqa: BLE001
            log.warning("speaker list failed: %r", ex)

    def _speaker(self, serial: str | None) -> dict:
        if serial:
            for s in self.speakers:
                if s["serial"] == serial:
                    return s
        pool = [s for s in self.speakers if s["online"]] or self.speakers
        if not pool:
            raise ServiceError("No Echo device is available.", NO_ECHO)
        return pool[0]

    async def _sequence(self, op_type: str, payload: dict, serial: str | None, with_target: bool = True) -> dict:
        await self._ensure_speakers()
        echo = self._speaker(serial)
        if with_target:
            payload = {**payload, **sequences.target(echo, self.locale, self._require_login().customer_id)}
        status, text = await self._call("post", PREVIEW_URI, sequences.preview_body(op_type, payload))
        if not 0 < status < 400:
            log.warning("%s -> HTTP %s: %s", op_type, status, " ".join(text.split())[:300])
            raise ServiceError(f"The Echo command failed (HTTP {status}).")
        return {"echo": echo["name"]}

    # ------------------------------------------------------------ session
    async def cmd_hello(self, _args: dict) -> dict:
        migrated = paths.migrate_legacy()
        st = session.load_state()
        return {
            "protocol": PROTOCOL_VERSION,
            "email": st.get("email") or "",
            "domain": st.get("domain") or "",
            "hasSession": bool((st.get("oauth") or {}).get("refresh_token")),
            "migrated": migrated,
        }

    async def cmd_connect(self, _args: dict) -> dict:
        """Sign in silently from saved tokens."""
        st = session.load_state()
        email, domain = st.get("email"), st.get("domain") or "amazon.com"
        if not email:
            raise ServiceError("No Amazon account is set up yet.", NEED_LOGIN)
        async with self.auth_lock:
            if self.login is None or self.email != email or self.domain != domain:
                await self._close_login()
                self._new_login(email, domain)
            if not (self.login.status or {}).get("login_successful"):
                if not await session.silent_login(self.login):
                    raise ServiceError("Please sign in to Amazon.", NEED_LOGIN)
            self._save()
        return {"email": self.email, "domain": self.domain}

    async def cmd_sign_in(self, args: dict) -> dict:
        email = str(args.get("email") or "").strip()
        domain = str(args.get("domain") or "amazon.com").strip()
        if not email:
            raise ServiceError("Enter your Amazon email.", BAD_REQUEST)
        async with self.auth_lock:
            await self._close_login()
            self._new_login(email, domain)
            login = self.login
            port = session.free_port()
            proxy = session.RoomyProxy(login, f"http://127.0.0.1:{port}")
            try:
                await proxy.start_proxy(host="127.0.0.1")
            except OSError as ex:
                raise ServiceError(f"Could not open the sign-in page: {ex.strerror or ex}") from ex
            self.sign_in_cancel = asyncio.Event()
            try:
                self.emit({"event": "login_url", "url": str(proxy.access_url())})
                deadline = time.time() + SIGN_IN_TIMEOUT_S
                while time.time() < deadline and not (login.authorization_code or login.access_token):
                    if self.sign_in_cancel.is_set():
                        raise ServiceError("Sign-in cancelled.", CANCELLED)
                    await asyncio.sleep(0.5)
                await asyncio.sleep(2)  # let the proxy render its final page
            finally:
                self.sign_in_cancel = None
                try:
                    await proxy.stop_proxy()
                except Exception:  # noqa: BLE001
                    pass
            if not (login.authorization_code or login.access_token):
                raise ServiceError("Sign-in timed out. Please try again.", TIMEOUT)
            if not await login.test_loggedin():
                raise ServiceError("Amazon did not accept the sign-in. Please try again.", NEED_LOGIN)
            self._save()
        return {"email": self.email, "domain": self.domain}

    async def cmd_cancel_sign_in(self, _args: dict) -> dict:
        if self.sign_in_cancel is not None:
            self.sign_in_cancel.set()
        return {}

    async def cmd_sign_out(self, _args: dict) -> dict:
        async with self.auth_lock:
            if self.login is not None:
                try:
                    await self.login.reset()
                except Exception as ex:  # noqa: BLE001
                    log.warning("reset failed: %r", ex)
            await self._close_login()
            session.clear_session()
            self.speakers = []
            self.email = self.domain = ""
        return {}

    # ------------------------------------------------------------ smart home
    async def cmd_devices(self, _args: dict) -> dict:
        status, text = await self._call("get", ENTITIES_URI)
        if status != 200:
            raise ServiceError(f"Amazon refused the device list (HTTP {status}).")
        try:
            entities = json.loads(text)
        except ValueError as ex:
            raise ServiceError("Amazon sent an unreadable device list.") from ex
        # Echo speakers appear as entities without operations; they come
        # from the device API instead.
        devices = [parsing.normalize_entity(e) for e in entities if isinstance(e, dict)]
        devices = [d for d in devices if d["operations"]]
        self.speakers = []
        await self._ensure_speakers()
        return {"devices": devices, "speakers": self.speakers}

    async def cmd_states(self, args: dict) -> dict:
        ids = [str(i) for i in args.get("ids") or [] if i]
        if not ids:
            return {"states": {}}
        body = {"stateRequests": [{"entityId": i, "entityType": "ENTITY"} for i in ids]}
        status, text = await self._call("post", STATE_URI, body, smart_home=True)
        if status >= 400:
            raise ServiceError(f"Could not read device status (HTTP {status}).")
        return {"states": parsing.parse_states(text)}

    async def cmd_control(self, args: dict) -> dict:
        entity_id = str(args.get("id") or "")
        params = args.get("params") or {}
        action = str(params.get("action") or "")
        if not entity_id or not action:
            raise ServiceError("Missing device or action.", BAD_REQUEST)

        async def work() -> dict:
            body = {"controlRequests": [
                {"entityId": entity_id, "entityType": "ENTITY", "parameters": params}
            ]}
            status, text = await self._call("put", STATE_URI, body, smart_home=True)
            if status < 400:
                code = parsing.control_error(text)
                if code is None:
                    return {"via": "direct"}
                log.warning("control error %s for %s", code, action)
                if "UNREACHABLE" in code:
                    raise ServiceError("The device isn't responding.", UNREACHABLE)
            phrase = args.get("phrase")
            if phrase:
                await self._sequence(
                    sequences.TEXT_COMMAND,
                    {"skillId": sequences.TELL_ALEXA_SKILL, "text": str(phrase)},
                    args.get("serial"),
                )
                return {"via": "voice"}
            raise ServiceError(f"Amazon rejected the command (HTTP {status}).")

        # Power toggles always go through; setBrightness/setColor/... coalesce.
        if action.startswith("set"):
            return await self._coalesced(f"{entity_id}:{action}", work)
        return await work()

    # ------------------------------------------------------------ Echo
    async def cmd_ask(self, args: dict) -> dict:
        text = str(args.get("text") or "").strip()
        if not text:
            raise ServiceError("Type something for Alexa.", BAD_REQUEST)
        return await self._sequence(
            sequences.TEXT_COMMAND, {"skillId": sequences.TELL_ALEXA_SKILL, "text": text}, args.get("serial")
        )

    async def cmd_speak(self, args: dict) -> dict:
        text = str(args.get("text") or "").strip()
        if not text:
            raise ServiceError("Type something to say.", BAD_REQUEST)
        return await self._sequence(sequences.SPEAK, {"textToSpeak": text}, args.get("serial"))

    async def cmd_volume(self, args: dict) -> dict:
        try:
            value = max(0, min(100, int(args.get("value"))))
        except (TypeError, ValueError) as ex:
            raise ServiceError("Invalid volume.", BAD_REQUEST) from ex
        serial = args.get("serial")
        return await self._coalesced(
            f"volume:{serial}",
            lambda: self._sequence(sequences.VOLUME, {"value": value}, serial),
        )

    async def cmd_stop(self, args: dict) -> dict:
        await self._ensure_speakers()
        echo = self._speaker(args.get("serial"))
        return await self._sequence(sequences.STOP, sequences.stop_payload(echo), echo["serial"], with_target=False)

    async def cmd_volumes(self, _args: dict) -> dict:
        status, text = await self._call("get", VOLUMES_URI)
        return {"volumes": parsing.parse_volumes(text) if status < 400 else {}}

    async def shutdown(self) -> None:
        self._save()
        await self._close_login()

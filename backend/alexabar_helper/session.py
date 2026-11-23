"""Amazon login: saved tokens, the AlexaLogin object, and the sign-in proxy."""

from __future__ import annotations

import json
import os
import socket

from aiohttp import web
from alexapy import AlexaLogin, AlexaProxy

from . import paths

OAUTH_KEYS = ("access_token", "refresh_token", "mac_dms", "expires_in")


class RoomyProxy(AlexaProxy):
    """AlexaProxy that tolerates huge cookie headers.

    Browsers send every cookie stored for 127.0.0.1 to any port on it, so other
    local dev tools can push the Cookie header past aiohttp's 8 KB default and
    the sign-in page fails with "400 LineTooLong".
    """

    async def start_proxy(self, host=None, ssl_context=None) -> None:
        app = web.Application()
        app.add_routes([web.route("*", "/{tail:.*}", self.all_handler)])
        self.runner = web.AppRunner(app, max_field_size=65536, max_line_size=65536)
        await self.runner.setup()
        site = web.TCPSite(self.runner, host=host, port=self.port, ssl_context=ssl_context)
        await site.start()
        self._active = True


def free_port() -> int:
    """A port on 127.0.0.1 that is free right now, for the sign-in proxy."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def load_state() -> dict:
    try:
        return json.loads(paths.STATE_FILE.read_text())
    except (OSError, ValueError):
        return {}


def save_state(login: AlexaLogin, email: str, domain: str) -> None:
    """Write tokens atomically with owner-only permissions."""
    paths.ensure_dirs()
    state = {
        "email": email,
        "domain": domain,
        "uuid": login.uuid,
        "oauth": {k: getattr(login, k, None) for k in OAUTH_KEYS},
    }
    tmp = paths.STATE_FILE.with_suffix(".tmp")
    tmp.write_text(json.dumps(state, indent=2))
    os.chmod(tmp, 0o600)
    tmp.replace(paths.STATE_FILE)
    protect_storage()


def protect_storage() -> None:
    """AlexaPy writes its cookie jar world-readable; restrict it."""
    if paths.STORAGE_DIR.is_dir():
        for f in paths.STORAGE_DIR.iterdir():
            if f.is_file():
                try:
                    os.chmod(f, 0o600)
                except OSError:
                    pass


def clear_session() -> None:
    """Delete saved tokens and cookies (sign out)."""
    try:
        paths.STATE_FILE.unlink()
    except OSError:
        pass
    if paths.STORAGE_DIR.is_dir():
        for f in paths.STORAGE_DIR.iterdir():
            if f.is_file():
                f.unlink(missing_ok=True)


def make_login(email: str, domain: str, state: dict) -> AlexaLogin:
    paths.ensure_dirs()
    return AlexaLogin(
        url=domain,
        email=email,
        password="",  # typed into Amazon's own page via the proxy, never here
        outputpath=lambda p: str(paths.DATA_DIR / p),
        oauth={k: v for k, v in (state.get("oauth") or {}).items() if v},
        uuid=state.get("uuid"),
    )


async def silent_login(login: AlexaLogin) -> bool:
    """Log in from saved tokens/cookies without any UI."""
    cookies = await login.load_cookie()
    if login.refresh_token or cookies:
        await login.login(cookies=cookies)
        return bool(login.status and login.status.get("login_successful"))
    return False

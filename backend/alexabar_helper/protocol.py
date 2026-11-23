"""JSON-lines protocol between the app and the helper.

    app -> helper   {"id": 7, "cmd": "devices", "args": {}}
    helper -> app   {"id": 7, "ok": true, "result": {...}}
                    {"id": 7, "ok": false, "error": "...", "code": "need_login"}
    helper -> app   {"event": "login_url", "url": "http://127.0.0.1:54321/..."}

stdout carries only protocol messages. Library prints and logs go to stderr,
which the app writes to its log file. The helper exits when stdin closes.
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import sys
import threading

from . import PROTOCOL_VERSION


def _claim_stdout():
    """Keep the real stdout for protocol messages; send everything else to stderr."""
    proto = os.fdopen(os.dup(1), "w", buffering=1, encoding="utf-8")
    os.dup2(2, 1)
    sys.stdout = sys.stderr
    return proto


def _configure_logging() -> None:
    logging.basicConfig(
        level=logging.INFO,
        stream=sys.stderr,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    # AlexaPy is chatty at INFO and can log account details.
    for name in ("alexapy", "authcaptureproxy", "aiohttp", "httpx"):
        logging.getLogger(name).setLevel(logging.WARNING)


async def _handle(service, msg: dict, emit) -> None:
    from .errors import BAD_REQUEST, ServiceError

    rid = msg.get("id")
    cmd = str(msg.get("cmd") or "")
    fn = getattr(service, f"cmd_{cmd}", None) if cmd.isidentifier() else None
    if fn is None:
        emit({"id": rid, "ok": False, "error": f"Unknown command {cmd!r}", "code": BAD_REQUEST})
        return
    try:
        result = await fn(msg.get("args") or {})
        emit({"id": rid, "ok": True, "result": result})
    except ServiceError as ex:
        emit({"id": rid, "ok": False, "error": str(ex), "code": ex.code})
    except asyncio.CancelledError:
        raise
    except Exception as ex:  # noqa: BLE001
        logging.getLogger("alexabar").exception("%s failed", cmd)
        emit({"id": rid, "ok": False, "error": f"Unexpected error: {type(ex).__name__}", "code": "error"})


async def _serve(proto) -> None:
    from .service import Service

    def emit(obj: dict) -> None:
        try:
            proto.write(json.dumps(obj, separators=(",", ":")) + "\n")
            proto.flush()
        except (OSError, ValueError):
            pass

    loop = asyncio.get_running_loop()
    inbox: asyncio.Queue = asyncio.Queue()

    def reader() -> None:
        for line in sys.stdin:
            line = line.strip()
            if line:
                loop.call_soon_threadsafe(inbox.put_nowait, line)
        loop.call_soon_threadsafe(inbox.put_nowait, None)  # app went away

    threading.Thread(target=reader, name="stdin", daemon=True).start()
    service = Service(emit)
    emit({"event": "ready", "protocol": PROTOCOL_VERSION})
    tasks: set[asyncio.Task] = set()
    while (line := await inbox.get()) is not None:
        try:
            msg = json.loads(line)
        except ValueError:
            logging.getLogger("alexabar").warning("ignoring malformed input line")
            continue
        if not isinstance(msg, dict):
            continue
        task = asyncio.create_task(_handle(service, msg, emit))
        tasks.add(task)
        task.add_done_callback(tasks.discard)
    # stdin closed: let in-flight commands finish briefly, then stop.
    if tasks:
        _, still_running = await asyncio.wait(set(tasks), timeout=3)
        for task in still_running:
            task.cancel()
    await service.shutdown()


def main() -> None:
    proto = _claim_stdout()
    _configure_logging()
    try:
        asyncio.run(_serve(proto))
    except KeyboardInterrupt:
        pass

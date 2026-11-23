"""Raw requests to alexa.amazon.<tld>, with CSRF headers and rate-limit handling."""

from __future__ import annotations

import asyncio
import logging

from alexapy import AlexaLogin

log = logging.getLogger("alexabar.http")

# User-Agent that alexa-remote2 (the Node library) sends. Some regions
# (e.g. amazon.in) only accept the smart home endpoints with it.
APP_UA = (
    "AppleWebKit PitanguiBridge/2.2.595606.0-"
    "[HARDWARE=iPhone14_7][SOFTWARE=17.4.1][DEVICE=iPhone]"
)

# Header profiles tried for smart home calls. Whichever works first is
# remembered and tried first next time.
_PROFILES: list[tuple[str, str | None]] = [("app", APP_UA), ("web", None)]

MAX_RATE_LIMIT_RETRIES = 2
MAX_RETRY_WAIT_S = 4.0


class RateLimited(Exception):
    """Amazon kept answering HTTP 429 Too Many Requests."""


async def request_headers(login: AlexaLogin) -> dict[str, str]:
    """Headers the Alexa web app sends, including the CSRF token.

    Without the `csrf` header Amazon answers PUT/POST with a 403
    "Website Temporarily Unavailable" page.
    """
    host = f"https://alexa.{login.url}"
    headers = dict(login._headers)
    headers["Referer"] = f"{host}/spa/index.html"
    headers["Origin"] = host
    cookies = login._get_cookies_from_session()
    if "csrf" not in cookies:
        await login.get_csrf()
        cookies = login._get_cookies_from_session()
    if "csrf" in cookies:
        headers["csrf"] = cookies["csrf"].value
    else:
        log.warning("no csrf cookie in session")
    return headers


def _retry_after(resp, attempt: int) -> float:
    try:
        value = float(resp.headers.get("Retry-After", ""))
    except ValueError:
        value = 0.0
    backoff = 0.8 * (2**attempt)  # 0.8 s, 1.6 s
    return min(max(value, backoff), MAX_RETRY_WAIT_S)


async def raw_call(login: AlexaLogin, method: str, uri: str, data=None, ua: str | None = None):
    """One request that keeps HTTP errors visible (AlexaPy hides 4xx bodies).

    Retries a couple of times on HTTP 429, then raises RateLimited.
    """
    for attempt in range(MAX_RATE_LIMIT_RETRIES + 1):
        headers = await request_headers(login)
        if ua:
            headers["User-Agent"] = ua
            headers["Accept"] = "application/json; charset=utf-8"
        resp = await getattr(login.session, method)(
            f"https://alexa.{login.url}{uri}",
            json=data,
            headers=headers,
            ssl=login._ssl,
        )
        text = await resp.text()
        if resp.status != 429:
            return resp.status, text
        if attempt == MAX_RATE_LIMIT_RETRIES:
            break
        wait = _retry_after(resp, attempt)
        log.info("429 on %s %s, retrying in %.1fs", method.upper(), uri, wait)
        await asyncio.sleep(wait)
    raise RateLimited(uri)


async def smart_home_call(login: AlexaLogin, method: str, uri: str, data=None):
    """Try each header profile until Amazon accepts the smart home request."""
    status, text = 0, ""
    for i, (label, ua) in enumerate(list(_PROFILES)):
        status, text = await raw_call(login, method, uri, data, ua=ua)
        if status < 400:
            if i:
                _PROFILES.insert(0, _PROFILES.pop(i))
            return status, text
        log.info("smart home call with %s profile -> HTTP %s", label, status)
    return status, text

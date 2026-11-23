"""Errors reported back to the app. `code` lets the app react (e.g. show sign-in)."""


class ServiceError(Exception):
    def __init__(self, message: str, code: str = "error") -> None:
        super().__init__(message)
        self.code = code


NEED_LOGIN = "need_login"
RATE_LIMITED = "rate_limited"
UNREACHABLE = "unreachable"
BAD_REQUEST = "bad_request"
CANCELLED = "cancelled"
TIMEOUT = "timeout"
NO_ECHO = "no_echo"

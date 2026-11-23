"""Background helper for the Alexa Bar macOS app.

The app starts this package as a child process and talks to it with one JSON
object per line over stdin/stdout. See `protocol.py` for the message format.
"""

PROTOCOL_VERSION = 2

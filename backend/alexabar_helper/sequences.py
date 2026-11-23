"""Echo commands sent as one-off routine previews (/api/behaviors/preview).

This API keeps working for accounts where Amazon blocks the older Echo
endpoints, and it covers everything the app needs: spoken text, typed
commands ("Alexa, ..."), volume and stop.
"""

from __future__ import annotations

import json

TEXT_COMMAND = "Alexa.TextCommand"
SPEAK = "Alexa.Speak"
VOLUME = "Alexa.DeviceControls.Volume"
STOP = "Alexa.DeviceControls.Stop"

TELL_ALEXA_SKILL = "amzn1.ask.1p.tellalexa"


def target(echo: dict, locale: str, customer_id: str | None) -> dict:
    return {
        "deviceType": echo["deviceType"],
        "deviceSerialNumber": echo["serial"],
        "locale": locale,
        "customerId": customer_id or echo["customerId"],
    }


def preview_body(op_type: str, payload: dict) -> dict:
    sequence = {
        "@type": "com.amazon.alexa.behaviors.model.Sequence",
        "startNode": {
            "@type": "com.amazon.alexa.behaviors.model.OpaquePayloadOperationNode",
            "type": op_type,
            "operationPayload": payload,
        },
    }
    return {"behaviorId": "PREVIEW", "sequenceJson": json.dumps(sequence), "status": "ENABLED"}


def stop_payload(echo: dict) -> dict:
    return {
        "devices": [{"deviceSerialNumber": echo["serial"], "deviceType": echo["deviceType"]}],
        "isAssociatedDevice": False,
    }

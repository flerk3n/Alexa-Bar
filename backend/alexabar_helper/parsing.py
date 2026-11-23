"""Turn Amazon's replies into the small, stable shapes the app decodes."""

from __future__ import annotations

import json

LOCALES = {
    "amazon.com": "en-US",
    "amazon.in": "en-IN",
    "amazon.co.uk": "en-GB",
    "amazon.ca": "en-CA",
    "amazon.com.au": "en-AU",
    "amazon.de": "de-DE",
    "amazon.fr": "fr-FR",
    "amazon.it": "it-IT",
    "amazon.es": "es-ES",
    "amazon.co.jp": "ja-JP",
    "amazon.com.br": "pt-BR",
    "amazon.com.mx": "es-MX",
}

# Echo-style device families that can speak and take commands.
SPEAKER_FAMILIES = {"ECHO", "KNIGHT", "ROOK", "TABLET", "FIRE_TV", "THIRD_PARTY_AVS_MEDIA_DISPLAY"}


def _type_suffix(desc: str) -> str:
    """Descriptions look like "SmartLife smart plug(SMARTPLUG)"."""
    if desc.endswith(")") and "(" in desc:
        return desc[desc.rfind("(") + 1 : -1].upper()
    return ""


def normalize_entity(e: dict) -> dict:
    desc = str(e.get("description") or "")
    icon = str((e.get("icon") or {}).get("value") or "").upper()
    appliance = _type_suffix(desc)
    return {
        "id": str(e.get("id") or ""),
        "name": str(e.get("displayName") or "Unnamed device"),
        "description": desc,
        "kind": icon or appliance or "OTHER",
        "applianceType": appliance,
        "operations": list(e.get("supportedOperations") or []),
        "available": str(e.get("availability") or "AVAILABLE").upper() == "AVAILABLE",
    }


def _capability(st: dict, c: dict) -> None:
    name, value = c.get("name"), c.get("value")
    if name == "powerState":
        st["on"] = value == "ON"
    elif name == "brightness" and isinstance(value, (int, float)):
        st["brightness"] = int(value)
    elif name == "colorTemperatureInKelvin" and isinstance(value, (int, float)):
        st["kelvin"] = int(value)
    elif name == "color" and isinstance(value, dict):
        st["color"] = {
            "hue": float(value.get("hue") or 0),
            "saturation": float(value.get("saturation") or 0),
            "brightness": float(value.get("brightness") or 0),
        }
    elif name == "colorProperties" and isinstance(value, dict):
        st["colorName"] = value.get("name")
        st["colorLabel"] = (value.get("localizationMap") or {}).get("en") or value.get("name")
    elif name == "connectivity":
        v = value.get("value") if isinstance(value, dict) else value
        st["reachable"] = str(v).upper() == "OK"
    elif name == "percentage" and isinstance(value, (int, float)):
        st["percentage"] = int(value)


def parse_states(text: str) -> dict[str, dict]:
    """/api/phoenix/state reply -> {entity_id: {"on": bool, ...}}."""
    out: dict[str, dict] = {}
    try:
        data = json.loads(text)
    except ValueError:
        return out
    for item in (data.get("deviceStates") if isinstance(data, dict) else None) or []:
        eid = (item.get("entity") or {}).get("entityId")
        if not eid:
            continue
        st: dict = {}
        for cap in item.get("capabilityStates") or []:
            try:
                c = json.loads(cap) if isinstance(cap, str) else cap
            except ValueError:
                continue
            if isinstance(c, dict):
                _capability(st, c)
        if item.get("error"):
            st.setdefault("reachable", False)
        out[eid] = st
    return out


def control_error(text: str) -> str | None:
    """Error code from a PUT /api/phoenix/state reply, or None on success."""
    try:
        errors = json.loads(text).get("errors") or []
    except (ValueError, AttributeError):
        return None
    if not errors:
        return None
    return str((errors[0] or {}).get("code") or "UNKNOWN")


def normalize_speaker(d: dict) -> dict:
    return {
        "serial": str(d.get("serialNumber") or ""),
        "deviceType": str(d.get("deviceType") or ""),
        "name": str(d.get("accountName") or "Echo"),
        "family": str(d.get("deviceFamily") or ""),
        "online": bool(d.get("online")),
        "customerId": str(d.get("deviceOwnerCustomerId") or ""),
        "capabilities": list(d.get("capabilities") or []),
    }


def is_speaker(d: dict) -> bool:
    """Real Echo-style speakers only.

    Skips speaker groups (WHA), the Alexa phone app ("This Device", VOX) and
    phone-paired accessories such as headphones (*_VOX_ACCESSORY).
    """
    fam = str(d.get("deviceFamily") or "")
    caps = set(d.get("capabilities") or [])
    if fam == "WHA" or "VOX" in fam.split("_"):
        return False
    return fam in SPEAKER_FAMILIES or (fam.startswith("THIRD_PARTY_AVS") and "VOLUME_SETTING" in caps)


def parse_volumes(text: str) -> dict[str, dict]:
    """allDeviceVolumes reply -> {serial: {"volume": int|None, "muted": bool}}."""
    out: dict[str, dict] = {}
    try:
        items = json.loads(text).get("volumes") or []
    except (ValueError, AttributeError):
        return out
    for v in items:
        if isinstance(v, dict) and v.get("dsn"):
            out[str(v["dsn"])] = {"volume": v.get("speakerVolume"), "muted": bool(v.get("speakerMuted"))}
    return out

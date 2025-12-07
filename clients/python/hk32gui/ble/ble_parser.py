# ble_parser.py
"""
BLE Notification Parser for HomeKit32 Python Client

Parses BLE notifications based on the protocol:
[device_id, command_id, payload...]

Returns a standardized dict suitable for GUI update.
"""

from typing import Optional


def parse_notification(data: bytes) -> Optional[dict]:
    """
    Parse a raw BLE notification.

    Args:
        data (bytes): Raw BLE data [device_id, command_id, payload...]

    Returns:
        dict: Parsed notification, e.g.
              {"device": "yellow_led", "state": True}
              {"device": "dht11", "temp": 22.5}
              {"device": "dht11", "hum": 41}
        None: If data could not be parsed
    """
    if not data or len(data) < 2:
        return None

    device_id = data[0]
    command_id = data[1]
    payload = data[2:]

    # --- Yellow LED (device_id = 0x01) ---
    if device_id == 0x01:
        # CMD_SET_STATE (0x01)
        if command_id == 0x01 and payload:
            state = bool(payload[0])
            return {"device": "yellow_led", "state": state}

    # --- DHT11 Sensor (device_id = 0x10) ---
    elif device_id == 0x10:
        # Temperature (CMD_TEMP = 0x01)
        if command_id == 0x01 and len(payload) >= 2:
            # Example encoding: payload[0] = integer part, payload[1] = fractional (x100)
            temp = payload[0] + payload[1] / 100
            return {"device": "dht11", "temp": temp}

        # Humidity (CMD_HUM = 0x02)
        elif command_id == 0x02 and len(payload) >= 1:
            hum = payload[0]
            return {"device": "dht11", "hum": hum}

    # Add more devices here as needed

    return None

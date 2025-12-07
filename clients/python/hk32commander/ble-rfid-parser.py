#!/usr/bin/env python3
# ================================================================
# File:        ble_rfid_parser.py
# Project:     homekit32 BLE Parser
# Author:      Robert W.W. Linn (c) 2025 MIT
# Description:
#   Parse RFID payloads received via BLE in the format:
#     [UL][UID bytes...][DL][DATA bytes...]
#   UL = UID length (1 byte)
#   UID = UID bytes
#   DL = Data length (1 byte)
#   DATA = Data bytes
# ================================================================

def parse_rfid_payload(payload: bytes):
    """Parse BLE RFID payload into UID and Data."""
    if len(payload) < 2:
        raise ValueError("Payload too short to contain UID and data lengths")

    idx = 0

    # --- UID ---
    uid_len = payload[idx]
    idx += 1
    uid = payload[idx: idx + uid_len]
    idx += uid_len

    # --- Data ---
    if idx >= len(payload):
        raise ValueError("No data length byte found")
    data_len = payload[idx]
    idx += 1
    data = payload[idx: idx + data_len]
    idx += data_len

    # Optional: warn if extra bytes left
    if idx != len(payload):
        print(f"⚠ Warning: {len(payload) - idx} extra bytes at end of payload")

    return uid, data


# ---------------------------
# Example usage
# ---------------------------
if __name__ == "__main__":
    # Example payload from B4R: 04 8C 4B 71 C1 10 02 04 ... BF 75
    example_payload = bytes.fromhex("048C4B71C110020400000000000000000000000000BF75")

    uid, data = parse_rfid_payload(example_payload)
    print(f"UID  = {uid.hex().upper()}")
    print(f"Data = {data.hex().upper()}")

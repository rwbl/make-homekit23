#!/usr/bin/env python3
# ================================================================
# File:        ble-test.py
# Project:     homekit32 BLE Test Utility
# Author:      Robert W.W. Linn (c) 2025 MIT
# Date:        2025-11-14
#
# Description:
#   Generic BLE command sender for homekit32 ESP32 device.
#   Sends <DeviceID><CommandID><Payload...> via Nordic UART service.
#   Keeps connection open until user presses Enter.
#
# Usage:
#   python ble-test.py -d <deviceID> -c <command> -p <payload>
#   All arguments must be hex (no spaces). Payload can be any length.
#
# Example:
#   python ble-test.py -d 01 -c 01 -p 01
#   → Turns Yellow LED ON
# ================================================================

import asyncio
import argparse
import json
import os
import datetime
from bleak import BleakClient, BleakScanner

# ---------------------------------------------------------------------------
# BLE UUIDs (Nordic UART compatible)
# ---------------------------------------------------------------------------
SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
CHAR_UUID_TX = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"  # Write
CHAR_UUID_RX = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"  # Notify

DEVICE_NAME = "homekit32"
CACHE_FILE = "ble_device.json"

# ---------------------------------------------------------------------------
# Helper: print timestamped log messages
# ---------------------------------------------------------------------------
def log(message: str) -> None:
    now = datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]
    print(f"[{now}] {message}")

# ---------------------------------------------------------------------------
# Helper: load/store BLE MAC address
# ---------------------------------------------------------------------------
def load_cached_device():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                data = json.load(f)
                return data.get("address")
        except Exception:
            return None
    return None

def save_cached_device(address: str) -> None:
    with open(CACHE_FILE, "w") as f:
        json.dump({"address": address}, f)

# ---------------------------------------------------------------------------
# Async BLE logic
# ---------------------------------------------------------------------------
async def run_ble(device_id: int, command_id: int, payload: bytes):
    message = bytes([device_id, command_id]) + payload
    log(f"➡ Sending bytes: {message.hex().upper()}")

    start_time = datetime.datetime.now()

    # Try cached BLE address
    address = load_cached_device()
    if not address:
        log(f"🔍 Searching for BLE device '{DEVICE_NAME}'...")
        device = await BleakScanner.find_device_by_filter(
            lambda d, ad: d.name == DEVICE_NAME,
            timeout=3.0
        )
        if not device:
            log(f"❌ Device '{DEVICE_NAME}' not found.")
            return
        address = device.address
        save_cached_device(address)
        log(f"✅ Found {DEVICE_NAME}: {address}")
    else:
        log(f"⚡ Using cached BLE address: {address}")

    # Connect
    async with BleakClient(address) as client:
        if not client.is_connected:
            log("❌ Connection failed.")
            return

        log("🔗 Connected to homekit32.")

        # RX notifications handler
        def handle_rx(_, data: bytearray):
            log(f"📩 Notification: {data.hex().upper()}")

        try:
            await client.start_notify(CHAR_UUID_RX, handle_rx)
        except Exception:
            log("⚠ RX notifications not available")

        # Send initial command
        await client.write_gatt_char(CHAR_UUID_TX, message)
        log("✅ Command sent.")

        # Keep connection until user presses Enter
        log("⏳ Connection open. Press Enter to disconnect...")
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(None, input)

        try:
            await client.stop_notify(CHAR_UUID_RX)
        except Exception:
            pass

    elapsed = (datetime.datetime.now() - start_time).total_seconds()
    log(f"🔌 Disconnected. (Elapsed: {elapsed:.2f}s)")

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------
async def main():
    parser = argparse.ArgumentParser(description="homekit32 BLE test tool")
    parser.add_argument("-d", "--device", required=True, help="Device ID (hex, e.g. 01)")
    parser.add_argument("-c", "--command", required=True, help="Command ID (hex, e.g. 01)")
    parser.add_argument("-p", "--payload", required=True, help="Payload as hex (any length)")

    args = parser.parse_args()

    try:
        device_id = int(args.device, 16)
        command_id = int(args.command, 16)
        payload = bytes.fromhex(args.payload)
    except ValueError:
        log("❌ Invalid hex input. Use hex without spaces.")
        return

    await run_ble(device_id, command_id, payload)

# ---------------------------------------------------------------------------
if __name__ == "__main__":
    asyncio.run(main())

#!/usr/bin/env python3
# ================================================================
# File:        ble-client-gui.py
# Project:     homekit32 BLE GUI Client
# Author:      Robert W.W. Linn (c) 2025 MIT
# Date:        2025-11-14
#
# Description:
#   PySide6 GUI for sending BLE commands to homekit32 ESP32
#   device using Nordic UART style characteristics.
#   Maintains connection until user disconnects.
#
# Requirements:
#   pip install bleak PySide6 qasync
#
# ================================================================

import sys
import asyncio
import json
import os
import datetime
from PySide6.QtWidgets import (
    QApplication, QWidget, QLabel, QLineEdit,
    QPushButton, QTextEdit, QVBoxLayout, QHBoxLayout
)
from PySide6.QtCore import Qt
from bleak import BleakClient, BleakScanner
import qasync


# ---------------------------------------------------------------------------
# BLE UUIDs
# ---------------------------------------------------------------------------
SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
CHAR_UUID_TX = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
CHAR_UUID_RX = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

DEVICE_NAME = "homekit32"
CACHE_FILE = "ble_device.json"


# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
def log(message: str, text_widget: QTextEdit = None):
    """Prints a timestamped message to console and optional QTextEdit."""
    now = datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]
    msg = f"[{now}] {message}"
    print(msg)
    if text_widget:
        text_widget.append(msg)
        text_widget.verticalScrollBar().setValue(
            text_widget.verticalScrollBar().maximum()
        )


def load_cached_device():
    """Load cached BLE MAC address from file."""
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                data = json.load(f)
                return data.get("address")
        except Exception:
            return None
    return None


def save_cached_device(address: str):
    """Save BLE MAC address to cache file."""
    with open(CACHE_FILE, "w") as f:
        json.dump({"address": address}, f)


# ---------------------------------------------------------------------------
# Main GUI class
# ---------------------------------------------------------------------------
class BLEClientGUI(QWidget):
    """PySide6 GUI for homekit32 BLE commands."""

    def __init__(self):
        super().__init__()
        self.setWindowTitle("homekit32 BLE Client")
        self.setGeometry(200, 200, 600, 450)

        # BLE client
        self.client: BleakClient | None = None
        self.connected = False
        self.address = load_cached_device()

        # -------------------------------------------------------------------
        # Widgets
        # -------------------------------------------------------------------
        self.device_label = QLabel("Device ID (hex):")
        self.device_input = QLineEdit("01")

        self.command_label = QLabel("Command ID (hex):")
        self.command_input = QLineEdit("01")

        self.payload_label = QLabel("Payload (hex):")
        self.payload_input = QLineEdit("01")

        self.connect_btn = QPushButton("Connect")
        self.disconnect_btn = QPushButton("Disconnect")
        self.send_btn = QPushButton("Send Command")

        self.log_text = QTextEdit()
        self.log_text.setReadOnly(True)

        self.clear_btn = QPushButton("Clear Log")  # NEW BUTTON

        # Layout
        layout = QVBoxLayout()
        input_layout = QHBoxLayout()
        input_layout.addWidget(self.device_label)
        input_layout.addWidget(self.device_input)
        input_layout.addWidget(self.command_label)
        input_layout.addWidget(self.command_input)
        input_layout.addWidget(self.payload_label)
        input_layout.addWidget(self.payload_input)
        layout.addLayout(input_layout)

        btn_layout = QHBoxLayout()
        btn_layout.addWidget(self.connect_btn)
        btn_layout.addWidget(self.disconnect_btn)
        btn_layout.addWidget(self.send_btn)
        layout.addLayout(btn_layout)

        layout.addWidget(self.log_text)
        layout.addWidget(self.clear_btn)  # ADD CLEAR BUTTON BELOW LOG

        self.setLayout(layout)

        # Connect signals
        self.connect_btn.clicked.connect(
            lambda: asyncio.create_task(self.connect_ble())
        )
        self.disconnect_btn.clicked.connect(
            lambda: asyncio.create_task(self.disconnect_ble())
        )
        self.send_btn.clicked.connect(
            lambda: asyncio.create_task(self.send_command())
        )
        self.clear_btn.clicked.connect(self.clear_log)  # CONNECT CLEAR BUTTON

    # -----------------------------------------------------------------------
    # BLE Notification handler
    # -----------------------------------------------------------------------
    def handle_rx(self, _: int, data: bytearray):
        """Handles incoming BLE notifications."""
        log(f"📩 Notification: {data.hex().upper()}", self.log_text)

    # -----------------------------------------------------------------------
    # Connect BLE device
    # -----------------------------------------------------------------------
    async def connect_ble(self):
        """Connect to BLE device and enable notifications."""
        if self.connected:
            log("⚡ Already connected.", self.log_text)
            return

        try:
            if not self.address:
                log(f"🔍 Searching for BLE device '{DEVICE_NAME}'...", self.log_text)
                device = await BleakScanner.find_device_by_filter(
                    lambda d, ad: d.name == DEVICE_NAME,
                    timeout=3.0
                )
                if not device:
                    log(f"❌ Device '{DEVICE_NAME}' not found.", self.log_text)
                    return
                self.address = device.address
                save_cached_device(self.address)
                log(f"✅ Found {DEVICE_NAME}: {self.address}", self.log_text)
            else:
                log(f"⚡ Using cached BLE address: {self.address}", self.log_text)

            self.client = BleakClient(self.address)
            await self.client.connect()
            self.connected = True
            log("🔗 Connected.", self.log_text)

            # Enable notifications
            try:
                await self.client.start_notify(CHAR_UUID_RX, self.handle_rx)
            except Exception:
                log("⚠ RX notifications not available.", self.log_text)

        except Exception as e:
            log(f"❌ Connection error: {e}", self.log_text)
            self.connected = False

    # -----------------------------------------------------------------------
    # Disconnect BLE device
    # -----------------------------------------------------------------------
    async def disconnect_ble(self):
        """Disconnect BLE device."""
        if self.client and self.connected:
            try:
                try:
                    await self.client.stop_notify(CHAR_UUID_RX)
                except Exception:
                    pass
                await self.client.disconnect()
            except Exception:
                pass
            self.connected = False
            log("🔌 Disconnected.", self.log_text)
        else:
            log("⚡ Not connected.", self.log_text)

    # -----------------------------------------------------------------------
    # Send command
    # -----------------------------------------------------------------------
    async def send_command(self):
        """Send device ID + command + payload to BLE device."""
        if not self.client or not self.connected:
            log("❌ Not connected.", self.log_text)
            return

        try:
            device_id = int(self.device_input.text(), 16)
            command_id = int(self.command_input.text(), 16)
            payload = bytes.fromhex(self.payload_input.text())
        except ValueError:
            log("❌ Invalid hex input.", self.log_text)
            return

        message = bytes([device_id, command_id]) + payload
        log(f"➡ Sending bytes: {message.hex().upper()}", self.log_text)
        try:
            await self.client.write_gatt_char(CHAR_UUID_TX, message)
            log("✅ Command sent.", self.log_text)
        except Exception as e:
            log(f"❌ Send error: {e}", self.log_text)

    # -----------------------------------------------------------------------
    # Clear log
    # -----------------------------------------------------------------------
    def clear_log(self):
        """Clear the QTextEdit log field."""
        self.log_text.clear()


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    app = QApplication(sys.argv)
    loop = qasync.QEventLoop(app)        # integrate asyncio with Qt
    asyncio.set_event_loop(loop)
    gui = BLEClientGUI()
    gui.show()
    with loop:
        loop.run_forever()

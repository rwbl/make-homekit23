"""
Main window with HMI tiles and BLE integration.
"""
import asyncio
from PySide6.QtWidgets import (
    QMainWindow, QWidget,
    QVBoxLayout, QGridLayout,
    QTextEdit, QPushButton
)
from hmi.tile_button import TileButton
from hmi.tile_readout import TileReadOut
from hmi.tile_utils import log
from hmi.tile_utils import TILE_SIZE_DEFAULT
from ble.ble_parser import parse_notification  # <-- import parser

class MainWindow(QMainWindow):
    def __init__(self, ble_manager):
        super().__init__()
        self.ble = ble_manager

        self.setWindowTitle("HomeKit32 Python HMI")
        central = QWidget()
        self.setCentralWidget(central)

        # --- Widgets ---
        self.tile_ble = TileButton("BLE Connect")
        self.tile_led = TileButton("Yellow LED")
        self.tile_temp = TileReadOut("Temp", "°C")
        self.tile_hum = TileReadOut("Humidity", "%")

        # -- Log ---
        self.log_text = QTextEdit()
        self.log_text.setReadOnly(True)
        self.clear_btn = QPushButton("Clear Log")

        # --- Main Layout ---
        layout = QVBoxLayout(central)

        # --- Tiles Grid Layout ---
        self.grid_rows = 2
        self.grid_cols = 6
        self.tiles = {}  # store tiles by (row, col)

        self.grid_layout = QGridLayout()
        self.grid_layout.setSpacing(5)

        # Fix row/col sizes
        for r in range(self.grid_rows):
            self.grid_layout.setRowMinimumHeight(r, TILE_SIZE_DEFAULT)
            self.grid_layout.setRowStretch(r, 0)
        for c in range(self.grid_cols):
            self.grid_layout.setColumnMinimumWidth(c, TILE_SIZE_DEFAULT)
            self.grid_layout.setColumnStretch(c, 0)
    
        # --- Add tiles to grid ---
        self.add_tile(self.tile_ble, cell_number=1)
        self.add_tile(self.tile_led, cell_number=2)
        self.add_tile(self.tile_temp, row=1, col=0)
        self.add_tile(self.tile_hum, row=1, col=1)

        #grid_layout.addWidget(self.tile_ble, 0, 0)
        #grid_layout.addWidget(self.tile_led, 0, 1)
        #grid_layout.addWidget(self.tile_temp, 1, 0)
        #grid_layout.addWidget(self.tile_hum, 1, 1)
        layout.addLayout(self.grid_layout)

        # --- Log Layout ---
        layout.addWidget(self.log_text)
        layout.addWidget(self.clear_btn)

        # --- Async callbacks for tiles ---
        self.tile_ble.on_click = self.on_ble_pressed
        self.tile_led.on_click = self.on_led_toggle
        self.clear_btn.clicked.connect(self.on_clear_log)  # QPushButton uses clicked

    # --------------------------------
    # Add tile to grid
    # --------------------------------
    def add_tile(self, tile, cell_number: int = None, row: int = None, col: int = None):
        if cell_number:
            if 1 <= cell_number <= self.grid_rows * self.grid_cols:
                r = (cell_number - 1) // self.grid_cols
                c = (cell_number - 1) % self.grid_cols
            else:
                raise ValueError("cell_number must be 1-16")
        elif row is not None and col is not None:
            if 0 <= row < self.grid_rows and 0 <= col < self.grid_cols:
                r, c = row, col
            else:
                raise ValueError("row/col out of range")
        else:
            raise ValueError("Must provide cell_number or row/col")

        self.grid_layout.addWidget(tile, r, c)
        self.tiles[(r, c)] = tile
    # -----------------------
    # BLE tile handlers
    # -----------------------
    async def on_ble_pressed(self):
        """Connect or disconnect BLE device"""
        log(f"BLE connecting...", self.log_text)
        if not self.ble.connected:
            success = await self.ble.connect()
            self.tile_ble.set_state(success)
            log(f"BLE connected {success}", self.log_text)
        else:
            await self.ble.disconnect()
            self.tile_ble.set_state(False)
            log("BLE disconnected", self.log_text)

    async def on_led_toggle(self):
        """Toggle LED and send 3-byte BLE command"""
        # Update GUI state first
        self.tile_led.toggle()
        state = self.tile_led._state_value

        device_id = 0x01
        command_id = 0x01
        value = 0x01 if state else 0x00
        payload = bytes([value])
        await self.ble.send(device_id=device_id, cmd=command_id, payload=payload)
        log(f"Yellow LED toggled to {state}", self.log_text)

    def on_clear_log(self):
        """Clear the QTextEdit log field."""
        self.log_text.clear()

    # -----------------------
    # BLE notifications
    # -----------------------
    def handle_notification(self, data: bytes):
        """
        BLE notification callback from BLEManager.
        Redirects parsing to ble_parser and updates GUI tiles.
        """
        if not isinstance(data, (bytes, bytearray)):
            print(f"[main_window.handle_notification] Warning: data not bytes: {data}")
            return

        # Log raw BLE bytes
        log(f"BLE Raw notification: {data.hex().upper()}", self.log_text)

        # Parse into structured dict
        parsed = parse_notification(data)

        # Forward parsed data to GUI
        if parsed:
            self.on_ble_notification(parsed)

    def on_ble_notification(self, data: dict):
        """
        Example BLE notification handler:
        data = {"temp": 22.4, "hum": 41.2}
        """
        print(f"[main_window.on_ble_notification] data={data}")
        if "temp" in data:
            self.tile_temp.set_value(data["temp"])
        if "hum" in data:
            self.tile_hum.set_value(data["hum"])

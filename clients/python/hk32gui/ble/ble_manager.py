import asyncio
from bleak import BleakClient, BleakScanner
from PySide6.QtCore import QObject, Signal
from .ble_constants import *

class BLEManager(QObject):
    notificationReceived = Signal(bytes)

    def __init__(self):
        super().__init__()
        self.client: BleakClient | None = None
        self.connected = False

    async def connect(self):
        if self.connected:
            print("[ble_manager.connect][I] Already connected.") 
            return True
        print("[ble_manager.connect][I] connecting...")

        device = await BleakScanner.find_device_by_filter(
            lambda d, ad: d.name == DEVICE_NAME,
            timeout=3
        )
        if not device:
            print("[ble_manager.connect][E] Device not found")
            return False

        self.client = BleakClient(device.address)
        await self.client.connect()
        self.connected = True
        print("[ble_manager.connect][I] connected.")

        try:
            await self.client.start_notify(CHAR_UUID_RX, self._notify_handler)
            print("[ble_manager.connect][I] RX notifications enabled.")
        except:
            print("[ble_manager.connect][E] RX notifications unavailable.")

        return True

    def _notify_handler(self, _sender, data: bytearray):
        self.notificationReceived.emit(bytes(data))

    async def disconnect(self):
        if self.client:
            try:
                await self.client.stop_notify(CHAR_UUID_RX)
            except:
                pass
            await self.client.disconnect()
            self.connected = False
            print("[ble_manager.disconnect][I] disconnected.")

    async def send(self, device_id: int, cmd: int, payload: bytes = b""):
        if not self.connected:
            print("[ble_manager.send][E] Not connected.")
            return

        msg = bytes([device_id, cmd]) + payload
        await self.client.write_gatt_char(CHAR_UUID_TX, msg)

#!/usr/bin/env python3
"""
homekit32 Python HMI Client
- PySide6 GUI using Tiles (ISA-101)
- Async BLE via Bleak
"""

import sys
import asyncio
from PySide6.QtWidgets import QApplication
import qasync

from ble.ble_manager import BLEManager
from ble.ble_parser import parse_notification
from ui.main_window import MainWindow
from hmi.tile_utils import log

def main():
    """
    Entry point for the HMI client.
    Initializes QApplication, BLEManager, and main window.
    """
    app = QApplication(sys.argv)

    # Integrate Qt event loop with asyncio
    loop = qasync.QEventLoop(app)
    asyncio.set_event_loop(loop)

    # Initialize BLE manager
    ble_manager = BLEManager()

    # Create main window
    window = MainWindow(ble_manager)
    window.resize(800, 600)
    window.show()

    ble_manager.notificationReceived.connect(window.handle_notification)

    # Run Qt + asyncio event loop
    with loop:
        loop.run_forever()

if __name__ == "__main__":
    main()

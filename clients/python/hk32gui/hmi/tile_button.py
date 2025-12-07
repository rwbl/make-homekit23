from PySide6.QtWidgets import QLabel, QVBoxLayout
from PySide6.QtCore import Qt
from PySide6.QtGui import QFont, QColor, QPalette
from .tile_base import TileBase
from .tile_utils import COLOR_TILE_ACTIVE, COLOR_TILE_INACTIVE, tile_stylesheet

class TileButton(TileBase):
    """
    Tile used for ON/OFF buttons.
    Title: 25% height, State: 75% height
    """

    def __init__(self, title: str = "Button", parent=None):
        super().__init__(title, parent)

        # Replace placeholder content layout
        self.content_layout = QVBoxLayout(self.content_widget)
        self.content_layout.setContentsMargins(0, 0, 0, 0)
        self.content_layout.setSpacing(0)

        # State label (ON/OFF)
        self.lbl_state = QLabel("OFF")
        self.lbl_state.setAlignment(Qt.AlignCenter)
        self.lbl_state.setFont(QFont("Arial", 18, QFont.Bold))
        self.content_layout.addWidget(self.lbl_state)

        # Initial state
        self._state_value = False
        self.on_click = None

        # Connect click signal
        self.clicked.connect(self._handle_click)
        self._apply_style()

    def _handle_click(self):
        """Call async callback if exists, else toggle."""
        if self.on_click:
            import asyncio
            asyncio.create_task(self.on_click())
        else:
            self.toggle()

    def toggle(self):
        """Toggle ON/OFF."""
        self._state_value = not self._state_value
        self.lbl_state.setText("ON" if self._state_value else "OFF")
        self._apply_style()

    def set_state(self, on: bool):
        """Explicitly set state."""
        self._state_value = on
        self.lbl_state.setText("ON" if on else "OFF")
        self._apply_style()

    def _apply_style(self):
        """Update background color."""
        palette = self.palette()
        palette.setColor(QPalette.Window, QColor(COLOR_TILE_ACTIVE) if self._state_value else QColor(COLOR_TILE_INACTIVE))
        self.setPalette(palette)
        self.setAutoFillBackground(True)
        self.lbl_state.repaint()

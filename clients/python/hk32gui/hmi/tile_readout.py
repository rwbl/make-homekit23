from PySide6.QtWidgets import QLabel, QVBoxLayout
from PySide6.QtCore import Qt
from PySide6.QtGui import QFont, QColor, QPalette
from .tile_base import TileBase


class TileReadOut(TileBase):
    """
    Sensor readout tile.
    Layout: Title 25%, Value 70%, Unit 5%
    """

    def __init__(self, title: str = "Sensor", unit: str = "", parent=None):
        super().__init__(title, parent)

        # Replace placeholder content layout
        self.content_layout = QVBoxLayout(self.content_widget)
        self.content_layout.setContentsMargins(0, 0, 0, 0)
        self.content_layout.setSpacing(0)

        # Value label (70%)
        self.lbl_value = QLabel("---")
        self.lbl_value.setAlignment(Qt.AlignCenter)
        self.lbl_value.setFont(QFont("Arial", 18, QFont.Medium))
        self.content_layout.addWidget(self.lbl_value, stretch=70)

        # Unit label (5%)
        self.lbl_unit = QLabel(unit)
        self.lbl_unit.setAlignment(Qt.AlignCenter)
        self.lbl_unit.setFont(QFont("Arial", 10))
        self.content_layout.addWidget(self.lbl_unit, stretch=5)

        # Default style
        self._apply_style()

    def set_value(self, value):
        """Update sensor value."""
        self.lbl_value.setText(str(value))
        self.lbl_value.repaint()

    def set_unit(self, unit: str):
        """Update unit label."""
        self.lbl_unit.setText(unit)
        self.lbl_unit.repaint()

    def _apply_style(self):
        """Apply default background."""
        palette = self.palette()
        palette.setColor(QPalette.Window, QColor("#2B2B2B"))
        self.setPalette(palette)
        self.setAutoFillBackground(True)
        self.lbl_value.setStyleSheet("color: white;")
        self.lbl_unit.setStyleSheet("color: white;")

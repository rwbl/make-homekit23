"""
TileBase: Generic HMI tile base class with proper layout
Author: Robert Linn
"""

from PySide6.QtWidgets import QWidget, QLabel, QVBoxLayout
from PySide6.QtCore import Qt, Signal, QSize
from PySide6.QtGui import QFont
from .tile_utils import TILE_SIZE_DEFAULT

class TileBase(QWidget):
    """
    Base class for HMI tiles.
    Emits clicked signal when pressed.
    """
    clicked = Signal()

    def __init__(self, title: str = "Title", parent=None):
        super().__init__(parent)
        self._title_text = title

        # Main vertical layout
        self.layout = QVBoxLayout(self)
        self.layout.setContentsMargins(4, 4, 4, 4)
        self.layout.setSpacing(2)

        # Title label (25% of tile)
        self.lbl_title = QLabel(title)
        self.lbl_title.setAlignment(Qt.AlignCenter)
        self.lbl_title.setFont(QFont("Arial", 10, QFont.Bold))
        self.layout.addWidget(self.lbl_title, stretch=25)

        # Placeholder for content (value/state)
        self.content_widget = QWidget()
        self.layout.addWidget(self.content_widget, stretch=75)

        # Tile size
        self.setFixedSize(TILE_SIZE_DEFAULT, TILE_SIZE_DEFAULT)  # fixed 120x120px

    def set_title(self, text: str):
        """Update the tile title."""
        self._title_text = text
        self.lbl_title.setText(text)

    def mousePressEvent(self, event):
        """Emit clicked signal on mouse press."""
        if event.button() == Qt.LeftButton:
            self.clicked.emit()
        super().mousePressEvent(event)

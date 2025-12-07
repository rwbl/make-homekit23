"""
tile_utils.py
ISA-101 standard colors and helper functions for HMI tiles
"""


import datetime
from PySide6.QtGui import QColor
from PySide6.QtWidgets import QTextEdit

# --------------------------
# ISA-101 standard colors
# --------------------------
# Tile backgrounds
COLOR_TILE_DEFAULT = QColor("#2B2B2B")  # Dark gray background
COLOR_TILE_ACTIVE = QColor("#808080")   # Light green for ON state
COLOR_TILE_INACTIVE = QColor("#B0B0B0") # Light red for OFF state
COLOR_TILE_BORDER = QColor("#555555")   # Border gray

# Text colors
COLOR_TEXT_DEFAULT = QColor("#FFFFFF")  # White
COLOR_TEXT_VALUE = QColor("#FFFF80")    # Yellowish for values
COLOR_TEXT_UNIT = QColor("#CCCCCC")     # Light gray for units
COLOR_TEXT_TITLE = QColor("#FFFFFF")    # Title white

# Tile sizes
TILE_SIZE_DEFAULT = 120
TILE_BORDER_RADIUS = 12

# --------------------------
# Helper functions
# --------------------------
def log(message: str, text_widget: QTextEdit = None):
    """
    Print a timestamped message to console and optionally to a QTextEdit.
    """
    now = datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]
    msg = f"[{now}] {message}"
    print(msg)
    if text_widget:
        text_widget.append(msg)
        # Auto-scroll to the bottom
        text_widget.verticalScrollBar().setValue(
            text_widget.verticalScrollBar().maximum()
        )

def qcolor_to_stylesheet(color: QColor) -> str:
    """Return CSS string for QColor."""
    return f"rgb({color.red()}, {color.green()}, {color.blue()})"

def tile_stylesheet(bg_color: QColor = COLOR_TILE_DEFAULT,
                    border_color: QColor = COLOR_TILE_BORDER,
                    text_color: QColor = COLOR_TEXT_DEFAULT,
                    radius: int = TILE_BORDER_RADIUS) -> str:
    """Return full QWidget stylesheet for a tile."""
    return f"""
    QWidget {{
        background-color: {qcolor_to_stylesheet(bg_color)};
        color: {qcolor_to_stylesheet(text_color)};
        border-radius: {radius}px;
        border: 1px solid {qcolor_to_stylesheet(border_color)};
    }}
    QLabel {{
        color: {qcolor_to_stylesheet(text_color)};
    }}
    """

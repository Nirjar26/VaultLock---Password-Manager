import sys
import os
from dotenv import load_dotenv

load_dotenv()

from PyQt6.QtWidgets import QApplication
from PyQt6.QtQml import QQmlApplicationEngine
from PyQt6.QtCore import QUrl, Qt
from PyQt6.QtGui import QIcon

from vaultlock.core.config import QT_STYLE, QT_CONTROLS_STYLE, WINDOW_ICON, MAIN_QML, APP_NAME
from vaultlock.controllers.main_controller import MainController
from vaultlock.core.window_effects import apply_mica_effect

def main():
    # Enable High DPI Scaling
    QApplication.setHighDpiScaleFactorRoundingPolicy(Qt.HighDpiScaleFactorRoundingPolicy.PassThrough)
    
    # Set Quick Controls Style
    os.environ["QT_QUICK_CONTROLS_STYLE"] = QT_CONTROLS_STYLE

    app = QApplication(sys.argv)
    app.setApplicationName(APP_NAME)
    
    # Set Window Icon
    if os.path.exists(WINDOW_ICON):
        app.setWindowIcon(QIcon(str(WINDOW_ICON)))
    
    # Force Dark Mode (Fusion Style)
    app.setStyle(QT_STYLE)

    engine = QQmlApplicationEngine()
    
    # Initialize Controller
    controller = MainController()
    engine.rootContext().setContextProperty("uiBridge", controller)
    
    # Load QML
    engine.load(QUrl.fromLocalFile(str(MAIN_QML)))
    
    if not engine.rootObjects():
        sys.exit(-1)
    
    # Apply Windows Effects
    window = engine.rootObjects()[0]
    apply_mica_effect(window, controller)

    sys.exit(app.exec())

if __name__ == "__main__":
    main()

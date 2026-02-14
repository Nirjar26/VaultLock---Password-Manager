
import os
import ctypes
from PyQt6.QtCore import QObject

def apply_mica_effect(window, controller):
    """
    Apply Windows 11 Mica Alt backdrop and handle screenshot protection.
    """
    if os.name != 'nt':
        return

    try:
        hwnd = int(window.winId())
        
        # Windows DWM API Constants
        DWMWA_USE_IMMERSIVE_DARK_MODE = 20
        DWMWA_SYSTEMBACKDROP_TYPE = 38
        DWMSBT_TABBEDWINDOW = 4 # Mica Alt (Windows 11 22H2+)
        
        dwmapi = ctypes.windll.dwmapi
        
        # 1. Force Dark Mode (Titlebar & Mica Backdrop)
        dark_mode = ctypes.c_int(1)
        dwmapi.DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, ctypes.byref(dark_mode), ctypes.sizeof(dark_mode))
        
        # 2. Enable Mica Alt
        backdrop_type = ctypes.c_int(DWMSBT_TABBEDWINDOW)
        dwmapi.DwmSetWindowAttribute(hwnd, DWMWA_SYSTEMBACKDROP_TYPE, ctypes.byref(backdrop_type), ctypes.sizeof(backdrop_type))
        
        # 3. Extend Frame into Client Area (Seamless glass)
        class MARGINS(ctypes.Structure):
            _fields_ = [("cxLeftWidth", ctypes.c_int), ("cxRightWidth", ctypes.c_int), ("cyTopHeight", ctypes.c_int), ("cyBottomHeight", ctypes.c_int)]
        margins = MARGINS(-1, -1, -1, -1)
        dwmapi.DwmExtendFrameIntoClientArea(hwnd, ctypes.byref(margins))
        
        # 4. Screenshot Protection (Optional)
        def apply_protection(enabled):
            # WDA_NONE = 0
            # WDA_EXCLUDEFROMCAPTURE = 0x00000011
            affinity = 0x00000011 if enabled else 0
            ctypes.windll.user32.SetWindowDisplayAffinity(hwnd, affinity)
            
        # Hook it into the controller settings
        controller.settingsChanged.connect(lambda: apply_protection(controller.getSetting("disable_screenshots") == "1"))
        
        # Apply initial state
        apply_protection(controller.getSetting("disable_screenshots") == "1")
        
    except Exception:
        pass  # Silent fail for non-Windows or older systems

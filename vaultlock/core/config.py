
import os
import sys
from pathlib import Path

# --- ENVIRONMENT & PATH CONFIGURATION ---

def get_base_paths():
    """
    Determine the base paths for resources (bundled) and data (external/writable).
    Supports both development (src) and frozen (PyInstaller) environments.
    """
    if getattr(sys, 'frozen', False):
        # Running as compiled executable (PyInstaller)
        # sys._MEIPASS is the temp folder where data is bundled
        bundled_base = Path(sys._MEIPASS)
        
        # sys.executable is the path to the .exe file
        # We want persistent data (DB, config) to live next to the exe
        writable_base = Path(sys.executable).parent
    else:
        # Running as standard Python script
        # __file__ is vaultlock/core/config.py
        # root is 3 levels up: vaultlock/core/config.py -> vaultlock/core -> vaultlock -> root
        root = Path(__file__).resolve().parent.parent.parent
        bundled_base = root
        writable_base = root

    return bundled_base, writable_base

BUNDLED_BASE, WRITABLE_BASE = get_base_paths()

# Internal Resources (Code, Assets, UI) - Read-Only in frozen mode
VAULTLOCK_DIR = BUNDLED_BASE / "vaultlock"
ASSETS_DIR = VAULTLOCK_DIR / "assets"
UI_DIR = VAULTLOCK_DIR / "ui"

# External Data (Database, User Config) - Writable
# We might want a specific 'data' or 'config' subfolder next to the exe
DATA_DIR = WRITABLE_BASE
# Ensure we don't clutter the root if possible, but for now we stick to root or follows setup
# If we wanted a explicit variable:
# USER_DATA_DIR = WRITABLE_BASE / "data"

# --- DATABASE CONFIGURATION ---
DB_NAME = os.getenv("VAULTLOCK_DB_NAME", "vault.db")
DATABASE_DIR = BUNDLED_BASE / "vaultlock" / "database" 
# NOTE: In dev, database is in vaultlock/database. 
# IN PROD/FROZEN: We probably want the DB to be in the WRITABLE_DIR, not the temp _MEIPASS.
# Let's fix this logic:

if getattr(sys, 'frozen', False):
    # In release, put vault.db next to the exe (or in a subfolder)
    DB_PATH = WRITABLE_BASE / DB_NAME
else:
    # In dev, keep it in the source tree or local
    DB_PATH = VAULTLOCK_DIR / "database" / DB_NAME

# --- APPLICATION SETTINGS ---
APP_NAME = "VaultLock"
VERSION = "1.0.0"

# --- SECURITY DEFAULTS ---
DEFAULT_LOCKOUT_ATTEMPTS = 5
DEFAULT_LOCKOUT_TIME = 30
DEFAULT_CLIPBOARD_CLEAR_TIME = 30

# --- UI CONFIGURATION ---
QT_STYLE = "Fusion"
QT_CONTROLS_STYLE = "Basic"
WINDOW_ICON = ASSETS_DIR / "VaultLock_windowicon.png"
MAIN_QML = UI_DIR / "Main.qml"

# --- ENV SECRET LOADING (Placeholder) ---
# If we had API keys, we would load them here
# API_KEY = os.getenv("API_KEY")

import base64
import os
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.fernet import Fernet, InvalidToken

class EncryptionService:
    def __init__(self, master_password, salt):
        self._key = None
        self._fernet = None
        self._salt = salt
        
        self._initialize_fernet(master_password)

    def _initialize_fernet(self, master_password):
        # OWASP recommended 600,000 iterations for PBKDF2-HMAC-SHA256
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=self._salt,
            iterations=600000,
        )
        key = base64.urlsafe_b64encode(kdf.derive(master_password.encode()))
        self._fernet = Fernet(key)
        # We do NOT store the master_password in the instance state to prevent memory leaks

    def encrypt(self, data: str) -> bytes:
        if not data or self._fernet is None:
            return b""
        return self._fernet.encrypt(data.encode())

    def decrypt(self, token: bytes) -> str:
        if not token or self._fernet is None:
            return ""
        try:
            # Ensure token is bytes
            if isinstance(token, str):
                token = token.encode()
            return self._fernet.decrypt(token).decode()
        except InvalidToken:
            return "[Decryption Failed]"
        except Exception:
            return "[Error]"

    def clear(self):
        """Scrub keys from memory."""
        self._key = None
        self._fernet = None
        self._salt = None

# Global singleton or instance management
_current_service = None

def initialize_encryption(master_password, user_id=None):
    global _current_service
    # Clear any existing service before creating a new one
    if _current_service:
        _current_service.clear()
        
    from vaultlock.database.db_manager import get_db_manager
    db = get_db_manager()
    salt = db.get_vault_salt(user_id) if user_id else None
    if not salt:
        # Emergency fallback or registration phase
        salt = b'\x82\x1c\x94\xf4\xbc\xda=\xb6\xb7\xa5\xbf\x91\r\x98p\xd6'
        
    _current_service = EncryptionService(master_password, salt)
    return _current_service

def clear_encryption():
    global _current_service
    if _current_service:
        _current_service.clear()
        _current_service = None

def get_encryption_service():
    # This might return None if not initialized (no master password provided yet)
    return _current_service

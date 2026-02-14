import os
import random
import string
import pyperclip
from PyQt6.QtCore import QObject, pyqtProperty, pyqtSlot, pyqtSignal, QTimer, QDateTime
from vaultlock.services.logo_manager import get_logo_manager
from vaultlock.database.db_manager import get_db_manager
from vaultlock.services.encryption_service import initialize_encryption, get_encryption_service, clear_encryption


class MainController(QObject):
    # Signals
    currentFilterChanged = pyqtSignal()
    searchQueryChanged = pyqtSignal()
    selectedIdChanged = pyqtSignal()
    filteredCredentialsChanged = pyqtSignal()
    countsChanged = pyqtSignal()
    foldersChanged = pyqtSignal()
    selectedItemChanged = pyqtSignal()
    logoUpdated = pyqtSignal(str, str) # name, path
    isAddingCredentialChanged = pyqtSignal()
    isEditingChanged = pyqtSignal()
    sidebarFoldersChanged = pyqtSignal()
    folderTreeChanged = pyqtSignal()
    isRegisteredChanged = pyqtSignal()
    isLockedChanged = pyqtSignal()
    userInfoChanged = pyqtSignal()
    settingsChanged = pyqtSignal()
    lockoutRemainingChanged = pyqtSignal()
    failedAttemptsChanged = pyqtSignal()
    sortOrderChanged = pyqtSignal()

    def __init__(self):
        super().__init__()
        self._current_filter = "All"
        self._search_query = ""
        self._selected_id = ""
        self._filtered_credentials = []
        self._counts = {}
        self._is_adding_credential = False
        self._is_editing = False
        self._is_locked = True
        self._failed_attempts = 0
        self._lockout_remaining = 0
        self.__master_password = None
        self._user_info = {"full_name": "", "email": ""}
        self._sort_order = "AZ"
        self._sort_criteria = "name_asc"
        
        self.logo_manager = get_logo_manager()
        self.logo_manager.logo_updated.connect(self.logoUpdated)
        
        self._last_activity = QDateTime.currentDateTime()
        self._clipboard_timer = QTimer(self)
        self._clipboard_timer.timeout.connect(self._clear_clipboard)
        
        self._lockout_timer = QTimer(self)
        self._lockout_timer.timeout.connect(self._update_lockout)
        self._lockout_timer.setInterval(1000)

        self.db = get_db_manager()
        self._active_user_id = None
        self._registration_mode = False
        self._folders = []
        self._all_credentials = []

        if self.isRegistered:
            self._is_locked = True
        else:
            self._is_locked = False

    # --- Properties ---

    @pyqtProperty(bool, notify=isRegisteredChanged)
    def registrationMode(self):
        return self._registration_mode

    @pyqtSlot()
    def enterRegistrationMode(self):
        self._registration_mode = True
        self.isRegisteredChanged.emit()

    @pyqtProperty(list, notify=isRegisteredChanged)
    def allUsers(self):
        return self.db.get_all_users()

    @pyqtProperty(int, notify=isLockedChanged)
    def activeUserId(self):
        return self._active_user_id if self._active_user_id else 0

    @pyqtProperty(str, notify=userInfoChanged)
    def userName(self):
        return self._user_info.get("full_name", "")

    @pyqtProperty(str, notify=userInfoChanged)
    def userEmail(self):
        return self._user_info.get("email", "")

    @pyqtProperty(bool, notify=settingsChanged)
    def hidePasswordsDefault(self):
        return self.getSetting("hide_passwords_default", "1") == "1"

    @pyqtProperty(str, notify=currentFilterChanged)
    def currentFilter(self):
        return self._current_filter
        
    @currentFilter.setter
    def currentFilter(self, val):
        if self._current_filter != val:
            self._current_filter = val
            self.currentFilterChanged.emit()
            self.update_models()

    @pyqtProperty(str, notify=searchQueryChanged)
    def searchQuery(self):
        return self._search_query
        
    @searchQuery.setter
    def searchQuery(self, val):
        if self._search_query != val:
            self._search_query = val
            self.searchQueryChanged.emit()
            self.update_models()

    @pyqtProperty(str, notify=selectedIdChanged)
    def selectedId(self):
        return self._selected_id
        
    @selectedId.setter
    def selectedId(self, val):
        if self._selected_id != val:
            self._selected_id = val
            self.selectedIdChanged.emit()
            self.selectedItemChanged.emit()

    @pyqtProperty('QVariantMap', notify=selectedItemChanged)
    def selectedItem(self):
        for item in self._all_credentials:
            if str(item["id"]) == str(self._selected_id):
                return item.copy()
        return {}

    @pyqtProperty(list, notify=filteredCredentialsChanged)
    def filteredCredentials(self):
        return self._filtered_credentials

    @pyqtProperty(list, notify=foldersChanged)
    def folders(self):
        return self._folders

    @pyqtProperty(list, notify=sidebarFoldersChanged)
    def sidebarFolders(self):
        return [f for f in self._folders if f['name'] != "No Folder"]
        
    @pyqtProperty('QVariantList', notify=folderTreeChanged)
    def folderTree(self):
        return self.getFolderTree()

    @pyqtProperty('QVariantMap', notify=countsChanged)
    def counts(self):
        return self._counts

    @pyqtProperty(bool, notify=isAddingCredentialChanged)
    def isAddingCredential(self):
        return self._is_adding_credential
    
    @isAddingCredential.setter
    def isAddingCredential(self, val):
        if self._is_adding_credential != val:
            self._is_adding_credential = val
            self.isAddingCredentialChanged.emit()

    @pyqtProperty(bool, notify=isEditingChanged)
    def isEditing(self):
        return self._is_editing
    
    @isEditing.setter
    def isEditing(self, val):
        if self._is_editing != val:
            self._is_editing = val
            self.isEditingChanged.emit()

    @pyqtProperty(bool, notify=isRegisteredChanged)
    def isRegistered(self):
        return self.db.is_vault_registered()

    @pyqtProperty(bool, notify=isLockedChanged)
    def isLocked(self):
        return self._is_locked

    @pyqtProperty(bool, notify=settingsChanged)
    def isPinSet(self):
        return bool(self.getSetting("pin_code"))

    @pyqtProperty(int, notify=lockoutRemainingChanged)
    def lockoutRemaining(self):
        return self._lockout_remaining

    @pyqtProperty(int, notify=failedAttemptsChanged)
    def failedAttempts(self):
        return self._failed_attempts

    @pyqtProperty(str, notify=sortOrderChanged)
    def sortOrder(self):
        return self._sort_order

    @sortOrder.setter
    def sortOrder(self, val):
        if self._sort_order != val:
            self._sort_order = val
            if val == "AZ": self._sort_criteria = "name_asc"
            elif val == "ZA": self._sort_criteria = "name_desc"
            self.sortOrderChanged.emit()
            self.update_models()

    @pyqtProperty(str, notify=sortOrderChanged)
    def sortCriteria(self):
        return self._sort_criteria

    @sortCriteria.setter
    def sortCriteria(self, val):
        if self._sort_criteria != val:
            self._sort_criteria = val
            if val == "name_asc": self._sort_order = "AZ"
            elif val == "name_desc": self._sort_order = "ZA"
            self.sortOrderChanged.emit()
            self.update_models()

    # --- Slots ---

    @pyqtSlot(int)
    def selectUser(self, user_id):
        self._active_user_id = user_id
        info = self.db.get_user_info(user_id)
        if info:
            self._user_info = info
            self.userInfoChanged.emit()
        self.isLockedChanged.emit()

    @pyqtSlot(str, result=bool)
    def unlockVault(self, password):
        self._reset_activity()
        if self._lockout_remaining > 0 or not self._active_user_id:
            return False

        if self.db.verify_password(self._active_user_id, password):
            try:
                initialize_encryption(password, self._active_user_id)
                self.__master_password = password
                self._is_locked = False
                self._failed_attempts = 0
                self.load_from_db()
                self.isLockedChanged.emit()
                self.failedAttemptsChanged.emit()
                return True
            except Exception as e:
                import traceback
                traceback.print_exc()
                return False
        
        self._failed_attempts += 1
        self.failedAttemptsChanged.emit()
        if self._failed_attempts >= 5: # Default limit
            self._start_lockout()
        return False

    def _start_lockout(self):
        self._lockout_remaining = 30
        self.lockoutRemainingChanged.emit()
        self._lockout_timer.start()

    def _update_lockout(self):
        if self._lockout_remaining > 0:
            self._lockout_remaining -= 1
            self.lockoutRemainingChanged.emit()
            if self._lockout_remaining <= 0:
                self._lockout_timer.stop()
                self._failed_attempts = 0
                self.failedAttemptsChanged.emit()
        
    @pyqtSlot(str)
    def copyToClipboard(self, text):
        if not text: return
        self._reset_activity()
        pyperclip.copy(text)
        
        clear_seconds = 30
        try:
            val = self.getSetting("clipboard_clear_time", "30")
            clear_seconds = int(val)
        except: pass
        
        if clear_seconds > 0:
            self._clipboard_timer.start(clear_seconds * 1000)

    def _clear_clipboard(self):
        self._clipboard_timer.stop()
        pyperclip.copy("")

    def _reset_activity(self):
        self._last_activity = QDateTime.currentDateTime()

    @pyqtSlot(int, bool, bool, bool, result=str)
    def generateSecurePassword(self, length=16, use_symbols=True, use_numbers=True, use_caps=True):
        chars = string.ascii_lowercase
        if use_caps: chars += string.ascii_uppercase
        if use_numbers: chars += string.digits
        if use_symbols: chars += "!@#$%^&*()_+-=[]{}|;:,.<>?"
        if not chars: return ""
        return ''.join(random.SystemRandom().choice(chars) for _ in range(length))

    @pyqtSlot(str, str, result=str)
    @pyqtSlot(str, result=str)
    def getSetting(self, key, default=""):
        return self.db.get_setting(self._active_user_id, key, default)

    @pyqtSlot(str, str)
    def setSetting(self, key, value):
        self.db.set_setting(self._active_user_id, key, value)
        self.settingsChanged.emit()

    @pyqtSlot()
    def lockVault(self):
        self._reset_activity()
        self._is_locked = True
        self.__master_password = None
        clear_encryption()
        self._all_credentials = []
        self._filtered_credentials = []
        self._folders = []
        self._counts = {}
        self._selected_id = ""
        
        self.filteredCredentialsChanged.emit()
        self.foldersChanged.emit()
        self.sidebarFoldersChanged.emit()
        self.folderTreeChanged.emit()
        self.countsChanged.emit()
        self.selectedIdChanged.emit()
        self.isLockedChanged.emit()

    @pyqtSlot()
    def wipeAllData(self):
        self._reset_activity()
        if self._active_user_id:
            self.db.wipe_user_data(self._active_user_id)
        
        self._all_credentials = []
        self._filtered_credentials = []
        self._folders = []
        self._counts = {}
        self._selected_id = ""
        self.__master_password = None
        self._active_user_id = None
        clear_encryption()
        
        self.isRegisteredChanged.emit()
        self.isLockedChanged.emit()
        self.userInfoChanged.emit()
        self.countsChanged.emit()
        self.foldersChanged.emit()
        self.sidebarFoldersChanged.emit()
        self.folderTreeChanged.emit()
        self.filteredCredentialsChanged.emit()

    @pyqtSlot()
    def logout(self):
        self.lockVault()
        self._active_user_id = None
        self._registration_mode = False
        self.isLockedChanged.emit()
        self.isRegisteredChanged.emit()
        self.userInfoChanged.emit()

    @pyqtSlot()
    def signInBack(self):
        self._active_user_id = None
        self._is_locked = True
        self._registration_mode = False
        self.isLockedChanged.emit()
        self.isRegisteredChanged.emit()

    @pyqtSlot(str, str, str, result=bool)
    def registerVault(self, full_name, email, password):
        try:
            user_id = self.db.register_vault(full_name, email, password)
            if user_id:
                self._active_user_id = user_id
                initialize_encryption(password, user_id)
                self.__master_password = password
                self._user_info = {"full_name": full_name, "email": email}
                self._is_locked = False
                self._registration_mode = False
                self.isRegisteredChanged.emit()
                self.isLockedChanged.emit()
                self.userInfoChanged.emit()
                self.load_from_db()
                return True
            return False
        except Exception as e:
            return False

    @pyqtSlot(str)
    def setFilter(self, name):
        self.currentFilter = name

    @pyqtSlot()
    def toggleSort(self):
        self.sortOrder = "ZA" if self.sortOrder == "AZ" else "AZ"

    @pyqtSlot("QVariantMap")
    def addCredential(self, data):
        new_id = self.db.add_credential(data, self._active_user_id)
        if new_id:
            self.load_from_db()
            self.isAddingCredential = False
            self.selectedId = str(new_id)

    @pyqtSlot(str)
    def deleteCredential(self, cred_id):
        self._reset_activity()
        self.db.delete_credential(cred_id)
        self.load_from_db()
        if self._selected_id == cred_id:
            self.selectedId = ""

    @pyqtSlot(str)
    def permanentlyDeleteCredential(self, cred_id):
        self._reset_activity()
        self.db.permanently_delete_credential(cred_id)
        self.load_from_db()
        if self._selected_id == cred_id:
            self.selectedId = ""

    @pyqtSlot(str, str)
    def updateCredentialFolder(self, cred_id, folder_name):
        self._reset_activity()
        folders = self.db.get_all_folders(self._active_user_id)
        f_id = None
        for f in folders:
            if f['name'] == folder_name:
                f_id = f['id']
                break
        self.db.update_credential(cred_id, {"folder_id": f_id})
        self.load_from_db()

    @pyqtSlot()
    def purgeDeletedItems(self):
        self._reset_activity()
        self.db.purge_deleted_credentials(self._active_user_id)
        self.load_from_db()

    @pyqtSlot("QVariant", str, result=bool)
    def renameFolder(self, folder_id, new_name):
        self._reset_activity()
        self.db.update_folder(folder_id, {"name": new_name})
        self.load_from_db()
        return True

    @pyqtSlot(int, int)
    def moveFolder(self, folder_id, new_parent_id):
        self._reset_activity()
        p_id = new_parent_id if (new_parent_id and new_parent_id > 0) else None
        self.db.update_folder(folder_id, {"parent_id": p_id})
        self.load_from_db()

    @pyqtSlot(int, str)
    def updateFolderColor(self, folder_id, color):
        self._reset_activity()
        self.db.update_folder(folder_id, {"color": color})
        self.load_from_db()

    @pyqtSlot(int, str)
    def updateFolderIcon(self, folder_id, icon):
        self._reset_activity()
        self.db.update_folder(folder_id, {"icon": icon})
        self.load_from_db()

    @pyqtSlot(result=list)
    def getFolderTree(self):
        folders = [f for f in self._folders if f['name'] != "No Folder"]
        folder_map = {f['id']: {**f, 'children': []} for f in folders}
        tree = []
        for f in folders:
            item = folder_map[f['id']]
            p_id = f.get('parent_id')
            if p_id and p_id != f['id']:
                parent = folder_map.get(p_id)
                if parent:
                    parent['children'].append(item)
                else:
                    tree.append(item)
            else:
                tree.append(item)
        return tree

    @pyqtSlot(str)
    def restoreCredential(self, cred_id):
        self._reset_activity()
        self.db.restore_credential(cred_id)
        self.load_from_db()

    @pyqtSlot(str, str, "QVariant")
    def createNewFolder(self, name, color="#4B5563", parent_id=None):
        self._reset_activity()
        if parent_id is not None and str(parent_id).isdigit():
            val = int(parent_id)
            p_id = val if val > 0 else None
        else:
            p_id = None
        self.db.add_folder(name, self._active_user_id, color, p_id)
        self.load_from_db()

    @pyqtSlot(int)
    def deleteFolder(self, folder_id):
        self._reset_activity()
        self.db.delete_folder(folder_id)
        self.currentFilter = "All"
        self.load_from_db()

    @pyqtSlot(str, result=bool)
    def verifyPin(self, pin):
        self._reset_activity()
        stored_pin = self.getSetting("pin_code")
        if not stored_pin or stored_pin != pin:
            return False

        wrapped_mp = self.getSetting("pin_wrapped_mp")
        pin_salt_hex = self.getSetting("pin_salt")
        if wrapped_mp and pin_salt_hex:
            try:
                from vaultlock.services.encryption_service import EncryptionService
                import base64
                pin_salt = bytes.fromhex(pin_salt_hex)
                pin_service = EncryptionService(pin, pin_salt)
                wrapped_bytes = base64.b64decode(wrapped_mp)
                master_password = pin_service.decrypt(wrapped_bytes)
                if master_password and master_password not in ["[Decryption Failed]", "[Error]"]:
                    if self.unlockVault(master_password):
                        return True
            except: pass
        return False

    @pyqtSlot(str)
    def setPin(self, pin):
        service = get_encryption_service()
        if not service or not self.__master_password: return
        import os
        import base64
        from vaultlock.services.encryption_service import EncryptionService
        self.setSetting("pin_code", pin)
        pin_salt = os.urandom(16)
        pin_service = EncryptionService(pin, pin_salt)
        wrapped_blob = pin_service.encrypt(self.__master_password)
        wrapped_b64 = base64.b64encode(wrapped_blob).decode('utf-8')
        self.setSetting("pin_salt", pin_salt.hex())
        self.setSetting("pin_wrapped_mp", wrapped_b64)
        self.settingsChanged.emit()

    @pyqtSlot()
    def removePin(self):
        self.setSetting("pin_code", "")
        self.setSetting("pin_salt", "")
        self.setSetting("pin_wrapped_mp", "")
        self.settingsChanged.emit()

    @pyqtSlot("QVariantMap")
    def updateCredential(self, data):
        self._reset_activity()
        cred_id = data.get('id')
        if not cred_id: return
        updates = {}
        mapping = ["service_name", "username", "email", "website", "favourite"]
        for key in mapping:
            if key in data:
                db_key = "is_favourite" if key == "favourite" else key
                updates[db_key] = data[key]
        if 'folder' in data:
            folders = self.db.get_all_folders(self._active_user_id)
            f_id = None
            for f in folders:
                if f['name'] == data['folder']:
                    f_id = f['id']
                    break
            updates['folder_id'] = f_id
        encryptor = get_encryption_service()
        if 'password' in data and encryptor:
            pwd = data['password']
            if pwd not in ["", "••••••••", "[Locked]", "[Decryption Failed]"]:
                updates['password_blob'] = encryptor.encrypt(pwd)
        if 'notes' in data and encryptor:
            notes = data['notes']
            if notes not in ["[Locked]", "[Decryption Failed]"]:
                updates['notes_blob'] = encryptor.encrypt(notes)
        self.db.update_credential(cred_id, updates)
        self.load_from_db()

    @pyqtSlot(str)
    def toggleFavourite(self, cred_id):
        self._reset_activity()
        item = next((i for i in self._all_credentials if i["id"] == cred_id), None)
        if item:
            new_state = not item["favourite"]
            self.db.update_credential(cred_id, {"is_favourite": 1 if new_state else 0})
            self.load_from_db()

    @pyqtSlot(str, result=str)
    def getFolderColor(self, name):
        return next((f["color"] for f in self._folders if f["name"] == name), "#4B5563")

    @pyqtSlot(str, str, result=bool)
    def changeMasterPassword(self, old_password, new_password):
        self._reset_activity()
        if not self.db.verify_password(self._active_user_id, old_password):
            return False
            
        try:
            encryptor = get_encryption_service()
            if not encryptor: return False
            
            all_creds = self.db.get_all_credentials(self._active_user_id)
            
            from vaultlock.services.encryption_service import EncryptionService
            import os
            new_salt = os.urandom(16)
            new_service = EncryptionService(new_password, new_salt)
            
            re_encrypted = []
            for cred in all_creds:
                # Sensitive items were decrypted during get_all_credentials
                p, n = cred.get('password', ''), cred.get('notes', '')
                if p in ["[Decryption Failed]", "[Error]", "[Locked]"]: return False
                
                re_encrypted.append((cred['id'], new_service.encrypt(p), new_service.encrypt(n)))
            
            if self.db.change_master_password(self._active_user_id, new_password, new_salt, re_encrypted):
                initialize_encryption(new_password)
                self.__master_password = new_password
                if self.isPinSet: self.removePin()
                return True
            return False
        except: return False

    @pyqtSlot(result=bool)
    def backupVault(self):
        return self.db.backup_vault()

    @pyqtSlot(str, str, result=str)
    def resolveLogo(self, name, website=""):
        self._reset_activity()
        path, is_cached = self.logo_manager.get_logo_path(name, website)
        return "file:///" + path.replace("\\", "/") if (is_cached and path) else ""

    def update_models(self):
        base = self._all_credentials
        q = self._search_query.lower()
        counts = {
            "All": len([x for x in base if not x.get("is_deleted")]),
            "Favourites": len([x for x in base if x.get("favourite") and not x.get("is_deleted")]),
            "Deleted": len([x for x in base if x.get("is_deleted")])
        }
        for f in self._folders:
            f_name = f.get("name", "Unknown")
            counts[f_name] = len([x for x in base if x.get("folder") == f_name and not x.get("is_deleted")])
        self._counts = counts
        self.countsChanged.emit()

        filtered = []
        for item in base:
            match = True
            if self._current_filter == "Deleted":
                if not item["is_deleted"]: match = False
            else:
                if item["is_deleted"]: match = False
            if not match: continue

            if self._current_filter == "Favourites":
                if not item["favourite"]: match = False
            elif self._current_filter != "All" and self._current_filter != "Deleted":
                if item["folder"] != self._current_filter: match = False
            
            if match and q:
                service_match = q in item["service_name"].lower() if item.get("service_name") else False
                username_match = q in item["username"].lower() if item.get("username") else False
                if not service_match and not username_match:
                    match = False
            if match: filtered.append(item)
        
        def safe_lower(x):
            name = x.get("service_name")
            return name.lower() if name else ""

        reverse = self._sort_order == "ZA"
        filtered.sort(key=safe_lower, reverse=reverse)
        
        self._filtered_credentials = filtered
        self.filteredCredentialsChanged.emit()
        self.selectedItemChanged.emit()

    def load_from_db(self):
        try:
            if not self._active_user_id: return
            db_folders = self.db.get_all_folders(self._active_user_id)
            self._folders = [{"name": "No Folder", "color": "#4B5563"}] + db_folders
            self._all_credentials = self.db.get_all_credentials(self._active_user_id)
            self.update_models()
            self.foldersChanged.emit()
            self.sidebarFoldersChanged.emit()
            self.folderTreeChanged.emit()
        except Exception:
            pass  # Silent fail - database not ready

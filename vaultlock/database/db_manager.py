import os
import sqlite3
from argon2 import PasswordHasher
from datetime import datetime
from contextlib import contextmanager
from vaultlock.services.encryption_service import get_encryption_service
from vaultlock.core.config import DB_PATH


class DatabaseManager:
    def __init__(self, db_path="vault.db"):
        self.db_path = db_path
        self._init_db()

    @contextmanager
    def _get_connection(self):
        conn = sqlite3.connect(self.db_path)
        try:
            conn.execute("PRAGMA foreign_keys = ON")
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    def _init_db(self):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("PRAGMA foreign_keys = ON")
            
            # Create Schema Info table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS schema_info (
                    version INTEGER PRIMARY KEY
                )
            ''')
            
            # Initialize schema version if empty
            cursor.execute("SELECT COUNT(*) FROM schema_info")
            if cursor.fetchone()[0] == 0:
                cursor.execute("INSERT INTO schema_info (version) VALUES (1)")
            
            # Create Users table (formerly master_vault)
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    full_name TEXT,
                    email TEXT UNIQUE,
                    master_password_hash TEXT,
                    vault_salt BLOB,
                    is_active BOOLEAN DEFAULT 0,
                    created_at TIMESTAMP DEFAULT (datetime('now', 'localtime'))
                )
            ''')

            # Migration: If master_vault exists and has data, move it to users
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='master_vault'")
            if cursor.fetchone():
                cursor.execute("SELECT full_name, email, master_password_hash, vault_salt FROM master_vault WHERE is_registered = 1")
                old_user = cursor.fetchone()
                if old_user:
                    cursor.execute("INSERT OR IGNORE INTO users (full_name, email, master_password_hash, vault_salt) VALUES (?, ?, ?, ?)", old_user)
                cursor.execute("DROP TABLE master_vault")

            # Create Folders table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS folders (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    color TEXT DEFAULT '#4B5563',
                    parent_id INTEGER,
                    user_id INTEGER,
                    icon TEXT DEFAULT 'folder.svg',
                    created_at TIMESTAMP DEFAULT (datetime('now', 'localtime')),
                    updated_at TIMESTAMP DEFAULT (datetime('now', 'localtime')),
                    FOREIGN KEY (parent_id) REFERENCES folders (id) ON DELETE CASCADE,
                    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
                )
            ''')
            
            # Migration: Ensure folders has user_id
            cursor.execute("PRAGMA table_info(folders)")
            cols = [c[1] for c in cursor.fetchall()]
            if 'user_id' not in cols:
                cursor.execute("ALTER TABLE folders ADD COLUMN user_id INTEGER REFERENCES users(id) ON DELETE CASCADE")
            if 'parent_id' not in cols:
                cursor.execute("ALTER TABLE folders ADD COLUMN parent_id INTEGER")
            if 'icon' not in cols:
                cursor.execute("ALTER TABLE folders ADD COLUMN icon TEXT DEFAULT 'folder.svg'")
            if 'updated_at' not in cols:
                cursor.execute("ALTER TABLE folders ADD COLUMN updated_at TIMESTAMP")
            
            # Create Settings table (User-specific)
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS settings (
                    user_id INTEGER,
                    key TEXT,
                    value TEXT,
                    PRIMARY KEY (user_id, key),
                    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
                )
            ''')

            # Create Credentials table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS credentials (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    service_name TEXT NOT NULL,
                    username TEXT,
                    email TEXT,
                    password_blob BLOB,
                    website TEXT,
                    notes_blob BLOB,
                    folder_id INTEGER,
                    user_id INTEGER,
                    is_favourite BOOLEAN DEFAULT 0,
                    is_deleted BOOLEAN DEFAULT 0,
                    created_at TIMESTAMP DEFAULT (datetime('now', 'localtime')),
                    updated_at TIMESTAMP DEFAULT (datetime('now', 'localtime')),
                    FOREIGN KEY (folder_id) REFERENCES folders (id) ON DELETE SET NULL,
                    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
                )
            ''')
            
            # Migration for credentials
            cursor.execute("PRAGMA table_info(credentials)")
            cols = [row[1] for row in cursor.fetchall()]
            if "is_deleted" not in cols:
                cursor.execute("ALTER TABLE credentials ADD COLUMN is_deleted BOOLEAN DEFAULT 0")
            if "user_id" not in cols:
                cursor.execute("ALTER TABLE credentials ADD COLUMN user_id INTEGER REFERENCES users(id) ON DELETE CASCADE")

            # Migration for settings (handling PK change)
            cursor.execute("PRAGMA table_info(settings)")
            s_cols = {c[1]: c[5] for c in cursor.fetchall()} # name: pk_index
            
            # If user_id is not present OR it's not part of a composite PK
            if 'user_id' not in s_cols or s_cols.get('key') == 1:
                # We need to recreate the table to support multi-user PK
                cursor.execute("ALTER TABLE settings RENAME TO settings_old")
                cursor.execute('''
                    CREATE TABLE settings (
                        user_id INTEGER,
                        key TEXT,
                        value TEXT,
                        PRIMARY KEY (user_id, key),
                        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
                    )
                ''')
                # Copy data back
                if 'user_id' in s_cols:
                    cursor.execute("INSERT INTO settings (user_id, key, value) SELECT user_id, key, value FROM settings_old")
                else:
                    cursor.execute("INSERT INTO settings (key, value) SELECT key, value FROM settings_old")
                cursor.execute("DROP TABLE settings_old")

            # Assign orphaned data to the first user
            cursor.execute("SELECT id FROM users LIMIT 1")
            first_user = cursor.fetchone()
            if first_user:
                u_id = first_user[0]
                cursor.execute("UPDATE credentials SET user_id = ? WHERE user_id IS NULL", (u_id,))
                cursor.execute("UPDATE folders SET user_id = ? WHERE user_id IS NULL", (u_id,))
                cursor.execute("UPDATE settings SET user_id = ? WHERE user_id IS NULL", (u_id,))

            conn.commit()

    def get_all_credentials(self, user_id):
        with self._get_connection() as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute('''
                SELECT c.*, f.name as folder_name 
                FROM credentials c 
                LEFT JOIN folders f ON c.folder_id = f.id
                WHERE c.user_id = ?
            ''', (user_id,))
            rows = cursor.fetchall()
            result = []
            for row in rows:
                d = dict(row)
                d['folder'] = d['folder_name'] if d['folder_name'] else "No Folder"
                d['favourite'] = bool(d['is_favourite'])
                d['is_deleted'] = bool(d.get('is_deleted', 0))
                d['id'] = str(d['id'])
                
                encryptor = get_encryption_service()
                if d.get('password_blob'):
                    d['password'] = encryptor.decrypt(d['password_blob']) if encryptor else "[Locked]"
                else:
                    d['password'] = ""
                    
                if d.get('notes_blob'):
                    d['notes'] = encryptor.decrypt(d['notes_blob']) if encryptor else "[Locked]"
                else:
                    d['notes'] = ""
                result.append(d)
            return result

    def get_all_folders(self, user_id):
        with self._get_connection() as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute("""
                SELECT f.*, 
                (SELECT COUNT(*) FROM credentials c WHERE c.folder_id = f.id AND c.is_deleted = 0) as item_count 
                FROM folders f
                WHERE f.user_id = ?
            """, (user_id,))
            return [dict(row) for row in cursor.fetchall()]

    def add_credential(self, data, user_id):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            folder_id = None
            if data.get('folder') and data.get('folder') != "No Folder":
                cursor.execute("SELECT id FROM folders WHERE name=? AND user_id=?", (data.get('folder'), user_id))
                row = cursor.fetchone()
                if row:
                    folder_id = row[0]

            encryptor = get_encryption_service()
            pwd_data = data.get('password', '')
            notes_data = data.get('notes', '')
            
            if encryptor:
                pwd_blob = encryptor.encrypt(pwd_data)
                notes_blob = encryptor.encrypt(notes_data)
            else:
                return None

            cursor.execute('''
                INSERT INTO credentials (service_name, username, email, website, folder_id, user_id, is_favourite, password_blob, notes_blob, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, (datetime('now', 'localtime')), (datetime('now', 'localtime')))
            ''', (
                data.get('service_name'),
                data.get('username'),
                data.get('email'),
                data.get('website'),
                folder_id,
                user_id,
                1 if data.get('favourite') else 0,
                pwd_blob,
                notes_blob
            ))
            conn.commit()
            return cursor.lastrowid

    def update_credential(self, cred_id, data):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            fields = []
            values = []
            mapping = {
                "service_name": "service_name",
                "username": "username",
                "email": "email",
                "website": "website",
                "folder_id": "folder_id",
                "is_favourite": "is_favourite",
                "password_blob": "password_blob",
                "notes_blob": "notes_blob"
            }
            for key, col in mapping.items():
                if key in data:
                    fields.append(f"{col} = ?")
                    values.append(data[key])
            if not fields: return
            values.append(cred_id)
            query = f"UPDATE credentials SET {', '.join(fields)}, updated_at=(datetime('now', 'localtime')) WHERE id=?"
            cursor.execute(query, tuple(values))
            conn.commit()

    def change_master_password(self, user_id, new_password, new_salt, re_encrypted_credentials):
        ph = PasswordHasher()
        new_hash = ph.hash(new_password)
        with self._get_connection() as conn:
            cursor = conn.cursor()
            try:
                cursor.execute("UPDATE users SET master_password_hash = ?, vault_salt = ? WHERE id = ?", 
                             (new_hash, new_salt, user_id))
                for cred_id, p_blob, n_blob in re_encrypted_credentials:
                    cursor.execute("UPDATE credentials SET password_blob = ?, notes_blob = ?, updated_at = (datetime('now', 'localtime')) WHERE id = ?", 
                                 (p_blob, n_blob, cred_id))
                conn.commit()
                return True
            except:
                conn.rollback()
                return False

    def delete_credential(self, cred_id):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("UPDATE credentials SET is_deleted=1 WHERE id=?", (cred_id,))
            conn.commit()

    def permanently_delete_credential(self, cred_id):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM credentials WHERE id=?", (cred_id,))
            conn.commit()

    def purge_deleted_credentials(self, user_id):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM credentials WHERE is_deleted = 1 AND user_id = ?", (user_id,))
            conn.commit()
            
    def restore_credential(self, cred_id):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("UPDATE credentials SET is_deleted=0 WHERE id=?", (cred_id,))
            conn.commit()

    def add_folder(self, name, user_id, color="#4B5563", parent_id=None, icon="folder.svg"):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            try:
                cursor.execute("INSERT INTO folders (name, color, parent_id, user_id, icon, created_at, updated_at) VALUES (?, ?, ?, ?, ?, (datetime('now', 'localtime')), (datetime('now', 'localtime')))", 
                             (name, color, parent_id, user_id, icon))
                conn.commit()
                return cursor.lastrowid
            except sqlite3.IntegrityError:
                return None

    def update_folder(self, folder_id, data):
        if not data: return
        allowed_cols = {"name", "color", "parent_id", "icon", "updated_at"}
        with self._get_connection() as conn:
            cursor = conn.cursor()
            updates = []
            params = []
            for key, val in data.items():
                if key in allowed_cols:
                    updates.append(f"{key} = ?")
                    params.append(val)
            if not updates: return
            updates.append("updated_at = (datetime('now', 'localtime'))")
            query = f"UPDATE folders SET {', '.join(updates)} WHERE id = ?"
            params.append(folder_id)
            cursor.execute(query, tuple(params))
            conn.commit()

    def delete_folder(self, folder_id):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            # Simplification: mark credentials as No Folder
            cursor.execute("UPDATE credentials SET folder_id = NULL WHERE folder_id = ?", (folder_id,))
            cursor.execute("DELETE FROM folders WHERE id = ?", (folder_id,))
            conn.commit()

    def get_all_users(self):
        with self._get_connection() as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute("SELECT id, full_name, email FROM users")
            return [dict(row) for row in cursor.fetchall()]

    def is_vault_registered(self):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM users")
            return cursor.fetchone()[0] > 0

    def register_vault(self, full_name, email, password):
        ph = PasswordHasher()
        hashed = ph.hash(password)
        salt = os.urandom(16)
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("INSERT INTO users (full_name, email, master_password_hash, vault_salt) VALUES (?, ?, ?, ?)", 
                         (full_name, email, hashed, salt))
            user_id = cursor.lastrowid
            
            # Init settings for this user
            defaults = [
                ("auto_lock_timer", "Immediately"),
                ("lock_on_minimize", "1"),
                ("clipboard_clear_time", "30"),
                ("clear_clipboard_on_exit", "1"),
                ("minimize_to_tray", "1"),
                ("close_to_minimize", "1"),
                ("pin_code", ""),
                ("failed_attempts_limit", "5"),
                ("hide_passwords_default", "1"),
                ("disable_screenshots", "0")
            ]
            for key, val in defaults:
                cursor.execute("INSERT OR REPLACE INTO settings (user_id, key, value) VALUES (?, ?, ?)", (user_id, key, val))
            conn.commit()
            return user_id

    def verify_password(self, user_id, password):
        ph = PasswordHasher()
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT master_password_hash FROM users WHERE id = ?", (user_id,))
            row = cursor.fetchone()
            if row and row[0]:
                try:
                    return ph.verify(row[0], password)
                except:
                    return False
            return False

    def get_vault_salt(self, user_id):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT vault_salt FROM users WHERE id = ?", (user_id,))
            row = cursor.fetchone()
            return row[0] if row else None

    def get_user_info(self, user_id):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT full_name, email FROM users WHERE id = ?", (user_id,))
            row = cursor.fetchone()
            if row:
                return {"full_name": row[0], "email": row[1]}
            return None

    def get_setting(self, user_id, key, default=None):
        if not user_id: return default
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT value FROM settings WHERE user_id = ? AND key = ?", (user_id, key))
            row = cursor.fetchone()
            return row[0] if row else default

    def set_setting(self, user_id, key, value):
        if not user_id: return
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("INSERT OR REPLACE INTO settings (user_id, key, value) VALUES (?, ?, ?)", (user_id, key, str(value)))
            conn.commit()

    def wipe_user_data(self, user_id):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM credentials WHERE user_id = ?", (user_id,))
            cursor.execute("DELETE FROM folders WHERE user_id = ?", (user_id,))
            cursor.execute("DELETE FROM users WHERE id = ?", (user_id,))
            conn.commit()

# Singleton instance
_db_instance = None

def get_db_manager():
    global _db_instance
    if _db_instance is None:
        _db_instance = DatabaseManager(str(DB_PATH))
    return _db_instance

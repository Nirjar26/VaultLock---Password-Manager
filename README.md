# VaultLock - Secure Password Manager

🔐 Secure offline password manager built with Python and Qt, featuring zero-knowledge architecture, AES encryption, and Argon2 hashing.

<img width="1918" height="988" alt="VaultLock App" src="https://github.com/user-attachments/assets/8bcc3f01-c398-4d71-bae1-aa8dc5e8643c" />

---

## Overview
VaultLock is a secure, offline password manager built with Python and PyQt6/QML, featuring a modern, clean interface inspired by Windows 11 Fluent Design. It uses industrial-grade encryption (AES-256) and hashing (Argon2) to ensure your credentials remain private.

### Key Features
- **Zero-Knowledge Architecture:** Your master password never leaves your device and is never stored in plaintext.
- **AES-256 Encryption:** All sensitive fields (passwords, notes) are encrypted using Fernet (AES-128 CBC + HMAC) derived from your master password.
- **Argon2 Hashing:** Master password verification uses Argon2id, making brute-force attacks computationally expensive.
- **Windows 11 Integration:** Support for Mica Alt backdrop effects, dark mode, and seamless window integration.
- **Clipboard Security:** Secure password generation and auto-clearing clipboard functionality.
- **Organization:** Group credentials into folders, mark favorites, and search instantly.
- **Logo Fetching:** Automatically fetches and caches high-res logos.

---

## Tech Stack
- **Language:** Python 3.10+
- **GUI Framework:** PyQt6 + QML (Qt Quick Controls 2)
- **Database:** SQLite3 (Local file-based storage)
- **Cryptography:**
  - `cryptography` (Fernet/AES)
  - `argon2-cffi`
- **Utilities:** `pyperclip`, `requests`

---

## Installation

### Prerequisites
1. Python 3.10+

2. Git

### Setup Steps

#### 1. Clone the Repository
```bash
git clone https://github.com/Nirjar26/VaultLock---Password-Manager.git
cd VaultLock---Password-Manager



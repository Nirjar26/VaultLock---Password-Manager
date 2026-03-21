<div align="center">

<img src="https://img.shields.io/badge/Platform-Windows%2011-0078D4?style=flat-square&logo=windows11&logoColor=white" />
<img src="https://img.shields.io/badge/Python-3.10+-3776AB?style=flat-square&logo=python&logoColor=white" />
<img src="https://img.shields.io/badge/Encryption-AES--256%20%2B%20Argon2id-00C853?style=flat-square&logo=shield&logoColor=white" />
<img src="https://img.shields.io/badge/UI-PyQt6%20%2F%20QML-41CD52?style=flat-square&logo=qt&logoColor=white" />
<img src="https://img.shields.io/badge/License-MIT-yellow?style=flat-square" />

<br/>
<br/>

# 🔐 VaultLock

### Zero-Knowledge Offline Password Manager

**AES-256 encryption · Argon2id hashing · Windows 11 Fluent UI · 100% local · No cloud, no telemetry, no trust required**

[Features](#-features) · [Security Model](#-security-model) · [Getting Started](#-getting-started) · [Architecture](#-architecture) · [Build](#-build-portable-exe)

</div>

---

## Why VaultLock?

Most password managers phone home. VaultLock doesn't.

Your master password never leaves your machine. Your vault never touches a server. The encryption key is derived locally, used locally, and discarded. If you lose your master password, the data is gone — by design. That's what zero-knowledge means.

Built for engineers who want to understand exactly what's protecting their credentials.

---

## ✦ Features

| Feature | Detail 
|---|---|
| **Zero-knowledge architecture** | Master password never stored or transmitted |
| **AES-256 encryption** | Fernet (AES-128-CBC + HMAC-SHA256) for all vault data |
| **Argon2id key derivation** | PHC winner — resistant to GPU brute-force & side-channel attacks |
| **Auto-clear clipboard** | Copied passwords purge from clipboard automatically |
| **Smart logo fetching** | SVG/PNG logos fetched and cached per saved site |
| **Organization** | Folders, favorites, and real-time fuzzy search |
| **Local SQLite backend** | Your data stays on your machine — always |
| **Windows 11 Fluent UI** | Native Mica Alt backdrop, dark mode, smooth QML transitions |
| **Portable build** | Single `.exe` via PyInstaller — no Python required to run |

---

## 🔐 Security Model

Understanding the threat model is as important as the feature list.

```
Master Password
      │
      ▼
  Argon2id KDF  ──── salt (random, stored in DB)
      │
      ▼
  Derived Key (never stored)
      │
      ▼
  Fernet (AES-128-CBC + HMAC-SHA256)
      │
      ▼
  Encrypted Vault  ──── vault.db (SQLite, local only)
```

**What is stored:** Argon2id salt, encrypted ciphertext, encrypted metadata  
**What is never stored:** Master password, derived key, plaintext credentials  
**Attack resistance:** GPU brute-force (Argon2id memory hardness), MITM (no network), clipboard sniffing (auto-clear)

> ⚠️ **Important:** If your master password is lost, your vault cannot be recovered. There is no reset flow. This is intentional.

---

## 🚀 Getting Started

### Prerequisites

- Python 3.10+
- Git
- Windows 10/11 (for native Fluent UI effects)

### Installation

```bash
# Clone the repository
git clone https://github.com/Nirjar26/VaultLock---Password-Manager.git
cd VaultLock---Password-Manager

# Create and activate a virtual environment
python -m venv .venv
.\.venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Launch
python main.py
```

### First Run

1. Set a strong master password — this is the only key to your vault
2. VaultLock creates `vaultlock/database/vault.db` automatically
3. Add your first credential via the **+** button
4. Logos are fetched automatically for recognized domains

---

## 🏗️ Architecture

```
VaultLock/
├── main.py                    # Entry point — bootstraps Qt app
├── build.py                   # PyInstaller build script
├── requirements.txt
│
└── vaultlock/
    ├── core/
    │   ├── encryption_service.py   # AES-256 + Argon2id — all crypto lives here
    │   └── config.py               # App-wide constants and paths
    │
    ├── ui/
    │   └── *.qml                   # Qt Quick / QML interface files
    │
    ├── services/
    │   ├── logo_service.py         # SVG/PNG logo fetch + cache
    │   └── password_generator.py   # Secure random password generation
    │
    └── database/
        └── vault.db                # Created at runtime — never committed
```

### Key design decisions

- **No ORM.** Direct SQLite3 via Python stdlib — minimal attack surface, no dependency on third-party DB layer
- **Crypto isolated.** All encryption/decryption lives in `encryption_service.py` — nothing else touches keys
- **QML for UI.** Separates interface from logic cleanly; enables smooth animations without blocking the main thread
- **PyInstaller for distribution.** Single-folder portable build — users don't need Python installed

---

## 📦 Build Portable .exe

```bash
python build.py
```

Output is written to `/release/VaultLock/VaultLock.exe` — fully self-contained, no Python runtime required.

> The built executable stores `vault.db` in the same directory as the `.exe` for easy backups and portability.

---

## 🔧 Dependencies

| Package | Purpose |
|---|---|
| `PyQt6` | Qt bindings for Python — window, QML engine |
| `argon2-cffi` | Argon2id password hashing |
| `cryptography` | Fernet (AES-256) encryption |
| `pyperclip` | Clipboard access + auto-clear |
| `requests` | Logo fetching from remote sources |

Full list with pinned versions in [`requirements.txt`](requirements.txt).

---

## 🗺️ Roadmap

- [ ] Password strength analyzer with entropy scoring
- [ ] Import from Bitwarden / 1Password / LastPass (CSV)
- [ ] TOTP / 2FA code generation built-in
- [ ] Vault export with encrypted backup format
- [ ] Linux & macOS support (platform-native UI fallback)
- [ ] Auto-lock on idle timeout

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<div align="center">

Built by [Nirjar Goswami](https://nirjxr.dev) · [LinkedIn](https://www.linkedin.com/in/nirjarbharthigoswami-b593633a7) · [Portfolio](https://nirjxr.dev)

*If this project helped you, consider starring the repo ⭐*

</div>

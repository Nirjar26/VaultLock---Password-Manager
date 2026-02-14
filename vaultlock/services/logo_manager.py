from PyQt6.QtCore import QObject, pyqtSignal, QThread, QStandardPaths
import os
import json
import hashlib
import requests
import re
import shutil

class LogoFetchWorker(QThread):
    """
    The Hunter: Background worker that attempts to fetch logos with browser-like behavior.
    """
    logo_ready = pyqtSignal(str, str) # domain, cache_path
    fetch_failed = pyqtSignal(str)    # domain

    def __init__(self, domain, cache_dir):
        super().__init__()
        self.domain = domain
        self.cache_dir = cache_dir

    def run(self):
        file_hash = hashlib.md5(self.domain.encode()).hexdigest()
        cache_file = os.path.join(self.cache_dir, f"{file_hash}.png")

        # Refined Source Priority
        sources = [
            f"https://logo.clearbit.com/{self.domain}?size=128",
            f"https://www.google.com/s2/favicons?sz=128&domain={self.domain}",
            f"https://icons.duckduckgo.com/ip3/{self.domain}.ico"
        ]

        # Browser Headers to avoid 403s
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
            "Accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8"
        }

        for url in sources:
            try:
                response = requests.get(url, headers=headers, timeout=4)
                if response.status_code == 200:
                    content = response.content
                    
                    # VALIDATION: Check for "empty" errors or tiny tracking pixels
                    if len(content) < 500: 
                        continue
                        
                    content_type = response.headers.get("Content-Type", "").lower()
                    if "image" not in content_type and "application/octet-stream" not in content_type:
                        continue
                    
                    # VALIDATION: Magic Bytes Check
                    # PNG, JPEG, ICO, WEBP, SVG
                    magic = content[:12].lower()
                    is_image = (
                        magic.startswith(b'\x89png') or 
                        magic.startswith(b'\xff\xd8\xff') or
                        magic.startswith(b'\x00\x00\x01\x00') or
                        b'webp' in magic or
                        b'<svg' in magic or
                        b'<?xml' in magic
                    )
                    if not is_image:
                        continue

                    # Write to temporary file first (atomic write)
                    temp_file = cache_file + ".tmp"
                    with open(temp_file, 'wb') as f:
                        f.write(content)
                    
                    # Move to final location
                    if os.path.exists(cache_file):
                        os.remove(cache_file)
                    os.rename(temp_file, cache_file)
                    
                    self.logo_ready.emit(self.domain, cache_file)
                    return

            except Exception as e:
                continue
        
        # If we get here, all sources failed
        self.fetch_failed.emit(self.domain)

class LogoManager(QObject):
    """
    The Orchestrator: Manages caching, validation, and async resolution.
    Singleton Pattern via get_logo_manager().
    """
    logo_updated = pyqtSignal(str, str) # name, logo_path

    def __init__(self, cache_dir=None):
        super().__init__()
        if cache_dir is None:
            app_data = QStandardPaths.writableLocation(QStandardPaths.StandardLocation.AppDataLocation)
            self.base_dir = os.path.join(app_data, "VaultLock")
            self.cache_dir = os.path.join(self.base_dir, "logo_cache")
        else:
            self.cache_dir = cache_dir
            self.base_dir = os.path.dirname(self.cache_dir)
            
        os.makedirs(self.cache_dir, exist_ok=True)
        
        # Paths
        self.bundled_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "logos")
        self.user_mapping_file = os.path.join(self.base_dir, "user_logo_mapping.json")
        
        # State
        self.user_mapping = self._load_user_mapping()
        self.pending_fetches = set()
        self.workers = []
        
        # Optimizations
        self.failed_domains = set() # Avoid retrying known dead ends
        self.memory_cache = {}      # Domain -> Path (Speed up lookups)

        # Heuristic Dictionary
        self.brand_dictionary = {
            "google": "google.com", "github": "github.com", "amazon": "amazon.com",
            "apple": "apple.com", "facebook": "facebook.com", "meta": "facebook.com",
            "linkedin": "linkedin.com", "twitter": "twitter.com", "x": "twitter.com",
            "netflix": "netflix.com", "spotify": "spotify.com", "slack": "slack.com",
            "discord": "discord.com", "dropbox": "dropbox.com", "microsoft": "microsoft.com",
            "outlook": "outlook.com", "gmail": "google.com", "adobe": "adobe.com",
            "figma": "figma.com", "notion": "notion.so", "zoom": "zoom.us",
            "reddit": "reddit.com", "paypal": "paypal.com", "stripe": "stripe.com",
            "binance": "binance.com", "coinbase": "coinbase.com", "openai": "openai.com",
            "whatsapp": "whatsapp.com", "telegram": "telegram.org", "signal": "signal.org"
        }

    def _load_user_mapping(self):
        if os.path.exists(self.user_mapping_file):
            try:
                with open(self.user_mapping_file, 'r') as f:
                    return json.load(f)
            except: return {}
        return {}

    def get_logo_path(self, name, website=None):
        """
        Tri-State Resolution:
        1. Cache/Bundle (Immediate Success) -> Return path, True
        2. Async (Pending) -> Return None, False (Triggers fallback, starts fetch)
        3. Failed/Unknown -> Return None, False (Fallbacks to Initials forever)
        """
        
        # 0. Normalization
        name_clean = re.sub(r'[^a-z0-9]', '', name.lower())
        
        # 1. User Override (Highest Priority)
        # Check mapping... (omitted for brevity, assume similar logic if needed)

        # 2. Determine Candidate Domain
        domain = self._resolve_domain(name, website)
        if not domain:
            return None, False

        # 3. Check Memory Cache
        if domain in self.memory_cache:
            return self.memory_cache[domain], True

        # 4. Check Failed List (Fail-Fast)
        if domain in self.failed_domains:
            # We already tried and failed. Return None to keep initials.
            return None, False

        # 5. Check Disk (Cache & Bundled)
        # Bundled
        bundled_path = os.path.join(self.bundled_dir, f"{domain}.png")
        if os.path.exists(bundled_path):
            self.memory_cache[domain] = bundled_path
            return bundled_path, True
            
        bundled_name_path = os.path.join(self.bundled_dir, f"{name_clean}.png")
        if os.path.exists(bundled_name_path):
            # Map domain to this file for future
            self.memory_cache[domain] = bundled_name_path
            return bundled_name_path, True

        # Cached
        cache_path = self._get_cache_path(domain)
        if os.path.exists(cache_path):
            # Integrity Check
            if self._validate_cache_file(cache_path):
                self.memory_cache[domain] = cache_path
                return cache_path, True
            else:
                # Corrupt - Delete and Refresh
                try: os.remove(cache_path)
                except: pass

        # 6. Async Fetch (Network)
        self._trigger_async_fetch(domain, name)
        
        return None, False

    def _resolve_domain(self, name, website):
        # Explicit Website
        if website:
            d = self._extract_domain(website)
            if d: return d
            
        # Dictionary Match
        clean_name = re.sub(r'[^a-z0-9]', '', name.lower())
        if clean_name in self.brand_dictionary:
            return self.brand_dictionary[clean_name]
            
        # Name Guess
        return f"{clean_name}.com"

    def _trigger_async_fetch(self, domain, name):
        if domain in self.pending_fetches:
            return

        self.pending_fetches.add(domain)
        worker = LogoFetchWorker(domain, self.cache_dir)
        worker.logo_ready.connect(lambda d, p: self._on_logo_ready(d, p, name))
        worker.fetch_failed.connect(lambda d: self._on_fetch_failed(d))
        worker.finished.connect(lambda: self._cleanup_worker(worker, domain))
        self.workers.append(worker)
        worker.start()

    def _on_logo_ready(self, domain, path, name):
        # Update caches
        self.memory_cache[domain] = path
        # Notify UI
        # We emit with 'name' because the UI (CredentialList) often keys off the service name
        self.logo_updated.emit(name, path)

    def _on_fetch_failed(self, domain):
        self.failed_domains.add(domain)
        # We don't need to emit anything; UI stays on initials.

    def _cleanup_worker(self, worker, domain):
        if worker in self.workers:
            self.workers.remove(worker)
        if domain in self.pending_fetches:
            self.pending_fetches.remove(domain)

    def _validate_cache_file(self, path):
        try:
            size = os.path.getsize(path)
            return size > 500 # Must be > 500 bytes (Filter out 1x1 pixels or empty files)
        except:
            return False

    def _extract_domain(self, url):
        if not url: return None
        try:
            if "://" not in url: url = "http://" + url
            from urllib.parse import urlparse
            d = urlparse(url).netloc
            return d[4:] if d.startswith('www.') else d
        except: return None
        
    def _get_cache_path(self, domain):
        file_hash = hashlib.md5(domain.encode()).hexdigest()
        return os.path.join(self.cache_dir, f"{file_hash}.png")


# Global singleton
_logo_manager_instance = None

def get_logo_manager():
    global _logo_manager_instance
    if _logo_manager_instance is None:
        _logo_manager_instance = LogoManager()
    return _logo_manager_instance

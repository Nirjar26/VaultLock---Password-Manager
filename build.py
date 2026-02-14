
import os
import shutil
import subprocess
import sys
from pathlib import Path

def clean():
    print("Cleaning build artifacts...")
    for p in ["build", "dist", "release", "vault.db", "vault.db.bak"]:
        path = Path(p)
        if path.exists():
            if path.is_dir():
                try:
                    shutil.rmtree(path)
                except Exception as e:
                    print(f"Error removing directory {p}: {e}")
            else:
                try:
                    os.remove(path)
                except Exception as e:
                    print(f"Error removing file {p}: {e}")
    
    # Clean pycache
    for root, dirs, files in os.walk("."):
        for d in dirs:
            if d == "__pycache__":
                shutil.rmtree(os.path.join(root, d))

def build():
    print("Building executable with PyInstaller...")
    
    # Separator for --add-data
    sep = ";" if os.name == 'nt' else ":"
    
    # PyInstaller arguments
    cmd = [
        sys.executable, "-m", "PyInstaller",
        "--noconfirm",
        "--onedir",            # Create a directory (faster startup than onefile)
        "--windowed",          # No console window
        "--name", "VaultLock", # Executable name
        "--icon", str(Path("vaultlock/assets/VaultLock_windowicon.ico")),
        
        # Bundle Assets (Src -> Dest in sandbox)
        f"--add-data", f"vaultlock/assets{sep}vaultlock/assets",
        f"--add-data", f"vaultlock/ui{sep}vaultlock/ui",
        
        # Ensure imports
        "--hidden-import", "argon2",
        "--hidden-import", "cffi",
        "--hidden-import", "cryptography",
        
        "main.py"
    ]
    
    subprocess.check_call(cmd)

def package():
    print("Packaging release...")
    release_dir = Path("release")
    if release_dir.exists():
        shutil.rmtree(release_dir)
    release_dir.mkdir()
    
    dist_dir = Path("dist/VaultLock")
    if not dist_dir.exists():
        print("Error: Build failed, dist/VaultLock not found.")
        return

    # 1. Move the built application
    # We put the app in release/app (or keep it as VaultLock)
    # The user wanted structure:
    # /release
    #    app.exe (inside the app folder for onedir)
    #    config/
    #    assets/
    
    # For 'onedir', the exe is INSIDE the folder. 
    # Example: release/VaultLock/VaultLock.exe
    target_app_dir = release_dir / "VaultLock"
    shutil.copytree(dist_dir, target_app_dir)
    
    # 2. Create external folders as requested
    # These are for USER VISIBILITY/EDITING (DB is created here)
    (release_dir / "config").mkdir()
    (release_dir / "assets").mkdir()
    
    # Copy assets for user visibility (optional, but requested structure implies it)
    # Note: The app uses the BUNDLED assets, not these external ones, unless we change config.
    # But usually 'assets' folder in release is for static resources like documentation or templates.
    # We will copy the assets there just in case.
    src_assets = Path("vaultlock/assets")
    dst_assets = release_dir / "assets"
    if src_assets.exists():
        # Remove empty dir created above
        dst_assets.rmdir()
        shutil.copytree(src_assets, dst_assets)
    
    # 3. Create a README for the release
    with open(release_dir / "README.txt", "w") as f:
        f.write("VaultLock Release\n=================\n\n")
        f.write("1. To run the application, open the 'VaultLock' folder and double-click 'VaultLock.exe'.\n")
        f.write("2. Your database 'vault.db' will be created in this folder (or 'VaultLock' folder depending on config).\n")
        f.write("3. Do not delete the internal files in 'VaultLock' directory.\n")

    print(f"Build success! Output is in: {release_dir.absolute()}")

if __name__ == "__main__":
    clean()
    try:
        build()
        package()
    except subprocess.CalledProcessError as e:
        print(f"\nError: Build failed. Make sure 'pyinstaller' is installed.\nRun: pip install -r requirements.txt\nDetails: {e}")
    except Exception as e:
        print(f"\nAn error occurred: {e}")


from PIL import Image
from pathlib import Path

def convert_to_ico(source_path, dest_path):
    try:
        img = Image.open(source_path)
        img.save(dest_path, format='ICO', sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]) # Better quality
        print(f"Successfully converted {source_path} to {dest_path}")
    except Exception as e:
        print(f"Failed to convert: {e}")

if __name__ == "__main__":
    src = Path("vaultlock/assets/VaultLock_windowicon.png")
    dst = Path("vaultlock/assets/VaultLock_windowicon.ico")
    if src.exists():
        convert_to_ico(src, dst)
    else:
        print(f"Source not found: {src}")

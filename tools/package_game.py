"""Package the final Windows and Web exports with controls and asset credits."""
from pathlib import Path
import hashlib
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
version = re.search(r'config/version="([^"]+)"', (ROOT / "project.godot").read_text()).group(1)
packages = ROOT / "build/packages"
packages.mkdir(exist_ok=True)
common = f"Kattelox Days {version}\n\nWASD/arrows: move. E: interact. J: fire. K: lock. Shift: dash.\nQ: bottle. L: Grenade Arm after crafting. C: select seeds.\n1-4: tools. Esc: pause. M: map. Tab: equipment. F11: fullscreen.\n\nTalk to Roll beside the Flutter to begin the repair chapter.\nFind weapon plans in the eastern ruin chamber and salvage crates\nfor scrap and shards. Roll builds the Grenade Arm at the workbench.\nTomatoes regrow after two watered nights; sunflowers take five.\nGive tomatoes to Roll, fish to Barrell and flowers to Amelia.\nv0.2 saves remain compatible. Continue starts beside the Flutter.\n\nUnofficial, non-commercial Capcom fan project. See CREDITS.md.\n"
for target, folder in [("Windows", "windows"), ("Web", "web")]:
    source = ROOT / "build" / folder
    instructions = "Extract this ZIP and open KatteloxDays.exe. No engine installation is needed.\n" if target == "Windows" else "Serve these files over HTTP, then open index.html in a WebGL 2 browser.\nFor a local test: python -m http.server 8000\nOpen http://localhost:8000. Keep the same browser/origin for your save.\n"
    (source / "START-HERE.txt").write_text(common + "\n" + instructions)
    (source / "CREDITS.md").write_bytes((ROOT / "docs/ASSETS.md").read_bytes())
    files = [f for f in source.iterdir() if f.is_file() and f.suffix not in [".import", ".tmp"] and ".tmp." not in f.name]
    archive = packages / f"KatteloxDays-{target}-{version}.zip"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zipped:
        for file in sorted(files): zipped.write(file, file.name)
    with zipfile.ZipFile(archive) as zipped:
        assert zipped.testzip() is None
        payload = "KatteloxDays.exe" if target == "Windows" else "index.pck"
        assert hashlib.sha256(zipped.read(payload)).digest() == hashlib.sha256((source/payload).read_bytes()).digest()
    print(f"{archive.name}: {archive.stat().st_size / 1048576:.2f} MiB, verified")

"""Package the final Windows and Web exports with controls and asset credits."""
from pathlib import Path
import hashlib
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
version = re.search(r'config/version="([^"]+)"', (ROOT / "project.godot").read_text()).group(1)
packages = ROOT / "build/packages"
packages.mkdir(exist_ok=True)
common = f"""Mega Man Legends: Flutterbound {version}

WASD/arrows: move. Mouse: aim. Left click/J: fire. K: lock.
Hold right click/H/controller RT, then release: charged Buster. Shift: dash.
Mouse wheel: camera zoom (saved).
E/F/Space: interact. Q: energy bottle. L: crafted Grenade Arm.
Esc: pause. M: map. Tab: equipment. F11: fullscreen.
Controller: left stick moves, right stick aims, X fires, RB dashes,
LB locks, A interacts, B throws grenades, Y heals, Start pauses.

Talk to Roll beside the Flutter and choose Check Flutter repairs.
Recover the Servo Motor, Ancient Circuit and Large Refractor.
Clear guarded caches, return parts to Roll and defeat Tron's mech.
Find eastern weapon plans and salvage scrap/shards for upgrades.
Data and the cabin bunk restore health and save progress.
Continue starts beside the Flutter. Deep Digs unlock after the ending.
Saves use flutterbound_v1.json; older Kattelox saves stay separate.

Unofficial, non-commercial Capcom fan project. See CREDITS.md.
"""
for target, folder in [("Windows", "windows"), ("Web", "web")]:
    source = ROOT / "build" / folder
    instructions = "Extract this ZIP and open Flutterbound.exe. No engine installation is needed.\n" if target == "Windows" else "Serve these files over HTTP, then open index.html in a WebGL 2 browser.\nFor a local test: python -m http.server 8000\nOpen http://localhost:8000. Keep the same browser/origin for your save.\n"
    (source / "START-HERE.txt").write_text(common + "\n" + instructions)
    (source / "CREDITS.md").write_bytes((ROOT / "docs/ASSETS.md").read_bytes())
    files = [f for f in source.iterdir() if f.is_file() and f.suffix not in [".import", ".tmp"] and ".tmp." not in f.name and "KatteloxDays" not in f.name]
    archive = packages / f"Flutterbound-{target}-{version}.zip"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zipped:
        for file in sorted(files): zipped.write(file, file.name)
    with zipfile.ZipFile(archive) as zipped:
        assert zipped.testzip() is None
        payload = "Flutterbound.exe" if target == "Windows" else "index.pck"
        assert hashlib.sha256(zipped.read(payload)).digest() == hashlib.sha256((source/payload).read_bytes()).digest()
    print(f"{archive.name}: {archive.stat().st_size / 1048576:.2f} MiB, verified")

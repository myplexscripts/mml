#!/usr/bin/env python3
"""Validate real gameplay and optionally export both supported targets."""
import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
ERRORS = re.compile(r"SCRIPT ERROR|^ERROR:|ObjectDB instances were leaked|CHECKS:.*[1-9][0-9]* failed|PLAYTEST: FAIL", re.MULTILINE)


def run(godot, name, arguments, timeout=120, expected=None):
    print(f"Checking {name}...", flush=True)
    with tempfile.TemporaryDirectory(prefix="kattelox-check-") as user_data:
        env = dict(os.environ)
        if name in ["legends", "combat", "geometry", "finish"]:
            env["XDG_DATA_HOME"] = user_data
        result = subprocess.run(
            [godot, "--headless", "--path", str(ROOT), *arguments],
            cwd=ROOT, env=env, capture_output=True, text=True, timeout=timeout,
        )
    output = result.stdout + result.stderr
    (ROOT / "build" / f"check-{name}.log").write_text(output)
    if result.returncode or ERRORS.search(output) or (expected and expected not in output):
        print(output, file=sys.stderr)
        raise RuntimeError(f"{name} failed; see build/check-{name}.log")
    for line in output.splitlines():
        if "CHECKS:" in line or "PLAYTEST:" in line:
            print(line, flush=True)
    print(f"PASS: {name}", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot", help="Godot 4.7.2 executable")
    parser.add_argument("--export", action="store_true", help="Export Windows and Web; requires templates")
    options = parser.parse_args()
    (ROOT / "build").mkdir(exist_ok=True)
    (ROOT / "build" / ".gdignore").touch()
    run(options.godot, "import", ["--editor", "--quit"])
    run(options.godot, "legends", ["--script", "tests/legends_test.gd"], expected="0 failed")
    run(options.godot, "combat", ["--script", "tests/legends_combat.gd"], expected="LEGENDS COMBAT: PASS")
    run(options.godot, "geometry", ["--script", "tests/legends_geometry.gd"], expected="0 failed")
    run(options.godot, "finish", ["--script", "tests/legends_finish.gd"], expected="0 failed")
    if options.export:
        for preset, folder, filename in [("Windows Desktop", "windows", "Flutterbound.exe"), ("Web", "web", "index.html")]:
            target = ROOT / "build" / folder / filename
            target.parent.mkdir(exist_ok=True)
            run(options.godot, "export-" + folder, ["--export-release", preset, str(target)], timeout=180)
            with tempfile.TemporaryDirectory(prefix="flutterbound-pack-") as empty:
                empty = Path(empty)
                (empty / "project.godot").write_text('config_version=5\n[application]\nconfig/name="Export verification"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
                shutil.copyfile(ROOT / "tests/export_pack_test.gd", empty / "check.gd")
                pack = target if folder == "windows" else target.with_suffix(".pck")
                result = subprocess.run([options.godot, "--headless", "--path", str(empty), "--script", str(empty / "check.gd"), "--", str(pack)], capture_output=True, text=True, timeout=90)
                output = result.stdout + result.stderr
                (ROOT / "build" / f"check-pack-{folder}.log").write_text(output)
                if result.returncode or ERRORS.search(output) or "EXPORT PACK: PASS" not in output:
                    raise RuntimeError(output)
                print(f"PASS: self-contained {folder} pack", flush=True)
    print("Flutterbound validation passed.")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Validate real gameplay and optionally export both supported targets."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
ERRORS = re.compile(r"SCRIPT ERROR|^ERROR:|ObjectDB instances were leaked|CHECKS:.*[1-9][0-9]* failed|PLAYTEST: FAIL", re.MULTILINE)


def run(godot, name, arguments, timeout=120, expected=None):
    print(f"Checking {name}...", flush=True)
    with tempfile.TemporaryDirectory(prefix="kattelox-check-") as user_data:
        env = dict(os.environ)
        if name in ["startup", "gameplay", "combat", "expansion"]:
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
    run(options.godot, "startup", ["--script", "tests/startup_test.gd"], expected="STARTUP: PASS")
    run(options.godot, "gameplay", ["--script", "tests/gameplay_test.gd"], expected="0 failed")
    run(options.godot, "expansion", ["--script", "tests/expansion_test.gd"], expected="0 failed")
    run(options.godot, "combat", ["--script", "tests/combat_playtest.gd"], expected="COMBAT PLAYTEST: PASS")
    if options.export:
        for preset, folder, filename in [("Windows Desktop", "windows", "KatteloxDays.exe"), ("Web", "web", "index.html")]:
            target = ROOT / "build" / folder / filename
            target.parent.mkdir(exist_ok=True)
            run(options.godot, "export-" + folder, ["--export-release", preset, str(target)], timeout=180)
    print("Kattelox Days validation passed.")


if __name__ == "__main__":
    main()

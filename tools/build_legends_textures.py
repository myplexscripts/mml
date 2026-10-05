"""Recreate the selected, credited Legends texture crops offline."""
import json
from pathlib import Path
from PIL import Image
root = Path(__file__).resolve().parents[1]
output = root / "assets/legends"
source = root / "assets/source/legends"
for texture in json.loads((output / "provenance.json").read_text())["textures"]:
    Image.open(source / texture["source"]).crop(texture["crop"]).save(output / texture["file"])
print("Legends textures rebuilt from preserved sources.")

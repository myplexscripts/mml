#!/usr/bin/env python3
"""Prepare the two external Legends Station source packs for Blender conversion."""
import argparse
from pathlib import Path
from PIL import Image
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('source_root',type=Path,help='Contains Teomo City Set/ and josh/MMV3.blend')
a=p.parse_args()
for folder in ['Buildings/2/textures','Buildings/Dock']:
 for source in (a.source_root/'Teomo City Set'/folder).glob('*.psd'):
  Image.open(source).convert('RGBA').save(source.with_suffix('.png'))
print('PSD composites converted, preserving the authored colours and UV atlases.')

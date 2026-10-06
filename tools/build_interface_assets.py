#!/usr/bin/env python3
"""Extract interface sprites from the credited Legends Station MML1 sheet."""
from pathlib import Path
from PIL import Image
from collections import deque
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'assets/source/legends/sprites1.png'
out=ROOT/'assets/interface';out.mkdir(exist_ok=True)
im=Image.open(source).convert('RGBA');pixels=im.load();w,h=im.size
# Remove only connected background white, preserving enclosed white highlights.
queue=deque((x,y) for x in range(w) for y in [0,h-1]);queue.extend((x,y) for x in [0,w-1] for y in range(h))
seen=set()
while queue:
 x,y=queue.popleft()
 if (x,y) in seen or not (0<=x<w and 0<=y<h):continue
 seen.add((x,y))
 if pixels[x,y][:3]!=(255,255,255):continue
 pixels[x,y]=(255,255,255,0)
 queue.extend(((x-1,y),(x+1,y),(x,y-1),(x,y+1)))
im.save(out/'legends_atlas.png')
icons={'buster':(544,250,588,284),'bottle':(12,163,31,199),'refractor':(43,199,67,233),'tool':(29,233,75,270),'life':(133,2,221,20),'zenny':(224,2,326,20),'weapon':(476,101,527,145),'key':(82,232,102,267),'mission_complete':(228,241,439,266)}
for name,rect in icons.items():im.crop(rect).save(out/(name+'.png'))

frame=im.crop((0,295,259,539));frame.paste((0,0,0,0),(24,24,235,220));frame.save(out/"map_frame.png")

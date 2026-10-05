"""Reproducible pixel-art pipeline. Pillow is needed only to rebuild the assets.

Kenney CC0 terrain and public-domain Seeteufel sprites are combined with
original Kattelox buildings, machinery, NPC animation, crops and item icons.
The game loads the resulting PNGs, never this script.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import random

ROOT = Path(__file__).resolve().parents[1]
A = ROOT / 'assets'
random.seed(74)
TOWN = Image.open(A / 'source/kenney_town.png').convert('RGBA')
URBAN = Image.open(A / 'source/kenney_urban.png').convert('RGBA')
FAN = Image.open(A / 'source/seeteufel.png').convert('RGBA')
INK = '#253c48'
CREAM = '#f4e9c9'

def canvas(w, h):
    im = Image.new('RGBA', (w, h)); return im, ImageDraw.Draw(im)

def save(im, folder, name):
    (A / folder).mkdir(parents=True, exist_ok=True)
    im.save(A / folder / (name + '.png'))

def crop(im, x, y, w=16, h=16):
    return im.crop((x, y, x+w, y+h))

def label(d, pos, text, colour=CREAM):
    # PIL's compact bitmap font is part of the build tooling, not bundled.
    d.text(pos, text, fill=colour, font=ImageFont.load_default(size=9))

def sprite_sheet():
    # Frame coordinates are defined by the original MegaPlayer.java.
    out, _ = canvas(38 * 4, 45 * 3)
    for row, y in enumerate([256, 302, 347]):
        for col in range(4): out.alpha_composite(crop(FAN, col*38, y, 38, 45), (col*38,row*45))
    save(out, 'characters', 'megaman')
    for name, rect in {'refractor':(132,210,26,46), 'shard':(158,210,25,37),
                       'ruin_panel':(45,0,114,120), 'ruin_pillar':(166,0,50,62),
                       'bonne_mech':(259,208,75,120)}.items():
        x,y,w,h=rect; save(crop(FAN,x,y,w,h),'items' if name in ['refractor','shard'] else 'world',name)
    # Source-sheet has genuine alpha, no background-colour keying.

def terrain():
    grass=crop(TOWN,16,0)
    save(grass,'world','grass')
    save(crop(TOWN,16,0),'world','grass_flower')
    save(crop(TOWN,32,0),'world','grass_daisy')
    save(crop(TOWN,16,32),'world','path')
    save(crop(TOWN,96,16,32,32),'world','tree')
    save(crop(TOWN,64,0,16,32),'world','tree_tall')
    save(crop(TOWN,64,32,16,16),'world','bush')
    flowers,d=canvas(24,24)
    for x,y,c in [(6,11,'#f0c967'),(16,17,'#ef8e71'),(15,6,'#f5e3a9')]:
        d.line((x,y+2,x,y+7),fill='#568553')
        d.rectangle((x-2,y-1,x+2,y+1),fill=c)
        d.rectangle((x-1,y-2,x+1,y+2),fill=c)
        d.point((x,y),fill='#bd8260')
    save(flowers,'world','flowers')
    # Recolour the urban cobblestone into Kattelox's warm paving.
    paving,d=canvas(32,32)
    d.rectangle((0,0,31,31),fill='#b0ad91')
    for row in range(4):
        for col in range(-1,4):
            x=col*12+(6 if row%2 else 0); y=row*8
            c=random.choice(['#c1bba0','#c8c0a4','#bfb99d','#cbc3a9'])
            d.rounded_rectangle((x+1,y+1,x+11,y+7),radius=1,fill=c)
            d.line((x+2,y+1,x+10,y+1),fill='#d5cdb0')
    save(paving,'world','paving')
    for name, colour in [('soil','#86604e'),('soil_wet','#594e46'),('ruin_floor','#354c55')]:
        im,d=canvas(32,32); d.rectangle((0,0,31,31),fill=colour)
        if name.startswith('soil'):
            for yy in [7,15,23]:
                d.line((3,yy,28,yy),fill='#aa8060' if name=='soil' else '#716655')
                d.line((4,yy+1,27,yy+1),fill='#503f38')
        else:
            d.rectangle((0,0,31,31),outline='#293e47'); d.line((2,2,29,2),fill='#47616b')
            for _ in range(6):
                x,y=random.randrange(3,29),random.randrange(3,29); d.point((x,y),fill='#4a5b61')
        save(im,'world',name)
    for idx in range(3):
        im,d=canvas(32,32); d.rectangle((0,0,31,31),fill=['#23547d','#2a6188','#327291'][idx])
        for x,y,w in [(2,8,12),(17,23,9),(3,27,5)]:
            d.line((x,y,x+w,y),fill='#4598ab'); d.line((x+2,y+1,x+w-2,y+1),fill='#39859c')
        save(im,'world',f'water_{idx}')
    im,d=canvas(32,64)
    d.rectangle((0,0,31,63),fill='#233742')
    d.rectangle((0,0,31,39),fill='#678383',outline='#20393e',width=2)
    d.rectangle((3,3,28,35),fill='#557371',outline='#86a099')
    d.line((6,8,6,30),fill='#3b5456',width=2);d.line((25,9,14,9,14,24,24,24),fill='#8ca19b',width=2)
    d.line((2,41,29,41),fill='#142832',width=2)
    d.rectangle((5,46,26,59),fill='#29464e'); d.line((7,50,24,50),fill='#3b626a')
    save(im,'world','wall')

def building(name, width, roof, title, kind='shop'):
    h=112; im,d=canvas(width,h)
    # Cast shadow, grounded wall, visible roof pitch and thick fascia.
    d.rectangle((5,15,width-1,h-3),fill='#273d463b')
    d.rectangle((8,42,width-9,h-7),fill='#d7cfae',outline=INK,width=2)
    d.rectangle((10,45,width-11,74),fill='#f2e5c5')
    for y in range(80,h-8,6): d.line((11,y,width-12,y),fill='#bcb898')
    for x in range(16,width-14,12):d.line((x,82,x,87),fill='#c6bd9d')
    d.polygon([(2,39),(20,8),(width-21,8),(width-3,39),(width-3,49),(2,49)],fill=roof,outline=INK,width=2)
    for y in range(16,39,7):
        a=int((39-y)*.55)
        d.line((3+a,y,width-4-a,y),fill='#ffffff29',width=2)
        for x in range(14+a,width-10-a,13):d.line((x,y,x-4,y+6),fill='#412f452f')
    d.line((4,40,width-5,40),fill='#ffd9a5',width=2)
    d.rectangle((width//2-10,80,width//2+10,105),fill='#334e5b',outline=INK,width=2)
    d.rectangle((width//2-7,82,width//2+7,91),fill='#689fac')
    d.point((width//2+6,96),fill='#f4c867')
    for x in [19,width-37]:
        d.rectangle((x,59,x+18,79),fill=INK)
        d.rectangle((x+2,61,x+16,76),fill='#5794ac')
        d.polygon([(x+2,61),(x+13,61),(x+2,73)],fill='#a8d9d4')
        d.line((x+9,61,x+9,77),fill=CREAM)
        d.rectangle((x-2,80,x+20,84),fill='#966958')
    if kind=='shop':
        for x in range(13,width-12,10):
            d.rectangle((x,49,min(x+9,width-13),56),fill=CREAM if (x//10)%2 else roof)
    if kind=='hall':
        d.rectangle((width//2-16,2,width//2+16,36),fill='#e4ddc1',outline=INK,width=2)
        d.ellipse((width//2-10,6,width//2+10,26),fill=CREAM,outline=INK,width=2)
        d.line((width//2,16,width//2,9),fill=INK);d.line((width//2,16,width//2+5,18),fill=INK)
    if kind=='museum':
        for x in [10,width-19]:d.rectangle((x,53,x+7,101),fill='#eee6d0',outline='#a0a28e')
    tw=int(d.textbbox((0,0),title,font=ImageFont.load_default(size=9))[2])
    d.rectangle((width//2-tw//2-5,64,width//2+tw//2+5,78),fill='#304f5c',outline='#ceb66b')
    label(d,(width//2-tw//2,65),title)
    d.rectangle((width//2-18,106,width//2+18,110),fill='#bcbca4',outline='#636c65')
    save(im,'world',name)

def flutter():
    im,d=canvas(224,144)
    # Flutter: yellow amphibious hull, red wing/roof, rounded observation cabin,
    # port/starboard engine pods, tail fin, deck rail and green status lights.
    d.ellipse((16,95,216,137),fill='#1b3e3d38')
    d.polygon([(161,56),(159,12),(168,3),(181,6),(190,62)],fill='#a54144',outline=INK,width=2)
    d.polygon([(166,10),(174,7),(183,56),(173,55)],fill='#e1715c')
    d.polygon([(18,76),(44,56),(173,53),(209,77),(209,106),(181,125),(49,125),(17,103)],fill='#bc8a45',outline=INK,width=3)
    d.polygon([(20,77),(43,60),(176,57),(206,78),(192,106),(38,107)],fill='#f0c658',outline='#714c39',width=2)
    d.polygon([(39,107),(191,107),(177,121),(53,121)],fill='#daab49')
    d.polygon([(37,57),(66,33),(146,28),(184,51),(188,72),(32,73)],fill='#bc4e45',outline=INK,width=2)
    d.polygon([(42,55),(66,37),(145,33),(178,54)],fill='#e1785a')
    d.line((64,40,146,36),fill='#f5b478',width=2)
    d.rectangle((51,57,164,83),fill='#2c4e66',outline=INK,width=2)
    for x in [55,78,101,124,147]:
        d.rectangle((x,60,x+17,80),fill='#65a4b1',outline='#273d56')
        d.polygon([(x+2,62),(x+14,62),(x+2,73)],fill='#bce7da')
        d.rectangle((x+2,76,x+15,79),fill='#3b829a')
    d.polygon([(6,79),(30,74),(42,87),(38,111),(6,109),(1,95)],fill='#ac4243',outline=INK,width=2)
    d.polygon([(193,80),(216,81),(223,96),(216,113),(191,111),(183,96)],fill='#ac4243',outline=INK,width=2)
    for x in [9,193]:
        d.ellipse((x,84,x+23,107),fill='#344651',outline='#f3bc60',width=2)
        d.ellipse((x+5,89,x+18,102),fill='#537378',outline='#152f3c',width=2)
        d.line((x+12,89,x+12,102),fill='#233d49',width=2);d.line((x+5,95,x+18,95),fill='#233d49',width=2)
    d.rectangle((59,84,157,91),fill='#fff1bc',outline='#a66e38')
    label(d,(91,83),'FLUTTER',INK)
    d.rectangle((111,95,138,123),fill='#8e6741',outline=INK,width=2)
    d.rectangle((116,99,133,121),fill='#bd995a');d.rectangle((123,103,127,106),fill='#304f5a')
    for x in [48,68,88,148,168]:
        d.ellipse((x,94,x+4,98),fill='#fff0a0');d.point((x+1,95),fill='#946636')
    d.ellipse((152,101,161,110),fill='#2f5b48',outline=INK);d.ellipse((154,103,158,107),fill='#b2e26c')
    d.line((38,30,156,30),fill='#314752',width=2)
    for x in range(39,158,14):d.line((x,21,x,33),fill='#526777',width=2)
    d.line((38,21,155,21),fill='#93b0b1')
    d.rectangle((93,126,153,133),fill='#ac9770',outline=INK);d.line((97,129,149,129),fill=CREAM)
    save(im,'world','flutter')

def npc(name, hair, shirt, pants, hat=False, data=False):
    sheet,_=canvas(24*4,36*4)
    for row in range(4):
        for frame in range(4):
            im,d=canvas(24,36); sway=[0,-1,0,1][frame]; yy=0 if frame%2==0 else 1
            if data:
                d.arc((12,18,23,32),230,90,fill='#493f3b',width=2)
                d.ellipse((5,14+yy,18,30+yy),fill='#875740',outline=INK)
                d.ellipse((4,4+yy,19,19+yy),fill='#aa7450',outline=INK)
                d.ellipse((1,8+yy,7,15+yy),fill='#cc9870',outline=INK)
                d.ellipse((17,8+yy,23,15+yy),fill='#cc9870',outline=INK)
                d.ellipse((6,9+yy,17,18+yy),fill='#ead1a2')
                d.rectangle((7,8+yy,9,11+yy),fill=INK);d.rectangle((14,8+yy,16,11+yy),fill=INK)
                d.rectangle((7,23,10,34-sway),fill='#603f34');d.rectangle((14,23,17,34+sway),fill='#603f34')
            else:
                d.rectangle((6,23,10,33-sway),fill=pants,outline=INK)
                d.rectangle((13,23,17,33+sway),fill=pants,outline=INK)
                d.rectangle((5,32-sway,10,34-sway),fill=INK);d.rectangle((13,32+sway,18,34+sway),fill=INK)
                d.polygon([(7,15+yy),(16,15+yy),(19,27+yy),(4,27+yy)],fill=shirt,outline=INK)
                d.line((8,17+yy,15,17+yy),fill='#ffffff70');d.rectangle((6,25+yy,17,27+yy),fill='#3b434a')
                d.rectangle((3,17+yy,5,27+yy+sway),fill='#efbb8b',outline=INK);d.rectangle((18,17+yy,20,27+yy-sway),fill='#efbb8b',outline=INK)
                d.ellipse((5,2+yy,18,17+yy),fill=hair,outline=INK)
                if row!=1:
                    d.rectangle((7,7+yy,16,15+yy),fill='#f7c99e')
                    if row==2:d.point((7,10+yy),fill=INK)
                    elif row==3:d.point((16,10+yy),fill=INK)
                    else:
                        d.point((9,10+yy),fill=INK);d.point((14,10+yy),fill=INK)
                    d.line((10,14+yy,13,14+yy),fill='#c7866d')
                d.polygon([(6,7+yy),(8,3+yy),(16,4+yy),(18,8+yy),(13,6+yy),(12,8+yy),(9,6+yy)],fill=hair)
                if name=='roll':
                    d.rectangle((4,1+yy,18,6+yy),fill='#d36a55',outline=INK);d.rectangle((3,5+yy,19,7+yy),fill='#efae6b')
                    d.rectangle((7,2+yy,10,4+yy),fill='#508389');d.rectangle((13,2+yy,16,4+yy),fill='#508389')
                    d.line((7,18+yy,7,25+yy),fill='#efb870');d.line((16,18+yy,16,25+yy),fill='#efb870')
                if name=='tron':
                    d.polygon([(5,7+yy),(2,3+yy),(8,4+yy),(9,1+yy),(13,4+yy),(20,3+yy),(18,12+yy)],fill=hair,outline=INK)
                    d.rectangle((10,18+yy,13,21+yy),fill='#f0b871')
                if name=='barrell':d.rectangle((7,13+yy,16,17+yy),fill='#d7d6bf');d.line((7,9+yy,16,9+yy),fill='#52616b')
                if hat:d.rectangle((5,1+yy,18,5+yy),fill=shirt,outline=INK)
            sheet.alpha_composite(im,(frame*24,row*36))
    save(sheet,'characters',name)

def machines():
    for name,colour in [('horokko','#537c69'),('zakobon','#aa6354'),('sharukurusu','#6a7f9e'),('servbot','#e9bd52')]:
        out,_=canvas(48*4,48)
        for f in range(4):
            im,d=canvas(48,48); y=f%2
            if name=='servbot':
                d.rectangle((13,24,19,42-y),fill='#496d94',outline=INK,width=2);d.rectangle((28,24,34,42+y),fill='#496d94',outline=INK,width=2)
                d.rectangle((12,21,35,31),fill='#648ba8',outline=INK,width=2)
                d.rectangle((8,9,39,24),fill=colour,outline=INK,width=2)
                d.rectangle((11,10,36,13),fill='#ffe28b')
                d.ellipse((15,15,18,19),fill=INK);d.ellipse((29,15,32,19),fill=INK);d.line((20,22,26,22),fill=INK)
                d.rectangle((5,23,11,32+y),fill=colour,outline=INK);d.rectangle((36,23,42,32-y),fill=colour,outline=INK)
            else:
                for x in [8,30]:
                    d.rectangle((x,28-y,x+9,41+y),fill='#304554',outline=INK,width=2)
                    for yy in [31,36]:d.line((x+1,yy,x+8,yy),fill='#8ca49f')
                if name=='sharukurusu':
                    d.polygon([(7,29),(18,7+y),(30,7+y),(41,29),(33,37),(14,37)],fill=colour,outline=INK,width=2)
                    d.polygon([(18,8+y),(23,2+y),(30,8+y)],fill='#b2c5c6',outline=INK)
                else:
                    d.rectangle((9,13+y,38,33+y),fill=colour,outline=INK,width=2)
                    d.rectangle((12,9+y,35,16+y),fill='#93a794',outline=INK)
                    d.line((14,12+y,32,12+y),fill='#d6d8b3')
                d.ellipse((16,18+y,32,31+y),fill='#243b46',outline='#c4b889')
                d.ellipse((20,21+y,28,29+y),fill='#ef7451');d.ellipse((22,22+y,25,25+y),fill='#ffe8a4')
                d.rectangle((7,21,12,28),fill='#afad88',outline=INK);d.rectangle((35,21,40,28),fill='#afad88',outline=INK)
            out.alpha_composite(im,(f*48,0))
        save(out,'characters',name)
    im,d=canvas(96,96)
    d.rectangle((7,43,27,85),fill='#365466',outline=INK,width=3);d.rectangle((69,43,89,85),fill='#365466',outline=INK,width=3)
    for x in [10,72]:
        for y in range(47,82,7):d.line((x,y,x+13,y),fill='#88a7a2',width=2)
    d.polygon([(17,44),(25,16),(72,16),(82,44),(76,74),(21,74)],fill='#507c74',outline=INK,width=3)
    d.polygon([(25,16),(34,6),(61,6),(72,16)],fill='#89a59a',outline=INK,width=3)
    d.rectangle((30,19,65,29),fill='#2b4c51',outline='#b7c39f',width=2)
    d.ellipse((28,34,68,72),fill='#203941',outline='#b9b693',width=3)
    d.ellipse((35,40,61,66),fill='#d95649',outline='#e7bc65',width=2);d.ellipse((40,44,54,58),fill='#ffe7a2')
    for x in [6,72]:d.rectangle((x,26,x+18,43),fill='#78978d',outline=INK,width=3);d.rectangle((x+4,30,x+14,37),fill='#32484f')
    d.rectangle((38,76,58,83),fill='#afb48e',outline=INK)
    save(im,'characters','guardian')

def props_items():
    bed,d=canvas(48,64)
    d.rectangle((3,4,44,59),fill='#a8815a',outline=INK,width=2)
    d.rectangle((6,9,41,54),fill='#e2d7b3',outline='#776858')
    d.rectangle((8,11,39,23),fill='#f5eace',outline='#b6b59f')
    d.rectangle((7,26,40,54),fill='#52798e',outline='#2c4b5d')
    d.line((8,29,38,29),fill='#a9c6bc',width=3)
    for x in range(10,39,7):d.line((x,33,x,51),fill='#658d9b')
    d.rectangle((3,51,44,59),fill='#b89462',outline=INK,width=2)
    save(bed,'world','bed')
    desk,d=canvas(80,56)
    d.rectangle((2,25,77,42),fill='#aa865d',outline=INK,width=2)
    d.line((5,28,74,28),fill='#e2c594',width=2)
    d.rectangle((8,43,15,55),fill='#695548');d.rectangle((65,43,72,55),fill='#695548')
    d.rectangle((24,4,59,26),fill='#2c4b5a',outline=INK,width=2)
    d.rectangle((28,8,55,21),fill='#79b8b4');d.line((30,13,51,13),fill='#d9e6b8')
    d.rectangle((20,30,57,36),fill='#496477',outline=INK)
    for x in range(22,56,5):d.line((x,32,x,35),fill='#a6b5a8')
    d.rectangle((6,19,18,27),fill='#cb9465',outline=INK)
    save(desk,'world','workbench')
    rug,d=canvas(96,64)
    d.rectangle((2,2,93,61),fill='#ab6d56',outline='#e2be86',width=3)
    d.rectangle((9,9,86,54),outline='#754f4b',width=3)
    d.polygon([(48,18),(62,32),(48,46),(34,32)],fill='#d7ae74',outline='#f2db9e',width=2)
    save(rug,'world','rug')
    for name,colour in [('crate','#b48a60'),('shipping','#458081'),('bench','#9f6b4d'),('board','#82634a')]:
        im,d=canvas(48,48)
        d.rectangle((5,13,43,39),fill=colour,outline=INK,width=2)
        for y in [17,26,35]:d.line((8,y,40,y),fill='#e1be80',width=2)
        if name=='shipping':
            d.rectangle((8,8,41,19),fill='#78aa9c',outline=INK,width=2);d.rectangle((13,20,35,29),fill='#ead39a');label(d,(15,20),'SELL',INK)
        elif name=='board':
            d.rectangle((7,4,41,32),fill='#a98050',outline=INK,width=2);d.rectangle((11,8,22,24),fill=CREAM);d.rectangle((26,12,36,28),fill='#e7c491')
            d.rectangle((11,34,15,45),fill='#6d5241');d.rectangle((34,34,38,45),fill='#6d5241')
        save(im,'world',name)
    im,d=canvas(48,48)
    d.rectangle((21,13,26,45),fill='#49666c',outline=INK);d.rectangle((8,4,38,13),fill='#416576',outline=INK)
    d.rectangle((12,5,34,10),fill='#a8d9ca');d.rectangle((18,40,30,45),fill='#6e8073')
    save(im,'world','lamp')
    im,d=canvas(80,72)
    d.rectangle((6,12,73,62),fill='#91a190',outline=INK,width=2)
    d.rectangle((10,16,69,57),fill='#5a7a70');d.rectangle((21,23,58,66),fill='#132f40',outline='#bbc59e',width=3)
    d.ellipse((26,27,54,47),fill='#39574f');d.rectangle((29,37,51,66),fill='#102934')
    for x in [12,61]:d.rectangle((x,25,x+5,49),fill='#728d7e');d.line((x+2,28,x+2,44),fill='#b9c6a0')
    d.ellipse((33,6,46,19),fill='#2b454c',outline='#c8bf89');d.ellipse((36,9,43,15),fill='#ec8463')
    save(im,'world','ruin_entrance')
    icons={
        'servo':('motor','#c8ba8b'), 'circuit':('chip','#74b7ad'), 'scrap':('metal','#a9b5b6'),
        'seed':('seed','#ddb477'), 'turnip':('crop','#f1dab0'), 'fish':('fish','#79bfc6'),
        'heal':('bottle','#ef8a74'), 'hoe':('tool','#b2cad0'), 'water':('can','#7bacb1'),
        'buster':('gun','#559dda'), 'relic':('relic','#d6b768'), 'key':('key','#ffc875'),
    }
    for name,(kind,c) in icons.items():
        im,d=canvas(32,32)
        if kind=='motor':
            d.rectangle((7,10,25,23),fill=c,outline=INK,width=2);d.rectangle((2,14,29,19),fill='#9ba7a3',outline=INK)
            for x in [9,14,19]:d.line((x,11,x,22),fill='#786d61')
        elif kind=='chip':
            d.rectangle((7,7,25,25),fill=c,outline=INK,width=2);d.rectangle((11,11,21,21),fill='#244b4e')
            for x in [9,15,21]:d.line((x,3,x,7),fill='#e6cc86');d.line((x,25,x,29),fill='#e6cc86')
        elif kind in ['seed','bottle','can']:
            d.rectangle((10,6,22,9),fill='#7d6753',outline=INK);d.rectangle((7,10,25,26),fill=c,outline=INK,width=2)
            d.rectangle((11,14,21,23),fill=CREAM)
            if kind=='can':d.line((25,13,30,9),fill=c,width=3)
            elif kind=='bottle':d.rectangle((15,16,17,22),fill='#dd6b60');d.rectangle((13,18,19,20),fill='#dd6b60')
            else:d.ellipse((14,17,19,23),fill='#997357')
        elif kind=='crop':
            d.ellipse((7,12,25,28),fill=c,outline=INK,width=2);d.polygon([(14,13),(8,4),(17,9),(21,2),(21,13)],fill='#72a05d',outline=INK)
        elif kind=='fish':
            d.ellipse((4,10,23,23),fill=c,outline=INK,width=2);d.polygon([(23,16),(30,9),(30,25)],fill=c,outline=INK);d.point((8,15),fill=INK)
        elif kind=='gun':
            d.polygon([(5,9),(24,7),(28,12),(27,22),(10,24),(5,19)],fill=c,outline=INK,width=2);d.ellipse((20,10,30,22),fill='#214568',outline='#adceca',width=2)
        elif kind=='tool':d.line((7,26,24,6),fill='#ba8961',width=3);d.rectangle((17,4,29,9),fill=c,outline=INK)
        elif kind=='key':d.ellipse((3,4,17,18),fill=c,outline=INK,width=2);d.line((13,15,27,28),fill=c,width=4);d.rectangle((22,21,28,24),fill=c)
        elif kind=='relic':d.polygon([(16,3),(26,12),(24,25),(16,29),(7,24),(6,11)],fill=c,outline=INK,width=2);d.ellipse((11,11,21,21),fill='#3d716c',outline='#f9e0a7')
        else:
            d.polygon([(4,18),(11,6),(26,9),(28,22),(18,28)],fill=c,outline=INK,width=2);d.line((11,6,16,23,27,22),fill='#647e89',width=2)
        save(im,'items',name)
    for stage in range(4):
        im,d=canvas(32,40)
        if stage>0:
            d.line((16,30,16,19-stage*3),fill='#527645',width=2)
            for k in range(stage):
                y=24-k*5;d.polygon([(16,y),(6-k,y-5),(8-k,y-10),(16,y-3)],fill='#95b969',outline='#4a7451')
                d.polygon([(16,y),(24+k,y-7),(28,y-5),(17,y+1)],fill='#719b53',outline='#4a7451')
            if stage==3:d.ellipse((8,22,25,36),fill='#e7d8b5',outline='#7f8e5b',width=2);d.line((12,25,18,25),fill='#fff1d0',width=2)
        save(im,'world',f'crop_{stage}')

sprite_sheet();terrain();flutter()
building('junk_shop',128,'#b86352','JUNK SHOP')
building('city_hall',160,'#537795','CITY HALL','hall')
building('museum',144,'#708576','MUSEUM','museum')
building('cafe',112,'#c6a267','CAFE')
building('police',112,'#536d89','POLICE')
building('house',96,'#a5685d','')
npc('roll','#e1b354','#bc5e54','#645761')
npc('tron','#735044','#d1666e','#62557b')
npc('barrell','#d7d6bf','#8d916c','#675a4d')
npc('amelia','#8c634f','#a5b0c4','#647585')
npc('junkman','#756150','#768d78','#6a6f80',hat=True)
npc('data','#87583e','#87583e','#87583e',data=True)
machines();props_items()
print('Built animated characters, terrain, Kattelox buildings, Flutter, machinery and icons.')

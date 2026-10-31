"""Procedural 16-bit pixel art for Act II (The Misty Forest).

Draws the tileable forest floor, mossy log ledges, brittle branches, springy mushrooms, acid
surface, bramble vines, eruption roots, the Arboris acid glob / bark reward and the cavern mouth.
Painted backdrops and character sprites come from process_zone_backgrounds.py / process_sprite_sheet.py.

Usage: python generate_act2_assets.py
"""
import math
import os
import random

from PIL import Image, ImageDraw

ENV = "assets/sprites/environment/forest"
HAZ = "assets/sprites/hazards"
BOSS = "assets/sprites/bosses/arboris"
COL = "assets/sprites/collectibles"
for d in (ENV, HAZ, BOSS, COL):
    os.makedirs(d, exist_ok=True)

rng = random.Random(7)

# Shared Misty Forest palette
SOIL_DARK = (22, 20, 24, 255)
SOIL = (40, 33, 32, 255)
SOIL_MID = (58, 46, 40, 255)
SOIL_HI = (76, 60, 50, 255)
MOSS_DARK = (30, 54, 36, 255)
MOSS = (48, 84, 46, 255)
MOSS_HI = (82, 122, 60, 255)
MOSS_TIP = (128, 162, 80, 255)
BARK_DARK = (34, 26, 24, 255)
BARK = (62, 46, 38, 255)
BARK_MID = (86, 64, 50, 255)
BARK_HI = (112, 88, 66, 255)
ROT = (90, 52, 110, 255)
ROT_HI = (150, 92, 190, 255)
THORN = (196, 120, 255, 255)
OUTLINE = (14, 10, 18, 255)
TEAL_DARK = (40, 92, 98, 255)
TEAL = (86, 170, 160, 255)
TEAL_HI = (150, 226, 206, 255)
TEAL_GLOW = (214, 255, 236, 255)
STEM = (166, 172, 154, 255)
STEM_SHADE = (112, 116, 106, 255)
ACID_DARK = (34, 60, 30, 255)
ACID = (74, 136, 44, 255)
ACID_HI = (140, 204, 70, 255)
ACID_FOAM = (206, 246, 150, 255)


def px(img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c)


def outline(img, color=OUTLINE):
    """1px dark outline around every opaque pixel, keeping sprites readable on busy backdrops."""
    src = img.copy()
    for y in range(img.height):
        for x in range(img.width):
            if src.getpixel((x, y))[3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < img.width and 0 <= ny < img.height and src.getpixel((nx, ny))[3] != 0:
                    img.putpixel((x, y), color)
                    break
    return img


# -------------------------------------------------------------
# Forest floor: mossy turf over root-laced soil, seamless 256 x 48
# -------------------------------------------------------------
def forest_floor():
    w, h = 256, 48
    im = Image.new("RGBA", (w, h), SOIL)
    for y in range(h):
        for x in range(w):
            v = ((x * 13) ^ (y * 7) + x * y) % 23
            c = SOIL
            if v < 3:
                c = SOIL_MID
            elif v == 3:
                c = SOIL_HI
            elif v > 19:
                c = SOIL_DARK
            # deeper soil darkens
            if y > 34 and v % 3 == 0:
                c = SOIL_DARK
            im.putpixel((x, y), c)
    # Roots snaking through the soil (wrap horizontally)
    for r in range(5):
        y0 = rng.randint(14, 40)
        phase = rng.random() * math.tau
        for x in range(w):
            y = int(y0 + math.sin(x / 256 * math.tau * (r % 2 + 1) + phase) * 4)
            px(im, x, y, BARK)
            px(im, x, y - 1, BARK_MID if x % 5 else BARK_HI)
    # Embedded stones
    for _ in range(9):
        cx, cy = rng.randint(4, w - 5), rng.randint(16, 42)
        for dy in range(-2, 3):
            for dx in range(-3, 4):
                if dx * dx / 9 + dy * dy / 4 <= 1:
                    px(im, cx + dx, cy + dy, (70, 72, 78, 255) if dy < 0 else (48, 50, 56, 255))
    # Moss turf band on top with hanging tufts
    for x in range(w):
        depth = 6 + int(2 * math.sin(x / 256 * math.tau * 4)) + (1 if x % 7 == 0 else 0)
        for y in range(depth):
            c = MOSS if y > 1 else MOSS_HI
            if y == depth - 1:
                c = MOSS_DARK
            px(im, x, y, c)
        px(im, x, 0, MOSS_TIP if x % 3 else MOSS_HI)
        if x % 11 == 0:
            for y in range(depth, depth + 3):
                px(im, x, y, MOSS_DARK)
    # Occasional purple thorn sprouts creeping in the turf
    for x in range(9, w, 37):
        px(im, x, 2, ROT_HI)
        px(im, x + 1, 3, ROT)
    im.save(os.path.join(ENV, "forest_floor.png"))


# -------------------------------------------------------------
# Mossy log ledge 140 x 32 (solid one-way platform)
# -------------------------------------------------------------
def log_ledge():
    w, h = 140, 32
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([2, 6, w - 3, 22], radius=7, fill=BARK)
    for x in range(4, w - 4):
        px(im, x, 7, BARK_HI)
        px(im, x, 8, BARK_MID)
        px(im, x, 21, BARK_DARK)
        if x % 9 == 0:
            for y in range(10, 20):
                px(im, x, y, BARK_DARK if y % 3 else BARK_MID)
    # cut log ends with rings
    for cx in (8, w - 9):
        d.ellipse([cx - 6, 7, cx + 6, 21], fill=BARK_HI)
        d.ellipse([cx - 4, 9, cx + 4, 19], fill=BARK_MID)
        d.ellipse([cx - 2, 12, cx + 2, 16], fill=BARK_HI)
    # moss blanket on top
    for x in range(3, w - 3):
        t = 3 + int(2 * math.sin(x * 0.3)) + (x % 4 == 0)
        for y in range(6 - 2, 6 + t):
            px(im, x, y, MOSS if y > 5 else MOSS_HI)
        px(im, x, 4, MOSS_TIP if x % 2 else MOSS_HI)
    # dangling moss strands
    for x in range(14, w - 14, 17):
        ln = rng.randint(4, 9)
        for y in range(22, 22 + ln):
            px(im, x, y, MOSS_DARK if y % 2 else MOSS)
    outline(im)
    im.save(os.path.join(ENV, "log_ledge.png"))


# -------------------------------------------------------------
# Brittle rotting branch 96 x 20 (crumbles under the hero)
# -------------------------------------------------------------
def brittle_branch():
    w, h = 96, 20
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for x in range(2, w - 2):
        thick = 7 - int(3 * abs(x - w / 2) / (w / 2))
        top = 6 + int(math.sin(x * 0.12) * 1.5)
        for y in range(top, top + thick):
            c = BARK_MID if y == top else BARK
            if y == top + thick - 1:
                c = BARK_DARK
            px(im, x, y, c)
        # cracks and violet rot
        if x % 13 == 5:
            for y in range(top, top + thick):
                px(im, x, y, OUTLINE)
        if x % 19 == 3:
            px(im, x, top + 1, ROT_HI)
            px(im, x + 1, top + 2, ROT)
    # twig stubs
    for x in (20, 51, 74):
        for i in range(5):
            px(im, x + i, 5 - i, BARK_MID)
    # a few dry leaves
    for x in (30, 62):
        px(im, x, 4, (150, 120, 60, 255))
        px(im, x + 1, 4, (120, 92, 46, 255))
    outline(im)
    im.save(os.path.join(ENV, "brittle_branch.png"))


# -------------------------------------------------------------
# Springy mushroom: cap 64 x 26 + tileable stem 18 x 32
# -------------------------------------------------------------
def mushroom(name, base, hi, glow, dark):
    w, h = 64, 26
    cap = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y in range(h):
        for x in range(w):
            nx = (x - w / 2 + 0.5) / (w / 2 - 1)
            ny = (y - h + 4) / (h - 4)
            # dome
            if nx * nx + ny * ny <= 1.0 and y < h - 4:
                shade = base
                if ny < -0.65:
                    shade = hi
                if nx < -0.6 or nx > 0.75:
                    shade = dark
                cap.putpixel((x, y), shade)
    # gills strip under the dome
    for x in range(6, w - 6):
        for y in range(h - 5, h - 2):
            cap.putpixel((x, y), STEM_SHADE if x % 3 == 0 else STEM)
    # glowing spots
    for (sx, sy, r) in ((18, 8, 3), (36, 5, 2), (46, 11, 3), (27, 14, 2)):
        for y in range(-r, r + 1):
            for x in range(-r, r + 1):
                if x * x + y * y <= r * r and cap.getpixel((sx + x, sy + y))[3]:
                    cap.putpixel((sx + x, sy + y), glow if x * x + y * y < r * r - 1 else hi)
    outline(cap)
    cap.save(os.path.join(ENV, "mushroom_cap_%s.png" % name))

    sw, sh = 18, 32
    stem = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    for y in range(sh):
        for x in range(3, sw - 3):
            c = STEM
            if x < 6:
                c = STEM_SHADE
            elif x > sw - 6:
                c = (198, 202, 184, 255)
            if (y * 5 + x) % 11 == 0:
                c = STEM_SHADE
            stem.putpixel((x, y), c)
        stem.putpixel((2, y), OUTLINE)
        stem.putpixel((sw - 3, y), OUTLINE)
    stem.save(os.path.join(ENV, "mushroom_stem.png"))


# -------------------------------------------------------------
# Acid surface tile 64 x 18 (repeats horizontally, scrolls in game)
# -------------------------------------------------------------
def acid_surface():
    w, h = 64, 18
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for x in range(w):
        wave = int(1.5 + 1.5 * math.sin(x / w * math.tau * 2))
        for y in range(wave, h):
            c = ACID
            if y <= wave + 1:
                c = ACID_HI
            elif y > 11:
                c = ACID_DARK
            elif (x * 3 + y * 5) % 13 == 0:
                c = ACID_HI
            im.putpixel((x, y), c)
        if x % 16 in (3, 4):
            im.putpixel((x, wave), ACID_FOAM)
    # bubbles
    for (bx, by) in ((10, 7), (27, 10), (44, 6), (56, 12)):
        for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
            px(im, bx + dx, by + dy, ACID_FOAM)
    im.save(os.path.join(HAZ, "acid_surface.png"))


# -------------------------------------------------------------
# Bramble vine segment 36 x 48 (stacked into bramble walls)
# -------------------------------------------------------------
def bramble():
    w, h = 36, 48
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for strand in range(3):
        phase = strand * 2.1
        for y in range(h):
            x = int(w / 2 + math.sin(y / h * math.tau + phase) * (8 + strand * 2))
            for t in range(-1, 2):
                px(im, x + t, y, ROT if t else (70, 38, 88, 255))
            if (y + strand * 5) % 9 == 0:
                side = 1 if strand % 2 else -1
                for i in range(1, 5):
                    px(im, x + side * i, y - i // 2, THORN if i > 2 else ROT_HI)
    # leaves of corrupted ivy
    for (lx, ly) in ((6, 10), (26, 22), (9, 36), (28, 42)):
        for dy in range(-2, 3):
            for dx in range(-2, 3):
                if abs(dx) + abs(dy) <= 2:
                    px(im, lx + dx, ly + dy, (52, 70, 44, 255) if dy >= 0 else (74, 98, 56, 255))
    outline(im)
    im.save(os.path.join(ENV, "bramble_vine.png"))


# -------------------------------------------------------------
# Eruption root spike 26 x 64
# -------------------------------------------------------------
def root_spike():
    w, h = 26, 64
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y in range(h):
        half = max(1, int((y / h) * 9) + 1)
        cx = w // 2 + int(math.sin(y * 0.18) * 2)
        for x in range(cx - half, cx + half + 1):
            c = BARK
            if x <= cx - half + 1:
                c = BARK_DARK
            elif x >= cx + half - 1:
                c = BARK_HI
            elif (x + y) % 7 == 0:
                c = BARK_MID
            px(im, x, y, c)
        if y % 10 == 6 and y > 8:
            side = 1 if (y // 10) % 2 else -1
            for i in range(1, 6):
                px(im, cx + side * (half + i), y - i, THORN if i > 3 else ROT_HI)
    # violet veins
    for y in range(12, h, 3):
        px(im, w // 2 + int(math.sin(y * 0.18) * 2), y, ROT_HI if y % 6 else THORN)
    outline(im)
    im.save(os.path.join(BOSS, "root_spike.png"))


def acid_glob():
    im = Image.new("RGBA", (14, 14), (0, 0, 0, 0))
    for y in range(14):
        for x in range(14):
            d = (x - 6.5) ** 2 + (y - 6.5) ** 2
            if d <= 30:
                c = ACID
                if d < 6 and x < 7 and y < 7:
                    c = ACID_FOAM
                elif x + y < 11:
                    c = ACID_HI
                elif x + y > 17:
                    c = ACID_DARK
                im.putpixel((x, y), c)
    outline(im)
    im.save(os.path.join(BOSS, "acid_glob.png"))


def arboris_bark():
    """Reward: a shard of purified Arboris bark with a turquoise heart-knot."""
    w, h = 22, 26
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    pts = [(11, 1), (19, 6), (20, 18), (11, 24), (2, 18), (3, 6)]
    ImageDraw.Draw(im).polygon(pts, fill=BARK_MID)
    for y in range(h):
        for x in range(w):
            if im.getpixel((x, y))[3]:
                if (x * 3 + y) % 7 == 0:
                    im.putpixel((x, y), BARK)
                if x > 14:
                    im.putpixel((x, y), BARK if (x + y) % 3 else BARK_DARK)
                if x < 6:
                    im.putpixel((x, y), BARK_HI)
    for (x, y) in ((10, 10), (11, 10), (12, 10), (9, 11), (13, 11), (10, 12), (11, 12), (12, 12), (11, 13), (11, 9)):
        im.putpixel((x, y), TEAL_HI)
    im.putpixel((11, 11), TEAL_GLOW)
    for (x, y) in ((6, 3), (7, 4), (16, 20), (15, 21)):
        im.putpixel((x, y), MOSS_HI)
    outline(im)
    im.save(os.path.join(COL, "arboris_bark.png"))


def cavern_mouth():
    """Dark cave entrance ringed with rock and turquoise crystals, 112 x 104 (Act III exit)."""
    w, h = 112, 104
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cx = w / 2
    for y in range(h):
        for x in range(w):
            nx = (x - cx) / (w / 2)
            ny = (h - y) / h
            r = nx * nx + (ny * 1.05) ** 2
            if r <= 1.0:
                if r > 0.62:
                    c = (64, 66, 74, 255) if (x * 7 + y * 3) % 11 else (86, 90, 98, 255)
                    if r > 0.9:
                        c = (40, 42, 50, 255)
                    if y < 20 and (x + y) % 5 == 0:
                        c = MOSS
                else:
                    depth = r / 0.62
                    c = (int(8 + 18 * depth), int(8 + 16 * depth), int(16 + 22 * depth), 255)
                im.putpixel((x, y), c)
    # crystals inside
    for (bx, by, s) in ((40, 88, 7), (52, 92, 10), (66, 90, 6), (74, 94, 8)):
        for i in range(s):
            for t in range(-(s - i) // 3, (s - i) // 3 + 1):
                px(im, bx + t, by - i, TEAL_HI if t <= 0 else TEAL)
        px(im, bx, by - s, TEAL_GLOW)
    # moss lip over the arch
    for x in range(10, w - 10):
        top = int(h - h * math.sqrt(max(0.0, 1 - ((x - cx) / (w / 2)) ** 2)) / 1.05)
        for y in range(top, top + 3):
            px(im, x, y, MOSS_HI if y == top else MOSS)
        if x % 9 == 0:
            for y in range(top + 3, top + 3 + rng.randint(3, 8)):
                px(im, x, y, MOSS_DARK)
    outline(im)
    im.save(os.path.join(ENV, "cavern_mouth.png"))


if __name__ == "__main__":
    forest_floor()
    log_ledge()
    brittle_branch()
    mushroom("teal", TEAL, TEAL_HI, TEAL_GLOW, TEAL_DARK)
    mushroom("violet", (132, 88, 176, 255), (178, 140, 220, 255), (236, 210, 255, 255), (82, 52, 118, 255))
    acid_surface()
    bramble()
    root_spike()
    acid_glob()
    arboris_bark()
    cavern_mouth()
    print("Act II assets written")

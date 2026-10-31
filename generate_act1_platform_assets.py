import os
from PIL import Image, ImageDraw
import numpy as np

env_dir = r"assets/sprites/environment"
os.makedirs(env_dir, exist_ok=True)

# -------------------------------------------------------------
# 1. 16-BIT SEAMLESS GROUND FLOOR (256 x 48)
# -------------------------------------------------------------
def create_ground_floor():
    w, h = 256, 48
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # Palette
    C_SLATE_HI = (118, 132, 152, 255)
    C_SLATE_MID = (72, 82, 98, 255)
    C_SLATE_LO = (48, 56, 68, 255)
    C_GROOVE = (26, 30, 38, 255)
    
    C_STONE_HI = (92, 86, 78, 255)
    C_STONE_MID = (74, 69, 62, 255)
    C_STONE_LO = (54, 50, 45, 255)
    C_STONE_DARK = (36, 33, 30, 255)
    C_MORTAR = (24, 22, 20, 255)
    C_MOSS = (48, 64, 46, 255)
    C_MOSS_HI = (68, 88, 62, 255)

    # 1. Top Walkable Slate Surface (y=0 to 6)
    # y=0: Crisp top highlight line
    for x in range(w):
        draw.point((x, 0), C_SLATE_HI if (x % 4 != 0) else C_SLATE_MID)
    # y=1..5: Slate slab body with subtle stone dithering
    for y in range(1, 6):
        for x in range(w):
            pattern = (x * 7 + y * 13) % 17
            if pattern < 4:
                c = C_SLATE_HI
            elif pattern < 12:
                c = C_SLATE_MID
            else:
                c = C_SLATE_LO
            draw.point((x, y), c)
    # y=6: Slate edge shadow groove
    for x in range(w):
        draw.point((x, 6), C_GROOVE)

    # 2. Main Stone Masonry Blocks (y=7 to 47)
    # Staggered bricks:
    # Row 1: y=7..19 (height 13), brick width = 64 (4 bricks per 256px)
    # Row 2: y=20..32 (height 13), brick width = 64 offset by 32
    # Row 3: y=33..47 (height 15), rough bedrock
    
    # Fill background with stone mid
    draw.rectangle([0, 7, w - 1, h - 1], fill=C_STONE_MID)

    # Textured dithering inside bricks
    for y in range(7, h):
        for x in range(w):
            val = ((x * 11) ^ (y * 19)) % 19
            if val == 0:
                draw.point((x, y), C_STONE_HI)
            elif val == 1:
                draw.point((x, y), C_STONE_LO)
            elif val == 2 and y > 20:
                draw.point((x, y), C_MOSS)

    # Draw Mortar horizontal joints
    for x in range(w):
        draw.point((x, 19), C_MORTAR)
        draw.point((x, 20), C_STONE_DARK)
        draw.point((x, 32), C_MORTAR)
        draw.point((x, 33), C_STONE_DARK)

    # Vertical Mortar joints for Row 1 (at x=0, 64, 128, 192)
    for bx in [0, 64, 128, 192]:
        for y in range(7, 20):
            draw.point((bx, y), C_MORTAR)
            draw.point(((bx + 1) % w, y), C_STONE_DARK)
            # Add subtle moss in corner crevices
            if y in (8, 9, 17, 18):
                draw.point(((bx + 2) % w, y), C_MOSS)

    # Vertical Mortar joints for Row 2 (at x=32, 96, 160, 224)
    for bx in [32, 96, 160, 224]:
        for y in range(20, 33):
            draw.point((bx, y), C_MORTAR)
            draw.point(((bx + 1) % w, y), C_STONE_DARK)
            if y in (21, 22, 30, 31):
                draw.point(((bx + 2) % w, y), C_MOSS)

    # Rough Bedrock bottom joints and moss tufts
    for bx in [16, 80, 144, 208]:
        for y in range(33, 44):
            draw.point((bx, y), C_MORTAR)
        # Ancient Persian relief accent dot in center of bedrock blocks
        draw.point(((bx + 32) % w, 38), C_STONE_HI)
        draw.point(((bx + 31) % w, 38), C_STONE_DARK)
        draw.point(((bx + 33) % w, 38), C_STONE_DARK)

    # Bottom shadow edge
    for x in range(w):
        draw.point((x, 46), C_STONE_LO)
        draw.point((x, 47), C_STONE_DARK)

    out_path = os.path.join(env_dir, "ground_floor.png")
    im.save(out_path)
    print(f"Saved 16-bit seamless ground_floor.png: {im.size}")

# -------------------------------------------------------------
# 2. 16-BIT CARVED FLOATING LEDGE (140 x 32)
# -------------------------------------------------------------
def create_floating_ledge():
    w, h = 140, 32
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # Palette
    C_SLATE_HI = (120, 136, 156, 255)
    C_SLATE_MID = (76, 86, 102, 255)
    C_SLATE_LO = (50, 58, 70, 255)
    C_GROOVE = (24, 28, 36, 255)
    
    C_STONE_HI = (102, 95, 86, 255)
    C_STONE_MID = (78, 72, 65, 255)
    C_STONE_LO = (56, 52, 46, 255)
    C_STONE_DARK = (36, 33, 29, 255)
    
    # Glowing Turquoise Sacred Inlay
    C_CYAN_GLOW = (140, 255, 240, 255)
    C_CYAN_HI = (0, 225, 205, 255)
    C_CYAN_MID = (0, 170, 155, 255)
    C_CYAN_DARK = (0, 110, 100, 255)

    # Architectural profile:
    # Top Walkable Slate (x=4..135, y=0..5)
    for x in range(4, 136):
        draw.point((x, 0), C_SLATE_HI if (x not in (4, 135)) else C_SLATE_MID)
        for y in range(1, 5):
            val = (x * 3 + y * 7) % 7
            draw.point((x, y), C_SLATE_HI if val == 0 else (C_SLATE_MID if val < 5 else C_SLATE_LO))
        draw.point((x, 5), C_GROOVE)

    # Left & Right Carved Corner Brackets (x=0..16 and x=123..139)
    # Tapering steps down
    bracket_profile = [
        (4, 135), (3, 136), (2, 137), (1, 138), (0, 139), # y=1..5
        (0, 139), (1, 138), (2, 137), (3, 136), (4, 135), # y=6..10
        (5, 134), (6, 133), (8, 131), (10, 129), (12, 127), # y=11..15
        (15, 124), (18, 121), (22, 117), (26, 113), (32, 107), # y=16..20
        (38, 101), (46, 93), (54, 85) # y=21..23
    ]

    for y_idx, (lx, rx) in enumerate(bracket_profile):
        y = y_idx + 1
        if y < h:
            for x in range(lx, rx + 1):
                if y > 5:
                    draw.point((x, y), C_STONE_MID)

    # Stone slab relief border (y=6..20, x=16..123)
    draw.rectangle([16, 6, 123, 20], fill=C_STONE_MID)
    # Bevel highlight top & left
    for x in range(16, 124):
        draw.point((x, 6), C_STONE_HI)
        draw.point((x, 20), C_STONE_DARK)
    for y in range(6, 21):
        draw.point((16, y), C_STONE_HI)
        draw.point((123, y), C_STONE_DARK)

    # Persian Ornamental Filigree Carving (Stepped diamond inlays)
    diamond_centers = [35, 70, 105]
    for cx in diamond_centers:
        # Diamond outer frame
        for dy in range(-4, 5):
            w_span = 4 - abs(dy)
            y = 13 + dy
            for dx in range(-w_span, w_span + 1):
                draw.point((cx + dx, y), C_STONE_DARK)
        # Inner glowing turquoise core
        draw.point((cx, 13), C_CYAN_GLOW)
        draw.point((cx - 1, 13), C_CYAN_HI)
        draw.point((cx + 1, 13), C_CYAN_HI)
        draw.point((cx, 12), C_CYAN_MID)
        draw.point((cx, 14), C_CYAN_MID)
        # Runes extending horizontally between diamonds
        for rx in range(cx - 12, cx - 4):
            if rx % 2 == 0:
                draw.point((rx, 13), C_CYAN_DARK)

    # Carved lower corbels / ornamental underside (y=21..24)
    for x in range(30, 110):
        if (x // 8) % 2 == 0 and y < h:
            draw.point((x, 21), C_STONE_HI)
            draw.point((x, 22), C_STONE_MID)
            draw.point((x, 23), C_STONE_DARK)

    out_path = os.path.join(env_dir, "floating_ledge.png")
    im.save(out_path)
    print(f"Saved 16-bit floating_ledge.png: {im.size}")

# -------------------------------------------------------------
# 3. 16-BIT CHASM PIT GAP (180 x 72)
# -------------------------------------------------------------
def create_pit_gap():
    w, h = 180, 72
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # Palette
    C_VOID_TOP = (18, 14, 26, 230)
    C_VOID_MID = (10, 8, 16, 250)
    C_VOID_BOT = (4, 3, 7, 255)
    
    C_ROCK_HI = (86, 78, 70, 255)
    C_ROCK_MID = (62, 56, 50, 255)
    C_ROCK_LO = (42, 38, 34, 255)
    C_ROCK_DARK = (24, 20, 18, 255)
    C_THORN = (65, 20, 75, 255)

    # Gradient Void Chasm in center
    for y in range(h):
        t = y / float(h - 1)
        r = int(C_VOID_TOP[0] * (1.0 - t) + C_VOID_BOT[0] * t)
        g = int(C_VOID_TOP[1] * (1.0 - t) + C_VOID_BOT[1] * t)
        b = int(C_VOID_TOP[2] * (1.0 - t) + C_VOID_BOT[2] * t)
        a = int(220 * (1.0 - t) + 255 * t)
        for x in range(w):
            draw.point((x, y), (r, g, b, a))

    # Left Craggy Precipice (x=0..26)
    np.random.seed(42)
    left_cliff = [
        int(16 + 8 * np.sin(y * 0.25) + 3 * np.cos(y * 0.7))
        for y in range(h)
    ]
    for y in range(h):
        wall_x = max(6, min(26, left_cliff[y]))
        for x in range(0, wall_x):
            if x == wall_x - 1:
                draw.point((x, y), C_ROCK_DARK)
            elif x == wall_x - 2:
                draw.point((x, y), C_ROCK_LO)
            elif x == wall_x - 3:
                draw.point((x, y), C_ROCK_MID)
            else:
                draw.point((x, y), C_ROCK_MID if (x + y) % 3 != 0 else C_ROCK_HI)

    # Right Craggy Precipice (x=154..179)
    right_cliff = [
        int(164 - 8 * np.sin(y * 0.22) - 3 * np.cos(y * 0.6))
        for y in range(h)
    ]
    for y in range(h):
        wall_x = max(154, min(174, right_cliff[y]))
        for x in range(wall_x, w):
            if x == wall_x:
                draw.point((x, y), C_ROCK_DARK)
            elif x == wall_x + 1:
                draw.point((x, y), C_ROCK_LO)
            elif x == wall_x + 2:
                draw.point((x, y), C_ROCK_MID)
            else:
                draw.point((x, y), C_ROCK_MID if (x + y) % 3 != 0 else C_ROCK_HI)

    # Subtle abyss dust motes / glowing spores rising from depths
    motes = [
        (45, 55), (75, 42), (105, 50), (135, 38),
        (60, 25), (90, 18), (120, 28), (80, 60), (110, 62)
    ]
    for mx, my in motes:
        draw.point((mx, my), (140, 60, 160, 180))
        draw.point((mx + 1, my), (90, 40, 110, 120))

    out_path = os.path.join(env_dir, "pit_gap.png")
    im.save(out_path)
    print(f"Saved 16-bit pit_gap.png: {im.size}")

if __name__ == "__main__":
    create_ground_floor()
    create_floating_ledge()
    create_pit_gap()

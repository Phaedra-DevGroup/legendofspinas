import os
from PIL import Image, ImageDraw

project_dir = os.path.dirname(os.path.abspath(__file__))
sprites_dir = os.path.join(project_dir, "assets", "sprites")

dirs = [
    os.path.join(sprites_dir, "enemies", "shield_bearer"),
    os.path.join(sprites_dir, "enemies", "mist_raven"),
    os.path.join(sprites_dir, "enemies", "spore_crawler"),
    os.path.join(sprites_dir, "bosses", "lurker"),
    os.path.join(sprites_dir, "environment"),
    os.path.join(sprites_dir, "hazards"),
]
for d in dirs:
    os.makedirs(d, exist_ok=True)

METAL = (140, 120, 95, 255)
METAL_DARK = (80, 66, 52, 255)
STONE = (95, 90, 100, 255)
STONE_DARK = (55, 52, 64, 255)
PURPLE = (150, 45, 195, 255)
PURPLE_DARK = (80, 18, 110, 255)
TURQUOISE = (70, 240, 230, 255)
EYE = (255, 45, 75, 255)

# ----------------------------------------------------
# 1. Corrupted Shield-Bearer (36x36)
# ----------------------------------------------------
def draw_shield_bearer(state="idle"):
    img = Image.new("RGBA", (36, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Legs
    d.line([(14, 28), (13, 34)], fill=STONE_DARK, width=3)
    d.line([(21, 28), (22, 34)], fill=STONE_DARK, width=3)
    # Torso
    d.polygon([(12, 12), (24, 12), (26, 29), (10, 29)], fill=STONE, outline=STONE_DARK)
    # Head
    d.ellipse([13, 5, 23, 15], fill=STONE_DARK)
    d.point((16, 10), fill=EYE)
    d.point((20, 10), fill=EYE)
    # Corrupted roots
    d.line([(12, 20), (8, 24), (10, 31)], fill=PURPLE, width=1)
    d.line([(24, 18), (27, 23)], fill=PURPLE, width=1)
    # Shield on the facing (right) side
    if state == "stun":
        d.polygon([(26, 24), (34, 27), (32, 33), (24, 30)], fill=METAL_DARK, outline=PURPLE)
        d.line([(16, 6), (20, 3)], fill=PURPLE, width=1)
    elif state == "bash":
        d.polygon([(28, 10), (35, 14), (33, 30), (26, 27)], fill=METAL, outline=METAL_DARK)
        d.line([(29, 12), (34, 15)], fill=(220, 200, 160, 255), width=1)
    else:
        d.polygon([(25, 11), (33, 14), (31, 31), (23, 28)], fill=METAL, outline=METAL_DARK)
        d.ellipse([26, 18, 30, 22], fill=PURPLE_DARK)
        d.point((28, 20), fill=PURPLE)
    return img

draw_shield_bearer("idle").save(os.path.join(sprites_dir, "enemies", "shield_bearer", "bearer_idle.png"))
draw_shield_bearer("bash").save(os.path.join(sprites_dir, "enemies", "shield_bearer", "bearer_bash.png"))
draw_shield_bearer("stun").save(os.path.join(sprites_dir, "enemies", "shield_bearer", "bearer_stun.png"))

# ----------------------------------------------------
# 2. Mist Raven (30x22) + Mist Cloud (28x16)
# ----------------------------------------------------
def draw_mist_raven(state="perch"):
    img = Image.new("RGBA", (30, 22), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    body = (30, 32, 48, 255)
    feather = (58, 62, 86, 255)
    mist = (170, 120, 230, 200)
    d.ellipse([10, 8, 20, 17], fill=body)
    d.ellipse([17, 6, 24, 12], fill=feather)
    d.polygon([(23, 9), (29, 10), (23, 12)], fill=(210, 160, 60, 255))
    d.point((20, 8), fill=EYE)
    if state == "perch":
        d.polygon([(11, 10), (4, 14), (12, 15)], fill=body)
        d.line([(12, 17), (12, 21)], fill=feather, width=1)
        d.line([(16, 17), (16, 21)], fill=feather, width=1)
    else:
        d.polygon([(11, 9), (2, 1), (13, 12)], fill=feather)
        d.polygon([(13, 8), (24, 0), (15, 13)], fill=feather)
        d.polygon([(11, 13), (3, 20), (15, 15)], fill=body)
        d.polygon([(14, 13), (24, 20), (16, 15)], fill=body)
    # Wisp of purple mist
    d.line([(6, 19), (1, 17)], fill=mist, width=2)
    return img

draw_mist_raven("perch").save(os.path.join(sprites_dir, "enemies", "mist_raven", "raven_perch.png"))
draw_mist_raven("swoop").save(os.path.join(sprites_dir, "enemies", "mist_raven", "raven_swoop.png"))

def draw_mist_cloud():
    img = Image.new("RGBA", (28, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i, (cx, cy, r) in enumerate([(8, 9, 6), (15, 8, 7), (21, 10, 5)]):
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(130, 60, 190, 110))
    d.ellipse([11, 6, 17, 11], fill=(180, 100, 240, 130))
    return img

draw_mist_cloud().save(os.path.join(sprites_dir, "enemies", "mist_raven", "mist_cloud.png"))

# ----------------------------------------------------
# 3. Spore Crawler (22x16)
# ----------------------------------------------------
def draw_spore_crawler(swollen=False):
    img = Image.new("RGBA", (22, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    shell = (120, 40, 160, 255) if not swollen else (235, 90, 255, 255)
    spine = (60, 16, 88, 255)
    # Legs
    for lx in (4, 8, 13, 17):
        d.line([(lx, 11), (lx - 1, 15)], fill=spine, width=1)
    # Scuttling shell
    d.ellipse([2, 4, 19, 13], fill=shell, outline=spine)
    # Spore sacs
    d.ellipse([6, 1, 11, 6], fill=(200, 90, 255, 255) if not swollen else (255, 220, 255, 255))
    d.ellipse([13, 2, 17, 6], fill=(200, 90, 255, 255) if not swollen else (255, 220, 255, 255))
    # Eyes
    d.point((7, 8), fill=EYE)
    d.point((14, 8), fill=EYE)
    return img

draw_spore_crawler(False).save(os.path.join(sprites_dir, "enemies", "spore_crawler", "crawler_idle.png"))
draw_spore_crawler(True).save(os.path.join(sprites_dir, "enemies", "spore_crawler", "crawler_swell.png"))

# ----------------------------------------------------
# 4. Hollow Lurker mini-boss (52x38)
# ----------------------------------------------------
def draw_lurker(state="idle"):
    img = Image.new("RGBA", (52, 38), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    carapace = (46, 40, 62, 255)
    carapace_hi = (78, 70, 100, 255)
    if state == "burrow":
        d.arc([4, 22, 48, 40], 180, 360, fill=carapace_hi, width=3)
        d.polygon([(8, 30), (24, 20), (40, 30)], fill=(60, 40, 30, 255))
        d.line([(18, 34), (24, 26)], fill=PURPLE, width=1)
        d.line([(30, 34), (26, 26)], fill=PURPLE, width=1)
        return img
    # Many legs
    for lx in (8, 14, 20, 28, 34, 40):
        d.line([(lx, 26), (lx - 3, 36)], fill=carapace, width=2)
    # Segmented carapace
    d.ellipse([2, 8, 50, 30], fill=carapace, outline=carapace_hi)
    d.ellipse([6, 4, 24, 18], fill=carapace_hi)
    d.line([(14, 10), (30, 8), (44, 14)], fill=PURPLE, width=1)
    # Fangs / thorns
    if state == "strike":
        d.polygon([(4, 26), (0, 34), (10, 30)], fill=PURPLE_DARK)
        d.polygon([(48, 26), (52, 34), (42, 30)], fill=PURPLE_DARK)
        d.ellipse([16, 16, 24, 24], fill=(255, 120, 255, 255))
    else:
        d.polygon([(6, 24), (2, 30), (12, 27)], fill=PURPLE_DARK)
        d.polygon([(46, 24), (50, 30), (40, 27)], fill=PURPLE_DARK)
    # Glowing eyes
    for ex in (14, 20, 30, 36):
        d.point((ex, 13), fill=EYE)
    return img

draw_lurker("idle").save(os.path.join(sprites_dir, "bosses", "lurker", "lurker_idle.png"))
draw_lurker("strike").save(os.path.join(sprites_dir, "bosses", "lurker", "lurker_strike.png"))
draw_lurker("burrow").save(os.path.join(sprites_dir, "bosses", "lurker", "lurker_burrow.png"))

# ----------------------------------------------------
# 5. Bronze Grapple Ring + chain (16x48)
# ----------------------------------------------------
def draw_grapple_ring():
    img = Image.new("RGBA", (16, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    bronze = (188, 140, 60, 255)
    bronze_dark = (110, 78, 32, 255)
    for y in range(0, 34, 5):
        d.ellipse([6, y, 10, y + 3], outline=bronze_dark)
    d.ellipse([2, 33, 14, 46], outline=bronze, width=2)
    d.point((8, 34), fill=(255, 230, 150, 255))
    return img

draw_grapple_ring().save(os.path.join(sprites_dir, "environment", "grapple_ring.png"))

# ----------------------------------------------------
# 6. Old Zal Sanctuary Campfire (34x30)
# ----------------------------------------------------
def draw_campfire():
    img = Image.new("RGBA", (34, 30), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Logs
    d.line([(6, 27), (27, 20)], fill=(92, 60, 38, 255), width=4)
    d.line([(7, 20), (27, 27)], fill=(70, 44, 28, 255), width=4)
    # Flames
    d.polygon([(17, 3), (24, 16), (17, 20), (10, 16)], fill=(255, 150, 40, 255))
    d.polygon([(17, 7), (21, 17), (17, 19), (13, 17)], fill=(255, 220, 90, 255))
    d.polygon([(17, 11), (19, 18), (17, 19), (15, 18)], fill=(120, 250, 240, 255))
    # Spirits / embers
    d.point((13, 5), fill=(255, 200, 90, 255))
    d.point((22, 2), fill=(255, 200, 90, 255))
    return img

draw_campfire().save(os.path.join(sprites_dir, "environment", "campfire.png"))

# ----------------------------------------------------
# 7. Thorn Arch (40x30)
# ----------------------------------------------------
def draw_thorn_arch():
    img = Image.new("RGBA", (40, 30), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    vine = (36, 60, 36, 255)
    d.arc([1, 2, 39, 56], 190, 350, fill=vine, width=3)
    d.arc([1, 8, 39, 62], 190, 350, fill=(52, 82, 50, 255), width=2)
    for (x, y) in ((5, 18), (11, 11), (20, 8), (29, 11), (35, 18)):
        d.line([(x, y), (x + (2 if x < 20 else -2), y + 8)], fill=PURPLE_DARK, width=1)
        d.polygon([(x - 2, y + 8), (x + 2, y + 8), (x, y + 13)], fill=PURPLE)
    return img

draw_thorn_arch().save(os.path.join(sprites_dir, "hazards", "thorn_arch.png"))

# ----------------------------------------------------
# 8. Pit Gap (180x72)
# ----------------------------------------------------
def draw_pit_gap():
    img = Image.new("RGBA", (180, 72), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 179, 71], fill=(10, 8, 14, 255))
    d.polygon([(0, 0), (180, 0), (172, 12), (150, 4), (120, 14), (90, 5), (60, 14), (30, 4), (8, 12)],
              fill=(26, 19, 34, 255))
    for x in range(10, 175, 22):
        d.line([(x, 12), (x + 4, 30)], fill=(60, 20, 80, 160), width=1)
        d.line([(x + 8, 16), (x + 4, 32)], fill=(45, 14, 60, 140), width=1)
    return img

draw_pit_gap().save(os.path.join(sprites_dir, "environment", "pit_gap.png"))

print("Act 1 expansion assets generated.")

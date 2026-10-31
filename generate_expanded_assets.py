import os
from PIL import Image, ImageDraw

project_dir = os.path.dirname(os.path.abspath(__file__))
sprites_dir = os.path.join(project_dir, "assets", "sprites")

# Create folders
dirs = [
    os.path.join(sprites_dir, "enemies", "hollow_villager"),
    os.path.join(sprites_dir, "enemies", "thorn_spitter"),
    os.path.join(sprites_dir, "bosses", "crusher", "fx"),
    os.path.join(sprites_dir, "collectibles"),
    os.path.join(sprites_dir, "environment"),
    os.path.join(sprites_dir, "projectiles"),
    os.path.join(project_dir, "assets", "ui")
]
for d in dirs:
    os.makedirs(d, exist_ok=True)

# ----------------------------------------------------
# 1. Hollow Villager (32x32)
# ----------------------------------------------------
def draw_hollow_villager(state="walk", frame=0):
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    robe_dark = (35, 30, 45, 255)
    robe_mid = (55, 48, 70, 255)
    skin_decay = (110, 115, 105, 255)
    root_purple = (180, 50, 230, 255)
    eye_red = (255, 45, 75, 255)
    iron_rust = (130, 75, 50, 255)
    wood_brown = (90, 60, 40, 255)

    # Corrupted roots creeping around legs
    d.line([(12, 28), (14, 22), (18, 25)], fill=root_purple, width=1)
    d.line([(19, 29), (17, 23)], fill=root_purple, width=1)

    # Robe / Body
    d.polygon([(11, 14), (21, 14), (24, 28), (8, 28)], fill=robe_mid, outline=robe_dark)
    # Head / Tattered cowl
    d.ellipse([11, 7, 21, 16], fill=robe_dark)
    d.rectangle([13, 10, 19, 15], fill=skin_decay)
    # Glowing evil eyes
    d.point((14, 12), fill=eye_red)
    d.point((17, 12), fill=eye_red)

    if state == "walk":
        leg_offset = 2 if frame % 2 == 0 else -2
        d.line([(12, 28), (12 + leg_offset, 31)], fill=robe_dark, width=2)
        d.line([(19, 28), (19 - leg_offset, 31)], fill=robe_dark, width=2)
        # Rusted pickaxe resting
        d.line([(6, 17), (6, 28)], fill=wood_brown, width=2)
        d.polygon([(4, 16), (8, 16), (11, 13), (1, 13)], fill=iron_rust)
    elif state == "attack_windup":
        d.line([(12, 28), (11, 31)], fill=robe_dark, width=2)
        d.line([(19, 28), (20, 31)], fill=robe_dark, width=2)
        # Raised pickaxe overhead
        d.line([(10, 14), (6, 4)], fill=wood_brown, width=2)
        d.polygon([(3, 3), (9, 3), (12, 0), (0, 0)], fill=(220, 80, 50, 255))
    elif state == "attack_swing":
        d.line([(12, 28), (10, 31)], fill=robe_dark, width=2)
        d.line([(19, 28), (22, 31)], fill=robe_dark, width=2)
        # Slammed pickaxe down into floor with sparks
        d.line([(18, 16), (28, 26)], fill=wood_brown, width=2)
        d.polygon([(26, 24), (30, 24), (32, 29), (24, 27)], fill=iron_rust)
        d.ellipse([27, 26, 31, 30], fill=(255, 180, 50, 220))
    elif state == "hurt":
        d.polygon([(11, 14), (21, 14), (24, 28), (8, 28)], fill=(180, 60, 60, 255))
        d.line([(12, 28), (10, 31)], fill=robe_dark, width=2)
        d.line([(19, 28), (18, 31)], fill=robe_dark, width=2)
    return img

for f in range(2):
    draw_hollow_villager("walk", f).save(os.path.join(sprites_dir, "enemies", "hollow_villager", f"villager_walk_{f}.png"))
draw_hollow_villager("attack_windup").save(os.path.join(sprites_dir, "enemies", "hollow_villager", "villager_windup.png"))
draw_hollow_villager("attack_swing").save(os.path.join(sprites_dir, "enemies", "hollow_villager", "villager_swing.png"))
draw_hollow_villager("hurt").save(os.path.join(sprites_dir, "enemies", "hollow_villager", "villager_hurt.png"))

# ----------------------------------------------------
# 2. Corrupted Thorn Spitter (24x24)
# ----------------------------------------------------
def draw_thorn_spitter(state="idle"):
    img = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    stem_dark = (30, 45, 30, 255)
    petal_purple = (150, 45, 195, 255)
    petal_dark = (85, 20, 115, 255)
    glow_cyan = (70, 240, 230, 255)

    # Base Roots
    d.polygon([(4, 23), (12, 17), (20, 23)], fill=stem_dark)
    d.line([(12, 21), (12, 12)], fill=stem_dark, width=3)

    if state == "idle":
        # Closed bulb
        d.ellipse([6, 5, 18, 16], fill=petal_purple, outline=petal_dark, width=1)
        d.point((12, 9), fill=glow_cyan)
        d.point((11, 10), fill=glow_cyan)
        d.point((13, 10), fill=glow_cyan)
    else:
        # Open blooming flower preparing shot
        d.polygon([(6, 10), (0, 4), (7, 6)], fill=petal_purple)
        d.polygon([(18, 10), (24, 4), (17, 6)], fill=petal_purple)
        d.polygon([(12, 6), (12, 0), (14, 5)], fill=petal_purple)
        d.ellipse([7, 6, 17, 16], fill=(220, 60, 255, 255), outline=glow_cyan, width=1)
        d.ellipse([10, 9, 14, 13], fill=(255, 255, 255, 255))
    return img

draw_thorn_spitter("idle").save(os.path.join(sprites_dir, "enemies", "thorn_spitter", "spitter_idle.png"))
draw_thorn_spitter("spit").save(os.path.join(sprites_dir, "enemies", "thorn_spitter", "spitter_spit.png"))

# Thorn Projectile (16x8)
def draw_thorn_projectile():
    img = Image.new("RGBA", (16, 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(0, 4), (12, 1), (16, 4), (12, 7)], fill=(215, 60, 255, 255), outline=(130, 20, 170, 255))
    d.line([(4, 4), (14, 4)], fill=(255, 210, 255, 255), width=1)
    return img
draw_thorn_projectile().save(os.path.join(sprites_dir, "projectiles", "thorn_spike.png"))

# ----------------------------------------------------
# 3. Boss FX: Falling Stalactite & Warning Reticle
# ----------------------------------------------------
def draw_stalactite():
    img = Image.new("RGBA", (20, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    stone_dark = (50, 48, 58, 255)
    stone_light = (110, 105, 125, 255)
    purple_glow = (190, 70, 255, 255)
    d.polygon([(1, 2), (18, 2), (10, 34)], fill=stone_light, outline=stone_dark, width=1)
    d.line([(10, 2), (10, 25)], fill=purple_glow, width=2)
    return img
draw_stalactite().save(os.path.join(sprites_dir, "bosses", "crusher", "fx", "stalactite.png"))

def draw_warning_reticle():
    img = Image.new("RGBA", (32, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([1, 1, 30, 10], outline=(255, 50, 80, 220), width=2)
    d.ellipse([8, 3, 23, 8], fill=(255, 50, 80, 100))
    return img
draw_warning_reticle().save(os.path.join(sprites_dir, "bosses", "crusher", "fx", "warning_reticle.png"))

def draw_crystal_spike():
    img = Image.new("RGBA", (24, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    crystal_purple = (205, 75, 255, 240)
    crystal_outline = (110, 25, 160, 255)
    crystal_light = (245, 190, 255, 255)
    d.polygon([(12, 1), (3, 30), (21, 30)], fill=crystal_purple, outline=crystal_outline, width=1)
    d.line([(12, 3), (12, 28)], fill=crystal_light, width=2)
    return img
draw_crystal_spike().save(os.path.join(sprites_dir, "bosses", "crusher", "fx", "crystal_spike.png"))

# ----------------------------------------------------
# 4. Collectibles & Environment
# ----------------------------------------------------
# Golden Pomegranate (18x18)
def draw_golden_pomegranate():
    img = Image.new("RGBA", (18, 18), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    gold_dark = (160, 110, 20, 255)
    gold_mid = (245, 195, 45, 255)
    gold_bright = (255, 240, 130, 255)
    ruby_seed = (235, 45, 75, 255)
    # Crown atop pomegranate
    d.polygon([(6, 3), (9, 0), (12, 3), (14, 1), (11, 4), (7, 4), (4, 1)], fill=gold_mid, outline=gold_dark)
    # Pomegranate round body
    d.ellipse([2, 4, 16, 17], fill=gold_mid, outline=gold_dark, width=1)
    # Glistening seeds inside cracked opening
    d.ellipse([6, 8, 12, 14], fill=(80, 20, 30, 255))
    d.point((8, 10), fill=ruby_seed)
    d.point((10, 10), fill=ruby_seed)
    d.point((9, 12), fill=ruby_seed)
    # Glistening highlight
    d.line([(4, 7), (6, 5)], fill=gold_bright, width=1)
    return img
draw_golden_pomegranate().save(os.path.join(sprites_dir, "collectibles", "golden_pomegranate.png"))

# Ancient Keystone (16x16)
def draw_keystone():
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    stone_dark = (45, 40, 55, 255)
    stone_mid = (85, 80, 105, 255)
    rune_cyan = (60, 240, 220, 255)
    # Diamond keystone shape
    d.polygon([(8, 1), (14, 8), (8, 14), (2, 8)], fill=stone_mid, outline=stone_dark, width=1)
    # Glowing rune
    d.line([(8, 4), (8, 12)], fill=rune_cyan, width=1)
    d.line([(5, 8), (11, 8)], fill=rune_cyan, width=1)
    return img
draw_keystone().save(os.path.join(sprites_dir, "collectibles", "ancient_keystone.png"))

# Lore Stele (20x36)
def draw_lore_stele():
    img = Image.new("RGBA", (20, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    stele_dark = (40, 42, 50, 255)
    stele_mid = (75, 80, 95, 255)
    rune_gold = (240, 200, 70, 255)
    # Plinth
    d.rectangle([2, 30, 18, 35], fill=stele_dark)
    # Tablet
    d.polygon([(4, 4), (16, 4), (17, 30), (3, 30)], fill=stele_mid, outline=stele_dark, width=1)
    # Rounded top
    d.ellipse([4, 1, 16, 8], fill=stele_mid, outline=stele_dark, width=1)
    # Persian Inscription lines
    d.line([(6, 10), (14, 10)], fill=rune_gold, width=1)
    d.line([(5, 14), (15, 14)], fill=rune_gold, width=1)
    d.line([(6, 18), (14, 18)], fill=rune_gold, width=1)
    d.line([(5, 22), (13, 22)], fill=rune_gold, width=1)
    d.line([(7, 26), (12, 26)], fill=rune_gold, width=1)
    return img
draw_lore_stele().save(os.path.join(sprites_dir, "environment", "lore_stele.png"))

# Ancient Beacon (28x44)
def draw_beacon():
    img = Image.new("RGBA", (28, 44), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    base_color = (60, 55, 70, 255)
    bronze = (175, 115, 45, 255)
    fire_glow = (70, 230, 240, 255)
    # Pillar
    d.rectangle([8, 16, 20, 42], fill=base_color, outline=(35, 30, 45, 255), width=1)
    d.polygon([(4, 42), (24, 42), (26, 44), (2, 44)], fill=bronze)
    # Brazen Bowl
    d.polygon([(4, 14), (24, 14), (20, 20), (8, 20)], fill=bronze)
    # Sacred Eternal Turquoise Fire
    d.polygon([(14, 2), (8, 13), (20, 13)], fill=fire_glow)
    d.ellipse([11, 6, 17, 13], fill=(255, 255, 255, 255))
    return img
draw_beacon().save(os.path.join(sprites_dir, "environment", "ancient_beacon.png"))

# Keystone Gate / Heavy Stone Door (24x96)
def draw_keystone_gate():
    img = Image.new("RGBA", (24, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    stone_dark = (35, 32, 45, 255)
    stone_mid = (65, 62, 80, 255)
    metal_trim = (140, 100, 40, 255)
    rune_cyan = (60, 240, 220, 255)
    d.rectangle([1, 1, 23, 95], fill=stone_mid, outline=stone_dark, width=2)
    # Iron reinforcements
    d.rectangle([1, 16, 23, 20], fill=metal_trim)
    d.rectangle([1, 46, 23, 50], fill=metal_trim)
    d.rectangle([1, 76, 23, 80], fill=metal_trim)
    # Keystone slots (2 sockets)
    d.polygon([(12, 30), (17, 34), (12, 38), (7, 34)], fill=(20, 18, 25, 255), outline=rune_cyan)
    d.polygon([(12, 60), (17, 64), (12, 68), (7, 64)], fill=(20, 18, 25, 255), outline=rune_cyan)
    return img
draw_keystone_gate().save(os.path.join(sprites_dir, "environment", "keystone_gate.png"))

print("All expanded Act 1 assets successfully generated.")

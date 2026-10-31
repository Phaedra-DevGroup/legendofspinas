import os
from PIL import Image, ImageDraw

base_dir = r"E:\Legend of Espinas\assets\sprites"
os.makedirs(os.path.join(base_dir, "enemies", "needle_bat"), exist_ok=True)
os.makedirs(os.path.join(base_dir, "enemies", "blighted_wolf"), exist_ok=True)
os.makedirs(os.path.join(base_dir, "bosses", "crusher"), exist_ok=True)
os.makedirs(os.path.join(base_dir, "hazards"), exist_ok=True)
os.makedirs(os.path.join(base_dir, "projectiles"), exist_ok=True)
os.makedirs(os.path.join(base_dir, "collectibles"), exist_ok=True)
ui_dir = r"E:\Legend of Espinas\assets\ui"
os.makedirs(ui_dir, exist_ok=True)

# ----------------------------------------------------
# 1. Needle Bat (24x20) - 2 Frames
# ----------------------------------------------------
def draw_needle_bat(frame=0):
    img = Image.new("RGBA", (24, 20), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body
    d.ellipse([10, 8, 14, 15], fill=(45, 25, 60, 255))
    # Head & Ears
    d.polygon([(10, 8), (9, 4), (11, 7)], fill=(65, 35, 85, 255))
    d.polygon([(14, 8), (15, 4), (13, 7)], fill=(65, 35, 85, 255))
    d.ellipse([10, 6, 14, 10], fill=(55, 30, 75, 255))
    # Glowing Eyes
    d.point((10, 8), fill=(255, 40, 70, 255))
    d.point((13, 8), fill=(255, 40, 70, 255))
    # Wings
    wing_color = (130, 50, 180, 240)
    wing_edge = (190, 90, 255, 255)
    if frame == 0: # Wings Up
        d.polygon([(10, 9), (3, 2), (1, 8), (5, 11), (9, 11)], fill=wing_color)
        d.polygon([(14, 9), (21, 2), (23, 8), (19, 11), (15, 11)], fill=wing_color)
        d.line([(10, 9), (3, 2), (1, 8)], fill=wing_edge, width=1)
        d.line([(14, 9), (21, 2), (23, 8)], fill=wing_edge, width=1)
    else: # Wings Down
        d.polygon([(10, 11), (2, 10), (0, 16), (6, 17), (9, 14)], fill=wing_color)
        d.polygon([(14, 11), (22, 10), (24, 16), (18, 17), (15, 14)], fill=wing_color)
        d.line([(10, 11), (2, 10), (0, 16)], fill=wing_edge, width=1)
        d.line([(14, 11), (22, 10), (24, 16)], fill=wing_edge, width=1)
    return img

bat_0 = draw_needle_bat(0)
bat_1 = draw_needle_bat(1)
bat_0.save(os.path.join(base_dir, "enemies", "needle_bat", "bat_fly_0.png"))
bat_1.save(os.path.join(base_dir, "enemies", "needle_bat", "bat_fly_1.png"))

# ----------------------------------------------------
# 2. Blighted Wolf (32x22) - 4 Frames
# ----------------------------------------------------
def draw_blighted_wolf(frame=0):
    img = Image.new("RGBA", (32, 22), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    fur_main = (30, 22, 42, 255)
    fur_highlight = (48, 36, 68, 255)
    spike_color = (195, 70, 255, 255)
    eye_color = (255, 230, 50, 255)
    
    # Body
    d.ellipse([8, 7, 24, 16], fill=fur_main)
    # Head & Snout
    d.polygon([(20, 8), (28, 9), (30, 11), (27, 13), (22, 14)], fill=fur_main)
    # Ears
    d.polygon([(22, 8), (24, 3), (25, 7)], fill=fur_highlight)
    # Evil glowing eye
    d.point((26, 9), fill=eye_color)
    d.point((27, 9), fill=eye_color)
    # Purple Corrupted Spikes along spine
    d.polygon([(10, 7), (11, 2), (13, 6)], fill=spike_color)
    d.polygon([(14, 7), (16, 1), (18, 6)], fill=spike_color)
    d.polygon([(18, 7), (20, 3), (21, 6)], fill=spike_color)
    # Tail
    d.line([(8, 10), (3, 8), (1, 12)], fill=fur_highlight, width=2)
    # Legs based on frame
    if frame == 0:
        d.line([(11, 15), (10, 21)], fill=fur_main, width=2) # Back L
        d.line([(15, 15), (17, 21)], fill=fur_highlight, width=2) # Back R
        d.line([(21, 15), (20, 21)], fill=fur_main, width=2) # Front L
        d.line([(25, 15), (27, 21)], fill=fur_highlight, width=2) # Front R
    elif frame == 1:
        d.line([(11, 15), (7, 19)], fill=fur_main, width=2)
        d.line([(15, 15), (15, 21)], fill=fur_highlight, width=2)
        d.line([(21, 15), (24, 21)], fill=fur_main, width=2)
        d.line([(25, 15), (28, 19)], fill=fur_highlight, width=2)
    elif frame == 2:
        d.line([(11, 15), (12, 21)], fill=fur_main, width=2)
        d.line([(15, 15), (13, 21)], fill=fur_highlight, width=2)
        d.line([(21, 15), (22, 21)], fill=fur_main, width=2)
        d.line([(25, 15), (23, 21)], fill=fur_highlight, width=2)
    else:
        d.line([(11, 15), (15, 19)], fill=fur_main, width=2)
        d.line([(15, 15), (12, 21)], fill=fur_highlight, width=2)
        d.line([(21, 15), (18, 20)], fill=fur_main, width=2)
        d.line([(25, 15), (26, 21)], fill=fur_highlight, width=2)
    return img

for f in range(4):
    wolf_img = draw_blighted_wolf(f)
    wolf_img.save(os.path.join(base_dir, "enemies", "blighted_wolf", f"wolf_run_{f}.png"))

# ----------------------------------------------------
# 3. Crusher of the Ruins Boss (56x56)
# ----------------------------------------------------
def draw_crusher(state="idle", frame=0):
    img = Image.new("RGBA", (56, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    stone_dark = (55, 52, 60, 255)
    stone_mid = (85, 80, 95, 255)
    stone_light = (120, 115, 135, 255)
    crack_glow = (200, 70, 255, 255)
    eye_glow = (255, 50, 90, 255)
    
    # Body Torso
    d.rectangle([16, 16, 40, 42], fill=stone_mid, outline=stone_dark, width=2)
    # Stone shoulder plates
    d.ellipse([10, 12, 22, 26], fill=stone_light, outline=stone_dark, width=2)
    d.ellipse([34, 12, 46, 26], fill=stone_light, outline=stone_dark, width=2)
    # Head
    d.rectangle([22, 6, 34, 18], fill=stone_light, outline=stone_dark, width=2)
    # Glowing eye visor
    d.line([(24, 11), (32, 11)], fill=eye_glow, width=2)
    # Corrupted Purple cracks across chest
    d.line([(20, 22), (27, 28), (25, 36)], fill=crack_glow, width=2)
    d.line([(27, 28), (35, 26), (37, 33)], fill=crack_glow, width=2)
    # Sturdy legs
    d.rectangle([18, 42, 26, 54], fill=stone_dark)
    d.rectangle([30, 42, 38, 54], fill=stone_dark)
    
    if state == "idle":
        # Arms at sides with heavy stone fists
        fist_y = 34 if frame == 0 else 32
        d.rectangle([8, fist_y, 18, fist_y + 16], fill=stone_light, outline=stone_dark, width=2)
        d.rectangle([38, fist_y, 48, fist_y + 16], fill=stone_light, outline=stone_dark, width=2)
    elif state == "slam":
        # Raised fists above head glowing with violet energy
        d.rectangle([12, 2, 24, 16], fill=stone_light, outline=crack_glow, width=2)
        d.rectangle([32, 2, 44, 16], fill=stone_light, outline=crack_glow, width=2)
        d.ellipse([10, 0, 46, 14], outline=crack_glow, width=1)
    elif state == "charge":
        # Leaning forward, one massive arm forward
        d.rectangle([36, 22, 54, 38], fill=stone_light, outline=stone_dark, width=2)
        d.rectangle([10, 26, 20, 40], fill=stone_dark)
    elif state == "stun":
        # Slumped, cracks flickering, dizzy stars above head
        d.rectangle([10, 36, 20, 50], fill=stone_dark)
        d.rectangle([36, 36, 46, 50], fill=stone_dark)
        # Dizzy stars
        d.text((18, 0), "*", fill=(255, 230, 50, 255))
        d.text((28, -2), "*", fill=(255, 230, 50, 255))
        d.text((36, 1), "*", fill=(255, 230, 50, 255))
    return img

draw_crusher("idle", 0).save(os.path.join(base_dir, "bosses", "crusher", "crusher_idle_0.png"))
draw_crusher("idle", 1).save(os.path.join(base_dir, "bosses", "crusher", "crusher_idle_1.png"))
draw_crusher("slam", 0).save(os.path.join(base_dir, "bosses", "crusher", "crusher_slam_0.png"))
draw_crusher("charge", 0).save(os.path.join(base_dir, "bosses", "crusher", "crusher_charge_0.png"))
draw_crusher("stun", 0).save(os.path.join(base_dir, "bosses", "crusher", "crusher_stun_0.png"))

# ----------------------------------------------------
# 4. Marg-mayeh Hazards (32x16)
# ----------------------------------------------------
def draw_thorns():
    img = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    spike_base = (35, 15, 50, 255)
    spike_mid = (130, 40, 185, 255)
    spike_glow = (220, 100, 255, 255)
    
    spikes = [(4, 15, 7, 2, 10, 15), (10, 15, 14, 0, 18, 15), (18, 15, 22, 3, 25, 15), (25, 15, 28, 5, 31, 15)]
    for x1, y1, x2, y2, x3, y3 in spikes:
        d.polygon([(x1, y1), (x2, y2), (x3, y3)], fill=spike_mid, outline=spike_base)
        d.line([(x2, y2), ((x1+x3)//2, y1)], fill=spike_glow, width=1)
    return img

draw_thorns().save(os.path.join(base_dir, "hazards", "thorns_hazard.png"))

# ----------------------------------------------------
# 5. Projectiles & Effects
# ----------------------------------------------------
# Nature Arrow (20x6)
def draw_nature_arrow():
    img = Image.new("RGBA", (20, 6), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.line([(2, 3), (17, 3)], fill=(110, 75, 45, 255), width=2)
    d.polygon([(16, 0), (20, 3), (16, 6)], fill=(80, 240, 180, 255))
    d.polygon([(0, 1), (4, 3), (0, 5)], fill=(120, 210, 90, 255))
    d.line([(5, 1), (12, 1)], fill=(150, 255, 200, 200), width=1)
    return img
draw_nature_arrow().save(os.path.join(base_dir, "projectiles", "nature_arrow.png"))

# Light Slash Arc (24x24)
def draw_light_slash():
    img = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.arc([2, 2, 22, 22], start=260, end=70, fill=(60, 230, 230, 255), width=3)
    d.arc([4, 4, 20, 20], start=270, end=60, fill=(200, 255, 255, 255), width=2)
    return img
draw_light_slash().save(os.path.join(base_dir, "projectiles", "light_slash.png"))

# Shockwave (16x20)
def draw_shockwave():
    img = Image.new("RGBA", (16, 20), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(0, 20), (6, 6), (10, 14), (14, 0), (16, 20)], fill=(180, 60, 250, 240), outline=(240, 140, 255, 255))
    return img
draw_shockwave().save(os.path.join(base_dir, "projectiles", "shockwave.png"))

# Thrown Rock (16x16)
def draw_thrown_rock():
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([1, 1, 14, 14], fill=(75, 70, 85, 255), outline=(40, 35, 45, 255), width=2)
    d.line([(4, 4), (8, 9), (12, 6)], fill=(200, 70, 255, 255), width=2)
    return img
draw_thrown_rock().save(os.path.join(base_dir, "projectiles", "thrown_rock.png"))

# ----------------------------------------------------
# 6. Collectibles & HUD Hearts
# ----------------------------------------------------
# Ancient Scrap (12x12)
def draw_ancient_scrap():
    img = Image.new("RGBA", (12, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([1, 1, 10, 10], fill=(215, 145, 40, 255), outline=(130, 85, 20, 255), width=1)
    d.point((6, 6), fill=(70, 240, 230, 255))
    return img
draw_ancient_scrap().save(os.path.join(base_dir, "collectibles", "ancient_scrap.png"))

# Ancient Gear Boss Drop (24x24)
def draw_ancient_gear():
    img = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([3, 3, 20, 20], fill=(245, 185, 45, 255), outline=(140, 95, 15, 255), width=2)
    # Gear teeth
    d.rectangle([10, 0, 14, 23], fill=(245, 185, 45, 255))
    d.rectangle([0, 10, 23, 14], fill=(245, 185, 45, 255))
    d.ellipse([7, 7, 16, 16], fill=(50, 45, 40, 255))
    d.ellipse([9, 9, 14, 14], fill=(70, 245, 235, 255))
    return img
draw_ancient_gear().save(os.path.join(base_dir, "collectibles", "ancient_gear.png"))

# Heart Full (14x12)
def draw_heart_full():
    img = Image.new("RGBA", (14, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(7, 11), (0, 4), (0, 2), (3, 0), (7, 3), (11, 0), (14, 2), (14, 4)], fill=(245, 45, 75, 255), outline=(150, 15, 35, 255))
    d.point((3, 2), fill=(255, 180, 195, 255))
    return img
draw_heart_full().save(os.path.join(ui_dir, "heart_full.png"))

# Heart Empty (14x12)
def draw_heart_empty():
    img = Image.new("RGBA", (14, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(7, 11), (0, 4), (0, 2), (3, 0), (7, 3), (11, 0), (14, 2), (14, 4)], fill=(45, 45, 55, 180), outline=(95, 95, 110, 255))
    return img
draw_heart_empty().save(os.path.join(ui_dir, "heart_empty.png"))

print("All Act 1 assets successfully generated.")

"""Turns the high-res AI-generated zone paintings into in-game pixel-art parallax strips.

Each source is reduced to the 360px-tall pixel grid of the game, palette-quantized for a crisp
limited-colour look, toned down slightly so gameplay sprites read on top of it, and mirrored
into a seamless 2x-wide strip that a Parallax2D can repeat forever.

Usage:  python process_zone_backgrounds.py <raw_dir>
Expects <raw_dir>/{terraces,mine,colosseum,summit}.jpg for Act I and {forest_edge,hollow,grove}.jpg for
Act II (the forge uses forge_background.png); writes assets/sprites/environment/bg_<zone>.png.
Zones whose source is missing are skipped, so each act can be regenerated on its own.
"""
import os
import sys
from PIL import Image, ImageEnhance, ImageOps

RAW = sys.argv[1] if len(sys.argv) > 1 else "raw"
OUT = "assets/sprites/environment"
H = 360
COLORS = 128

ZONES = {
    # zone: (brightness, saturation)
    "terraces": (0.78, 0.85),
    "forge": (0.8, 0.85),
    "mine": (0.85, 0.9),
    "colosseum": (0.82, 0.85),
    "summit": (0.85, 0.9),
    # Act II: The Misty Forest
    "forest_edge": (0.8, 0.85),
    "hollow": (0.85, 0.9),
    "grove": (0.82, 0.88),
}

for zone, (bright, sat) in ZONES.items():
    # The forge cavern reuses the original hand-made backdrop already in the project
    src = os.path.join(OUT, "forge_background.png") if zone == "forge" else os.path.join(RAW, zone + ".jpg")
    if not os.path.exists(src):
        print("skip", zone)
        continue
    im = Image.open(src).convert("RGB")
    w = round(im.width * H / im.height)
    im = im.resize((w, H), Image.LANCZOS)
    # crop to an even 640 grid so the mirrored seam lands exactly on a pixel column
    left = (w - 640) // 2
    im = im.crop((left, 0, left + 640, H))
    im = ImageEnhance.Color(im).enhance(sat)
    im = ImageEnhance.Brightness(im).enhance(bright)
    im = im.quantize(colors=COLORS, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).convert("RGB")
    strip = Image.new("RGB", (1280, H))
    strip.paste(im, (0, 0))
    strip.paste(ImageOps.mirror(im), (640, 0))
    path = os.path.join(OUT, "bg_%s.png" % zone)
    strip.save(path)
    print("wrote", path)

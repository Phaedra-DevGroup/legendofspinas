"""Generates the pixel-art UI kit (9-slice frames, slider, bars, HUD icons)
and the project-wide Godot theme `assets/ui/theme/espinas_theme.tres`.

Palette: Persian turquoise + forged bronze on night-indigo stone.
Run from the project root:  python generate_ui_theme.py
"""
import os
from PIL import Image

OUT = "assets/ui/theme"
os.makedirs(OUT, exist_ok=True)

OUTLINE = (12, 8, 20, 255)
BRONZE_HI = (246, 210, 120, 255)
BRONZE = (196, 144, 66, 255)
BRONZE_LO = (122, 80, 40, 255)
BRONZE_DK = (74, 46, 26, 255)
TURQ_HI = (150, 255, 236, 255)
TURQ = (64, 214, 200, 255)
TURQ_LO = (30, 128, 132, 255)
INDIGO_HI = (58, 50, 88, 255)
INDIGO = (38, 32, 62, 255)
INDIGO_LO = (26, 21, 44, 255)
INDIGO_DK = (18, 14, 32, 255)
TEAL_HI = (52, 96, 104, 255)
TEAL = (34, 66, 76, 255)
TEAL_LO = (22, 44, 54, 255)
GREY_HI = (110, 108, 120, 255)
GREY = (72, 70, 82, 255)
GREY_LO = (46, 44, 54, 255)
CLEAR = (0, 0, 0, 0)


def new(w, h, c=CLEAR):
    return Image.new("RGBA", (w, h), c)


def rect(im, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            im.putpixel((x, y), c)


def frame(w, h, fill_top, fill_mid, fill_bot, border_hi, border_lo, inner_hi=None, rivets=None, chamfer=True, band=2):
    """Outline + 2px bevelled metal border + vertical 3-band fill, with clipped corners."""
    im = new(w, h)
    rect(im, 0, 0, w - 1, h - 1, OUTLINE)
    # bevel border
    rect(im, 1, 1, w - 2, h - 2, border_lo)
    rect(im, 1, 1, w - 3, h - 3, border_hi)
    rect(im, 2, 2, w - 3, h - 3, border_lo if inner_hi is None else inner_hi)
    # fill bands
    rect(im, 3, 3, w - 4, h - 4, fill_mid)
    # Shading bands stay inside the 9-slice margins so stretching never smears them
    rect(im, 3, 3, w - 4, 3 + band - 1, fill_top)
    rect(im, 3, h - 4 - band + 1, w - 4, h - 4, fill_bot)
    # inner shadow line under the top border
    for x in range(3, w - 3):
        im.putpixel((x, 3), fill_top)
    if chamfer:
        for (cx, cy) in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
            im.putpixel((cx, cy), CLEAR)
        for (cx, cy) in ((1, 0), (0, 1), (w - 2, 0), (w - 1, 1), (0, h - 2), (1, h - 1), (w - 1, h - 2), (w - 2, h - 1)):
            im.putpixel((cx, cy), OUTLINE)
        for (cx, cy) in ((1, 1), (w - 2, 1), (1, h - 2), (w - 2, h - 2)):
            im.putpixel((cx, cy), OUTLINE)
    if rivets:
        for (cx, cy) in ((4, 4), (w - 5, 4), (4, h - 5), (w - 5, h - 5)):
            im.putpixel((cx, cy), rivets)
    return im


def save(im, name):
    im.save(os.path.join(OUT, name))


# --- Panels -------------------------------------------------------------
panel = frame(32, 32, INDIGO_HI, INDIGO, INDIGO_LO, BRONZE_HI, BRONZE_LO, inner_hi=BRONZE_DK, rivets=TURQ)
# turquoise filigree diamonds on the top/bottom edge centers live in the stretch area; keep corners only
save(panel, "panel.png")

panel_dark = frame(32, 32, INDIGO_LO, INDIGO_DK, INDIGO_DK, BRONZE, BRONZE_DK, inner_hi=OUTLINE, rivets=BRONZE_HI)
save(panel_dark, "panel_dark.png")

card = frame(24, 24, TEAL_HI, TEAL, TEAL_LO, TURQ, TURQ_LO, inner_hi=OUTLINE)
save(card, "card.png")

# --- Buttons ------------------------------------------------------------
save(frame(24, 18, TEAL_HI, TEAL, TEAL_LO, BRONZE_HI, BRONZE_LO, inner_hi=BRONZE_DK, band=3), "btn_normal.png")
save(frame(24, 18, (74, 132, 138, 255), TEAL_HI, TEAL, BRONZE_HI, BRONZE, inner_hi=BRONZE_LO, band=3), "btn_hover.png")
pressed = frame(24, 18, TEAL_LO, TEAL_LO, TEAL, BRONZE_LO, BRONZE_HI, inner_hi=OUTLINE, band=3)
save(pressed, "btn_pressed.png")
save(frame(24, 18, GREY, GREY_LO, GREY_LO, GREY_HI, GREY_LO, inner_hi=OUTLINE, band=3), "btn_disabled.png")

focus = new(24, 18)
for x in range(2, 22):
    focus.putpixel((x, 0), TURQ_HI)
    focus.putpixel((x, 17), TURQ_HI)
for y in range(2, 16):
    focus.putpixel((0, y), TURQ_HI)
    focus.putpixel((23, y), TURQ_HI)
for (cx, cy) in ((1, 1), (22, 1), (1, 16), (22, 16)):
    focus.putpixel((cx, cy), TURQ_HI)
save(focus, "btn_focus.png")

# --- Slider & bars --------------------------------------------------------
track = new(12, 6)
rect(track, 0, 0, 11, 5, OUTLINE)
rect(track, 1, 1, 10, 4, INDIGO_DK)
rect(track, 1, 1, 10, 1, (8, 6, 14, 255))
for (cx, cy) in ((0, 0), (11, 0), (0, 5), (11, 5)):
    track.putpixel((cx, cy), CLEAR)
save(track, "slider_track.png")

track_fill = new(12, 6)
rect(track_fill, 0, 0, 11, 5, OUTLINE)
rect(track_fill, 1, 1, 10, 4, TURQ_LO)
rect(track_fill, 1, 1, 10, 2, TURQ)
for (cx, cy) in ((0, 0), (11, 0), (0, 5), (11, 5)):
    track_fill.putpixel((cx, cy), CLEAR)
save(track_fill, "slider_fill.png")


def gem(size, hi, mid, lo):
    im = new(size, size)
    c = size // 2
    for y in range(size):
        for x in range(size):
            d = abs(x - c + 0.5) + abs(y - c + 0.5)
            if d <= c - 0.5:
                im.putpixel((x, y), OUTLINE)
            if d <= c - 1.5:
                im.putpixel((x, y), lo if (x + y) > size - 2 else (hi if (x + y) < size - 4 else mid))
    return im


save(gem(12, BRONZE_HI, BRONZE, BRONZE_LO), "grabber.png")
save(gem(12, TURQ_HI, TURQ, TURQ_LO), "grabber_hl.png")

bar_bg = new(12, 8)
rect(bar_bg, 0, 0, 11, 7, OUTLINE)
rect(bar_bg, 1, 1, 10, 6, (36, 14, 28, 255))
rect(bar_bg, 1, 1, 10, 1, (22, 8, 18, 255))
save(bar_bg, "bar_bg.png")

bar_fill = new(12, 8)
rect(bar_fill, 0, 0, 11, 7, CLEAR)
rect(bar_fill, 1, 1, 10, 6, (196, 40, 74, 255))
rect(bar_fill, 1, 1, 10, 2, (255, 104, 128, 255))
rect(bar_fill, 1, 6, 10, 6, (122, 20, 52, 255))
save(bar_fill, "bar_fill.png")

# --- HUD icons ------------------------------------------------------------
# HUD plate behind hearts/counters
save(frame(20, 16, INDIGO_LO, INDIGO_DK, INDIGO_DK, BRONZE_LO, BRONZE_DK, inner_hi=OUTLINE), "hud_plate.png")

scrap = new(12, 12)
pts = {
    (5, 1): BRONZE_HI, (6, 1): BRONZE_HI,
}
# small cog
cog = [
    "....oo....",
    "..o.hh.o..",
    ".ohhhhhho.",
    "..hmmmmh..",
    "ohmmddmmho",
    "ohmmddmmlo",
    "..hmmmml..",
    ".ollllllo.",
    "..o.ll.o..",
    "....oo....",
]
cmap = {"o": OUTLINE, "h": BRONZE_HI, "m": BRONZE, "l": BRONZE_LO, "d": BRONZE_DK, ".": CLEAR}
icon = new(10, 10)
for y, row in enumerate(cog):
    for x, ch in enumerate(row):
        icon.putpixel((x, y), cmap[ch])
save(icon, "icon_scrap.png")

key = [
    "...oo...",
    "..ohho..",
    ".ohttho.",
    "ohttTtho",
    "ohtTttlo",
    ".olttlo.",
    "..ollo..",
    "...oo...",
]
kmap = {"o": OUTLINE, "h": TURQ_HI, "t": TURQ, "T": (230, 255, 250, 255), "l": TURQ_LO, ".": CLEAR}
icon = new(8, 8)
for y, row in enumerate(key):
    for x, ch in enumerate(row):
        icon.putpixel((x, y), kmap[ch])
save(icon, "icon_keystone.png")
dim = icon.copy()
for y in range(8):
    for x in range(8):
        r, g, b, a = dim.getpixel((x, y))
        if a and (r, g, b) != OUTLINE[:3]:
            v = (r + g + b) // 9 + 20
            dim.putpixel((x, y), (v, v, v + 10, 255))
save(dim, "icon_keystone_empty.png")

print("UI kit written to", OUT)

# --- Theme resource ---------------------------------------------------------
TEX = [
    "panel", "panel_dark", "card", "btn_normal", "btn_hover", "btn_pressed", "btn_disabled", "btn_focus",
    "slider_track", "slider_fill", "grabber", "grabber_hl", "bar_bg", "bar_fill",
]
lines = ['[gd_resource type="Theme" load_steps=%d format=3]' % (len(TEX) + 2 + 12), ""]
for i, t in enumerate(TEX):
    lines.append('[ext_resource type="Texture2D" path="res://assets/ui/theme/%s.png" id="%d_%s"]' % (t, i + 1, t))
lines.append('[ext_resource type="FontFile" path="res://assets/fonts/Vazirmatn.ttf" id="font_reg"]')
lines.append("")


def sbt(sid, tex, margin, content, tile=False, extra=None):
    l, t, r, b = content
    out = [
        '[sub_resource type="StyleBoxTexture" id="%s"]' % sid,
        "content_margin_left = %.1f" % l,
        "content_margin_top = %.1f" % t,
        "content_margin_right = %.1f" % r,
        "content_margin_bottom = %.1f" % b,
        'texture = ExtResource("%d_%s")' % (TEX.index(tex) + 1, tex),
        "texture_margin_left = %.1f" % margin,
        "texture_margin_top = %.1f" % margin,
        "texture_margin_right = %.1f" % margin,
        "texture_margin_bottom = %.1f" % margin,
    ]
    if extra:
        out += extra
    out.append("")
    return out


lines += sbt("panel", "panel", 7, (12, 10, 12, 10))
lines += sbt("panel_dark", "panel_dark", 7, (8, 6, 8, 6))
lines += sbt("card", "card", 6, (8, 6, 8, 6))
lines += sbt("btn_normal", "btn_normal", 7, (10, 4, 10, 5))
lines += sbt("btn_hover", "btn_hover", 7, (10, 4, 10, 5))
lines += sbt("btn_pressed", "btn_pressed", 7, (10, 5, 10, 4))
lines += sbt("btn_disabled", "btn_disabled", 7, (10, 4, 10, 5))
lines += sbt("btn_focus", "btn_focus", 3, (10, 4, 10, 5))
lines += sbt("slider", "slider_track", 3, (0, 3, 0, 3))
lines += sbt("slider_fill", "slider_fill", 3, (0, 3, 0, 3))
lines += sbt("bar_bg", "bar_bg", 3, (0, 0, 0, 0))
lines += sbt("bar_fill", "bar_fill", 3, (0, 0, 0, 0))

lines += [
    "[resource]",
    'default_font = ExtResource("font_reg")',
    "default_font_size = 11",
    'Button/colors/font_color = Color(0.94, 0.92, 0.84, 1)',
    'Button/colors/font_hover_color = Color(1, 0.96, 0.78, 1)',
    'Button/colors/font_pressed_color = Color(0.6, 1, 0.94, 1)',
    'Button/colors/font_focus_color = Color(1, 0.96, 0.78, 1)',
    'Button/colors/font_disabled_color = Color(0.6, 0.6, 0.64, 1)',
    'Button/colors/font_outline_color = Color(0.05, 0.03, 0.08, 1)',
    "Button/constants/outline_size = 2",
    'Button/styles/normal = SubResource("btn_normal")',
    'Button/styles/hover = SubResource("btn_hover")',
    'Button/styles/pressed = SubResource("btn_pressed")',
    'Button/styles/disabled = SubResource("btn_disabled")',
    'Button/styles/focus = SubResource("btn_focus")',
    'Label/colors/font_shadow_color = Color(0.03, 0.02, 0.06, 0.85)',
    "Label/constants/shadow_offset_x = 1",
    "Label/constants/shadow_offset_y = 1",
    'PanelContainer/styles/panel = SubResource("panel")',
    'Panel/styles/panel = SubResource("panel")',
    'HSlider/icons/grabber = ExtResource("%d_grabber")' % (TEX.index("grabber") + 1),
    'HSlider/icons/grabber_highlight = ExtResource("%d_grabber_hl")' % (TEX.index("grabber_hl") + 1),
    'HSlider/styles/slider = SubResource("slider")',
    'HSlider/styles/grabber_area = SubResource("slider_fill")',
    'HSlider/styles/grabber_area_highlight = SubResource("slider_fill")',
    'ProgressBar/styles/background = SubResource("bar_bg")',
    'ProgressBar/styles/fill = SubResource("bar_fill")',
    'RichTextLabel/colors/default_color = Color(0.9, 0.9, 0.94, 1)',
    'CardPanel/base_type = &"PanelContainer"',
    'CardPanel/styles/panel = SubResource("card")',
    'DarkPanel/base_type = &"PanelContainer"',
    'DarkPanel/styles/panel = SubResource("panel_dark")',
    "",
]
with open(os.path.join(OUT, "espinas_theme.tres"), "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(lines))
print("theme written")

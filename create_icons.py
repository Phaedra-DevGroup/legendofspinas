import os
from PIL import Image, ImageDraw
import numpy as np

def make_espinas_icon(size):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    
    # Outer circle / rounded square background
    # Dark mountain twilight gradient
    center = size / 2.0
    radius = size * 0.46
    
    for y in range(size):
        for x in range(size):
            dx = x - center
            dy = y - center
            d = np.sqrt(dx*dx + dy*dy)
            if d <= radius:
                # Vertical gradient: dark indigo top to deep teal-night bottom
                t = y / float(size)
                r = int(14 * (1.0 - t) + 8 * t)
                g = int(20 * (1.0 - t) + 26 * t)
                b = int(38 * (1.0 - t) + 36 * t)
                im.putpixel((x, y), (r, g, b, 255))
            elif d <= radius + 1.5:
                # Anti-aliasing edge
                alpha = int(255 * (radius + 1.5 - d) / 1.5)
                im.putpixel((x, y), (14, 20, 38, max(0, min(255, alpha))))

    # Gold ornamental ring
    ring_r = radius * 0.92
    ring_thick = max(2, int(size * 0.025))
    for a_deg in range(360):
        rad = np.radians(a_deg)
        for tr in range(int(ring_r - ring_thick), int(ring_r + 1)):
            px = int(center + tr * np.cos(rad))
            py = int(center + tr * np.sin(rad))
            if 0 <= px < size and 0 <= py < size:
                # Golden color with highlight on top
                brightness = 0.8 + 0.3 * np.sin(rad)
                im.putpixel((px, py), (int(215 * brightness), int(175 * brightness), int(65 * brightness), 255))

    # Center Sacred Mountain Peak silhouette
    peak_points = [
        (center - size * 0.28, center + size * 0.25),
        (center - size * 0.1, center - size * 0.05),
        (center, center - size * 0.22), # Main peak of Espinas
        (center + size * 0.12, center - size * 0.08),
        (center + size * 0.28, center + size * 0.25)
    ]
    draw.polygon(peak_points, fill=(28, 24, 34, 255))

    # Glowing Turquoise Sacred Crystal / Flame atop Espinas
    crystal_h = size * 0.22
    crystal_w = size * 0.12
    cy = center - size * 0.05
    
    for y in range(int(cy - crystal_h), int(cy + crystal_h)):
        for x in range(int(center - crystal_w), int(center + crystal_w + 1)):
            ny = (y - cy) / crystal_h
            nx = (x - center) / crystal_w
            # Diamond equation: |nx| + |ny| <= 1.0
            val = abs(nx) + abs(ny)
            if val <= 1.0:
                core_glow = 1.0 - val
                r = int(0 * (1.0 - core_glow) + 180 * core_glow)
                g = int(200 * (1.0 - core_glow) + 255 * core_glow)
                b = int(185 * (1.0 - core_glow) + 245 * core_glow)
                im.putpixel((x, y), (r, g, b, 255))

    return im

icon_192 = make_espinas_icon(192)
icon_192.save("assets/icon.png")
icon_192.save("icon.png")
print("Saved 192x192 icon.png")

icon_432 = make_espinas_icon(432)
icon_432.save("assets/icon_adaptive.png")
print("Saved 432x432 icon_adaptive.png")

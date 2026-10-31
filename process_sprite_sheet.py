"""Cuts an AI-generated pixel-art sprite sheet (frames in a row on a flat magenta background)
into clean game frames.

- keys out the magenta backdrop (and the pink fringe it leaves on edges)
- splits frames on empty columns and keeps the N largest
- scales every frame by the same factor to the target height, with hard 1-bit alpha
- reduces the palette and bottom-aligns all frames on a shared canvas (so the feet never jump)

Usage: python process_sprite_sheet.py <sheet.png|jpg> <out_prefix> <target_height> <frame_names comma-separated> [--grid] [--flip]
e.g.   python process_sprite_sheet.py raw/lurker.png assets/sprites/bosses/lurker/lurker_ 92 idle,strike,burrow
--grid  frames are laid out in rows (found as separate blobs, read top-to-bottom, left-to-right)
--flip  mirror every frame horizontally (when the sheet faces the other way)
Use "_" as a frame name to skip that frame.
"""
import sys
from collections import deque

import numpy as np
from PIL import Image, ImageOps

args = [a for a in sys.argv[1:] if not a.startswith("--")]
flags = {a for a in sys.argv[1:] if a.startswith("--")}
src, prefix, target_h, names = args[0], args[1], int(args[2]), args[3].split(",")
COLORS = 40

im = Image.open(src).convert("RGBA")
px = im.load()
w, h = im.size


def magenta_ness(r, g, b):
    return min(r, b) - g


for y in range(h):
    for x in range(w):
        r, g, b, a = px[x, y]
        m = magenta_ness(r, g, b)
        if m > 70 and r > 120 and b > 120:
            px[x, y] = (0, 0, 0, 0)

def find_blob_boxes(count):
    """Bounding boxes of the `count` largest sprite blobs, in reading order (rows, then x)."""
    cell = 6
    alpha = np.array(im.getchannel("A")) > 0
    gh, gw = h // cell, w // cell
    grid = alpha[:gh * cell, :gw * cell].reshape(gh, cell, gw, cell).any(axis=(1, 3))
    # close small gaps (thin branches, detached leaves) so a pose stays one blob
    grown = grid.copy()
    for dy in (-2, -1, 0, 1, 2):
        for dx in (-2, -1, 0, 1, 2):
            grown |= np.roll(np.roll(grid, dy, 0), dx, 1)
    seen = np.zeros_like(grown)
    blobs = []
    for y0 in range(gh):
        for x0 in range(gw):
            if not grown[y0, x0] or seen[y0, x0]:
                continue
            q = deque([(y0, x0)])
            seen[y0, x0] = True
            cells = []
            while q:
                cy, cx = q.popleft()
                cells.append((cy, cx))
                for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                    if 0 <= ny < gh and 0 <= nx < gw and grown[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        q.append((ny, nx))
            ys = [c[0] for c in cells]
            xs = [c[1] for c in cells]
            blobs.append((len(cells), min(xs) * cell, min(ys) * cell, (max(xs) + 1) * cell, (max(ys) + 1) * cell))
    blobs = sorted(blobs, reverse=True)[:count]
    if len(blobs) < count:
        sys.exit("found only %d frames" % len(blobs))
    row_h = max(b[4] - b[2] for b in blobs) * 0.5
    return [b[1:] for b in sorted(blobs, key=lambda b: (round(b[2] / row_h), b[1]))]


def find_column_boxes(count):
    """Frames in one row, split on empty columns."""
    cols = [sum(1 for y in range(0, h, 2) if px[x, y][3] > 0) for x in range(w)]
    segments = []
    start = None
    for x, c in enumerate(cols + [0]):
        if c > 2 and start is None:
            start = x
        elif c <= 2 and start is not None:
            if x - start > w * 0.04:
                segments.append((start, x))
            start = None
    segments = sorted(sorted(segments, key=lambda s: s[1] - s[0], reverse=True)[:count])
    if len(segments) < count:
        sys.exit("found only %d frames" % len(segments))
    return [(x0, 0, x1, h) for (x0, x1) in segments]


boxes = find_blob_boxes(len(names)) if "--grid" in flags else find_column_boxes(len(names))
crops = []
for box in boxes:
    frame = im.crop(box)
    frame = frame.crop(frame.getbbox())
    if "--flip" in flags:
        frame = ImageOps.mirror(frame)
    crops.append(frame)

scale = target_h / max(c.height for c in crops)
out = []
for c in crops:
    nw, nh = max(1, round(c.width * scale)), max(1, round(c.height * scale))
    small = c.resize((nw, nh), Image.LANCZOS)
    p = small.load()
    for y in range(nh):
        for x in range(nw):
            r, g, b, a = p[x, y]
            if a < 140 or (magenta_ness(r, g, b) > 40 and r > 110 and b > 110):
                p[x, y] = (0, 0, 0, 0)
            else:
                p[x, y] = (r, g, b, 255)
    out.append(small)

# Shared palette across frames so colours stay identical between poses
strip = Image.new("RGBA", (sum(o.width for o in out), max(o.height for o in out)), (0, 0, 0, 0))
x = 0
for o in out:
    strip.paste(o, (x, 0))
    x += o.width
rgb = strip.convert("RGB")
pal = rgb.quantize(colors=COLORS, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)

canvas_w = max(o.width for o in out) + 2
canvas_h = max(o.height for o in out) + 2
x = 0
for name, o in zip(names, out):
    q = rgb.crop((x, 0, x + o.width, o.height)).quantize(palette=pal, dither=Image.Dither.NONE).convert("RGBA")
    q.putalpha(o.getchannel("A"))
    x += o.width
    if name == "_":
        continue
    canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    canvas.paste(q, ((canvas_w - o.width) // 2, canvas_h - 1 - o.height), q)
    canvas.save(prefix + name + ".png")
    print("wrote", prefix + name + ".png", canvas.size)

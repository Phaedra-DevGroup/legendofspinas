"""Removes the light background halo left around cut-out sprites.

Pixels that are bright and nearly grey (leftover white/grey backdrop) are cleared when they touch
transparency; the pass repeats so 2-3px thick fringes peel away, while bright pixels *inside* the
silhouette (eyes, highlights) are untouched because they never border transparency.

Usage:  python fix_sprite_fringe.py <png> [<png> ...]   (files are rewritten in place)
"""
import sys
from PIL import Image

PASSES = 4


def is_fringe(r, g, b):
    hi, lo = max(r, g, b), min(r, g, b)
    return hi >= 150 and (hi - lo) <= 40


def clean(path):
    im = Image.open(path).convert("RGBA")
    px = im.load()
    w, h = im.size
    removed = 0
    for _ in range(PASSES):
        doomed = []
        for y in range(h):
            for x in range(w):
                r, g, b, a = px[x, y]
                if a == 0 or not is_fringe(r, g, b):
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if nx < 0 or ny < 0 or nx >= w or ny >= h or px[nx, ny][3] == 0:
                        doomed.append((x, y))
                        break
        if not doomed:
            break
        for p in doomed:
            px[p] = (0, 0, 0, 0)
        removed += len(doomed)
    im.save(path)
    return removed


if __name__ == "__main__":
    for p in sys.argv[1:]:
        print(p, "removed", clean(p))

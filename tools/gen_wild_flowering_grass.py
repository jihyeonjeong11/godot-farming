import random
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "craftland" / "Craftland Terrain" / "32x32" / "CL_Crops_Mining.png"
OUT = ROOT / "assets" / "ai_generated" / "wilds" / "flowering_grass.png"
REGION = (827, 608, 198, 97)

CLUMPS = [
    (5, 32, 32, 30),
    (37, 34, 32, 26),
    (73, 32, 24, 32),
    (107, 36, 22, 26),
    (9, 64, 24, 26),
    (39, 68, 29, 28),
    (68, 64, 33, 32),
    (105, 66, 26, 28),
    (133, 46, 64, 50),
]

OUTLINE = (61, 47, 44, 255)
STEM = (93, 78, 50, 255)
STEM_LIT = (122, 92, 40, 255)

FAMILIES = {
    "white": {"hi": (250, 246, 226, 255), "mid": (226, 216, 190, 255), "shade": (176, 160, 146, 255), "eye": (232, 176, 52, 255)},
    "yellow": {"hi": (255, 232, 120, 255), "mid": (236, 192, 62, 255), "shade": (184, 132, 40, 255), "eye": (150, 78, 34, 255)},
    "lilac": {"hi": (226, 196, 236, 255), "mid": (186, 146, 206, 255), "shade": (132, 96, 150, 255), "eye": (246, 226, 140, 255)},
}

MIX = [
    ("white", "white", "yellow"),
    ("yellow", "yellow", "white"),
    ("lilac", "lilac", "white"),
    ("white", "lilac"),
    ("yellow", "white"),
    ("lilac", "yellow", "lilac"),
    ("white", "yellow", "lilac"),
    ("yellow", "lilac"),
    ("white", "yellow", "lilac", "white", "yellow"),
]


def opaque(px, x, y, w, h):
    return 0 <= x < w and 0 <= y < h and px[x, y][3] == 255


def tips(px, rect, w, h):
    x0, y0, cw, ch = rect
    found = []
    for x in range(x0, x0 + cw):
        for y in range(y0, y0 + ch):
            if opaque(px, x, y, w, h):
                found.append((x, y))
                break
    return found


def pick(found, rng, bin_w=6):
    bins = {}
    for p in found:
        bins.setdefault((p[0] - found[0][0]) // bin_w, []).append(p)
    chosen = []
    for key in sorted(bins):
        cand = sorted(bins[key], key=lambda p: p[1] + rng.random() * 3)
        if rng.random() < 0.85:
            chosen.append(cand[0])
    return chosen


def inner(px, rect, w, h, rng, heads):
    x0, y0, cw, ch = rect
    spots = []
    for y in range(y0 + 6, y0 + ch - 8):
        for x in range(x0 + 2, x0 + cw - 2):
            if all(opaque(px, x + dx, y + dy, w, h) for dx in (-2, -1, 0, 1, 2) for dy in (-2, -1, 0, 1, 2)):
                spots.append((x, y))
    rng.shuffle(spots)
    chosen = []
    want = max(1, cw // 14)
    for p in spots:
        if all(abs(p[0] - q[0]) + abs(p[1] - q[1]) >= 7 for q in chosen + heads):
            chosen.append(p)
        if len(chosen) >= want:
            break
    return chosen


def draw_flower(px, cx, cy, fam, w, h):
    pal = FAMILIES[fam]
    petals = [(0, -1, "hi"), (-1, 0, "mid"), (1, 0, "mid"), (0, 1, "shade")]
    cells = {(cx, cy): pal["eye"]}
    for dx, dy, role in petals:
        cells[(cx + dx, cy + dy)] = pal[role]
    ring = set()
    for (x, y) in cells:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, y + dy)
            if n not in cells and not opaque(px, n[0], n[1], w, h):
                ring.add(n)
    for (x, y) in ring:
        if 0 <= x < w and 0 <= y < h:
            px[x, y] = OUTLINE
    for (x, y), c in cells.items():
        if 0 <= x < w and 0 <= y < h:
            px[x, y] = c


def main():
    x, y, w, h = REGION
    sheet = Image.open(SRC).convert("RGBA").crop((x, y, x + w, y + h))
    px = sheet.load()
    rng = random.Random(23)
    for i, rect in enumerate(CLUMPS):
        mix = MIX[i]
        heads = pick(tips(px, rect, w, h), rng)
        nested = inner(px, rect, w, h, rng, heads)
        for k, (tx, ty) in enumerate(heads):
            fam = mix[k % len(mix)]
            cy = max(ty - rng.choice((1, 2)) - 1, rect[1] + 2)
            for sy in range(cy + 2, ty):
                px[tx, sy] = STEM_LIT if sy == cy + 2 else STEM
            draw_flower(px, tx, cy, fam, w, h)
        for k, (fx, fy) in enumerate(nested):
            draw_flower(px, fx, fy, mix[(k + 1) % len(mix)], w, h)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print(OUT, sheet.size)


if __name__ == "__main__":
    main()

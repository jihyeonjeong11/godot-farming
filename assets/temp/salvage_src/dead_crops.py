import colorsys, os, sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "..", "craftland", "Craftland Terrain", "32x32", "CL_Crops_Mining.png")
OUT = os.path.join(HERE, "..", "salvagables.png")
G = 32

DEAD = [(61, 47, 44), (79, 54, 48), (103, 59, 49), (93, 78, 50),
        (122, 92, 40), (174, 89, 39), (181, 119, 140), (195, 137, 102)]

TALL = [(33, 2), (33, 4), (33, 6), (33, 8), (43, 0), (43, 2), (42, 8), (41, 10), (25, 0)]
SMALL = [(33, 11), (39, 7), (25, 13), (25, 15), (25, 3), (25, 7), (25, 9), (25, 11), (32, 13)]
COL0, ROW_SMALL, ROW_TALL = 6, 2, 3

KNOWN = {
    (40, 86, 19): (103, 59, 49), (82, 147, 18): (93, 78, 50), (148, 197, 31): (122, 92, 40),
    (70, 117, 24): (174, 89, 39), (44, 65, 19): (79, 54, 48), (37, 55, 15): (61, 47, 44),
    (31, 47, 12): (61, 47, 44), (21, 96, 56): (93, 78, 50), (69, 165, 0): (174, 89, 39),
    (15, 119, 3): (195, 137, 102), (138, 216, 56): (181, 119, 140), (226, 197, 0): (195, 137, 102),
    (255, 255, 20): (181, 119, 140),
}
PINK = (181, 119, 140)


def keep(c):
    r, g, b, a = c
    if a < 255:
        return True
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    return 10 / 360 <= h <= 50 / 360 and v <= 0.65


def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def kill(tile):
    px = tile.load()
    live = sorted({px[x, y] for y in range(tile.height) for x in range(tile.width)
                   if px[x, y][3] and not keep(px[x, y])}, key=lum)
    m = {c: KNOWN[c[:3]] + (255,) for c in live if c[:3] in KNOWN}
    rest = [c for c in live if c not in m]
    pal = sorted([d for d in DEAD if d != PINK], key=lum)
    for i, c in enumerate(rest):
        m[c] = pal[min(len(pal) - 1, i * len(pal) // len(rest))] + (255,)
    for y in range(tile.height):
        for x in range(tile.width):
            if px[x, y] in m:
                px[x, y] = m[px[x, y]]
    return tile


src = Image.open(SRC).convert("RGBA")
sheet = Image.open(OUT).convert("RGBA")
for i, (cx, cy) in enumerate(TALL):
    t = kill(src.crop((cx * G, cy * G, cx * G + G, cy * G + 2 * G)))
    x, y = (COL0 + i) * G, ROW_TALL * G
    sheet.paste(Image.new("RGBA", t.size), (x, y))
    sheet.alpha_composite(t, (x, y))
for i, (cx, cy) in enumerate(SMALL):
    t = kill(src.crop((cx * G, cy * G, cx * G + G, cy * G + G)))
    x, y = (COL0 + i) * G, ROW_SMALL * G
    sheet.paste(Image.new("RGBA", t.size), (x, y))
    sheet.alpha_composite(t, (x, y))
sheet.save(OUT)

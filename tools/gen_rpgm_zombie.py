import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "temp", "rpgm_character")
OUT = os.path.join(SRC, "rpgm_zombie_sheet.png")

CELL = 64
DIRS = ["left", "down", "up", "right"]

SKIN = {
    (210, 170, 123): (146, 160, 112),
    (127, 104, 67): (92, 104, 70),
    (128, 104, 67): (92, 104, 70),
}
ROT = (112, 126, 84)
EYE = (214, 36, 36)
SOCKET = (60, 58, 46)
EYES = {
    "down": [(30, 24), (34, 24)],
    "left": [(29, 23)],
    "right": [(34, 23)],
    "up": [],
}
CLOTH = {
    "shirt": (0, {(124, 40, 27): (96, 70, 58), (86, 28, 20): (66, 48, 40)}),
    "pants": (0, {(16, 49, 63): (58, 64, 66), (11, 36, 48): (40, 45, 47)}),
}
BLOOD = (110, 22, 18)


def cell_box(col, row):
    return (col * CELL, row * CELL, col * CELL + CELL, row * CELL + CELL)


def noise(x, y, seed):
    h = (x * 374761393 + y * 668265263 + seed * 2246822519) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    return (h ^ (h >> 16)) % 100


def head_top(cell, x):
    px = cell.load()
    return next(y for y in range(CELL) if px[x, y][3] > 0)


def skin(body):
    out = body.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            p = px[x, y]
            if p[3] == 0 or p[:3] not in SKIN:
                continue
            c = SKIN[p[:3]]
            if p[:3] == (210, 170, 123) and noise(x // 2, y // 2, 1) < 12:
                c = ROT
            px[x, y] = c + (255,)
    return out


def interior(px, x, y, w, h):
    return all(0 <= n[0] < w and 0 <= n[1] < h and px[n][3] > 0
        for n in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))


def cloth(part):
    variant, table = CLOTH[part]
    sheet = Image.open(os.path.join(SRC, "outfits", "%s.png" % part)).convert("RGBA")
    h = len(DIRS) * CELL
    src = sheet.crop((0, variant * h, sheet.width, variant * h + h))
    out = src.copy()
    spx, px = src.load(), out.load()
    seed = 2 if part == "shirt" else 3
    for y in range(out.height):
        for x in range(out.width):
            p = spx[x, y]
            if p[3] == 0:
                continue
            c = table.get(p[:3], p[:3])
            lx, ly = x % CELL, y % CELL
            n = noise(lx // 2, ly // 2, seed)
            if n < 14 and interior(spx, x, y, out.width, out.height):
                px[x, y] = (0, 0, 0, 0)
                continue
            if noise(lx, ly, seed + 10) < 8:
                c = BLOOD
            px[x, y] = c + (255,)
    return out


def eyes(sheet, body):
    px = sheet.load()
    cols = body.width // CELL
    for row, d in enumerate(DIRS):
        idle = body.crop(cell_box(0, row))
        x0, _, x1, _ = idle.getbbox()
        mid = (x0 + x1) // 2
        for col in range(cols):
            dy = head_top(body.crop(cell_box(col, row)), mid) - head_top(idle, mid)
            for ex, ey in EYES[d]:
                gx, gy = col * CELL + ex, row * CELL + ey + dy
                px[gx, gy] = EYE + (255,)
                px[gx, gy + 1] = SOCKET + (255,)


def build():
    body = Image.open(os.path.join(SRC, "rpgm_body_sheet.png")).convert("RGBA")
    sheet = skin(body)
    for part in ("pants", "shirt"):
        sheet.alpha_composite(cloth(part))
    eyes(sheet, body)
    sheet.save(OUT)


if __name__ == "__main__":
    build()

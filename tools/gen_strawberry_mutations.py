import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "craftland", "Craftland Terrain", "32x32", "CL_Crops_Mining.png")
OUT = os.path.join(ROOT, "assets", "temp", "crop_strawberry_mut")
ROW_Y = 480
CELLS = [28, 29, 30, 31, 32, 33, 34]
N = len(CELLS)

L_DARK = (37, 55, 15, 255)
L_MID = (40, 86, 19, 255)
L_TEAL = (21, 96, 56, 255)
L_GREEN = (15, 119, 3, 255)
L_LIT = (69, 165, 0, 255)
L_HI = (138, 216, 56, 255)
L_CALYX = (0, 98, 13, 255)

ROLE = {
    L_DARK: "l_dark", L_MID: "l_mid", L_TEAL: "l_teal", L_GREEN: "l_green",
    L_LIT: "l_lit", L_HI: "l_hi", L_CALYX: "l_calyx",
    (72, 27, 42, 255): "b_out",
    (118, 21, 25, 255): "b_dark", (97, 34, 37, 255): "b_dark", (114, 38, 21, 255): "b_dark",
    (157, 14, 19, 255): "b_mid", (159, 11, 17, 255): "b_mid", (159, 52, 28, 255): "b_mid",
    (199, 56, 13, 255): "b_lit",
    (243, 112, 72, 255): "b_hi", (214, 55, 55, 255): "b_hi",
}
BERRY_ROLES = {"b_out", "b_dark", "b_mid", "b_lit", "b_hi"}
LEAF_ROLES = {"l_dark", "l_mid", "l_teal", "l_green", "l_lit", "l_hi", "l_calyx"}

LEAF_BASE = {
    "l_dark": L_DARK, "l_mid": L_MID, "l_teal": L_TEAL, "l_green": L_GREEN,
    "l_lit": L_LIT, "l_hi": L_HI, "l_calyx": L_CALYX,
}
BERRY_BASE = {
    "b_out": (72, 27, 42, 255), "b_dark": (118, 21, 25, 255), "b_mid": (157, 14, 19, 255),
    "b_lit": (199, 56, 13, 255), "b_hi": (243, 112, 72, 255),
}

LEAF_DARKGREEN = {
    "l_dark": (22, 38, 10, 255), "l_mid": (30, 66, 14, 255), "l_teal": (16, 74, 44, 255),
    "l_green": (12, 92, 4, 255), "l_lit": (48, 124, 6, 255), "l_hi": (96, 176, 40, 255),
    "l_calyx": (10, 76, 12, 255),
}
LEAF_PALE = {
    "l_dark": (104, 112, 50, 255), "l_mid": (150, 162, 80, 255), "l_teal": (130, 150, 96, 255),
    "l_green": (140, 168, 84, 255), "l_lit": (206, 214, 120, 255), "l_hi": (248, 246, 190, 255),
    "l_calyx": (130, 150, 70, 255),
}
LEAF_SICK = {
    "l_dark": (28, 62, 30, 255), "l_mid": (36, 96, 48, 255), "l_teal": (24, 108, 78, 255),
    "l_green": (28, 134, 62, 255), "l_lit": (86, 186, 70, 255), "l_hi": (176, 240, 120, 255),
    "l_calyx": (20, 108, 40, 255),
}

BERRY_WHITE = {
    "b_out": (96, 80, 78, 255), "b_dark": (176, 160, 150, 255), "b_mid": (226, 218, 206, 255),
    "b_lit": (198, 54, 40, 255), "b_hi": (240, 124, 104, 255),
}
BERRY_YELLOW = {
    "b_out": (104, 72, 18, 255), "b_dark": (170, 126, 30, 255), "b_mid": (228, 190, 58, 255),
    "b_lit": (246, 220, 96, 255), "b_hi": (255, 246, 168, 255),
}
BERRY_GLOW = {
    "b_out": (8, 54, 50, 255), "b_dark": (20, 122, 110, 255), "b_mid": (60, 222, 190, 255),
    "b_lit": (140, 255, 222, 255), "b_hi": (224, 255, 248, 255),
}
BERRY_PURPLE = {
    "b_out": (40, 20, 56, 255), "b_dark": (76, 36, 100, 255), "b_mid": (120, 56, 152, 255),
    "b_lit": (172, 96, 200, 255), "b_hi": (218, 154, 240, 255),
}
BERRY_LEAFY = {
    "b_out": (44, 68, 18, 255), "b_dark": (74, 110, 26, 255), "b_mid": (126, 166, 46, 255),
    "b_lit": (178, 208, 82, 255), "b_hi": (224, 242, 142, 255),
}
BERRY_BRIGHT = {
    "b_out": (70, 22, 30, 255), "b_dark": (126, 24, 32, 255), "b_mid": (198, 28, 36, 255),
    "b_lit": (232, 84, 62, 255), "b_hi": (252, 150, 130, 255),
}


def load_cells():
    sheet = Image.open(SRC).convert("RGBA")
    cells = []
    for cx in CELLS:
        cell = sheet.crop((cx * 32, ROW_Y, cx * 32 + 32, ROW_Y + 32))
        cells.append(cell.resize((16, 16), Image.NEAREST))
    return cells


def recolor(img, ramp):
    out = img.copy()
    px = out.load()
    for y in range(16):
        for x in range(16):
            role = ROLE.get(px[x, y])
            if role is not None and role in ramp:
                px[x, y] = ramp[role]
    return out


def role_at(px, x, y):
    if not (0 <= x < 16 and 0 <= y < 16):
        return None
    return ROLE.get(px[x, y])


def blank():
    return Image.new("RGBA", (16, 16), (0, 0, 0, 0))


def scaled(img, w, h, ox, oy):
    out = blank()
    out.paste(img.resize((w, h), Image.NEAREST), (ox, oy))
    return out


def swell_berries(img, ramp):
    out = img.copy()
    px = out.load()
    src = img.load()
    for y in range(16):
        for x in range(16):
            if src[x, y][3] == 0:
                continue
            if role_at(src, x, y) in BERRY_ROLES:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if role_at(src, x + dx, y + dy) in ("b_mid", "b_hi"):
                    px[x, y] = ramp["b_dark"]
                    break
    return out


FUSE_MAP = [2, 3, 4, 5, 6, 7, 7, 8, 7, 8, 8, 9, 10, 11, 12, 13]


def fuse(img, ramp):
    out = blank()
    src = img.load()
    px = out.load()
    for y in range(16):
        for x in range(16):
            px[x, y] = src[FUSE_MAP[x], y]
    for y in range(16):
        for x in (7, 8):
            if role_at(px, x, y) in ("b_mid", "b_lit", "b_hi"):
                px[x, y] = ramp["b_dark"]
            elif role_at(px, x, y) in LEAF_ROLES and y > 4:
                px[x, y] = ramp["l_dark"]
    for y in range(16):
        xs = [x for x in range(16) if role_at(px, x, y) in BERRY_ROLES]
        if len(xs) >= 6:
            px[xs[0], y] = ramp["b_out"]
            px[xs[-1], y] = ramp["b_out"]
    return out


def giant_berry(img, ramp):
    out = blank()
    big = img.resize((19, 19), Image.NEAREST).crop((2, 2, 18, 18))
    out.alpha_composite(big)
    return out


def bush_with_giant(bush, icon, ramp):
    out = blank()
    px = bush.copy()
    p = px.load()
    for y in range(16):
        for x in range(16):
            if role_at(p, x, y) in BERRY_ROLES:
                p[x, y] = ramp["l_mid"] if (x + y) % 2 else ramp["l_lit"]
    out.alpha_composite(px)
    fruit = icon.crop((3, 3, 14, 16)).resize((10, 11), Image.NEAREST)
    layer = blank()
    layer.paste(fruit, (3, 4))
    out.alpha_composite(layer)
    return out


SPRIG_LEN = [0, 2, 3, 2, 4, 2, 3, 4, 3, 2, 4, 3, 2, 3, 2, 0]


def sprigs(img, ramp):
    out = img.copy()
    px = out.load()
    for x in range(16):
        length = SPRIG_LEN[x]
        if length == 0:
            continue
        top = None
        for y in range(16):
            if px[x, y][3] > 100:
                top = y
                break
        if top is None or top < 2:
            continue
        for i in range(1, length + 1):
            y = top - i
            if y < 0:
                break
            px[x, y] = ramp["l_hi"] if i == length else ramp["l_lit"]
    return out


def serrate(img):
    out = img.copy()
    px = out.load()
    for y in (7, 9, 11, 13):
        xs = [x for x in range(16) if role_at(px, x, y) in BERRY_ROLES]
        if len(xs) < 4:
            continue
        px[xs[0], y] = (0, 0, 0, 0)
        px[xs[-1], y] = (0, 0, 0, 0)
    return out


def halo(img, color):
    out = blank()
    src = img.load()
    glow = blank()
    g = glow.load()
    for y in range(16):
        for x in range(16):
            if role_at(src, x, y) not in ("b_mid", "b_lit", "b_hi"):
                continue
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < 16 and 0 <= ny < 16 and src[nx, ny][3] == 0:
                        g[nx, ny] = color
    out.alpha_composite(glow)
    out.alpha_composite(img)
    return out


SEAM = [8, 9, 7, 8, 10, 9, 7, 8, 9, 10, 8, 7, 9, 8, 9, 8]


def chimera_split(img, ramp_a, ramp_b):
    a = recolor(img, ramp_a)
    b = recolor(img, ramp_b)
    out = a.copy()
    pa = out.load()
    pb = b.load()
    for y in range(16):
        for x in range(SEAM[y], 16):
            pa[x, y] = pb[x, y]
    return out


def make_fasciation(cells):
    ramp = dict(LEAF_BASE, **BERRY_BASE)
    res = []
    for i, c in enumerate(cells):
        img = recolor(c, ramp)
        if i in (2, 3, 4):
            img = swell_berries(img, ramp)
        if i == 6:
            img = fuse(img, ramp)
        res.append(img)
    return res


def make_pineberry(cells):
    ramp = dict(LEAF_BASE, **BERRY_WHITE)
    return [recolor(c, ramp) for c in cells]


def make_yellow(cells):
    ramp = dict(LEAF_BASE, **BERRY_YELLOW)
    return [recolor(c, ramp) for c in cells]


def make_alpine(cells):
    ramp = dict(LEAF_DARKGREEN, **BERRY_BRIGHT)
    res = []
    for i, c in enumerate(cells):
        img = recolor(c, ramp)
        if i == 6:
            img = scaled(img, 13, 13, 2, 3)
        else:
            img = scaled(img, 12, 12, 2, 4)
        res.append(img)
    return res


def make_chimera(cells):
    ramp_a = dict(LEAF_BASE, **BERRY_BASE)
    ramp_b = dict(LEAF_PALE, **BERRY_WHITE)
    return [chimera_split(c, ramp_a, ramp_b) for c in cells]


def make_dwarf(cells):
    ramp = dict(LEAF_DARKGREEN, **BERRY_BASE)
    res = []
    for i, c in enumerate(cells):
        img = recolor(c, ramp)
        if i == 6:
            img = scaled(img, 16, 12, 0, 4)
        else:
            img = scaled(img, 16, 11, 0, 5)
        res.append(img)
    return res


def make_broom(cells):
    ramp = dict(LEAF_BASE)
    ramp.update({
        "b_out": L_DARK, "b_dark": L_DARK, "b_mid": L_MID,
        "b_lit": L_LIT, "b_hi": L_HI,
    })
    res = []
    for i, c in enumerate(cells):
        img = recolor(c, ramp)
        if i >= 2:
            img = sprigs(img, ramp)
        res.append(img)
    return res


def make_phyllody(cells):
    ramp = dict(LEAF_DARKGREEN, **BERRY_LEAFY)
    res = []
    for i, c in enumerate(cells):
        img = recolor(c, ramp)
        if i in (3, 4, 6):
            img = serrate(img)
        res.append(img)
    return res


def make_glowing(cells):
    ramp = dict(LEAF_DARKGREEN, **BERRY_GLOW)
    res = []
    for i, c in enumerate(cells):
        img = recolor(c, ramp)
        if i >= 2:
            img = halo(img, (90, 255, 220, 120))
        res.append(img)
    return res


def make_mutfruit(cells):
    ramp = dict(LEAF_DARKGREEN, **BERRY_PURPLE)
    icon = recolor(cells[6], ramp)
    res = []
    for i, c in enumerate(cells):
        img = recolor(c, ramp)
        if i in (3, 4):
            img = bush_with_giant(img, icon, ramp)
        if i == 6:
            img = giant_berry(img, ramp)
        res.append(img)
    return res


VARIANTS = [
    ("fasciation", make_fasciation),
    ("pineberry", make_pineberry),
    ("yellow_wonder", make_yellow),
    ("alpine", make_alpine),
    ("chimera", make_chimera),
    ("dwarf", make_dwarf),
    ("witches_broom", make_broom),
    ("phyllody", make_phyllody),
    ("glowing", make_glowing),
    ("mutfruit", make_mutfruit),
]


def sheet_from(cells16):
    out = Image.new("RGBA", (32 * N, 32), (0, 0, 0, 0))
    for i, c in enumerate(cells16):
        out.paste(c.resize((32, 32), Image.NEAREST), (i * 32, 0))
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    cells = load_cells()
    rows = [("_base", cells)]
    for name, fn in VARIANTS:
        rows.append((name, fn(cells)))

    for name, cs in rows:
        sheet_from(cs).save(os.path.join(OUT, name + ".png"))

    overview = Image.new("RGBA", (32 * N, 32 * len(rows)), (0, 0, 0, 0))
    for i, (_, cs) in enumerate(rows):
        overview.paste(sheet_from(cs), (0, i * 32))
    overview.save(os.path.join(OUT, "_overview.png"))
    print("wrote", len(rows), "sheets to", OUT)


if __name__ == "__main__":
    main()

import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "craftland", "Craftland Terrain", "32x32", "CL_Crops_Mining.png")
OUT = os.path.join(ROOT, "assets", "temp", "crop_corn_mut")

W, H = 16, 32
STAGES = [
    ("s0", (904, 44, 918, 60)),
    ("s1", (936, 38, 952, 60)),
    ("s2", (964, 24, 986, 60)),
    ("s3", (996, 10, 1018, 62)),
    ("ripe", (1024, 0, 1056, 60)),
    ("regrow", (1088, 4, 1120, 28)),
    ("item", (1096, 34, 1114, 64)),
]
N = len(STAGES)
ITEM = N - 1

ROLE = {
    (31, 47, 12, 255): "g_dark", (28, 60, 13, 255): "g_dark", (44, 65, 19, 255): "g_dark2",
    (40, 86, 19, 255): "g_mid", (70, 117, 24, 255): "g_mid2",
    (82, 147, 18, 255): "g_lit", (87, 167, 7, 255): "g_lit",
    (148, 197, 31, 255): "g_hi", (155, 217, 9, 255): "g_hi",
    (35, 30, 19, 255): "s_dark", (44, 21, 12, 255): "s_dark2",
    (110, 52, 27, 255): "s_mid", (158, 118, 70, 255): "s_lit",
    (110, 87, 22, 255): "k_dark", (132, 101, 13, 255): "k_dark",
    (189, 170, 43, 255): "k_mid", (226, 197, 0, 255): "k_lit", (255, 255, 20, 255): "k_hi",
}
KERNEL = ("k_dark", "k_mid", "k_lit", "k_hi")
GREEN = ("g_dark", "g_dark2", "g_mid", "g_mid2", "g_lit", "g_hi")

GREEN_BASE = {
    "g_dark": (31, 47, 12, 255), "g_dark2": (44, 65, 19, 255), "g_mid": (40, 86, 19, 255),
    "g_mid2": (70, 117, 24, 255), "g_lit": (82, 147, 18, 255), "g_hi": (148, 197, 31, 255),
}
STEM_BASE = {
    "s_dark": (35, 30, 19, 255), "s_dark2": (44, 21, 12, 255),
    "s_mid": (110, 52, 27, 255), "s_lit": (158, 118, 70, 255),
}
KERNEL_BASE = {
    "k_dark": (110, 87, 22, 255), "k_mid": (189, 170, 43, 255),
    "k_lit": (226, 197, 0, 255), "k_hi": (255, 255, 20, 255),
}

GREEN_DEEP = {
    "g_dark": (18, 34, 12, 255), "g_dark2": (26, 50, 16, 255), "g_mid": (26, 66, 18, 255),
    "g_mid2": (44, 92, 22, 255), "g_lit": (54, 116, 16, 255), "g_hi": (104, 160, 28, 255),
}
GREEN_SICK = {
    "g_dark": (26, 52, 26, 255), "g_dark2": (34, 70, 36, 255), "g_mid": (34, 88, 46, 255),
    "g_mid2": (44, 116, 66, 255), "g_lit": (62, 150, 78, 255), "g_hi": (126, 204, 108, 255),
}
GREEN_DRY = {
    "g_dark": (56, 48, 22, 255), "g_dark2": (78, 68, 30, 255), "g_mid": (104, 92, 38, 255),
    "g_mid2": (134, 118, 50, 255), "g_lit": (166, 148, 64, 255), "g_hi": (206, 190, 110, 255),
}
GREEN_PLUM = {
    "g_dark": (32, 38, 24, 255), "g_dark2": (48, 60, 28, 255), "g_mid": (52, 82, 32, 255),
    "g_mid2": (88, 96, 40, 255), "g_lit": (110, 134, 34, 255), "g_hi": (170, 186, 60, 255),
}

K_PURPLE = {"k_dark": (48, 18, 62, 255), "k_mid": (96, 40, 122, 255),
            "k_lit": (146, 66, 178, 255), "k_hi": (206, 138, 234, 255)}
K_RED = {"k_dark": (78, 18, 20, 255), "k_mid": (142, 32, 30, 255),
         "k_lit": (196, 54, 44, 255), "k_hi": (240, 118, 86, 255)}
K_SMUT = {"k_dark": (22, 20, 24, 255), "k_mid": (58, 54, 62, 255),
          "k_lit": (98, 92, 100, 255), "k_hi": (146, 140, 146, 255)}
K_GLOW = {"k_dark": (10, 60, 46, 255), "k_mid": (28, 140, 108, 255),
          "k_lit": (74, 228, 170, 255), "k_hi": (196, 255, 226, 255)}
K_BARE = {"k_dark": (140, 126, 96, 255), "k_mid": (190, 176, 142, 255),
          "k_lit": (224, 214, 186, 255), "k_hi": (248, 244, 226, 255)}

GEM_HUES = [
    (206, 52, 58), (232, 132, 38), (248, 214, 60), (118, 204, 68),
    (52, 176, 206), (86, 100, 212), (162, 84, 204), (228, 112, 176),
    (238, 238, 228), (74, 56, 86),
]


def shade(rgb, f):
    return (min(255, int(rgb[0] * f)), min(255, int(rgb[1] * f)), min(255, int(rgb[2] * f)), 255)


def blank():
    return Image.new("RGBA", (W, H), (0, 0, 0, 0))


def load_stages():
    sheet = Image.open(SRC).convert("RGBA")
    out = []
    for _, r in STAGES:
        c = sheet.crop(r)
        c = c.resize((c.width // 2, c.height // 2), Image.NEAREST)
        canvas = blank()
        canvas.paste(c, ((W - c.width) // 2, H - c.height))
        out.append(canvas)
    return out


def role_at(px, x, y):
    if not (0 <= x < W and 0 <= y < H):
        return None
    return ROLE.get(px[x, y])


def recolor(img, ramp):
    out = img.copy()
    px = out.load()
    for y in range(H):
        for x in range(W):
            r = ROLE.get(px[x, y])
            if r is not None and r in ramp:
                px[x, y] = ramp[r]
    return out


def peel(img, ramp):
    out = img.copy()
    px = out.load()
    pat = (("k_lit", "k_hi", "k_lit"), ("k_mid", "k_lit", "k_mid"))
    for y in range(H - 9, H - 2):
        for i, x in enumerate((6, 7, 8)):
            if px[x, y][3] == 0:
                continue
            px[x, y] = ramp[pat[y % 2][i]]
        for x in (5, 9):
            if px[x, y][3]:
                px[x, y] = ramp["k_dark"]
    return out


def gem_kernels(img):
    out = img.copy()
    px = out.load()
    tone = {"k_dark": 0.45, "k_mid": 0.72, "k_lit": 1.0, "k_hi": 1.28}
    for y in range(H):
        for x in range(W):
            r = ROLE.get(px[x, y])
            if r not in KERNEL:
                continue
            hue = GEM_HUES[((x // 2) * 5 + (y // 2) * 3) % len(GEM_HUES)]
            px[x, y] = shade(hue, tone[r])
    return out


def widen_kernels(img, ramp):
    out = img.copy()
    px = out.load()
    src = img.load()
    for y in range(H):
        for x in range(W):
            if role_at(src, x, y) in KERNEL:
                continue
            if src[x, y][3] == 0:
                continue
            for dx in (-1, 1):
                if role_at(src, x + dx, y) in ("k_lit", "k_hi", "k_mid"):
                    px[x, y] = ramp["k_dark"]
                    break
    return out


def stretch_h(img, cx, amount):
    out = blank()
    src = img.load()
    px = out.load()
    for x in range(W):
        if x < cx - amount:
            sx = x + amount
        elif x > cx + amount:
            sx = x - amount
        else:
            sx = cx
        for y in range(H):
            px[x, y] = src[sx, y]
    for y in range(H):
        for x in (cx - 3, cx, cx + 3):
            if role_at(px, x, y) in ("k_lit", "k_hi", "k_mid"):
                px[x, y] = ramp_get(px, x, y)
    return out


def ramp_get(px, x, y):
    c = px[x, y]
    return (max(0, c[0] - 70), max(0, c[1] - 70), max(0, c[2] - 60), 255)


def squash(img, factor):
    out = blank()
    h = max(4, int(H * factor))
    out.paste(img.resize((W, h), Image.NEAREST), (0, H - h))
    return out


def kernel_box(img):
    px = img.load()
    xs, ys = [], []
    for y in range(H):
        for x in range(W):
            if role_at(px, x, y) in KERNEL:
                xs.append(x)
                ys.append(y)
    if not xs:
        return None
    return (min(xs), min(ys), max(xs) + 1, max(ys) + 1)


EAR = (
    (None, "g_mid", None),
    ("g_dark", "k_lit", "g_dark2"),
    ("g_dark", "k_hi", "g_mid"),
    ("g_dark", "k_lit", "g_dark2"),
    ("g_dark", "k_hi", "g_mid"),
    (None, "g_dark", None),
)


def extra_ears(img, ramp):
    box = kernel_box(img)
    if box is None:
        return img
    out = img.copy()
    px = out.load()
    base = box[3] - 1
    for ox, oy in ((-4, 2), (3, 6), (-3, 10)):
        for ry, row in enumerate(EAR):
            for rx, role in enumerate(row):
                if role is None:
                    continue
                x = W // 2 + ox + rx
                y = base + oy + ry
                if 0 <= x < W and 0 <= y < H:
                    px[x, y] = ramp[role]
    return out


def sparse_kernels(img):
    out = img.copy()
    px = out.load()
    for y in range(H):
        for x in range(W):
            if role_at(px, x, y) in ("k_lit", "k_hi") and (x + y) % 2 == 0:
                px[x, y] = (0, 0, 0, 0)
    return out


def galls(img, ramp):
    out = img.copy()
    px = out.load()
    src = img.load()
    for y in range(H):
        for x in range(W):
            if role_at(src, x, y) in KERNEL:
                continue
            near = False
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    if role_at(src, x + dx, y + dy) in KERNEL:
                        near = True
            if not near:
                continue
            if (x * 7 + y * 3) % 5 < 3:
                px[x, y] = ramp["k_mid"] if (x + y) % 2 else ramp["k_dark"]
    return out


def branches(img, ramp):
    out = img.copy()
    px = out.load()
    src = img.load()
    seeds = [(x, y) for y in range(H) for x in range(W) if role_at(src, x, y) in ("k_lit", "k_hi")]
    if not seeds:
        return out
    cutoff = min(y for _, y in seeds) + 10
    for x, y in seeds:
        if y > cutoff:
            continue
        for d in (1, 2, 3):
            for sx in (x - d, x + d):
                sy = y + d // 2
                if not (0 <= sx < W and 0 <= sy < H):
                    continue
                if role_at(px, sx, sy) in KERNEL:
                    continue
                px[sx, sy] = ramp["k_hi"] if d == 3 else ramp["k_mid"]
    return out


def halo(img, color):
    out = blank()
    src = img.load()
    glow = blank()
    g = glow.load()
    for y in range(H):
        for x in range(W):
            if role_at(src, x, y) not in ("k_lit", "k_hi"):
                continue
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and src[nx, ny][3] == 0:
                        g[nx, ny] = color
    out.alpha_composite(glow)
    out.alpha_composite(img)
    return out


def build(stages, green, stem, kernel, post=None):
    ramp = dict(green)
    ramp.update(stem)
    ramp.update(kernel)
    res = []
    for i, s in enumerate(stages):
        img = recolor(s, ramp)
        if i == ITEM:
            img = peel(img, ramp)
        if post is not None:
            img = post(img, ramp, i)
        res.append(img)
    return res


def p_fasciation(img, ramp, i):
    if i == ITEM:
        return stretch_h(img, W // 2, 1)
    return widen_kernels(img, ramp)


def p_gem(img, ramp, i):
    return gem_kernels(img)


def p_smut(img, ramp, i):
    return galls(img, ramp)


def p_prolific(img, ramp, i):
    if i in (3, 4, 5):
        return extra_ears(img, ramp)
    return img


def p_barren(img, ramp, i):
    return sparse_kernels(img)


def p_ramosa(img, ramp, i):
    if i in (3, 4, 5):
        return branches(img, ramp)
    return img


def p_dwarf(img, ramp, i):
    return squash(img, 0.62 if i != ITEM else 0.8)


def p_glow(img, ramp, i):
    return halo(img, (90, 255, 220, 120))


VARIANTS = [
    ("fasciation", GREEN_BASE, STEM_BASE, KERNEL_BASE, p_fasciation),
    ("glass_gem", GREEN_BASE, STEM_BASE, KERNEL_BASE, p_gem),
    ("purple", GREEN_PLUM, STEM_BASE, K_PURPLE, None),
    ("pericarp_red", GREEN_BASE, STEM_BASE, K_RED, None),
    ("smut", GREEN_DEEP, STEM_BASE, K_SMUT, p_smut),
    ("prolific", GREEN_BASE, STEM_BASE, KERNEL_BASE, p_prolific),
    ("barren", GREEN_DRY, STEM_BASE, K_BARE, p_barren),
    ("ramosa", GREEN_BASE, STEM_BASE, KERNEL_BASE, p_ramosa),
    ("dwarf", GREEN_DEEP, STEM_BASE, KERNEL_BASE, p_dwarf),
    ("glowing", GREEN_SICK, STEM_BASE, K_GLOW, p_glow),
]


def sheet_from(cells):
    out = Image.new("RGBA", (W * 2 * N, H * 2), (0, 0, 0, 0))
    for i, c in enumerate(cells):
        out.paste(c.resize((W * 2, H * 2), Image.NEAREST), (i * W * 2, 0))
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    stages = load_stages()
    rows = [("_base", stages)]
    for name, green, stem, kernel, post in VARIANTS:
        rows.append((name, build(stages, green, stem, kernel, post)))

    for name, cs in rows:
        sheet_from(cs).save(os.path.join(OUT, name + ".png"))

    overview = Image.new("RGBA", (W * 2 * N, H * 2 * len(rows)), (0, 0, 0, 0))
    for i, (_, cs) in enumerate(rows):
        overview.paste(sheet_from(cs), (0, i * H * 2))
    overview.save(os.path.join(OUT, "_overview.png"))
    print("wrote", len(rows), "sheets to", OUT)


if __name__ == "__main__":
    main()

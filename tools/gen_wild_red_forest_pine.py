import random

from PIL import Image

from wilds_common import ROOT, WILDS, CLEAR

SRC = ROOT / "assets" / "craftland" / "Craftland Terrain" / "32x32" / "CL_Crops_Mining.png"
BOX = (400, 608, 800, 772)
CUT_Y = 767

GREENS = [(34, 49, 24, 255), (55, 89, 28, 255), (74, 120, 39, 255), (111, 152, 40, 255), (147, 198, 58, 255)]
RUST = [(58, 24, 16, 255), (110, 42, 20, 255), (156, 66, 26, 255), (196, 102, 38, 255), (232, 150, 64, 255)]
NEEDLE = dict(zip(GREENS, RUST))
DRY = {
    RUST[2]: (134, 70, 40, 255),
    RUST[3]: (176, 112, 62, 255),
    RUST[4]: (222, 176, 112, 255),
}

OUTLINES = {(30, 30, 33, 255), (32, 31, 31, 255)}
TRUNK = {(70, 43, 41, 255), (101, 76, 58, 255), (101, 75, 56, 255), (143, 108, 84, 255), (77, 66, 37, 255)}
PACKET = {(216, 207, 128, 255), (244, 236, 166, 255), (166, 160, 116, 255), (175, 149, 116, 255)}
SHADOW_A = 77

OUT = (30, 30, 33, 255)
BARK_L = (150, 132, 116, 255)
BARK_D = (98, 84, 74, 255)
TWIG = (124, 108, 96, 255)
TWIG_D = (78, 66, 60, 255)


def base():
    img = Image.open(SRC).convert("RGBA").crop(BOX)
    px = img.load()
    for y in range(img.height):
        if BOX[1] + y >= CUT_Y:
            for x in range(img.width):
                px[x, y] = CLEAR
    return img


def red(img):
    img = img.copy()
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            c = NEEDLE.get(px[x, y])
            if c is None:
                continue
            if c in DRY and (x * 7 + y * 13 + (x // 3) * (y // 4)) % 9 == 0:
                c = DRY[c]
            px[x, y] = c
    return img


def components(px, w, h):
    seen, comps = set(), []
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if (x, y) in seen or c[3] in (0, SHADOW_A):
                continue
            stack, comp = [(x, y)], []
            seen.add((x, y))
            while stack:
                cx, cy = stack.pop()
                comp.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and px[nx, ny][3] not in (0, SHADOW_A):
                        seen.add((nx, ny))
                        stack.append((nx, ny))
            comps.append(comp)
    return comps


def dead_tree(px, comp, rng):
    colors = {p: px[p] for p in comp}
    if any(c in PACKET for c in colors.values()):
        return
    if not any(c in NEEDLE for c in colors.values()):
        return
    trunk = [p for p, c in colors.items() if c in TRUNK]
    if not trunk:
        return
    trunk_top = min(p[1] for p in trunk)
    top_row = [p[0] for p in trunk if p[1] <= trunk_top + 1]
    cx = (min(top_row) + max(top_row)) / 2
    crown = [p for p, c in colors.items() if c in NEEDLE or (c in OUTLINES and p[1] < trunk_top)]
    tip = min(p[1] for p in crown)
    half = {}
    for x, y in crown:
        half[y] = max(half.get(y, 0), abs(x - cx))
    for p in crown:
        px[p] = CLEAR
    height = trunk_top - tip

    def put(x, y, c, over=False):
        if over or px[x, y][3] == 0:
            px[x, y] = c

    def needles(x, y):
        for _ in range(rng.randint(2, 4)):
            put(x + rng.randint(-1, 1), y + rng.randint(1, 2), rng.choice(RUST[1:4]))

    y = trunk_top - 3
    side = rng.choice((-1, 1))
    while y > tip + 2:
        t = (y - tip) / max(height, 1)
        w = 1 + round(3 * t)
        sides = (side, -side) if rng.random() < 0.35 else (side,)
        for s in sides:
            reach = half.get(y, 0) * rng.uniform(0.55, 0.95)
            n = int(reach - w / 2)
            if n < 2:
                continue
            x0 = int(cx + s * (w / 2 + 0.5) + 0.5)
            sag = rng.uniform(0.15, 0.4)
            for k in range(n):
                f = k / n
                bx = x0 + s * k
                by = int(y + f * f * n * sag + 0.5)
                put(bx, by, TWIG)
                put(bx, by + 1, TWIG_D)
                if k == int(n * 0.6) and n >= 6 and rng.random() < 0.6:
                    for j in range(1, rng.randint(2, 4)):
                        put(bx + s * j, by - j, TWIG)
                if rng.random() < 0.12:
                    needles(bx, by)
        side = -side
        y -= rng.randint(4, 6)
    for y in range(tip, trunk_top + 1):
        t = (y - tip) / max(height, 1)
        w = 1 + round(3 * t)
        x0 = round(cx - w / 2)
        row = {1: [BARK_D], 2: [BARK_L, BARK_D], 3: [BARK_L, BARK_D, OUT], 4: [OUT, BARK_L, BARK_D, OUT]}[w]
        for i, c in enumerate(row):
            put(x0 + i, y, c, over=True)


def dead(img):
    out = img.copy()
    px = out.load()
    rng = random.Random(4)
    for comp in components(px, out.width, out.height):
        dead_tree(px, comp, rng)
    return red(out)


def save(img, name):
    WILDS.mkdir(parents=True, exist_ok=True)
    out = WILDS / name
    img.save(out)
    print(out, img.size, "origin", BOX[:2])


def main():
    src = base()
    save(red(src), "red_forest_pine.png")
    save(dead(src), "red_forest_dead_pine.png")


if __name__ == "__main__":
    main()

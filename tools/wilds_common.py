import math
import random
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
WILDS = ROOT / "assets" / "ai_generated" / "wilds"

W, H = 32, 64
CLEAR = (0, 0, 0, 0)
SHADOW = (0, 0, 0, 77)

G_DARK = (31, 47, 12, 255)
G_DARK2 = (44, 65, 19, 255)
G_MID = (40, 86, 19, 255)
G_MID2 = (70, 117, 24, 255)
G_LIT = (82, 147, 18, 255)
G_HI = (148, 197, 31, 255)

S_DARK = (35, 30, 19, 255)
S_DARK2 = (44, 21, 12, 255)

P_EDGE = (112, 62, 6, 255)
P_DARK = (150, 92, 8, 255)
P_MID = (214, 150, 14, 255)
P_LIT = (240, 196, 24, 255)
P_HI = (255, 236, 96, 255)

P_WILT_D = (96, 54, 20, 255)
P_WILT = (150, 92, 34, 255)
P_WILT_L = (186, 130, 52, 255)

D_DARK = (44, 21, 12, 255)
D_MID = (72, 40, 18, 255)
D_LIT = (110, 70, 30, 255)
D_SEED = (150, 112, 54, 255)
D_RIDGE = (166, 189, 73, 255)
D_RIDGE_D = (113, 105, 20, 255)

SEED_D = (30, 28, 30, 255)
SEED = (64, 62, 66, 255)
SEED_STRIPE = (196, 192, 180, 255)

SOIL_D = (66, 53, 17, 255)
SOIL = (113, 105, 20, 255)

PETALS = (P_DARK, P_MID, P_LIT, P_HI)
BROWNS = (P_WILT_D, P_WILT, P_WILT_L, D_DARK, D_MID, D_LIT, D_SEED)
SEEDS = (SEED_D, SEED, SEED_STRIPE)


class Cell:
    def __init__(self):
        self.img = Image.new("RGBA", (W, H), CLEAR)
        self.px = self.img.load()

    def put(self, x, y, c):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < W and 0 <= y < H:
            self.px[x, y] = c

    def ellipse(self, cx, cy, rx, ry, c):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                    self.put(x, y, c)


BASE = H - 5


def shadow(cv, cx, rx, ry=2.2):
    for y in range(H - 8, H):
        for x in range(W):
            if ((x - cx) / rx) ** 2 + ((y - (H - 4)) / ry) ** 2 <= 1.0:
                cv.put(x, y, SHADOW)


def stem(cv, pts, width_fn):
    n = len(pts) - 1
    for i, (x, y) in enumerate(pts):
        w = width_fn(i / max(n, 1))
        left = int(math.floor(x - w / 2 + 0.5))
        right = max(int(math.floor(x + w / 2)), left)
        for xx in range(left, right + 1):
            if xx == left:
                c = G_LIT
            elif xx == right:
                c = G_DARK2
            else:
                c = G_MID2 if (xx - left) < (right - left) / 2 else G_MID
            cv.put(xx, y, c)
        if w >= 4 and i % 3 == 0:
            cv.put(left + 1, y, G_HI)
        if w >= 5 and i % 4 == 1:
            cv.put(left + 2 + (i % 2), y, G_DARK2)


def path(x0, y0, x1, y1, bend=0.0):
    steps = max(int(abs(y1 - y0)), 1)
    pts = []
    for i in range(steps + 1):
        t = i / steps
        pts.append((x0 + (x1 - x0) * t + math.sin(t * math.pi) * bend, round(y0 + (y1 - y0) * t)))
    return pts


def leaf(cv, bx, by, ang, length, width, droop=0.0):
    ux, uy = math.cos(ang), math.sin(ang)
    nx, ny = -uy, ux
    up = -1 if ny > 0 else 1
    steps = int(length * 4)
    for s in range(steps + 1):
        t = s / steps
        cx = bx + ux * t * length
        cy = by + uy * t * length + droop * t * t * length
        hw = width * (math.sin(math.pi * t) ** 0.7) * (1.15 - 0.55 * t)
        if t < 0.12:
            hw = min(hw, 0.6)
        n = max(int(hw * 3), 1)
        for k in range(-n, n + 1):
            o = k / 3
            side = o * up
            if abs(o) < 0.4:
                c = G_DARK2 if t > 0.15 else G_MID
            elif side > 0:
                c = G_HI if abs(o) > hw - 0.7 and t < 0.7 else G_LIT
            else:
                c = G_DARK2 if abs(o) > hw - 0.7 else G_MID
            cv.put(cx + nx * o, cy + ny * o, c)


def outline(cv):
    src = cv.img.copy().load()
    for y in range(H):
        for x in range(W):
            c = src[x, y]
            if c[3] != 255:
                continue
            for dx, dy in ((1, 0), (0, 1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < W and 0 <= ny < H) or src[nx, ny][3] == 255:
                    continue
                if c in PETALS:
                    dark = P_EDGE
                elif c in BROWNS:
                    dark = S_DARK2
                elif c in SEEDS:
                    dark = SEED_D
                elif c in (SOIL, SOIL_D):
                    dark = S_DARK
                else:
                    dark = G_DARK
                cv.put(nx, ny, dark)


def disk_mask(centers):
    m = set()
    for cx, cy, rx, ry in centers:
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                    m.add((x, y))
    return m


def dist_to(mask, x, y, limit):
    best = 99
    for dy in range(-limit, limit + 1):
        for dx in range(-limit, limit + 1):
            if (x + dx, y + dy) in mask:
                best = min(best, math.hypot(dx, dy))
    return best


def flower(cv, centers, petal_len, wilt=False, ridge=None, rng=None, petal_skip=0.0):
    rng = rng or random.Random(7)
    mask = disk_mask(centers)
    xs = [p[0] for p in mask]
    ys = [p[1] for p in mask]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    mx, my = (x0 + x1) / 2, (y0 + y1) / 2
    lim = int(petal_len) + 2
    for y in range(y0 - lim, y1 + lim + 1):
        for x in range(x0 - lim, x1 + lim + 1):
            if (x, y) in mask:
                continue
            d = dist_to(mask, x, y, lim)
            if d > petal_len:
                continue
            ang = math.atan2(y - my, x - mx)
            lobe = math.cos(ang * 14 + x * 0.5) * 1.3
            if d > petal_len - 1 + lobe:
                continue
            if petal_skip and rng.random() < petal_skip:
                continue
            py = y
            if wilt:
                c = P_WILT_L if y < my - 1 else (P_WILT if d < petal_len - 1 else P_WILT_D)
                if y > my:
                    py = y + 1
            elif y < my - 1:
                c = P_HI if d > petal_len - 1.5 else P_LIT
            elif y > my + 1:
                c = P_DARK if d > petal_len - 1.5 else P_MID
            else:
                c = P_LIT if d < petal_len - 1 else P_MID
            cv.put(x, py, c)
    for (x, y) in mask:
        edge = any((x + dx, y + dy) not in mask for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if edge:
            c = D_DARK
        elif (x, y + 2) not in mask:
            c = D_DARK if wilt else D_MID
        elif (x + 2 * y) % 5 == 0:
            c = D_SEED
        elif (x - y) % 4 == 0:
            c = D_LIT
        else:
            c = D_DARK if wilt else D_MID
        cv.put(x, y, c)
    if ridge:
        for i, (x, y) in enumerate(ridge):
            cv.put(x, y, D_RIDGE if i % 3 else D_RIDGE_D)


def crest(x0, x1, cy, amp, tilt, rx, ry, n=9):
    centers, ridge = [], []
    for i in range(n):
        t = i / (n - 1)
        cx = x0 + t * (x1 - x0)
        y = cy - math.sin(t * math.pi * 2.0) * amp + t * tilt
        centers.append((cx, y, rx, ry))
        ridge.append((round(cx), round(y)))
    return centers, ridge


def seed_shape(cv, cx, cy, ang):
    ux, uy = math.cos(ang), math.sin(ang)
    for si in range(-8, 9):
        s = si * 0.5
        hw = 2.0 * (1 - ((s + 0.8) / 4.6) ** 2)
        if hw <= 0:
            continue
        for k in range(-5, 6):
            o = k * 0.5
            if abs(o) > hw:
                continue
            if abs(o) > hw - 0.6:
                c = SEED_STRIPE if o < 0 else SEED
            elif abs(o) < 0.3:
                c = SEED_STRIPE
            else:
                c = SEED if o < 0 else SEED_D
            cv.put(cx + ux * s - uy * o, cy + uy * s + ux * o, c)


def soil(cv, cx, y):
    for x in range(cx - 4, cx + 5):
        cv.put(x, y, SOIL)
        if abs(x - cx) < 3:
            cv.put(x, y - 1, SOIL)
    cv.put(cx - 1, y - 1, SOIL_D)
    cv.put(cx + 2, y, SOIL_D)


def save_sheet(cells, name):
    w = sum(c.width for c in cells)
    h = max(c.height for c in cells)
    sheet = Image.new("RGBA", (w, h), CLEAR)
    x = 0
    for c in cells:
        sheet.paste(c, (x, h - c.height))
        x += c.width
    WILDS.mkdir(parents=True, exist_ok=True)
    out = WILDS / name
    sheet.save(out)
    print(out, sheet.size)
    return out

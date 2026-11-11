import math
import random

from PIL import Image

from wilds_common import *

SRC = ROOT / "assets" / "craftland" / "Craftland Terrain" / "32x32" / "CL_Crops_Mining.png"
X0, Y0 = 896, 64

CALYX = ((31, 47, 12, 255), (10, 152, 31, 255), (124, 191, 30, 255))

CALYX_D, CALYX_M, CALYX_L = CALYX

O_OUT = (86, 34, 8, 255)
O_DARK = (176, 76, 4, 255)
O_MID = (226, 116, 10, 255)
O_LIT = (248, 156, 28, 255)
O_HI = (255, 198, 70, 255)
O_SHINE = (255, 236, 176, 255)
O_RAMP = (O_DARK, O_MID, O_LIT, O_HI)

N_OUT = (52, 62, 10, 255)
N_DARK = (112, 138, 18, 255)
N_MID = (156, 180, 30, 255)
N_LIT = (196, 212, 56, 255)
N_HI = (230, 240, 128, 255)
N_SHINE = (248, 252, 208, 255)
N_RAMP = (N_DARK, N_MID, N_LIT, N_HI)

G_OUT = (31, 47, 12, 255)
G_RAMP = ((52, 96, 18, 255), (82, 140, 24, 255), (124, 186, 36, 255), (176, 222, 84, 255))
G_SHINE = (226, 246, 170, 255)


def knob_layout(cx, cy, rx, ry, n_ring, n_core, r_ring, r_core, seed):
    rng = random.Random(seed)
    knobs = [(cx, cy, rx * 0.5, ry * 0.5)]
    for i in range(n_ring):
        a = (i + rng.uniform(-0.35, 0.35)) / n_ring * math.tau
        r = r_ring * rng.uniform(0.65, 1.3)
        reach = rng.uniform(0.75, 1.1)
        aspect = rng.uniform(0.8, 1.4)
        kx = cx + math.cos(a) * (rx - r * 0.15) * reach
        ky = cy + math.sin(a) * (ry - r * 0.15) * reach
        if abs(math.cos(a)) > abs(math.sin(a)):
            knobs.append((kx, ky, r * aspect, r))
        else:
            knobs.append((kx, ky, r, r * aspect))
    for _ in range(n_core):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0.15, 0.55)
        r = r_core * rng.uniform(0.75, 1.2)
        knobs.append((cx + math.cos(a) * rx * d, cy + math.sin(a) * ry * d, r, r * rng.uniform(0.85, 1.2)))
    return knobs


def knob_cluster(cv, knobs, ramp, out, shine, nubs=(), nub_ramp=N_RAMP, nub_shine=N_SHINE):
    owner = {}
    allk = [(k, ramp, shine, 0) for k in knobs] + [(k, nub_ramp, nub_shine, 1) for k in nubs]
    for y in range(H):
        for x in range(W):
            best, best_v = None, 0.0
            for i, ((kx, ky, krx, kry), _, _, layer) in enumerate(allk):
                v = 1 - ((x + 0.5 - kx) / krx) ** 2 - ((y + 0.5 - ky) / kry) ** 2
                if v > 0:
                    v += layer * 0.35
                if v > best_v:
                    best, best_v = i, v
            if best is not None:
                owner[(x, y)] = best
    ys = [p[1] for p in owner]
    gy0, gy1 = min(ys), max(ys)
    for (x, y), i in owner.items():
        (kx, ky, krx, kry), rmp, _, layer = allk[i]
        nx, ny = (x + 0.5 - kx) / krx, (y + 0.5 - ky) / kry
        g = (y - gy0) / max(gy1 - gy0, 1)
        light = -0.7 * nx - 0.95 * ny + 0.35 - g * 0.6
        lv = 3 if light > 0.75 else 2 if light > 0.05 else 1 if light > -0.6 else 0
        if layer == 0 and any(owner.get((x + dx, y + dy), i) != i for dx, dy in ((1, 0), (0, 1))):
            lv = 0
        cv.put(x, y, rmp[max(0, min(3, lv))])
    for (kx, ky, krx, kry), _, shn, layer in allk:
        sx, sy = math.floor(kx - krx * 0.4), math.floor(ky - kry * 0.45)
        if owner.get((sx, sy)) is not None and allk[owner[(sx, sy)]][0] == (kx, ky, krx, kry) and krx >= 2.0:
            cv.put(sx, sy, shn)
    for (x, y), i in owner.items():
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if (x + dx, y + dy) not in owner:
                cv.put(x + dx, y + dy, out if allk[i][3] == 0 else N_OUT)


def sheet():
    return Image.open(SRC).convert("RGBA")


def crop(src, col, y0=0, y1=64, dy=0):
    cv = Cell()
    part = src.crop((X0 + col * 32, Y0 + y0, X0 + col * 32 + 32, Y0 + y1))
    cv.img.alpha_composite(part, (0, y0 + dy))
    cv.px = cv.img.load()
    return cv


def calyx(cv, x, y, big=False):
    d, m, l = CALYX
    pts = [(0, -2, d), (0, -1, m), (1, -1, l), (0, 0, l), (-1, 0, m), (1, 0, m),
           (-2, 0, m), (-3, 1, d), (2, 0, l), (3, 1, m), (4, 2, d), (-1, 1, d), (0, 1, m), (1, 1, d)]
    if big:
        pts += [(-4, 1, d), (-3, 0, m), (5, 2, d), (-1, -3, d), (2, 2, d), (-2, 2, d)]
    for ox, oy, c in pts:
        cv.put(x + ox, y + oy, c)


def stage_seeds(src):
    cv = Cell()
    part = src.crop((X0 + 32, Y0 + 2, X0 + 64, Y0 + 26))
    cv.img.alpha_composite(part, (0, 34))
    return cv.img


def stage_sprout(src):
    return crop(src, 0, 32, 64).img


def stage_small(src):
    return crop(src, 1, 32, 64).img


def stage_young(src):
    return crop(src, 2).img


def stage_flowering(src):
    return crop(src, 3).img


FRUIT_SPOTS = ((14, 10), (22, 19), (8, 22), (16, 32), (10, 42), (22, 44))
NUB_SPOTS = (1, 3, 5)
ITEM_KNOBS = knob_layout(15.5, 51, 8.5, 7.0, 8, 3, 3.0, 2.6, 9)


def tiny_calyx(cv, x, y):
    for ox, oy, c in ((0, -1, CALYX_D), (-1, 0, CALYX_M), (0, 0, CALYX_L), (1, 0, CALYX_M)):
        cv.put(x + ox, y + oy, c)


def mini_clusters(cv, ramp, out, shine, scale, with_nubs):
    for i, (x, y) in enumerate(FRUIT_SPOTS):
        knobs = knob_layout(x, y + 0.5, 3.4 * scale, 3.0 * scale, 5, 1, 1.7 * scale, 1.5 * scale, 20 + i)
        nubs = ((x + 0.5, y + 0.8, 1.1, 1.0),) if with_nubs and i in NUB_SPOTS else ()
        knob_cluster(cv, knobs, ramp, out, shine, nubs=nubs)
        tiny_calyx(cv, round(x), round(y - 2.6 * scale))


def stage_green(src):
    cv = crop(src, 5)
    mini_clusters(cv, G_RAMP, G_OUT, G_SHINE, 0.85, False)
    return cv.img


def stage_ripe(src):
    cv = crop(src, 5)
    mini_clusters(cv, O_RAMP, O_OUT, O_SHINE, 1.0, True)
    return cv.img


def stage_item(src):
    cv = Cell()
    shadow(cv, 16, 10, 2.2)
    knob_cluster(cv, ITEM_KNOBS, O_RAMP, O_OUT, O_SHINE,
                 nubs=((14, 50, 1.6, 1.6), (17.5, 51, 1.8, 1.6)))
    calyx(cv, 15, 44)
    return cv.img


STAGES = [
    ("seeds", stage_seeds),
    ("sprout", stage_sprout),
    ("small", stage_small),
    ("young", stage_young),
    ("flowering", stage_flowering),
    ("green", stage_green),
    ("ripe", stage_ripe),
    ("item", stage_item),
]


def main():
    src = sheet()
    save_sheet([fn(src) for _, fn in STAGES], "proliferation_tomato.png")


if __name__ == "__main__":
    main()

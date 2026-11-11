import math
import random

from PIL import Image

from wilds_common import *

SRC = ROOT / "assets" / "craftland" / "Craftland Terrain" / "32x32" / "CL_Crops_Mining.png"
STAKE_BOX = (1184, 0, 1216, 64)
STAKE_DY = 6

STAKE_GREEN = {
    (121, 78, 39, 255): G_MID2,
    (179, 146, 73, 255): G_LIT,
    (223, 186, 102, 255): G_HI,
    (51, 36, 36, 255): G_DARK,
    (157, 99, 48, 255): G_LIT,
    (100, 67, 38, 255): G_MID,
}

_stake = None


def green_stake():
    global _stake
    if _stake is None:
        src = Image.open(SRC).convert("RGBA").crop(STAKE_BOX)
        px = src.load()
        for y in range(src.height):
            for x in range(src.width):
                if px[x, y] in STAKE_GREEN:
                    px[x, y] = STAKE_GREEN[px[x, y]]
        _stake = Image.new("RGBA", (W, H), CLEAR)
        _stake.alpha_composite(src, (0, STAKE_DY))
    return _stake.copy()


def full_stake(top_y):
    top_y -= top_y % 2
    img = green_stake()
    px = img.load()
    for y in range(top_y):
        for x in range(W):
            px[x, y] = CLEAR
    for x in (16, 17):
        px[x, top_y] = G_DARK
        px[x, top_y + 1] = G_DARK
    return img


def full_shadow(rx, ry=2.2):
    cv = Cell()
    shadow(cv, 16.5, rx, ry)
    return cv


def full_leaves(specs):
    cv = Cell()
    for y, side, ln, wd in specs:
        x = 14 if side < 0 else 19
        leaf(cv, x, y, math.radians(195 if side < 0 else -15), ln, wd, droop=0.3)
    outline(cv)
    return cv


def full_compose(layers):
    img = Image.new("RGBA", (W, H), CLEAR)
    for layer in layers:
        img.alpha_composite(layer.img if isinstance(layer, Cell) else layer)
    return img


def stage_seeds():
    cv = Cell()
    shadow(cv, 16, 10, 2)
    seed_shape(cv, 9, BASE - 3, -1.2)
    seed_shape(cv, 22, BASE - 4, -0.4)
    seed_shape(cv, 16, BASE - 9, -1.6)
    outline(cv)
    return cv.img


def stage_planted():
    cv = Cell()
    shadow(cv, 16, 6, 1.6)
    soil(cv, 16, BASE)
    stem(cv, path(16, BASE - 1, 16, BASE - 3), lambda t: 1)
    for x, c in ((14, G_HI), (15, G_LIT), (17, G_MID2), (18, G_MID)):
        cv.put(x, BASE - 4, c)
    outline(cv)
    return cv.img


def stage_seedling():
    cv = Cell()
    shadow(cv, 16, 7, 1.8)
    stem(cv, path(16, BASE, 16, BASE - 7), lambda t: 2)
    leaf(cv, 15, BASE - 7, math.radians(195), 6, 2.2, droop=0.1)
    leaf(cv, 17, BASE - 7, math.radians(-15), 6, 2.2, droop=0.1)
    leaf(cv, 16, BASE - 8, math.radians(-90), 3, 1.2)
    outline(cv)
    return cv.img


def stage_young():
    top = BASE - 18
    return full_compose([
        full_shadow(8),
        full_leaves(((BASE - 5, -1, 8, 3.0), (BASE - 9, 1, 8, 3.0))),
        full_stake(top),
        full_leaves(((top + 4, -1, 5, 2.0), (top + 2, 1, 5, 2.0))),
    ])


def stage_bud():
    top = BASE - 32
    head = Cell()
    head.ellipse(16.5, top, 3.5, 2.5, G_MID2)
    head.ellipse(16.5, top - 1, 2.5, 1.5, G_LIT)
    for x in (14, 16, 17, 19):
        head.put(x, top - 2 - (x % 3 == 0), G_HI)
    head.put(16, top - 4, P_MID)
    head.put(17, top - 4, P_LIT)
    head.put(14, top - 3, P_LIT)
    head.put(19, top - 3, P_LIT)
    outline(head)
    return full_compose([
        full_shadow(9),
        full_leaves(((BASE - 5, -1, 9, 3.4), (BASE - 11, 1, 9, 3.4), (BASE - 18, -1, 8, 3.0), (BASE - 23, 1, 7, 2.6))),
        full_stake(top),
        full_leaves(((top + 5, -1, 5, 2.0),)),
        head,
    ])


LEAVES_TALL = ((BASE - 5, -1, 9, 3.4), (BASE - 11, 1, 9, 3.4), (BASE - 18, -1, 8, 3.0), (BASE - 23, 1, 8, 3.0), (BASE - 29, -1, 6, 2.2))


def stage_bloom():
    rng = random.Random(11)
    top = BASE - 36
    head = Cell()
    stem(head, path(14, BASE - 26, 7, BASE - 30, bend=-1), lambda t: 2)
    centers, ridge = crest(11, 22, top - 4, 1.6, -1.0, 2.2, 2.8, n=8)
    flower(head, centers, 3.0, ridge=ridge, rng=rng)
    flower(head, [(6, BASE - 31, 1.6, 1.5)], 2.0, rng=rng)
    outline(head)
    return full_compose([full_shadow(10), full_leaves(LEAVES_TALL), full_stake(top), head])


def stage_ripe():
    rng = random.Random(23)
    top = BASE - 34
    head = Cell()
    centers, ridge = crest(11, 22, top - 2, 1.4, 2.0, 2.0, 2.8, n=8)
    flower(head, centers, 2.4, wilt=True, ridge=ridge, rng=rng, petal_skip=0.35)
    outline(head)
    return full_compose([full_shadow(10), full_leaves(LEAVES_TALL), full_stake(top), head])


def stage_item():
    rng = random.Random(31)
    cv = Cell()
    shadow(cv, 16, 10, 2)
    stem(cv, path(16, BASE, 16, BASE - 6), lambda t: 2)
    centers, ridge = crest(9, 23, BASE - 13, 2.0, 0, 2.6, 3.4, n=8)
    flower(cv, centers, 3.0, ridge=ridge, rng=rng, petal_skip=0.15)
    outline(cv)
    return cv.img


STAGES = [
    ("seeds", stage_seeds),
    ("planted", stage_planted),
    ("seedling", stage_seedling),
    ("young", stage_young),
    ("bud", stage_bud),
    ("bloom", stage_bloom),
    ("ripe", stage_ripe),
    ("item", stage_item),
]


def main():
    save_sheet([fn() for _, fn in STAGES], "sunflower_mutant.png")


if __name__ == "__main__":
    main()

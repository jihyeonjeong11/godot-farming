from PIL import Image

from wilds_common import *
from gen_strawberry_mutations import ROLE, BERRY_ROLES

SRC = ROOT / "assets" / "craftland" / "Craftland Terrain" / "32x32" / "CL_Crops_Mining.png"
ROW_Y = 480

YEL = {"b_out": (110, 70, 20, 255), "b_dark": (200, 150, 40, 255), "b_mid": (232, 196, 70, 255),
       "b_lit": (246, 222, 110, 255), "b_hi": (255, 244, 170, 255)}
ORG = {"b_out": (110, 40, 20, 255), "b_dark": (200, 90, 30, 255), "b_mid": (236, 128, 50, 255),
       "b_lit": (248, 164, 80, 255), "b_hi": (255, 206, 140, 255)}
RED = {"b_out": (84, 22, 30, 255), "b_dark": (150, 24, 34, 255), "b_mid": (206, 40, 48, 255),
       "b_lit": (232, 90, 80, 255), "b_hi": (250, 150, 130, 255)}
PALE = {"b_out": (70, 90, 40, 255), "b_dark": (150, 170, 90, 255), "b_mid": (200, 214, 140, 255),
        "b_lit": (226, 236, 176, 255), "b_hi": (246, 250, 220, 255)}

SP_D = (24, 64, 30, 255)
SP_M = (46, 104, 40, 255)
SP_L = (92, 150, 60, 255)

BANDS = {
    "green": ((1.0, PALE),),
    "half": ((0.55, YEL), (1.0, ORG)),
    "ripe": ((0.35, YEL), (0.65, ORG), (1.0, RED)),
}


def cell(src, col, top=ROW_Y):
    cv = Cell()
    cv.img.alpha_composite(src.crop((col * 32, top, col * 32 + 32, top + 32)), (0, 32))
    cv.px = cv.img.load()
    return cv


def berry_role(cv, x, y):
    if not (0 <= x < W and 0 <= y < H):
        return None
    r = ROLE.get(cv.px[x, y])
    return r if r in BERRY_ROLES else None


def components(cv):
    seen, comps = set(), []
    for y in range(H):
        for x in range(W):
            if (x, y) in seen or berry_role(cv, x, y) is None:
                continue
            stack, comp = [(x, y)], []
            seen.add((x, y))
            while stack:
                px, py = stack.pop()
                comp.append((px, py))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    n = (px + dx, py + dy)
                    if n not in seen and berry_role(cv, *n) is not None:
                        seen.add(n)
                        stack.append(n)
            comps.append(comp)
    return comps


def band_ramp(bands, t):
    for limit, ramp in bands:
        if t <= limit:
            return ramp
    return bands[-1][1]


def recolor_berries(cv, bands):
    comps = components(cv)
    for comp in comps:
        ys = [p[1] for p in comp]
        y0, y1 = min(ys), max(ys)
        roles = {p: berry_role(cv, *p) for p in comp}
        for (x, y), role in roles.items():
            t = (y - y0) / max(y1 - y0, 1)
            cv.put(x, y, band_ramp(bands, t)[role])
    return comps


def sprout(cv, x, y, inside):
    cv.put(x, y, SP_D)
    if (x, y - 1) in inside:
        cv.put(x, y - 1, SP_L)
    if (x - 1, y - 1) in inside:
        cv.put(x - 1, y - 1, SP_M)


def bush_sprouts(cv, comps):
    for comp in comps:
        inside = set(comp)
        xs = [p[0] for p in comp]
        ys = [p[1] for p in comp]
        cx = (min(xs) + max(xs) + 1) // 2
        cy = (min(ys) + max(ys) + 1) // 2
        if (cx, cy) in inside:
            cv.put(cx, cy, SP_D)
            if (cx - 1, cy - 1) in inside:
                cv.put(cx - 1, cy - 1, SP_M)
        top = min(ys)
        tops = [p[0] for p in comp if p[1] == top]
        if len(comp) >= 6 and tops:
            x = max(tops)
            if cv.px[x + 1, top][3] == 0 if x + 1 < W else False:
                cv.put(x + 1, top, SP_M)


def item_sprouts(cv, comp):
    inside = set(comp)
    body = {p for p in comp if berry_role(cv, *p) != "b_out"}
    ys = [p[1] for p in comp]
    y0, y1 = min(ys), max(ys)
    row = 0
    for y in range(y0 + 3, y1 - 1, 3):
        offset = 1 if row % 2 else 3
        for x in range(offset, W, 4):
            if (x, y) in body and (x, y + 1) in inside:
                sprout(cv, x, y, body)
        row += 1
    for y in range(y0 + 2, y1, 3):
        line = sorted(p[0] for p in comp if p[1] == y)
        if not line:
            continue
        for x, dx in ((line[0], -1), (line[-1], 1)):
            if cv.px[x + dx, y][3] == 0:
                cv.put(x + dx, y, SP_M)
                if cv.px[x + dx, y - 1][3] == 0:
                    cv.put(x + dx, y - 1, SP_L)
    for x in range(min(p[0] for p in comp) + 2, max(p[0] for p in comp), 4):
        bottom = max((p[1] for p in comp if p[0] == x), default=None)
        if bottom is not None and cv.px[x, bottom + 1][3] == 0:
            cv.put(x, bottom + 1, SP_M)


def bush_stage(src, col, kind):
    cv = cell(src, col)
    comps = recolor_berries(cv, BANDS[kind])
    bush_sprouts(cv, comps)
    return cv.img


def stage_seeds(src):
    return cell(src, 29, ROW_Y - 32).img


def stage_sprout(src):
    return cell(src, 28).img


def stage_small(src):
    return cell(src, 29).img


LEAF_FILL = ((40, 86, 19, 255), (69, 165, 0, 255))


def stage_young(src):
    cv = cell(src, 30)
    for comp in components(cv):
        for x, y in comp:
            cv.put(x, y, LEAF_FILL[(x // 2 + y // 2) % 2])
    return cv.img


def stage_green(src):
    return bush_stage(src, 31, "green")


def stage_half(src):
    return bush_stage(src, 32, "half")


def stage_ripe(src):
    return bush_stage(src, 32, "ripe")


def stage_item(src):
    cv = cell(src, 34)
    comps = recolor_berries(cv, BANDS["ripe"])
    for comp in comps:
        if len(comp) > 40:
            item_sprouts(cv, comp)
    return cv.img


STAGES = [
    ("seeds", stage_seeds),
    ("sprout", stage_sprout),
    ("small", stage_small),
    ("young", stage_young),
    ("green", stage_green),
    ("half", stage_half),
    ("ripe", stage_ripe),
    ("item", stage_item),
]


def main():
    src = Image.open(SRC).convert("RGBA")
    save_sheet([fn(src) for _, fn in STAGES], "viviparous_strawberry.png")


if __name__ == "__main__":
    main()

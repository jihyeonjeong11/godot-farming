import math
import random
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "ai_generated" / "wood_generator.png"

FW, FH = 96, 64
LIT_FRAMES = 6
CLEAR = (0, 0, 0, 0)

OUTLINE = (20, 21, 35, 255)
SHADOW = (0, 0, 0, 102)
BLACK_D = (22, 21, 19, 255)
BLACK = (33, 33, 30, 255)
BLACK_M = (50, 50, 50, 255)
BLACK_L = (79, 79, 80, 255)
SOOT_BROWN = (58, 44, 34, 255)
RUST_D = (74, 59, 41, 255)
RUST = (110, 82, 52, 255)
SILVER_D = (103, 100, 110, 255)
SILVER = (150, 150, 162, 255)
SILVER_L = (205, 205, 215, 255)
GREEN_D = (36, 66, 38, 255)
GREEN = (62, 118, 56, 255)
GREEN_L = (110, 164, 78, 255)
RAD_D = (143, 140, 122, 255)
RAD = (201, 198, 178, 255)
RAD_L = (232, 230, 216, 255)
CRATE_D = (60, 62, 66, 255)
CRATE = (96, 98, 104, 255)
CRATE_L = (130, 132, 140, 255)
LABEL_B = (47, 90, 140, 255)
LABEL_R = (184, 77, 55, 255)
LABEL_W = (222, 219, 200, 255)
WIRE_R = (190, 60, 50, 255)
WIRE_B = (40, 40, 44, 255)
WOOD = (79, 48, 28, 255)
WOOD_L = (135, 91, 51, 255)
WOOD_END = (184, 150, 100, 255)
LED_ON = (90, 220, 90, 255)
LED_OFF = (40, 70, 40, 255)
FIRE = [
    (102, 44, 33, 255),
    (184, 77, 55, 255),
    (255, 172, 56, 255),
    (255, 215, 52, 255),
    (255, 246, 83, 255),
    (255, 253, 162, 255),
]
STEAM_D = (170, 175, 180, 170)
STEAM = (215, 218, 222, 190)
STEAM_L = (240, 242, 245, 210)


class Canvas:
    def __init__(self):
        self.img = Image.new("RGBA", (FW, FH), CLEAR)

    def put(self, x, y, c):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < FW and 0 <= y < FH:
            self.img.putpixel((x, y), c)

    def get(self, x, y):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < FW and 0 <= y < FH:
            return self.img.getpixel((x, y))
        return None

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.put(x, y, c)

    def ellipse(self, cx, cy, rx, ry, c, only_empty=False):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                dx = (x - cx) / rx if rx else 0
                dy = (y - cy) / ry if ry else 0
                if dx * dx + dy * dy <= 1.0:
                    if only_empty and self.get(x, y) != CLEAR:
                        continue
                    self.put(x, y, c)


def walk(pts):
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(n + 1):
            yield x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n


def draw_shadow(cv):
    for y in range(52, 63):
        for x in range(2, 94):
            dx = (x - 48) / 46
            dy = (y - 58) / 4.2
            if dx * dx + dy * dy <= 1.0:
                cv.put(x, y, SHADOW)


def draw_crate_battery(cv, lit, t):
    bx0, by0, bx1, by1 = 7, 24, 25, 40
    cv.rect(bx0, by0, bx1, by1, OUTLINE)
    cv.rect(bx0 + 1, by0 + 1, bx1 - 1, by0 + 4, BLACK_M)
    cv.rect(bx0 + 1, by0 + 1, bx1 - 1, by0 + 1, BLACK_L)
    cv.rect(bx0 + 1, by0 + 5, bx1 - 1, by1 - 1, BLACK)
    cv.rect(bx0 + 1, by0 + 5, bx0 + 1, by1 - 1, BLACK_M)
    cv.rect(bx0 + 3, by0 + 7, bx1 - 3, by0 + 11, LABEL_B)
    cv.rect(bx0 + 3, by0 + 7, bx1 - 3, by0 + 7, LABEL_W)
    cv.rect(bx1 - 7, by0 + 9, bx1 - 3, by0 + 11, LABEL_R)
    cv.rect(bx0 + 4, by0 + 9, bx0 + 8, by0 + 9, LABEL_W)
    for tx, col in ((bx0 + 3, WIRE_R), (bx1 - 4, BLACK_L)):
        cv.rect(tx, by0 - 2, tx + 2, by0, OUTLINE)
        cv.rect(tx + 1, by0 - 1, tx + 1, by0, col)
    cv.put(bx0 + 10, by0 + 2, OUTLINE)
    cv.put(bx0 + 10, by0 + 3, LED_ON if lit and t % 3 != 2 else LED_OFF)

    cx0, cy0, cx1, cy1 = 3, 34, 29, 54
    cv.rect(cx0, cy0, cx1, cy1, OUTLINE)
    cv.rect(cx0 + 1, cy0 + 1, cx1 - 1, cy1 - 1, CRATE)
    cv.rect(cx0 + 1, cy0 + 1, cx1 - 1, cy0 + 2, CRATE_L)
    for y in range(cy0 + 4, cy1 - 2, 3):
        for x in range(cx0 + 2, cx1 - 1, 3):
            cv.rect(x, y, x + 1, y + 1, CRATE_D)
    cv.rect(cx0 + 1, cy1 - 2, cx1 - 1, cy1 - 1, CRATE_D)
    cv.rect(cx0 + 8, cy0 + 4, cx0 + 17, cy0 + 6, OUTLINE)


def draw_turbine(cv, lit, t):
    bx0, bx1, top, bot = 33, 51, 25, 47
    cx = (bx0 + bx1) / 2
    for y in range(top, bot + 1):
        k = (y - top) / (bot - top)
        inset = round(k * 1.5)
        l, r = bx0 + inset, bx1 - inset
        cv.put(l, y, OUTLINE)
        cv.put(r, y, OUTLINE)
        for x in range(l + 1, r):
            u = (x - l) / (r - l)
            c = BLACK_M if u < 0.25 else (BLACK if u < 0.8 else BLACK_D)
            cv.put(x, y, c)
    cv.rect(bx0 + 2, bot, bx1 - 2, bot, OUTLINE)
    cv.ellipse(cx, top, (bx1 - bx0) / 2 + 0.5, 3, OUTLINE)
    cv.ellipse(cx, top, (bx1 - bx0) / 2 - 0.5, 2, SILVER_D)
    cv.ellipse(cx, top + 0.5, (bx1 - bx0) / 2 - 2, 1.4, BLACK_D)
    for y in (top + 6, top + 16):
        cv.rect(bx0 + 1, y, bx1 - 1, y, BLACK_L)
    for x, y in ((bx1 - 3, top + 9), (bx1 - 4, top + 10), (bx0 + 4, top + 13)):
        cv.put(x, y, RUST_D)

    hx0, hx1, hy0, hy1 = 37, 47, 13, 24
    cv.rect(hx0, hy0, hx1, hy1, OUTLINE)
    cv.rect(hx0 + 1, hy0 + 1, hx1 - 1, hy1 - 1, SILVER)
    cv.rect(hx0 + 1, hy0 + 1, hx0 + 2, hy1 - 1, SILVER_L)
    cv.rect(hx1 - 2, hy0 + 1, hx1 - 1, hy1 - 1, SILVER_D)
    cv.rect(hx0 + 1, hy0 + 5, hx1 - 1, hy0 + 5, SILVER_D)
    cv.rect(hx0 - 2, hy1 - 3, hx1 + 2, hy1, OUTLINE)
    cv.rect(hx0 - 1, hy1 - 2, hx1 + 1, hy1 - 1, SILVER_D)
    cv.rect(hx0 - 1, hy1 - 2, hx1 + 1, hy1 - 2, SILVER)

    rcx, rcy = 42, 9
    cv.ellipse(rcx, rcy, 5.5, 3.2, OUTLINE)
    cv.ellipse(rcx, rcy, 4.5, 2.2, BLACK_M)
    ang = (t * math.tau / 4 / LIT_FRAMES) if lit else 0.4
    for k in range(4):
        a = ang + k * math.tau / 4
        for s in (1, 2, 3, 4):
            cv.put(rcx + math.cos(a) * s, rcy + math.sin(a) * s * 0.5, SILVER_L if k % 2 == 0 else SILVER)
    cv.put(rcx, rcy, OUTLINE)
    cv.rect(rcx - 1, rcy + 3, rcx + 1, hy0, OUTLINE)
    cv.put(rcx, rcy + 3, SILVER_D)


def draw_boiler(cv, lit, t, rng):
    lx0, lx1 = 59, 90
    ftop, fbot = 43, 57
    for x in (lx0, lx1 - 2):
        cv.rect(x - 1, ftop, x + 2, fbot, OUTLINE)
        cv.rect(x, ftop, x + 1, fbot - 1, GREEN)
        cv.rect(x, ftop, x, fbot - 1, GREEN_L)
        cv.rect(x - 2, fbot - 1, x + 3, fbot, OUTLINE)
        cv.rect(x - 1, fbot - 1, x + 2, fbot - 1, RUST_D)

    fx0, fx1, fy0, fy1 = lx0 + 3, lx1 - 4, ftop + 2, fbot - 2
    if lit:
        for x in range(fx0 - 2, fx1 + 3):
            if rng.random() < 0.75:
                cv.put(x, fbot + 1, FIRE[1] if rng.random() < 0.5 else FIRE[0])
    for x0, x1, y in ((fx0 + 1, fx1 - 6, fy1 - 1), (fx0 + 6, fx1 - 1, fy1 - 3)):
        cv.rect(x0, y, x1, y + 1, WOOD if lit else (60, 40, 26, 255))
        cv.rect(x0, y, x1, y, WOOD_L if not lit else FIRE[1])
        cv.put(x1, y, WOOD_END)
        cv.put(x0, y, WOOD_END)
    if lit:
        phase = t * math.tau / LIT_FRAMES
        for x in range(fx0, fx1 + 1):
            u = (x - fx0) / (fx1 - fx0)
            h = 4 + 5 * math.sin(math.pi * u)
            h += 1.6 * math.sin(phase + x * 0.8) + 1.1 * math.sin(phase * 2 + x * 0.33)
            h += rng.uniform(-0.7, 0.7)
            for y in range(max(fy1 - int(h), fy0 - 2), fy1 + 1):
                d = (fy1 - y) / max(h, 1)
                if d > 0.85:
                    c = FIRE[1]
                elif d > 0.6:
                    c = FIRE[2]
                elif d > 0.35:
                    c = FIRE[3]
                elif d > 0.15:
                    c = FIRE[4]
                else:
                    c = FIRE[5]
                if cv.get(x, y) == WOOD_END and d < 0.3:
                    continue
                cv.put(x, y, c)
    else:
        for x in range(fx0 + 2, fx1 - 1, 3):
            cv.put(x, fy1 + 1, BLACK_L)

    px0, px1, ptop, pbot = 61, 88, 18, 44
    pcx = (px0 + px1) / 2
    for y in range(ptop, pbot + 1):
        cv.put(px0, y, OUTLINE)
        cv.put(px1, y, OUTLINE)
        for x in range(px0 + 1, px1):
            u = (x - px0) / (px1 - px0)
            if u < 0.18:
                c = BLACK_L
            elif u < 0.45:
                c = BLACK_M
            elif u < 0.85:
                c = BLACK
            else:
                c = BLACK_D
            v = (y - ptop) / (pbot - ptop)
            if v > 0.55 and (x * 7 + y * 3) % 5 < 2:
                c = SOOT_BROWN if c != BLACK_L else RUST_D
            if v > 0.82:
                c = BLACK_D if (x + y) % 3 else SOOT_BROWN
            cv.put(x, y, c)
    cv.ellipse(pcx, pbot, (px1 - px0) / 2, 2.2, OUTLINE)
    cv.rect(px0 + 1, pbot - 2, px1 - 1, pbot - 1, BLACK_D)
    for x, y in ((66, 30), (67, 31), (80, 27), (72, 37), (73, 37)):
        cv.put(x, y, RUST)
    if lit:
        for x in range(px0 + 2, px1 - 1):
            if (x + t) % 3 == 0:
                cv.put(x, pbot - 1, FIRE[1])

    cv.ellipse(pcx, ptop, (px1 - px0) / 2 + 1.5, 4.5, OUTLINE)
    cv.ellipse(pcx, ptop, (px1 - px0) / 2 + 0.5, 3.5, BLACK_M)
    cv.ellipse(pcx, ptop - 0.5, (px1 - px0) / 2 - 1.5, 2.6, BLACK_L)
    cv.ellipse(pcx, ptop - 0.5, (px1 - px0) / 2 - 3, 1.8, BLACK_M)
    for wx, wy in ((px0 - 1, ptop + 1), (px1 + 1, ptop + 1), (px0 + 6, ptop + 3), (px1 - 6, ptop + 3)):
        cv.rect(wx - 1, wy - 3, wx + 1, wy, OUTLINE)
        cv.put(wx, wy - 2, SILVER)
        cv.put(wx, wy - 1, SILVER_D)
        cv.put(wx - 1, wy - 3, SILVER_D)
        cv.put(wx + 1, wy - 3, SILVER_D)

    vx, vy = 79, ptop - 1
    cv.rect(vx - 1, vy - 6, vx + 1, vy, OUTLINE)
    cv.rect(vx, vy - 5, vx, vy, SILVER)
    cv.rect(vx - 2, vy - 7, vx + 2, vy - 6, OUTLINE)
    cv.rect(vx - 1, vy - 7, vx + 1, vy - 7, SILVER_L)

    gx, gy = 72, ptop - 2
    cv.ellipse(gx, gy, 2.5, 2.5, OUTLINE)
    cv.ellipse(gx, gy, 1.6, 1.6, LABEL_W)
    cv.put(gx + (1 if lit else -1), gy - 1, LABEL_R)

    cv.rect(lx0 - 1, ftop - 1, lx1, ftop + 1, OUTLINE)
    cv.rect(lx0, ftop, lx1 - 1, ftop, GREEN_L)
    cv.rect(lx0, ftop + 1, lx1 - 1, ftop + 1, GREEN_D)
    cv.rect(lx0 + 2, fbot - 3, lx1 - 3, fbot - 2, OUTLINE)
    cv.rect(lx0 + 2, fbot - 3, lx1 - 3, fbot - 3, GREEN_D)
    for x in (lx0 + 6, lx1 - 8):
        cv.put(x, ftop, RUST)


def draw_steam_pipe(cv):
    pts = [(65, 13), (62, 11), (56, 11), (48, 14)]
    for x, y in walk(pts):
        cv.put(x, y - 1, OUTLINE)
        cv.put(x, y, SILVER_L)
        cv.put(x, y + 1, SILVER_D)
        cv.put(x, y + 2, OUTLINE)
    cv.rect(64, 11, 67, 17, OUTLINE)
    cv.rect(65, 12, 66, 16, SILVER)
    cv.rect(46, 13, 48, 17, OUTLINE)
    cv.rect(47, 14, 47, 16, SILVER)


def draw_hose(cv):
    pts = [(34, 21), (29, 24), (27, 30), (28, 38), (31, 44)]
    for x, y in walk(pts):
        cv.put(x - 1, y, OUTLINE)
        cv.put(x + 2, y, OUTLINE)
        cv.put(x, y, BLACK_L)
        cv.put(x + 1, y, BLACK)
    cv.rect(33, 19, 37, 22, OUTLINE)
    cv.rect(34, 20, 36, 21, SILVER)


def draw_radiator(cv):
    x0, x1, y0, y1 = 30, 56, 44, 60
    cv.rect(x0, y0, x1, y0 + 3, OUTLINE)
    cv.rect(x0, y1 - 3, x1, y1, OUTLINE)
    for x in range(x0 + 1, x1, 3):
        cv.rect(x - 1, y0, x + 2, y1, OUTLINE)
        cv.rect(x, y0 + 1, x + 1, y1 - 1, RAD)
        cv.rect(x, y0 + 1, x, y1 - 1, RAD_L)
        for y in range(y0 + 4, y1 - 3):
            if (y + x) % 5 == 0:
                cv.put(x + 1, y, RAD_D)
    cv.rect(x0 + 1, y0 + 1, x1 - 1, y0 + 2, RAD)
    cv.rect(x0 + 1, y0 + 1, x1 - 1, y0 + 1, RAD_L)
    cv.rect(x0 + 1, y1 - 2, x1 - 1, y1 - 1, RAD_D)
    cv.rect(x0 + 1, y1 - 2, x1 - 1, y1 - 2, RAD)
    for x, y in ((x0 + 5, y0 + 8), (x0 + 6, y0 + 9), (x1 - 6, y0 + 11), (x0 + 13, y1 - 2)):
        cv.put(x, y, RUST)
    cv.rect(x1, y1 - 4, x1 + 6, y1 - 1, OUTLINE)
    cv.rect(x1 + 1, y1 - 3, x1 + 5, y1 - 2, SILVER)
    cv.rect(x1 + 1, y1 - 3, x1 + 5, y1 - 3, SILVER_L)
    cv.rect(x1 + 5, y1 - 8, x1 + 7, y1 - 1, OUTLINE)
    cv.rect(x1 + 6, y1 - 7, x1 + 6, y1 - 2, SILVER)


def draw_wires(cv, lit, t):
    red = [(38, 15), (33, 13), (24, 14), (17, 18), (11, 22)]
    blk = [(38, 18), (33, 17), (26, 18), (21, 21), (19, 22)]
    for pts, col in ((blk, WIRE_B), (red, WIRE_R)):
        for x, y in walk(pts):
            if cv.get(x, y - 1) == CLEAR:
                cv.put(x, y - 1, OUTLINE)
            cv.put(x, y, col)
    if lit:
        n = len(red) - 1
        p = (t % LIT_FRAMES) / LIT_FRAMES
        seg = min(int(p * n), n - 1)
        f = p * n - seg
        (x0, y0), (x1, y1) = red[seg], red[seg + 1]
        cv.put(x0 + (x1 - x0) * f, y0 + (y1 - y0) * f, FIRE[4])


def draw_steam(cv, t):
    for k in range(3):
        p = ((t + k * LIT_FRAMES / 3) % LIT_FRAMES) / LIT_FRAMES
        x = 79 + p * 9 + math.sin(p * math.pi * 1.6) * 1.2
        y = 9 - p * 5
        r = 1.5 + p * 2.2
        cv.ellipse(x, y + 0.6, r, r, STEAM_D, only_empty=True)
        cv.ellipse(x, y, r, r, STEAM if p < 0.55 else STEAM_L)
        cv.ellipse(x - r * 0.35, y - r * 0.35, max(r * 0.45, 0.6), max(r * 0.45, 0.6), STEAM_L)
    p = (t % LIT_FRAMES) / LIT_FRAMES
    for i in range(2):
        q = (p + i * 0.5) % 1.0
        x = 49 + q * 5
        y = 5 - q * 5
        cv.put(x, y, STEAM_L if q < 0.5 else STEAM)
        cv.put(x + 1, y, STEAM)


def draw_frame(lit, t):
    rng = random.Random(4242 + t * 31 + (0 if lit else 777))
    cv = Canvas()
    draw_shadow(cv)
    draw_crate_battery(cv, lit, t)
    draw_turbine(cv, lit, t)
    draw_boiler(cv, lit, t, rng)
    draw_steam_pipe(cv)
    draw_hose(cv)
    draw_wires(cv, lit, t)
    draw_radiator(cv)
    if lit:
        draw_steam(cv, t)
    return cv.img


def main():
    frames = [draw_frame(False, 0)] + [draw_frame(True, t) for t in range(LIT_FRAMES)]
    sheet = Image.new("RGBA", (FW * len(frames), FH), CLEAR)
    for i, f in enumerate(frames):
        sheet.paste(f, (i * FW, 0))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print(OUT, sheet.size)


if __name__ == "__main__":
    main()

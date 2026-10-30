import sys
from common import Canvas, P

W, H = 60, 92
GROUND = 86
c = Canvas(W, H, seed=21)


def pole(x):
    c.rect(x, 6, x + 2, GROUND - 3, "c0")
    c.vline(x, 6, GROUND - 3, "c1")
    c.rect(x - 4, GROUND - 3, x + 6, GROUND - 1, "t2")
    c.hline(x - 4, x + 6, GROUND - 3, "c0")


pole(5)
pole(51)
c.rect(3, 4, 56, 6, "c0")
c.hline(3, 56, 4, "c2")
c.hline(4, 55, 5, "c1")
c.rect(2, 3, 4, 7, "t2")
c.rect(55, 3, 57, 7, "t2")


def panel(x0, x1, bottom, seed):
    rnd = c.rnd
    ramp = ("b0", "b1", "b2", "b3", "bh", "b3", "b2", "b1")
    x = x0
    while x <= x1:
        width = rnd.randint(4, 7)
        for i in range(width):
            if x + i > x1:
                break
            col = ramp[min(len(ramp) - 1, int(i / width * len(ramp)))]
            drop = bottom + int(3 * (((x + i) * 7 + seed) % 5) / 4) - (2 if rnd.random() < 0.2 else 0)
            for y in range(8, drop + 1):
                c.px(x + i, y, col)
        x += width
    for x in range(x0, x1 + 1, 3):
        c.px(x, 7, "c1")
        c.px(x, 8, "b0")


panel(9, 30, 74, 1)
panel(31, 48, 56, 4)

for x in range(31, 49):
    top = 57 + ((x * 5) % 4)
    for y in range(top, top + 3 + (x % 3)):
        if (x + y) % 4:
            c.px(x, y, "b1" if y < top + 2 else "b0")

for pts in (((19, 38), (20, 38), (21, 39), (20, 40), (19, 40), (18, 39), (21, 40)),
            ((40, 30), (41, 30), (41, 31), (42, 31)),
            ((14, 61), (15, 61), (15, 62), (16, 62), (14, 62))):
    for x, y in pts:
        c.img.putpixel((x, y), (0, 0, 0, 0))

for cx, cy in ((24, 66), (12, 70), (36, 50), (44, 46)):
    for dy in range(-2, 3):
        for dx in range(-3, 4):
            if abs(dx) + abs(dy) <= 3 and c.is_paint(cx + dx, cy + dy) and c.rnd.random() < 0.7:
                c.px(cx + dx, cy + dy, "dirt2" if abs(dx) + abs(dy) > 1 else "dirt1")

c.grime(70, 76, 0.5)
c.outline()
c.grass(((6, 5, 6), (28, 4, 4), (52, 5, 7)), GROUND)
c.finish((0, GROUND - 5, W - 1, GROUND + 4), sys.argv[1])

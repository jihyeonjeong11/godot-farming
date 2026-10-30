import sys
from common import Canvas

W, H = 50, 100
GROUND = 94
c = Canvas(W, H, seed=44)

c.poly([(5, 10), (8, 4), (42, 4), (45, 10)], "b2")
c.hline(9, 41, 4, "bh")
c.hline(8, 42, 5, "b3")
c.rect(5, 10, 38, GROUND - 4, "b2")
c.rect(39, 10, 45, GROUND - 4, "b1")
c.vline(39, 10, GROUND - 4, "b0")
c.vline(6, 11, GROUND - 5, "b3")
c.hline(5, 45, 10, "b1")
c.rect(7, 12, 37, 17, "red")
c.hline(7, 37, 12, "red2")
for x in range(10, 35, 4):
    c.rect(x, 14, x + 1, 15, "b3")

c.rect(8, 20, 29, 64, "b0")
c.rect(9, 21, 28, 63, "g0")
cans = ("cn0", "cn1", "cn2", "cn3", "cn4", "b3")
for row, y in enumerate(range(24, 62, 9)):
    c.hline(9, 28, y + 6, "c0")
    c.hline(9, 28, y + 7, "t2")
    for slot, x in enumerate(range(10, 28, 4)):
        if c.rnd.random() < 0.35:
            continue
        col = cans[(row * 3 + slot) % len(cans)]
        c.rect(x, y + 1, x + 2, y + 5, col)
        c.px(x, y + 1, "c2")
        c.vline(x + 2, y + 2, y + 5, "t1")
for i in range(18):
    c.px(11 + i // 2, 60 - i * 2, "g1")
for x, y in ((22, 30), (23, 31), (24, 31), (25, 32), (24, 33), (21, 29), (20, 29), (26, 34), (27, 36)):
    c.px(x, y, "g3")
c.px(23, 32, "g2")

c.rect(31, 20, 37, 64, "b1")
c.rect(32, 22, 36, 26, "q0")
c.hline(32, 36, 22, "q2")
c.px(33, 24, "q4")
for y in range(30, 52, 4):
    c.rect(32, y, 33, y + 1, "c1")
    c.rect(35, y, 36, y + 1, "c1")
c.rect(33, 55, 35, 60, "t1")
c.px(34, 56, "c0")

c.rect(8, 68, 29, 78, "b0")
c.rect(9, 70, 28, 77, "t1")
c.hline(9, 28, 70, "t2")
c.rect(13, 74, 15, 77, "cn1")
c.rect(31, 68, 37, 78, "b1")
c.hline(5, 45, 82, "b0")

c.rect(6, GROUND - 4, 10, GROUND - 1, "t2")
c.rect(40, GROUND - 4, 44, GROUND - 1, "t2")

for cx, cy, r, d in ((41, 40, 2, 2), (10, 84, 2, 1), (36, 86, 2, 1), (8, 22, 1, 1), (43, 72, 2, 2), (30, 8, 1, 0)):
    c.rust_patch(cx, cy, r, d)
for x, y in ((15, 86), (16, 87), (17, 87), (18, 88), (19, 87)):
    c.px(x, y, "b0")

c.grime(GROUND - 13, GROUND - 4, 0.55)
c.outline()
c.grass(((5, 4, 6), (25, 3, 3), (46, 4, 6)), GROUND)
c.finish((1, GROUND - 6, W - 2, GROUND + 4), sys.argv[1])

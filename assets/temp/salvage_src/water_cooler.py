import sys
from common import Canvas, P

W, H = 40, 84
GROUND = 78
c = Canvas(W, H, seed=33)

c.poly([(6, 30), (8, 27), (31, 27), (33, 30), (33, GROUND - 2), (6, GROUND - 2)], "b2")
c.rect(6, 31, 27, GROUND - 2, "b2")
c.rect(28, 31, 33, GROUND - 2, "b1")
c.hline(8, 31, 27, "bh")
c.hline(7, 32, 28, "b3")
c.hline(6, 33, 29, "b3")
c.hline(6, 33, 30, "b1")
c.vline(28, 31, GROUND - 2, "b0")
c.vline(7, 31, GROUND - 3, "b3")

c.rect(9, 34, 25, 47, "b1")
c.rect(10, 35, 24, 46, "t2")
c.hline(10, 24, 35, "t1")
c.rect(10, 44, 24, 46, "c0")
c.hline(10, 24, 44, "c1")
for x in range(11, 24, 2):
    c.px(x, 45, "t2")
c.rect(12, 37, 14, 39, "red")
c.px(12, 37, "red2")
c.rect(20, 37, 22, 39, "blue")
c.px(20, 37, "blue2")
c.px(13, 40, "c1")
c.px(21, 40, "c1")
c.px(21, 42, "q3")

c.hline(9, 25, 52, "b0")
c.hline(9, 25, 53, "b3")
c.vline(9, 52, GROUND - 5, "b0")
c.vline(25, 52, GROUND - 5, "b0")
c.hline(9, 25, GROUND - 5, "b0")
c.rect(22, 60, 23, 64, "c0")
c.px(22, 60, "c1")

c.rect(14, 22, 25, 27, "q1")
c.hline(14, 25, 22, "q2")
c.poly([(9, 8), (12, 4), (27, 4), (30, 8), (30, 18), (26, 22), (13, 22), (9, 18)], "q2")
c.poly([(9, 12), (30, 12), (30, 18), (26, 22), (13, 22), (9, 18)], "q1")
c.hline(12, 27, 4, "q4")
c.hline(10, 29, 5, "q3")
for y in range(6, 21):
    c.px(11, y, "q4" if y < 12 else "q3")
c.hline(9, 30, 12, "q3")
for y in range(13, 21):
    c.px(28, y, "q0")
for y in (8, 15):
    c.hline(10, 29, y, "q1" if y < 12 else "q0")
for x, y in ((22, 6), (23, 7), (23, 8), (24, 9), (25, 10), (25, 11), (26, 12), (24, 8)):
    c.px(x, y, "g3")

for cx, cy, r, d in ((30, 58, 2, 2), (10, 68, 2, 1), (27, 31, 1, 1), (17, 50, 1, 2)):
    c.rust_patch(cx, cy, r, d)
for x, y in ((14, 58), (15, 59), (16, 59), (17, 60), (16, 58)):
    c.px(x, y, "b0")

c.grime(GROUND - 9, GROUND - 2, 0.55)
c.outline()
c.grass(((5, 4, 5), (34, 4, 6)), GROUND)
c.finish((1, GROUND - 5, W - 2, GROUND + 4), sys.argv[1])

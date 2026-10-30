import sys
from common import Canvas

W, H = 44, 60
GROUND = 54
c = Canvas(W, H, seed=55)

c.poly([(6, 26), (38, 26), (34, GROUND - 2), (10, GROUND - 2)], "b2")
for y in range(26, GROUND - 1):
    t = (y - 26) / (GROUND - 28)
    right = int(38 - 4 * t)
    c.hline(right - 5, right, y, "b1")
    c.px(right - 6, y, "b0")
    c.px(int(6 + 4 * t) + 1, y, "b3")
c.hline(10, 34, GROUND - 6, "b0")
c.hline(10, 34, GROUND - 5, "b1")

for y in range(18, 30):
    for x in range(3, 42):
        e = ((x - 22) / 19) ** 2 + ((y - 24) / 6) ** 2
        if e <= 1:
            c.px(x, y, "b3" if y < 24 else "b2")
        if e <= 1 and y <= 19:
            c.px(x, y, "bh")
for y in range(19, 29):
    for x in range(5, 40):
        e = ((x - 22) / 16) ** 2 + ((y - 24) / 4.5) ** 2
        if e <= 1:
            c.px(x, y, "s1" if y < 23 else "s2")
            if c.rnd.random() < 0.18:
                c.px(x, y, "s3")
            if c.rnd.random() < 0.08:
                c.px(x, y, "s0")
for y in range(19, 21):
    for x in range(8, 37):
        e = ((x - 22) / 16) ** 2 + ((y - 24) / 4.5) ** 2
        if e <= 1:
            c.px(x, y, "s0")

for y in range(8, 25):
    x = 13 - (24 - y) // 6
    c.px(x, y, "w2")
    c.px(x + 1, y, "w1")
for x, y in ((11, 12), (10, 11), (9, 10), (8, 10), (13, 15), (14, 14), (15, 13), (16, 13), (10, 18), (9, 17)):
    c.px(x, y, "w1")

for y in range(14, 25):
    c.px(25, y, "lf1")
    c.px(26, y, "lf0" if y > 20 else "lf1")
for x, y in ((21, 13), (22, 13), (23, 13), (20, 14), (21, 14), (22, 14), (23, 14), (24, 14), (22, 15), (23, 15), (24, 15)):
    c.px(x, y, "lf2" if y == 13 else "lf1")
for x, y in ((28, 10), (29, 10), (30, 10), (27, 11), (28, 11), (29, 11), (30, 11), (31, 11), (27, 12), (28, 12), (29, 12)):
    c.px(x, y, "lf2" if y == 10 else "lf1")
c.px(27, 13, "lf1"); c.px(26, 13, "lf1")
c.px(24, 12, "lf2"); c.px(25, 13, "lf2")
for x, y in ((32, 23), (33, 23), (33, 22), (34, 22), (16, 25), (17, 25), (17, 24)):
    c.px(x, y, "lf1")

for x, y in ((30, 32), (31, 33), (31, 34), (32, 35), (31, 36), (32, 37), (33, 38), (32, 39)):
    c.px(x, y, "b0")
for cx, cy, r, d in ((12, 40, 2, 2), (20, 46, 1, 1)):
    c.rust_patch(cx, cy, r, d)

c.grime(GROUND - 8, GROUND - 2, 0.5)
c.outline()
c.grass(((6, 4, 5), (38, 4, 5)), GROUND)
c.finish((2, GROUND - 5, W - 3, GROUND + 4), sys.argv[1])

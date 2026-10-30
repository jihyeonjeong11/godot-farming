import sys, random
from PIL import Image, ImageDraw


def hx(s):
    return tuple(int(s[i:i + 2], 16) for i in (1, 3, 5)) + (255,)


P = {k: hx(v) for k, v in dict(
    ol="#151b1b",
    dirt0="#29302f", dirt1="#4a3c31", dirt2="#584e41",
    r0="#4a3c31", r1="#52432f", r2="#776041", r3="#8a392b",
    g0="#22232a", g1="#40465d", g2="#7d7d89", g3="#9e9f91",
    t0="#100f0f", t1="#1e1c1c", t2="#393939", t3="#555555", t4="#7a7a7a",
    c0="#535353", c1="#918f8f", c2="#a7a7a7",
    gr0="#2f2318", gr1="#655d45", gr2="#968743", gr3="#b2ac7d",
    lamp="#9e9f91", tail="#9c3a2a", tail2="#bc6b3d",
).items()}
PAINTS = {
    "teal": dict(b0="#2f3e3d", b1="#3f5456", b2="#516c70", b3="#7a9094", bh="#9aaeb0"),
    "yellow": dict(b0="#4f4529", b1="#7a6a34", b2="#9c8a43", b3="#b9a95f", bh="#d1c58c"),
}
P.update({k: hx(v) for k, v in PAINTS[sys.argv[2] if len(sys.argv) > 2 else "yellow"].items()})
BODY = {P[k][:3] for k in ("b0", "b1", "b2", "b3", "bh")}
SHADOW = (0, 0, 0, 102)
W, H = 144, 96
GROUND = 88
FRONT_WHEEL, REAR_WHEEL, WHEEL_Y = 32, 108, 78
rnd = random.Random(11)
img = Image.new("RGBA", (W, H))
draw = ImageDraw.Draw(img)


def get(x, y):
    return img.getpixel((x, y)) if 0 <= x < W and 0 <= y < H else (0, 0, 0, 0)


def px(x, y, col):
    if 0 <= x < W and 0 <= y < H:
        img.putpixel((x, y), P[col])


def poly(pts, col):
    draw.polygon(pts, fill=P[col])


def hline(x0, x1, y, col):
    for x in range(x0, x1 + 1):
        px(x, y, col)


def is_body(x, y):
    return get(x, y)[:3] in BODY


SILHOUETTE = [(7, 49), (9, 41), (14, 36), (42, 33), (56, 13), (90, 13), (106, 35),
              (127, 35), (132, 39), (134, 47), (135, 68), (131, 73), (9, 73), (6, 69)]
poly(SILHOUETTE, "b1")

poly([(7, 47), (9, 41), (14, 36), (42, 33), (49, 47)], "b2")
poly([(101, 47), (106, 35), (127, 35), (132, 39), (134, 47)], "b2")
poly([(56, 13), (90, 13), (93, 20), (53, 20)], "b2")
hline(57, 89, 13, "bh"); hline(56, 90, 14, "b3"); hline(55, 91, 15, "b3")
hline(15, 41, 34, "bh"); hline(11, 43, 35, "b3"); hline(10, 44, 36, "b3")
hline(107, 126, 35, "bh"); hline(106, 129, 36, "b3")

poly([(42, 33), (56, 13), (60, 13), (48, 34)], "g1")
for i in range(6):
    px(50 - i, 20 + i * 2, "g2"); px(51 - i, 20 + i * 2, "g3")
poly([(90, 13), (106, 35), (102, 35), (88, 15)], "g0")

poly([(53, 20), (93, 20), (102, 45), (49, 45)], "g0")
for y in range(20, 46):
    t = (y - 20) / 25
    hline(int(53 - 4 * t), int(55 - 4 * t), y, "b1")
    hline(int(91 + 11 * t), int(93 + 11 * t), y, "b0")
    hline(74, 76, y, "b0")
for i in range(16):
    px(62 + i // 2, 43 - i, "g1"); px(63 + i // 2, 43 - i, "g1"); px(67 + i // 2, 43 - i, "g1")

for y in range(21, 45):
    for x in range(77, 104):
        if get(x, y)[:3] == P["g0"][:3]:
            px(x, y, "t0")
for sx, sy in ((80, 24), (86, 28), (94, 34), (83, 39), (97, 42), (90, 22), (79, 33)):
    px(sx, sy, "g2"); px(sx + 1, sy, "g1"); px(sx, sy - 1, "g1")
for x in range(77, 92):
    if (x * 7) % 5 < 3:
        px(x, 21 + (x % 3), "g2")

hline(8, 134, 46, "b2"); hline(8, 134, 47, "b3"); hline(9, 133, 48, "b2")
for y in range(49, 74):
    for x in range(5, 137):
        if is_body(x, y) and y >= 68:
            px(x, y, "b0")
hline(9, 133, 52, "b2")
hline(9, 133, 64, "b0")

for x in (59, 77, 95):
    for y in range(49, 69):
        px(x, y, "b0")
    px(x + 1, 49, "b3"); px(x + 1, 50, "b2")
hline(63, 66, 54, "c1"); hline(63, 66, 55, "c0")
hline(81, 84, 54, "c1"); hline(81, 84, 55, "c0")

for y in range(50, 56):
    hline(7, 12, y, "lamp")
hline(8, 11, 51, "c2"); px(11, 55, "t2"); px(8, 54, "t2")
for y in range(50, 56):
    hline(129, 134, y, "tail")
hline(130, 133, 51, "tail2")


def bumper(x0, x1, y0, y1):
    for y in range(y0, y1 + 1):
        hline(x0, x1, y, "c0")
    hline(x0, x1, y0, "c1")
    hline(x0 + 1, x1 - 1, y0 + 1, "c2")


bumper(3, 14, 63, 67)
bumper(126, 139, 63, 67)

for y in range(68, 74):
    for x in range(5, 137):
        if is_body(x, y):
            k = (y - 67) / 6
            r = rnd.random()
            if r < k * 0.6:
                px(x, y, "dirt1" if rnd.random() < 0.6 else "dirt0")


def wheel(cx, cy, flat):
    for y in range(cy - 14, cy + 1):
        for x in range(cx - 15, cx + 16):
            if ((x - cx) / 15) ** 2 + ((y - cy) / 14) ** 2 <= 1:
                px(x, y, "ol")
    for y in range(cy - 13, cy - 11):
        for x in range(cx - 15, cx + 16):
            if abs(((x - cx) / 15) ** 2 + ((y - cy) / 14) ** 2 - 1) < 0.12 and y < cy - 10:
                px(x, y - 1, "b0")
    for y in range(cy - 10, cy + 11):
        for x in range(cx - 11, cx + 12):
            if flat and y > cy + 7:
                continue
            sx = 11 if flat and y > cy + 4 else 10
            e = ((x - cx) / sx) ** 2 + ((y - cy) / 10) ** 2
            if e <= 1:
                px(x, y, "t1")
            if e <= 0.4:
                px(x, y, "t2" if flat else "c0")
            if e <= 0.16:
                px(x, y, "t3" if flat else "c1")
            if e <= 0.04 and not flat:
                px(x, y, "c2")
    for x in range(cx - 7, cx + 3):
        px(x, cy - 9, "t2")
    for a, b in ((-5, -1), (5, 1), (-1, 5), (1, -5)):
        if not flat:
            px(cx + a // 2, cy + b // 2, "t2")


wheel(FRONT_WHEEL, WHEEL_Y, False)
wheel(REAR_WHEEL, WHEEL_Y + 1, True)


def rust_patch(cx, cy, r, drips):
    for y in range(cy - r - 1, cy + r + 2):
        for x in range(cx - r - 2, cx + r + 3):
            if not (is_body(x, y) or get(x, y)[:3] in (P["dirt0"][:3], P["dirt1"][:3])):
                continue
            dist = (((x - cx) / (r + 1.5)) ** 2 + ((y - cy) / (r * 0.8 + 1)) ** 2) ** 0.5 + rnd.uniform(-0.25, 0.25)
            if dist < 0.3 and rnd.random() < 0.5:
                px(x, y, "r3")
            elif dist < 0.5:
                px(x, y, "r2")
            elif dist < 0.85:
                px(x, y, "r1")
    for _ in range(drips):
        x = cx + rnd.randint(-r, r)
        for k in range(rnd.randint(2, 5)):
            if is_body(x, cy + r // 2 + k):
                px(x, cy + r // 2 + k, "r1" if k else "r2")


for cx, cy, r, dr in ((48, 68, 2, 2), (55, 66, 1, 1), (16, 67, 2, 1), (122, 67, 2, 2), (94, 68, 2, 1),
                      (12, 46, 2, 1), (130, 46, 2, 1), (49, 45, 1, 2), (103, 45, 1, 2), (62, 59, 1, 2), (80, 61, 1, 1)):
    rust_patch(cx, cy, r, dr)
for x in range(8, 134):
    if rnd.random() < 0.3 and is_body(x, 48):
        px(x, 48, "r1")

for x, y in ((20, 56), (21, 57), (22, 57), (23, 58), (24, 58), (25, 57)):
    px(x, y, "b0")
for x, y in ((21, 56), (22, 56), (23, 57)):
    px(x, y, "b3")

alpha = img.copy()
for y in range(H):
    for x in range(W):
        if alpha.getpixel((x, y))[3] == 255:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < W and 0 <= ny < H) or alpha.getpixel((nx, ny))[3] == 0:
                    img.putpixel((x, y), P["ol"])
                    break

gr = random.Random(5)
for cx, half, peak in ((10, 6, 7), (54, 7, 6), (84, 5, 5), (130, 7, 8)):
    for bx in range(cx - half, cx + half + 1):
        if gr.random() < 0.2:
            continue
        h = max(2, int(peak * (1 - abs(bx - cx) / (half + 1)) ** 0.6) + gr.randint(-1, 1))
        by = GROUND + gr.randint(-1, 0)
        lean = -1 if bx < cx else 1
        for k in range(h):
            col = "gr0" if k == 0 else ("gr1" if k < h * 0.45 else gr.choice(["gr2", "gr2", "gr3"]))
            px(bx + (k * lean) // 3, by - k, col)

shadow = Image.new("RGBA", (W, H))
ImageDraw.Draw(shadow).ellipse((3, 76, 141, 93), fill=SHADOW)
out = Image.alpha_composite(shadow, img)
out = out.crop(out.getbbox())
out.save(sys.argv[1])
print("size", out.size)

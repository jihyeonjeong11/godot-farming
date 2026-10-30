import random
from PIL import Image, ImageDraw


def hx(s):
    return tuple(int(s[i:i + 2], 16) for i in (1, 3, 5)) + (255,)


P = {k: hx(v) for k, v in dict(
    ol="#151b1b",
    b0="#4f4529", b1="#7a6a34", b2="#9c8a43", b3="#b9a95f", bh="#d1c58c",
    dirt0="#29302f", dirt1="#4a3c31", dirt2="#584e41",
    r1="#52432f", r2="#776041", r3="#8a392b",
    w0="#2f2318", w1="#4a3b29", w2="#5f4c37", w3="#776041",
    g0="#22232a", g1="#40465d", g2="#7d7d89", g3="#9e9f91",
    q0="#334740", q1="#3d4a49", q2="#576a6b", q3="#6e8584", q4="#9eb0ad",
    t0="#100f0f", t1="#1e1c1c", t2="#393939", t3="#555555", t4="#7a7a7a",
    c0="#535353", c1="#918f8f", c2="#a7a7a7",
    gr0="#2f2318", gr1="#655d45", gr2="#968743", gr3="#b2ac7d",
    red="#9c3a2a", red2="#bc6b3d", blue="#40465d", blue2="#6e8584",
    s0="#1e1610", s1="#2f2318", s2="#4a3b29", s3="#5f4c37",
    lf0="#3f4a22", lf1="#5a6827", lf2="#8b9a41",
    cn0="#763f36", cn1="#9d5345", cn2="#3d4a49", cn3="#6e8584", cn4="#b7aca7",
).items()}
SHADOW = (0, 0, 0, 102)
YELLOW = {P[k][:3] for k in ("b0", "b1", "b2", "b3", "bh")}


class Canvas:
    def __init__(self, w, h, seed=1):
        self.w, self.h = w, h
        self.img = Image.new("RGBA", (w, h))
        self.draw = ImageDraw.Draw(self.img)
        self.rnd = random.Random(seed)

    def get(self, x, y):
        return self.img.getpixel((x, y)) if 0 <= x < self.w and 0 <= y < self.h else (0, 0, 0, 0)

    def px(self, x, y, col):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.img.putpixel((x, y), P[col])

    def hline(self, x0, x1, y, col):
        for x in range(x0, x1 + 1):
            self.px(x, y, col)

    def vline(self, x, y0, y1, col):
        for y in range(y0, y1 + 1):
            self.px(x, y, col)

    def rect(self, x0, y0, x1, y1, col):
        for y in range(y0, y1 + 1):
            self.hline(x0, x1, y, col)

    def poly(self, pts, col):
        self.draw.polygon(pts, fill=P[col])

    def is_paint(self, x, y):
        return self.get(x, y)[:3] in YELLOW

    def grime(self, y0, y1, density=0.6):
        for y in range(y0, y1 + 1):
            k = (y - y0 + 1) / (y1 - y0 + 1)
            for x in range(self.w):
                c = self.get(x, y)
                if c[3] == 255 and c[:3] != P["ol"][:3] and self.rnd.random() < k * density:
                    self.px(x, y, "dirt1" if self.rnd.random() < 0.6 else "dirt0")

    def rust_patch(self, cx, cy, r, drips=0):
        for y in range(cy - r - 1, cy + r + 2):
            for x in range(cx - r - 2, cx + r + 3):
                if not self.is_paint(x, y):
                    continue
                dist = (((x - cx) / (r + 1.5)) ** 2 + ((y - cy) / (r * 0.8 + 1)) ** 2) ** 0.5 + self.rnd.uniform(-0.25, 0.25)
                if dist < 0.3 and self.rnd.random() < 0.5:
                    self.px(x, y, "r3")
                elif dist < 0.5:
                    self.px(x, y, "r2")
                elif dist < 0.85:
                    self.px(x, y, "r1")
        for _ in range(drips):
            x = cx + self.rnd.randint(-r, r)
            for k in range(self.rnd.randint(2, 5)):
                if self.is_paint(x, cy + r // 2 + k):
                    self.px(x, cy + r // 2 + k, "r1" if k else "r2")

    def outline(self):
        src = self.img.copy()
        for y in range(self.h):
            for x in range(self.w):
                if src.getpixel((x, y))[3] != 255:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if not (0 <= nx < self.w and 0 <= ny < self.h) or src.getpixel((nx, ny))[3] == 0:
                        self.img.putpixel((x, y), P["ol"])
                        break

    def grass(self, clumps, ground, seed=5):
        gr = random.Random(seed)
        for cx, half, peak in clumps:
            for bx in range(cx - half, cx + half + 1):
                if gr.random() < 0.2:
                    continue
                h = max(2, int(peak * (1 - abs(bx - cx) / (half + 1)) ** 0.6) + gr.randint(-1, 1))
                by = ground + gr.randint(-1, 0)
                lean = -1 if bx < cx else 1
                for k in range(h):
                    col = "gr0" if k == 0 else ("gr1" if k < h * 0.45 else gr.choice(["gr2", "gr2", "gr3"]))
                    self.px(bx + (k * lean) // 3, by - k, col)

    def finish(self, shadow_box, path):
        shadow = Image.new("RGBA", (self.w, self.h))
        ImageDraw.Draw(shadow).ellipse(shadow_box, fill=SHADOW)
        out = Image.alpha_composite(shadow, self.img)
        out = out.crop(out.getbbox())
        out.save(path)
        print("size", out.size)
        return out

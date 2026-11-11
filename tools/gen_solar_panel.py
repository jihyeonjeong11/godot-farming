from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "ai_generated" / "solar_panel.png"

W, H = 64, 64

OUTLINE = (20, 21, 35, 255)
SHADOW = (0, 0, 0, 102)
METAL_D = (44, 46, 48, 255)
METAL = (82, 84, 92, 255)
METAL_L = (125, 125, 137, 255)
FRAME_L = (174, 171, 152, 255)
FRAME = (143, 140, 122, 255)
CELL_D = (35, 64, 102, 255)
CELL = (47, 90, 140, 255)
CELL_L = (67, 120, 176, 255)
GLARE = (106, 156, 204, 255)
GLARE_L = (160, 196, 228, 255)
RUST = (74, 59, 41, 255)
RUST_L = (110, 82, 52, 255)
CABLE = (60, 66, 34, 255)
CABLE_L = (96, 104, 52, 255)
LED = (90, 200, 90, 255)
LED_R = (190, 60, 50, 255)

PANEL_TOP, PANEL_BOT = 6, 33
PANEL_L_TOP, PANEL_R_TOP = 7, 56
PANEL_L_BOT, PANEL_R_BOT = 3, 60


def put(img, x, y, c):
    if 0 <= x < W and 0 <= y < H:
        img.putpixel((x, y), c)


def rect(img, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(img, x, y, c)


def panel_span(y):
    t = (y - PANEL_TOP) / (PANEL_BOT - PANEL_TOP)
    l = round(PANEL_L_TOP + (PANEL_L_BOT - PANEL_L_TOP) * t)
    r = round(PANEL_R_TOP + (PANEL_R_BOT - PANEL_R_TOP) * t)
    return l, r


def draw_shadow(img):
    for y in range(57, 63):
        for x in range(4, 61):
            dx = (x - 32) / 29
            dy = (y - 59.5) / 3.2
            if dx * dx + dy * dy <= 1.0:
                put(img, x, y, SHADOW)


def draw_leg(img, x, y0, y1, rusty):
    rect(img, x - 1, y0, x + 2, y1, OUTLINE)
    rect(img, x, y0, x + 1, y1 - 1, METAL)
    for y in range(y0, y1):
        put(img, x, y, METAL_L)
    if rusty:
        for y in (y0 + 5, y0 + 6, y0 + 11):
            put(img, x + 1, y, RUST_L)
            put(img, x, y, RUST)
    rect(img, x - 2, y1 - 1, x + 3, y1 + 1, OUTLINE)
    rect(img, x - 1, y1 - 1, x + 2, y1, METAL_D)


def draw_stand(img):
    draw_leg(img, 11, 33, 58, True)
    draw_leg(img, 51, 33, 58, False)
    for i in range(0, 15):
        x = 13 + i
        y = 38 + i // 2
        put(img, x, y, OUTLINE)
        put(img, x, y + 1, METAL_D)
    rect(img, 12, 44, 51, 46, OUTLINE)
    rect(img, 13, 45, 50, 45, METAL)
    for x in range(13, 51, 6):
        put(img, x, 45, METAL_L)


def draw_panel(img):
    for y in range(PANEL_TOP, PANEL_BOT + 1):
        l, r = panel_span(y)
        for x in range(l, r + 1):
            put(img, x, y, FRAME)
        put(img, l, y, OUTLINE)
        put(img, r, y, OUTLINE)
        put(img, l + 1, y, FRAME_L)
    l, r = panel_span(PANEL_TOP)
    for x in range(l, r + 1):
        put(img, x, PANEL_TOP, OUTLINE)
        put(img, x, PANEL_TOP + 1, FRAME_L)
    l, r = panel_span(PANEL_BOT)
    for x in range(l, r + 1):
        put(img, x, PANEL_BOT, OUTLINE)
    for x in range(l + 1, r):
        put(img, x, PANEL_BOT + 1, METAL_D)
        put(img, x, PANEL_BOT + 2, OUTLINE)
    put(img, l, PANEL_BOT + 1, OUTLINE)
    put(img, r, PANEL_BOT + 1, OUTLINE)

    cols, rows = 5, 3
    in_top, in_bot = PANEL_TOP + 2, PANEL_BOT - 2
    row_h = (in_bot - in_top + 1) / rows
    for y in range(in_top, in_bot + 1):
        l, r = panel_span(y)
        il, ir = l + 2, r - 2
        ry = int((y - in_top) / row_h)
        row_y0 = in_top + round(ry * row_h)
        is_row_gap = y == row_y0 and ry > 0
        col_w = (ir - il + 1) / cols
        bounds = [il + round(k * col_w) for k in range(1, cols)]
        for x in range(il, ir + 1):
            col_x0 = max([il] + [b for b in bounds if b <= x])
            if is_row_gap or x in bounds:
                put(img, x, y, OUTLINE)
                continue
            local_y = y - row_y0
            c = CELL
            if local_y <= 1:
                c = CELL_L
            elif y == in_top + round((ry + 1) * row_h) - 1:
                c = CELL_D
            if (x - col_x0) % 3 == 1 and local_y > 1:
                c = CELL_D if c == CELL else c
            put(img, x, y, c)

    for k in range(14):
        for w in range(3):
            y = in_top + 1 + k
            l, r = panel_span(y)
            x = l + 22 + w - k
            if x <= l + 2:
                continue
            cur = img.getpixel((x, y))
            if cur in (CELL, CELL_L, CELL_D):
                put(img, x, y, GLARE_L if w == 1 else GLARE)
    for k in range(10):
        y = in_top + 4 + k
        l, r = panel_span(y)
        x = l + 36 - k
        cur = img.getpixel((x, y))
        if cur in (CELL, CELL_L, CELL_D):
            put(img, x, y, GLARE)

    for x, y in ((20, 31), (21, 31), (44, 9), (45, 9), (46, 10)):
        cur = img.getpixel((x, y))
        if cur not in (OUTLINE,):
            put(img, x, y, RUST_L)


def draw_battery(img):
    x0, y0, x1, y1 = 38, 46, 56, 58
    rect(img, x0, y0, x1, y1, OUTLINE)
    rect(img, x0 + 1, y0 + 1, x1 - 1, y1 - 1, METAL)
    rect(img, x0 + 1, y0 + 1, x1 - 1, y0 + 3, METAL_L)
    rect(img, x0 + 1, y0 + 4, x1 - 1, y0 + 4, OUTLINE)
    rect(img, x0 + 1, y1 - 1, x1 - 1, y1 - 1, METAL_D)
    for x in (x0 + 3, x1 - 3):
        put(img, x, y0 + 2, METAL_D)
    rect(img, x0 + 3, y0 + 6, x0 + 8, y0 + 9, OUTLINE)
    rect(img, x0 + 4, y0 + 7, x0 + 7, y0 + 8, CELL_D)
    put(img, x0 + 4, y0 + 7, LED)
    put(img, x0 + 5, y0 + 7, LED)
    for y in range(y0 + 6, y0 + 10, 2):
        rect(img, x0 + 11, y, x1 - 3, y, METAL_D)
    put(img, x1 - 2, y0 + 7, LED_R)
    put(img, x0 + 2, y1 - 2, RUST)
    put(img, x0 + 3, y1 - 2, RUST_L)


def draw_cable(img):
    pts = [(48, 35), (48, 36), (47, 37), (46, 38), (45, 39), (45, 40),
           (45, 41), (45, 42), (45, 43), (45, 44), (45, 45)]
    for x, y in pts:
        put(img, x - 1, y, OUTLINE)
        put(img, x + 1, y, OUTLINE)
        put(img, x, y, CABLE_L if y % 2 else CABLE)


def main():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw_shadow(img)
    draw_stand(img)
    draw_panel(img)
    draw_cable(img)
    draw_battery(img)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT)
    print(OUT)


if __name__ == "__main__":
    main()

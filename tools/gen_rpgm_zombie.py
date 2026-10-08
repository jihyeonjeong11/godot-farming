import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "temp", "rpgm_character")
OUT = os.path.join(SRC, "rpgm_zombie_sheet.png")
FRAMES_OUT = os.path.join(SRC, "rpgm_zombie_frames.tres")
SHEET_RES = "res://assets/temp/rpgm_character/rpgm_zombie_sheet.png"
SHEET_UID = "uid://n5i77xwhdurv"
FRAMES_UID = "uid://b1s8hdh7uycg4"

CELL = 64
DIRS = ["left", "down", "up", "right"]
ANIM_DIR = {"left": "left", "down": "front", "up": "back", "right": "right"}
WALK_COLS = 7
ATTACK_COL = 7
DIE_COL = 13
COLS = 17

SKIN = {
    (210, 170, 123): (146, 160, 112),
    (127, 104, 67): (92, 104, 70),
    (128, 104, 67): (92, 104, 70),
}
ROT = (112, 126, 84)
EYE = (214, 36, 36)
SOCKET = (60, 58, 46)
EYES = {
    "down": [(30, 24), (34, 24)],
    "left": [(29, 23)],
    "right": [(34, 23)],
    "up": [],
}
CLOTH = {
    "shirt": (0, {(124, 40, 27): (96, 70, 58), (86, 28, 20): (66, 48, 40)}),
    "pants": (0, {(16, 49, 63): (58, 64, 66), (11, 36, 48): (40, 45, 47)}),
}
BLOOD = (110, 22, 18)


def cell_box(col, row):
    return (col * CELL, row * CELL, col * CELL + CELL, row * CELL + CELL)


def noise(x, y, seed):
    h = (x * 374761393 + y * 668265263 + seed * 2246822519) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    return (h ^ (h >> 16)) % 100


def head_top(cell, x):
    px = cell.load()
    return next(y for y in range(CELL) if px[x, y][3] > 0)


def skin(body):
    out = body.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            p = px[x, y]
            if p[3] == 0 or p[:3] not in SKIN:
                continue
            c = SKIN[p[:3]]
            if p[:3] == (210, 170, 123) and noise(x // 2, y // 2, 1) < 12:
                c = ROT
            px[x, y] = c + (255,)
    return out


def interior(px, x, y, w, h):
    return all(0 <= n[0] < w and 0 <= n[1] < h and px[n][3] > 0
        for n in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))


def cloth(part):
    variant, table = CLOTH[part]
    sheet = Image.open(os.path.join(SRC, "outfits", "%s.png" % part)).convert("RGBA")
    h = len(DIRS) * CELL
    src = sheet.crop((0, variant * h, sheet.width, variant * h + h))
    out = src.copy()
    spx, px = src.load(), out.load()
    seed = 2 if part == "shirt" else 3
    for y in range(out.height):
        for x in range(out.width):
            p = spx[x, y]
            if p[3] == 0:
                continue
            c = table.get(p[:3], p[:3])
            lx, ly = x % CELL, y % CELL
            n = noise(lx // 2, ly // 2, seed)
            if n < 14 and interior(spx, x, y, out.width, out.height):
                px[x, y] = (0, 0, 0, 0)
                continue
            if noise(lx, ly, seed + 10) < 8:
                c = BLOOD
            px[x, y] = c + (255,)
    return out


def eyes(sheet, body):
    px = sheet.load()
    cols = body.width // CELL
    for row, d in enumerate(DIRS):
        idle = body.crop(cell_box(0, row))
        x0, _, x1, _ = idle.getbbox()
        mid = (x0 + x1) // 2
        for col in range(cols):
            dy = head_top(body.crop(cell_box(col, row)), mid) - head_top(idle, mid)
            for ex, ey in EYES[d]:
                gx, gy = col * CELL + ex, row * CELL + ey + dy
                px[gx, gy] = EYE + (255,)
                px[gx, gy + 1] = SOCKET + (255,)


INK = (20, 20, 20)
ARM = (146, 160, 112)
ARM_SHADE = (92, 104, 70)

ARM_CUT = {
    "down": ([(25, 27), (37, 39)], [28, 36], 31, 39, []),
    "up": ([(25, 27), (37, 39)], [28, 36], 31, 39, []),
    "left": ([(35, 37)], [34], 31, 39, [(28, 37), (28, 38)]),
    "right": ([(26, 28)], [29], 31, 39, [(35, 37), (35, 38)]),
}

SIDE_POSES = [
    ((1, 0), (30, 25), (27, 24)),
    ((-2, 0), (25, 32), (24, 30)),
    ((-2, 0), (24, 33), (23, 31)),
    ((-1, 0), (26, 36), (25, 34)),
]

ATTACK = {
    "down": [
        ((0, -1), [((27, 31), (24, 25)), ((37, 31), (40, 25))]),
        ((0, 2), [((27, 31), (29, 35)), ((37, 31), (35, 35))]),
        ((0, 2), [((27, 31), (29, 37)), ((37, 31), (35, 37))]),
        ((0, 1), [((27, 31), (28, 38)), ((37, 31), (36, 38))]),
    ],
    "up": [
        ((0, 1), [((27, 31), (25, 36)), ((37, 31), (39, 36))]),
        ((0, -2), [((27, 31), (28, 25)), ((37, 31), (36, 25))]),
        ((0, -2), [((27, 31), (28, 24)), ((37, 31), (36, 24))]),
        ((0, -1), [((27, 31), (27, 28)), ((37, 31), (37, 28))]),
    ],
    "left": [(s, [((31, 30), f), ((35, 31), n)]) for s, n, f in SIDE_POSES],
    "right": [((-s[0], s[1]), [((32, 30), (63 - f[0], f[1])), ((28, 31), (63 - n[0], n[1]))])
        for s, n, f in SIDE_POSES],
}


def cut_arms(cell, d):
    out = cell.copy()
    px = out.load()
    spans, edges, y0, y1, extra = ARM_CUT[d]
    for y in range(y0, y1 + 1):
        for a, b in spans:
            for x in range(a, b + 1):
                px[x, y] = (0, 0, 0, 0)
        for x in edges:
            if y < y1 and px[x, y][3] > 0:
                px[x, y] = INK + (255,)
    for p in extra:
        px[p] = (0, 0, 0, 0)
    return out


def shifted(cell, offset):
    out = Image.new("RGBA", cell.size)
    out.alpha_composite(cell, (max(offset[0], 0), max(offset[1], 0)),
        (max(-offset[0], 0), max(-offset[1], 0)))
    return out


def arm_layer(shoulder, hand, offset):
    sx, sy = shoulder[0] + offset[0], shoulder[1] + offset[1]
    hx, hy = hand[0] + offset[0], hand[1] + offset[1]
    steps = max(abs(hx - sx), abs(hy - sy), 1)
    flat = abs(hx - sx) >= abs(hy - sy)
    fill = {}
    for i in range(steps + 1):
        x = round(sx + (hx - sx) * i / steps)
        y = round(sy + (hy - sy) * i / steps)
        fill[(x, y)] = ARM
        fill[(x, y + 1) if flat else (x + 1, y)] = ARM_SHADE if flat else ARM
    for dx in (0, 1):
        for dy in (0, 1):
            fill.setdefault((hx + dx, hy + dy), ARM)
    layer = Image.new("RGBA", (CELL, CELL))
    px = layer.load()
    for (x, y) in fill:
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if (nx, ny) not in fill and 0 <= nx < CELL and 0 <= ny < CELL:
                px[nx, ny] = INK + (255,)
    for (x, y), c in fill.items():
        if 0 <= x < CELL and 0 <= y < CELL:
            px[x, y] = c + (255,)
    return layer


def attack_cell(idle, d, pose):
    offset, arms = pose
    body = shifted(cut_arms(idle, d), offset)
    out = Image.new("RGBA", (CELL, CELL))
    if d in ("left", "right"):
        out.alpha_composite(arm_layer(arms[0][0], arms[0][1], offset))
        out.alpha_composite(body)
        out.alpha_composite(arm_layer(arms[1][0], arms[1][1], offset))
        return out
    out.alpha_composite(body)
    for shoulder, hand in arms:
        out.alpha_composite(arm_layer(shoulder, hand, offset))
    if d == "up":
        head = body.crop((0, 0, CELL, 29 + offset[1]))
        out.alpha_composite(head)
    return out


def lying(idle, d, bottom, blood):
    fig = idle.crop(idle.getbbox()).rotate(-90 if d == "right" else 90, expand=True)
    out = Image.new("RGBA", (CELL, CELL))
    x = (CELL - fig.width) // 2
    if blood:
        pool = Image.new("RGBA", (CELL, CELL))
        ppx = pool.load()
        cx, cy, rx, ry = CELL // 2, bottom - 2, fig.width // 2 + 2, 3
        for py in range(cy - ry, cy + ry + 1):
            for qx in range(cx - rx, cx + rx + 1):
                if ((qx - cx) / rx) ** 2 + ((py - cy) / ry) ** 2 <= 1:
                    ppx[qx, py] = BLOOD + (230,)
        out.alpha_composite(pool)
    out.alpha_composite(fig, (x, bottom - fig.height))
    return out


def kneel(idle):
    out = Image.new("RGBA", (CELL, CELL))
    out.alpha_composite(idle.crop((0, 0, CELL, 40)), (0, 4))
    out.alpha_composite(idle.crop((0, 44, CELL, CELL)), (0, 44))
    return out


def extend(base):
    sheet = Image.new("RGBA", (COLS * CELL, len(DIRS) * CELL))
    sheet.alpha_composite(base.crop((0, 0, WALK_COLS * CELL, base.height)))
    for row, d in enumerate(DIRS):
        idle = base.crop(cell_box(0, row))
        cells = [idle] + [attack_cell(idle, d, p) for p in ATTACK[d]] + [idle]
        cells += [kneel(idle), lying(idle, d, 44, False), lying(idle, d, 46, False), lying(idle, d, 46, True)]
        for i, c in enumerate(cells):
            sheet.alpha_composite(c, ((ATTACK_COL + i) * CELL, row * CELL))
    return sheet


ANIMS = [
    ("idle", [0], None, True, 5.0),
    ("walk", [1, 2, 3, 4, 5, 6], None, True, 8.0),
    ("attack", [7, 8, 9, 10, 11, 12], [1, 2, 1, 1.5, 1, 1], False, 10.0),
]


def build_frames():
    subs = []
    anims = []

    def frames_for(row, cols, durs):
        out = []
        for i, col in enumerate(cols):
            key = "r%dc%d" % (row, col)
            if not any(key + '"' in s for s in subs):
                subs.append('[sub_resource type="AtlasTexture" id="AtlasTexture_%s"]\natlas = ExtResource("1_sheet")\nregion = Rect2(%d, %d, %d, %d)\n'
                    % (key, col * CELL, row * CELL, CELL, CELL))
            out.append('{\n"duration": %s,\n"texture": SubResource("AtlasTexture_%s")\n}' % (float(durs[i]) if durs else 1.0, key))
        return out

    for row, d in enumerate(DIRS):
        for act, cols, durs, loop, speed in ANIMS:
            anims.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s_%s",\n"speed": %s\n}'
                % (", ".join(frames_for(row, cols, durs)), "true" if loop else "false", act, ANIM_DIR[d], speed))
    die = frames_for(DIRS.index("down"), [0, 13, 14, 15, 16], [1, 1, 1, 1, 2])
    anims.append('{\n"frames": [%s],\n"loop": false,\n"name": &"die",\n"speed": 8.0\n}' % ", ".join(die))
    text = '[gd_resource type="SpriteFrames" format=3 uid="%s"]\n\n' % FRAMES_UID
    text += '[ext_resource type="Texture2D" uid="%s" path="%s" id="1_sheet"]\n\n' % (SHEET_UID, SHEET_RES)
    text += "\n".join(subs)
    text += "\n[resource]\nanimations = [%s]\n" % ", ".join(anims)
    with open(FRAMES_OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def build():
    body = Image.open(os.path.join(SRC, "rpgm_body_sheet.png")).convert("RGBA")
    sheet = skin(body)
    for part in ("pants", "shirt"):
        sheet.alpha_composite(cloth(part))
    eyes(sheet, body)
    extend(sheet).save(OUT)
    build_frames()


if __name__ == "__main__":
    build()

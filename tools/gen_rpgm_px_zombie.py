import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "temp", "rpgm_character_px")
OUT = os.path.join(SRC, "zombie_sheet.png")
FRAMES_OUT = os.path.join(SRC, "zombie_frames.tres")
SHEET_RES = "res://assets/temp/rpgm_character_px/zombie_sheet.png"

CELL = 64
DIRS = ["left", "down", "up", "right"]
ANIM_DIR = {"left": "left", "down": "front", "up": "back", "right": "right"}
BASE_COLS = 10
DIE_COL = 10
COLS = 14

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
    "left": [(31, 23)],
    "right": [(32, 23)],
    "up": [],
}
CLOTH = {
    "shirt": {(86, 28, 20): (66, 48, 40), (124, 40, 27): (96, 70, 58),
        (135, 46, 32): (96, 70, 58), (201, 54, 32): (120, 88, 72)},
    "pants": {(16, 49, 63): (58, 64, 66)},
}
CLOTH_SEED = {"shirt": 2, "pants": 3}
BLOOD = (110, 22, 18)
INK = (20, 20, 20)
ATTACK_COLS = (7, 8, 9)
BACK_BAG = {(50, 49, 49): (66, 48, 40), INK: (66, 48, 40)}


def cell_box(col, row):
    return (col * CELL, row * CELL, col * CELL + CELL, row * CELL + CELL)


def noise(x, y, seed):
    h = (x * 374761393 + y * 668265263 + seed * 2246822519) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    return (h ^ (h >> 16)) % 100


def layer(name):
    im = Image.open(os.path.join(SRC, name)).convert("RGBA")
    return im.crop((0, 0, BASE_COLS * CELL, len(DIRS) * CELL))


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


def near(x, y):
    return [(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]


def strip_grip(src):
    out = src.copy()
    px = out.load()
    for row in range(len(DIRS)):
        for col in ATTACK_COLS:
            for y in range(row * CELL, row * CELL + CELL):
                for x in range(col * CELL, col * CELL + CELL):
                    if px[x, y][3] and px[x, y][:3] == INK and not any(
                            src.getpixel(n)[3] and src.getpixel(n)[:3] != INK for n in near(x, y)):
                        px[x, y] = (0, 0, 0, 0)
    return out


def back_bag():
    bag = layer("bag.png")
    out = Image.new("RGBA", bag.size)
    row = DIRS.index("up")
    region = bag.crop((0, row * CELL, bag.width, row * CELL + CELL))
    px = region.load()
    for y in range(region.height):
        for x in range(region.width):
            p = px[x, y]
            if p[3]:
                px[x, y] = BACK_BAG.get(p[:3], p[:3]) + (255,)
    out.alpha_composite(region, (0, row * CELL))
    return out


def cloth(part):
    src = strip_grip(layer("outfits/%s.png" % part))
    out = src.copy()
    spx, px = src.load(), out.load()
    table, seed = CLOTH[part], CLOTH_SEED[part]
    for y in range(out.height):
        for x in range(out.width):
            p = spx[x, y]
            if p[3] == 0:
                continue
            c = table.get(p[:3], p[:3])
            lx, ly = x % CELL, y % CELL
            if noise(lx // 2, ly // 2, seed) < 14 and interior(spx, x, y, out.width, out.height):
                px[x, y] = (0, 0, 0, 0)
                continue
            if noise(lx, ly, seed + 10) < 8:
                c = BLOOD
            px[x, y] = c + (255,)
    return out


def eyes(sheet, body):
    px = sheet.load()
    for row, d in enumerate(DIRS):
        idle = body.crop(cell_box(0, row))
        x0, _, x1, _ = idle.getbbox()
        mid = (x0 + x1) // 2
        for col in range(BASE_COLS):
            dy = head_top(body.crop(cell_box(col, row)), mid) - head_top(idle, mid)
            for ex, ey in EYES[d]:
                gx, gy = col * CELL + ex, row * CELL + ey + dy
                px[gx, gy] = EYE + (255,)
                px[gx, gy + 1] = SOCKET + (255,)


def lying(idle, bottom, blood):
    fig = idle.crop(idle.getbbox()).rotate(90, expand=True)
    out = Image.new("RGBA", (CELL, CELL))
    if blood:
        pool = Image.new("RGBA", (CELL, CELL))
        ppx = pool.load()
        cx, cy, rx, ry = CELL // 2, bottom - 2, fig.width // 2 + 2, 3
        for py in range(cy - ry, cy + ry + 1):
            for qx in range(cx - rx, cx + rx + 1):
                if ((qx - cx) / rx) ** 2 + ((py - cy) / ry) ** 2 <= 1:
                    ppx[qx, py] = BLOOD + (230,)
        out.alpha_composite(pool)
    out.alpha_composite(fig, ((CELL - fig.width) // 2, bottom - fig.height))
    return out


def kneel(idle):
    out = Image.new("RGBA", (CELL, CELL))
    out.alpha_composite(idle.crop((0, 0, CELL, 40)), (0, 4))
    out.alpha_composite(idle.crop((0, 44, CELL, CELL)), (0, 44))
    return out


ANIMS = [
    ("idle", [0], None, True, 5.0),
    ("walk", [1, 2, 3, 4, 5, 6], None, True, 8.0),
    ("attack", [0, 7, 8, 9, 9, 0], [1, 2, 1, 1.5, 1, 1], False, 10.0),
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
    die = frames_for(DIRS.index("down"), [0] + list(range(DIE_COL, COLS)), [1, 1, 1, 1, 2])
    anims.append('{\n"frames": [%s],\n"loop": false,\n"name": &"die",\n"speed": 8.0\n}' % ", ".join(die))
    text = '[gd_resource type="SpriteFrames" format=3]\n\n'
    text += '[ext_resource type="Texture2D" path="%s" id="1_sheet"]\n\n' % SHEET_RES
    text += "\n".join(subs)
    text += "\n[resource]\nanimations = [%s]\n" % ", ".join(anims)
    with open(FRAMES_OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def build():
    body = layer("body_naked.png")
    figure = skin(body)
    figure.alpha_composite(layer("outfits/shoes.png"))
    figure.alpha_composite(back_bag())
    for part in ("pants", "shirt"):
        figure.alpha_composite(cloth(part))
    eyes(figure, body)
    sheet = Image.new("RGBA", (COLS * CELL, len(DIRS) * CELL))
    sheet.alpha_composite(layer("shadow.png"))
    sheet.alpha_composite(figure)
    row = DIRS.index("down")
    idle = figure.crop(cell_box(0, row))
    shadow = Image.open(os.path.join(SRC, "shadow.png")).convert("RGBA").crop(cell_box(0, row))
    standing = Image.new("RGBA", (CELL, CELL))
    standing.alpha_composite(shadow)
    standing.alpha_composite(kneel(idle))
    for i, c in enumerate([standing, lying(idle, 46, False), lying(idle, 47, False), lying(idle, 47, True)]):
        sheet.alpha_composite(c, ((DIE_COL + i) * CELL, row * CELL))
    sheet.save(OUT)
    build_frames()


if __name__ == "__main__":
    build()

import os
from PIL import Image, ImageOps

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "temp", "rpgm_character")
OUT = os.path.join(SRC, "outfits")
FRAMES_OUT = os.path.join(ROOT, "scenes", "characters", "player", "rpgm_body_frames.tres")
BODY_RES = "res://assets/temp/rpgm_character/rpgm_body_sheet.png"
FRAMES_UID = "uid://dg4d1sv3fl8jg"
BODY_UID = "uid://cfs7ybi7k406j"

CELL = 64
DIRS = ["left", "down", "up", "right"]

ANIMS = [
    ("idle", [0], None, True, 8.0),
    ("walk", [1, 2, 3, 4, 5, 6], None, True, 10.0),
    ("swing", {"left": [7, 8, 9, 9], "right": [7, 8, 9, 9], "down": [7, 8, 9, 9, 0], "up": [7, 8, 9, 9, 0]},
        {"left": [1, 1, 1.7, 1.3], "right": [1, 1, 1.7, 1.3], "down": [1, 1, 1.7, 1.3, 3], "up": [1, 1, 1.7, 1.3, 3]}, False, 10.0),
    ("water", [7, 8], [1, 4], False, 10.0),
    ("sickle", [7, 8, 9], [1, 1, 2], False, 10.0),
    ("shoot", [0, 0], [0.5, 1], False, 10.0),
]


def hexc(s):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), 255)


OUTFITS = {
    "hair": [
        {},
        {"ece2e2": "9696a0", "323131": "5f5f69", "141414": "14191d"},
        {"ece2e2": "9696a0", "323131": "5f5f69", "141414": "5f5f69", "clip": True},
    ],
    "shirt": [
        {},
        {"561c14": "4e5834", "7c281b": "58623a", "872e20": "645638", "c93620": "7a6c46"},
    ],
    "pants": [
        {},
        {"10313f": "3e5496", "141414": "14191d"},
        {"10313f": "545e3a", "141414": "14191d"},
    ],
    "shoes": [
        {},
        {"141414": "463c36"},
    ],
}


def recolor(src, body, spec):
    out = src.copy()
    table = {hexc(k): hexc(v) for k, v in spec.items() if k != "clip"}
    px = out.load()
    bpx = body.load()
    for y in range(out.height):
        for x in range(out.width):
            p = px[x, y]
            if p[3] == 0:
                continue
            if spec.get("clip") and bpx[x, y][3] == 0:
                px[x, y] = (0, 0, 0, 0)
                continue
            if p in table:
                px[x, y] = table[p]
    return out


INK = (20, 20, 20, 255)
SKIN = (210, 170, 123, 255)
ATTACK_COLS = [7, 8, 9]
ARMS = {
    "down": {
        "erase": [(x, y) for x in range(25, 28) for y in range(31, 40)],
        "seam": [(28, y) for y in range(31, 39)],
        "swing": {7: ((26, 30), (26, 23)), 8: ((27, 29), (28, 18)), 9: ((26, 31), (24, 38))},
    },
    "up": {
        "erase": [(x, y) for x in range(37, 40) for y in range(31, 38)] + [(38, 38), (39, 38)],
        "seam": [(36, y) for y in range(32, 38)],
        "swing": {7: ((37, 30), (37, 23)), 8: ((36, 29), (35, 18)), 9: None},
    },
}
SLEEVES = {"down": lambda x, y: x <= 27 and 31 <= y <= 32, "up": lambda x, y: x >= 37 and 31 <= y <= 32}


def cell_box(col, row):
    return (col * CELL, row * CELL, col * CELL + CELL, row * CELL + CELL)


def arm_mask(start, end):
    mask = set()
    steps = max(abs(end[0] - start[0]), abs(end[1] - start[1]), 1)
    for i in range(steps + 1):
        x = round(start[0] + (end[0] - start[0]) * i / steps)
        y = round(start[1] + (end[1] - start[1]) * i / steps)
        mask.update({(x, y), (x + 1, y)})
    mask.update({(end[0], end[1] - 1), (end[0] + 1, end[1] - 1)})
    return mask


def draw_arm(px, start, end):
    mask = arm_mask(start, end)
    for x, y in mask:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                n = (x + dx, y + dy)
                if n in mask:
                    continue
                if abs(n[0] - start[0]) <= 1 and n[1] >= start[1] - 1 and px[n][3] > 0:
                    continue
                px[n] = INK
    for p in mask:
        px[p] = SKIN


def build_attack_arms():
    path = os.path.join(SRC, "rpgm_body_sheet.png")
    body = Image.open(path).convert("RGBA")
    for d, spec in ARMS.items():
        row = DIRS.index(d)
        for col in ATTACK_COLS:
            cell = body.crop(cell_box(0, row))
            px = cell.load()
            for p in spec["erase"]:
                px[p] = (0, 0, 0, 0)
            for p in spec["seam"]:
                if px[p][3] > 0:
                    px[p] = INK
            if spec["swing"][col]:
                draw_arm(px, *spec["swing"][col])
            body.paste(cell, cell_box(col, row)[:2])
    left, right = DIRS.index("left"), DIRS.index("right")
    for col in ATTACK_COLS:
        body.paste(ImageOps.mirror(body.crop(cell_box(col, left))), cell_box(col, right)[:2])
    body.save(path)


def pad_attack_cols(src, part):
    rows = src.height // CELL
    out = Image.new("RGBA", (CELL * (ATTACK_COLS[-1] + 1), src.height), (0, 0, 0, 0))
    out.paste(src, (0, 0))
    for row in range(rows):
        d = DIRS[row % len(DIRS)]
        cell = src.crop(cell_box(0, row))
        if part == "shirt" and d in SLEEVES:
            px = cell.load()
            for y in range(CELL):
                for x in range(CELL):
                    if SLEEVES[d](x, y):
                        px[x, y] = (0, 0, 0, 0)
        for col in ATTACK_COLS:
            out.paste(cell, cell_box(col, row)[:2])
    return out


def build_outfits():
    os.makedirs(OUT, exist_ok=True)
    body = Image.open(os.path.join(SRC, "rpgm_body_sheet.png")).convert("RGBA")
    for part, variants in OUTFITS.items():
        src = Image.open(os.path.join(SRC, "parts", "rpgm_%s_sheet.png" % part)).convert("RGBA")
        src = pad_attack_cols(src, part)
        sheet = Image.new("RGBA", (src.width, src.height * len(variants)), (0, 0, 0, 0))
        for i, spec in enumerate(variants):
            sheet.alpha_composite(recolor(src, body, spec), (0, i * src.height))
        sheet.save(os.path.join(OUT, "%s.png" % part))


def build_frames():
    subs = []
    anims = []
    seen = {}
    for dir_i, d in enumerate(DIRS):
        for act, cols, durs, loop, speed in ANIMS:
            c = cols[d] if isinstance(cols, dict) else cols
            du = durs[d] if isinstance(durs, dict) else durs
            frames = []
            for i, col in enumerate(c):
                key = "r%dc%d" % (dir_i, col)
                if key not in seen:
                    seen[key] = True
                    subs.append('[sub_resource type="AtlasTexture" id="AtlasTexture_%s"]\natlas = ExtResource("1_body")\nregion = Rect2(%d, %d, %d, %d)\n'
                        % (key, col * CELL, dir_i * CELL, CELL, CELL))
                frames.append('{\n"duration": %s,\n"texture": SubResource("AtlasTexture_%s")\n}' % (float(du[i]) if du else 1.0, key))
            anims.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s_%s",\n"speed": %s\n}'
                % (", ".join(frames), "true" if loop else "false", act, d, speed))
    text = '[gd_resource type="SpriteFrames" format=3 uid="%s"]\n\n' % FRAMES_UID
    text += '[ext_resource type="Texture2D" uid="%s" path="%s" id="1_body"]\n\n' % (BODY_UID, BODY_RES)
    text += "\n".join(subs)
    text += "\n[resource]\nanimations = [%s]\n" % ", ".join(anims)
    with open(FRAMES_OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


if __name__ == "__main__":
    build_attack_arms()
    build_outfits()
    build_frames()

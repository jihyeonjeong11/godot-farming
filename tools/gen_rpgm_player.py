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
        ("7c281b", "561c14"),
        ("58623a", "4e5834"),
    ],
    "pants": [
        ("10313f", "0b2430"),
        ("3e5496", "2f4075"),
        ("545e3a", "40482c"),
    ],
    "shoes": [
        ("141414", "141414"),
        ("463c36", "141414"),
    ],
}

SLEEVE_Y = (29, 32)
TORSO_Y = (33, 37)
LEG_TOP = 38
LEG_MIN_BOTTOM = 42
FOOT_TOP = 44


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


def is_ink(p):
    return p[3] > 0 and p[:3] == INK[:3]


def is_flesh(p):
    return p[3] > 0 and not is_ink(p)


def flood(px, seeds, ok):
    seen = set()
    stack = [q for q in seeds if ok(q)]
    while stack:
        q = stack.pop()
        if q in seen:
            continue
        seen.add(q)
        x, y = q
        for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= n[0] < CELL and 0 <= n[1] < CELL and n not in seen and ok(n):
                stack.append(n)
    return seen


def shirt_mask(px, span):
    x0, x1 = span
    sleeves = {(x, y) for x in range(x0, x1) for y in range(SLEEVE_Y[0], SLEEVE_Y[1] + 1) if is_flesh(px[x, y])}
    in_torso = lambda q: TORSO_Y[0] <= q[1] <= TORSO_Y[1] and is_flesh(px[q])
    mid = (x0 + x1) // 2
    seeds = [(mid + dx, TORSO_Y[0]) for dx in (0, -1, 1, -2, 2)]
    return sleeves | flood(px, seeds, in_torso)


def leg_components(px):
    legs = set()
    seen = set()
    below = lambda q: q[1] >= LEG_TOP and is_flesh(px[q])
    for y in range(LEG_TOP, CELL):
        for x in range(CELL):
            if (x, y) in seen or not below((x, y)):
                continue
            comp = flood(px, [(x, y)], below)
            seen |= comp
            if max(q[1] for q in comp) >= LEG_MIN_BOTTOM:
                legs |= comp
    return legs


def feet_mask(px, legs):
    feet = {(x, y) for x in range(CELL) for y in range(FOOT_TOP, CELL) if is_ink(px[x, y])}
    soles = set()
    for x in {q[0] for q in feet}:
        soles.add((x, max(q[1] for q in feet if q[0] == x)))
    return feet - soles, soles


def paint(cell_px, mask, base, shade, px):
    for q in mask:
        x, y = q
        edge = any(not (0 <= n[0] < CELL) or n not in mask and (px[n][3] == 0 or is_ink(px[n]))
            for n in ((x - 1, y), (x + 1, y)))
        cell_px[q] = shade if edge else base


def outfit_cell(body_cell, part, colors, span):
    px = body_cell.load()
    out = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    opx = out.load()
    base, shade = hexc(colors[0]), hexc(colors[1])
    if part == "shirt":
        paint(opx, shirt_mask(px, span), base, shade, px)
    elif part == "pants":
        paint(opx, leg_components(px), base, shade, px)
    elif part == "shoes":
        top, soles = feet_mask(px, leg_components(px))
        for q in top:
            opx[q] = base
        for q in soles:
            opx[q] = shade
    return out


def body_spans(body):
    return [body.crop(cell_box(0, row)).getbbox()[0::2] for row in range(len(DIRS))]


def head_top(cell, x):
    px = cell.load()
    return next(y for y in range(CELL) if px[x, y][3] > 0)


def hair_sheet(body):
    src = Image.open(os.path.join(SRC, "parts", "rpgm_hair_sheet.png")).convert("RGBA")
    cols = body.width // CELL
    out = Image.new("RGBA", body.size, (0, 0, 0, 0))
    for row in range(len(DIRS)):
        idle_cell = body.crop(cell_box(0, row))
        x0, _, x1, _ = idle_cell.getbbox()
        mid = (x0 + x1) // 2
        idle = idle_cell.load()
        for col in range(cols):
            pose_cell = body.crop(cell_box(col, row))
            dy = head_top(pose_cell, mid) - head_top(idle_cell, mid)
            cell = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
            cell.paste(src.crop(cell_box(0, row)), (0, dy))
            if col in ATTACK_COLS:
                px = cell.load()
                pose = pose_cell.load()
                for y in range(CELL):
                    for x in range(CELL):
                        if pose[x, y][3] > 0 and pose[x, y] != idle[x, y]:
                            px[x, y] = (0, 0, 0, 0)
            out.paste(cell, cell_box(col, row)[:2])
    return out


def build_outfits():
    os.makedirs(OUT, exist_ok=True)
    body = Image.open(os.path.join(SRC, "rpgm_body_sheet.png")).convert("RGBA")
    cols, rows = body.width // CELL, body.height // CELL
    spans = body_spans(body)
    for part, variants in OUTFITS.items():
        sheet = Image.new("RGBA", (body.width, body.height * len(variants)), (0, 0, 0, 0))
        if part == "hair":
            hair = hair_sheet(body)
            for i, spec in enumerate(variants):
                sheet.alpha_composite(recolor(hair, body, spec), (0, i * body.height))
        else:
            for i, colors in enumerate(variants):
                for row in range(rows):
                    for col in range(cols):
                        cell = outfit_cell(body.crop(cell_box(col, row)), part, colors, spans[row])
                        sheet.alpha_composite(cell, (col * CELL, i * body.height + row * CELL))
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

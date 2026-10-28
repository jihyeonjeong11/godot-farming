import os
from PIL import Image, ImageOps

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "temp", "rpgm_character")
OUT = os.path.join(ROOT, "assets", "temp", "rpgm_character_px")

CELL = 64
ROWS = [("left", "side"), ("down", "down"), ("up", "up"), ("right", None)]
LAYOUT = [("idle", [0])] + [("walk", [i]) for i in range(6)] + [("attack", [i]) for i in range(3)] \
    + [("idle", [i]) for i in range(1, 6)] + [("pick up", [i]) for i in range(6)]
LAYERS = ["shadow", "body", "pants", "shoes", "shirt", "bag", "hair", "fx"]


def rgba(*c):
    return tuple(c) if len(c) == 4 else tuple(c) + (255,)


INK = rgba(20, 20, 20)
COLORS = {
    rgba(0, 0, 0, 64): "shadow",
    rgba(210, 170, 123): "body",
    rgba(127, 104, 67): "body",
    rgba(128, 104, 67): "body",
    rgba(16, 49, 63): "pants",
    rgba(86, 28, 20): "shirt",
    rgba(124, 40, 27): "shirt",
    rgba(135, 46, 32): "shirt",
    rgba(201, 54, 32): "shirt",
    rgba(50, 49, 49): "bag",
    rgba(236, 226, 226): "hair",
    rgba(53, 158, 126): "fx",
    rgba(72, 213, 170): "fx",
    rgba(37, 110, 88): "fx",
}
SKIN = rgba(210, 170, 123)
SKIN_SHADE = rgba(127, 104, 67)
HEAD_ABOVE_FACE = 4
SIDE_HEAD_WIDTH = 7
BACK_HEAD = (-4, 3, 10)
NECK_ROWS = 2
OUTFITS = {
    "hair": [{}, {(236, 226, 226): (150, 150, 160), INK[:3]: (20, 25, 29)},
        {(236, 226, 226): (150, 150, 160), INK[:3]: (95, 95, 105)}],
    "shirt": [(86, 28, 20), (78, 88, 52)],
    "pants": [{}, {(16, 49, 63): (62, 84, 150)}, {(16, 49, 63): (84, 94, 58)}],
    "shoes": [{}, {INK[:3]: (70, 60, 54)}],
}
SHOE_TOP = 43
SHOE_BELOW_BELT = 3
BAG_MIN = 8


def neighbors(q):
    x, y = q
    return [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]


def near(q, r=1):
    return [(q[0] + dx, q[1] + dy) for dx in range(-r, r + 1) for dy in range(-r, r + 1) if dx or dy]


def classify(cell, view):
    px = cell.load()
    label = {}
    ink = set()
    for y in range(CELL):
        for x in range(CELL):
            p = px[x, y]
            if p[3] == 0:
                continue
            if p == INK:
                ink.add((x, y))
            elif p in COLORS:
                label[(x, y)] = COLORS[p]
            else:
                raise ValueError("unknown color %s at %s" % (p, (x, y)))
    belt = {q for q in ink if label.get((q[0], q[1] + 1)) == "pants"}
    shoe_top = max(q[1] for q in belt) + SHOE_BELOW_BELT if belt else SHOE_TOP
    for q in ink:
        if q in belt:
            label[q] = "pants"
        elif q[1] >= shoe_top:
            label[q] = "shoes"
        elif any(label.get(n) == "hair" for n in neighbors(q)):
            label[q] = "hair"
    if view == "down":
        for q in ink - set(label):
            label[q] = "bag" if any(label.get(n) == "bag" for n in near(q)) else "shirt"
    rest = ink - set(label)
    while rest:
        comp, stack = set(), [rest.pop()]
        while stack:
            q = stack.pop()
            comp.add(q)
            for n in neighbors(q):
                if n in rest:
                    rest.discard(n)
                    stack.append(n)
        touches_bag = any(label.get(n) == "bag" for q in comp for n in neighbors(q))
        part = "bag" if touches_bag or len(comp) >= BAG_MIN else "shirt"
        for q in comp:
            label[q] = part
    return label


def split(cell, view):
    layers = {name: Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0)) for name in LAYERS}
    px = cell.load()
    for q, part in classify(cell, view).items():
        layers[part].putpixel(q, px[q])
    return layers


def frames(name):
    im = Image.open(os.path.join(SRC, "_%s.png" % name)).convert("RGBA")
    cols = im.width // CELL
    return [im.crop(((i % cols) * CELL, (i // cols) * CELL, (i % cols + 1) * CELL, (i // cols + 1) * CELL))
        for i in range(cols * (im.height // CELL))]


def source_cell(view, anim, i):
    if anim == "pick up":
        return frames(anim)[i] if view == "side" else None
    return frames("%s %s" % (view, anim))[i]


def build():
    os.makedirs(OUT, exist_ok=True)
    size = (len(LAYOUT) * CELL, len(ROWS) * CELL)
    sheets = {name: Image.new("RGBA", size, (0, 0, 0, 0)) for name in LAYERS}
    flat = Image.new("RGBA", size, (0, 0, 0, 0))
    for row, (_, view) in enumerate(ROWS):
        for col, (anim, idx) in enumerate(LAYOUT):
            pos = (col * CELL, row * CELL)
            if view is None:
                mirror_pos = (col * CELL, 0)
                for name in LAYERS:
                    sheets[name].paste(ImageOps.mirror(sheets[name].crop(mirror_pos + (mirror_pos[0] + CELL, CELL))), pos)
                flat.paste(ImageOps.mirror(flat.crop(mirror_pos + (mirror_pos[0] + CELL, CELL))), pos)
                continue
            cell = source_cell(view, anim, idx[0])
            if cell is None:
                continue
            flat.paste(cell, pos)
            for name, layer in split(cell, view).items():
                sheets[name].paste(layer, pos)
    for name, sheet in sheets.items():
        sheet.save(os.path.join(OUT, "%s.png" % name))
    return sheets, flat


def pixels(cell):
    px = cell.load()
    return {(x, y) for y in range(CELL) for x in range(CELL) if px[x, y][3]}


def head_box(cells, view):
    face_line = min(pixels(cells["shirt"]) | {(0, CELL)}, key=lambda q: q[1])[1]
    face = {q for q in pixels(cells["body"]) if q[1] < face_line}
    if view == "up" or not face:
        pants = pixels(cells["pants"])
        cx = round(sum(q[0] for q in pants) / len(pants))
        return cx + BACK_HEAD[0], face_line - BACK_HEAD[2], cx + BACK_HEAD[1], face_line - 1
    xs, ys = [q[0] for q in face], [q[1] for q in face]
    x0 = min(xs) - 1
    x1 = min(xs) + SIDE_HEAD_WIDTH if view == "side" else max(xs) + 1
    return x0, min(ys) - HEAD_ABOVE_FACE, x1, max(ys)


def naked_cell(cells, box, view):
    out = cells["body"].copy()
    px = out.load()
    skin = pixels(cells["body"])
    clothes = pixels(cells["shirt"]) | pixels(cells["pants"]) | pixels(cells["shoes"])
    for q in clothes:
        px[q] = SKIN
    shirt = pixels(cells["shirt"])
    neck = min((q[1] for q in shirt), default=0) + NECK_ROWS
    for q in shirt:
        if q[1] >= neck and any((q[0] + dx, q[1]) in skin for dx in (-1, 1)):
            px[q] = SKIN_SHADE
    solid = skin | clothes
    for q in pixels(cells["bag"]):
        row = [p[0] for p in solid if p[1] == q[1]]
        if view == "up" or row and min(row) < q[0] < max(row):
            px[q] = SKIN
    if box:
        x0, y0, x1, y1 = box
        corners = {(x0, y0), (x1, y0), (x0, y0 + 1), (x1, y0 + 1), (x0 + 1, y0), (x1 - 1, y0)}
        for q in pixels(cells["hair"]) | pixels(cells["bag"]):
            if x0 <= q[0] <= x1 and y0 <= q[1] <= y1 and q not in corners:
                px[q] = SKIN
    return out


def cells_at(sheets, col, row):
    box = (col * CELL, row * CELL, col * CELL + CELL, row * CELL + CELL)
    return {name: sheet.crop(box) for name, sheet in sheets.items()}


def build_naked(sheets):
    naked = Image.new("RGBA", sheets["body"].size, (0, 0, 0, 0))
    for col in range(len(LAYOUT)):
        for row, (_, view) in enumerate(ROWS):
            pos = (col * CELL, row * CELL)
            if view is None:
                naked.paste(ImageOps.mirror(naked.crop((pos[0], 0, pos[0] + CELL, CELL))), pos)
                continue
            cells = cells_at(sheets, col, row)
            if not pixels(cells["pants"]):
                continue
            naked.paste(naked_cell(cells, head_box(cells, view), view), pos)
    naked.save(os.path.join(OUT, "body_naked.png"))
    return naked


def recolor(sheet, spec):
    out = sheet.copy()
    px = out.load()
    table = {k + (255,): v + (255,) for k, v in spec.items()}
    for y in range(out.height):
        for x in range(out.width):
            if px[x, y] in table:
                px[x, y] = table[px[x, y]]
    return out


def shirt_spec(base):
    orig = COLORS_OF("shirt")
    main = (86, 28, 20)
    spec = {c[:3]: tuple(min(255, round(base[i] * c[i] / main[i])) for i in range(3)) for c in orig}
    return spec


def COLORS_OF(part):
    return [c for c, name in COLORS.items() if name == part]


def build_outfits(sheets):
    os.makedirs(os.path.join(OUT, "outfits"), exist_ok=True)
    for part, variants in OUTFITS.items():
        out = Image.new("RGBA", (sheets[part].width, sheets[part].height * len(variants)), (0, 0, 0, 0))
        for i, v in enumerate(variants):
            spec = shirt_spec(v) if part == "shirt" else v
            out.paste(recolor(sheets[part], spec), (0, i * sheets[part].height))
        out.save(os.path.join(OUT, "outfits", "%s.png" % part))


def verify(sheets, flat):
    out = Image.new("RGBA", flat.size, (0, 0, 0, 0))
    for name in LAYERS:
        out.alpha_composite(sheets[name])
    dressed = Image.new("RGBA", flat.size, (0, 0, 0, 0))
    dressed.alpha_composite(sheets["shadow"])
    dressed.alpha_composite(build_naked(sheets))
    for name in LAYERS[2:]:
        dressed.alpha_composite(sheets[name])
    c = dressed.load()
    print("naked + clothes mismatched pixels:", sum(1 for y in range(flat.height) for x in range(flat.width)
        if c[x, y] != flat.load()[x, y] and (c[x, y][3] or flat.load()[x, y][3])))
    a, b = out.load(), flat.load()
    bad = [(x, y) for y in range(flat.height) for x in range(flat.width)
        if a[x, y] != b[x, y] and (a[x, y][3] or b[x, y][3])]
    print("mismatched pixels:", len(bad))
    return not bad


if __name__ == "__main__":
    sheets, flat = build()
    verify(sheets, flat)
    build_outfits(sheets)

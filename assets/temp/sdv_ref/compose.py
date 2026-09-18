import math
from PIL import Image, ImageDraw, ImageFont

SRC = ""
fb = Image.open(SRC + "farmer_base.png").convert("RGBA")
pants = Image.open(SRC + "pants.png").convert("RGBA")
shirts = Image.open(SRC + "shirts.png").convert("RGBA")
hairs = Image.open(SRC + "hairstyles.png").convert("RGBA")
tools = Image.open(SRC + "tools.png").convert("RGBA")

FY = [1,2,2,0,5,6,1,2,2,1, 0,2,0,1,1,0,2,2,3,3, 2,2,1,1,0,0,2,2,4,4, 0,0,1,2,1,1,1,1,0,0,
      1,1,1,0,0,-2,-1,1,1,0, -1,-2,-1,-1,5,4,0,0,3,2, -1,0,4,2,0,0,2,1,0,-1, 1,-2,0,0,1,1,1,1,1,1,
      0,0,0,0,1,-1,-1,-1,-1,1, 1,0,0,0,0,4,1,0,1,2, 1,0,1,0,1,2,-3,-4,-1,0, 0,2,1,-4,-1,0,0,-3,0,0,
      -1,0,0,2,1,1]

SLEEVE = [fb.getpixel((256 + i, 0)) for i in range(3)]
SKIN_DEFAULT = [fb.getpixel((260 + i, 0)) for i in range(3)]

SHIRT_IDX = 8
HAIR_IDX = 0
PANTS_COLOR = (80, 100, 170)
HAIR_COLOR = (210, 140, 60)
HOE_INDEX = 21


def body_rect(frame):
    return (frame % 6 * 16, frame // 6 * 32, 16, 32)


def crop(img, r):
    return img.crop((r[0], r[1], r[0] + r[2], r[1] + r[3]))


def tint(img, color):
    r, g, b = color
    px = img.load()
    out = img.copy()
    o = out.load()
    for y in range(img.height):
        for x in range(img.width):
            pr, pg, pb, pa = px[x, y]
            o[x, y] = (pr * r // 255, pg * g // 255, pb * b // 255, pa)
    return out


def swap_colors(img, mapping):
    out = img.copy()
    o = out.load()
    for y in range(img.height):
        for x in range(img.width):
            c = o[x, y]
            if c in mapping:
                o[x, y] = mapping[c]
    return out


def sleeve_colors(shirt_idx):
    sx, sy = shirt_idx * 8 % 128, shirt_idx * 8 // 128 * 32
    cols = []
    for row in (4, 3, 2):
        dye = shirts.getpixel((sx + 128, sy + row))
        base = shirts.getpixel((sx, sy + row))
        cols.append(dye if dye[3] == 255 else base)
    return cols


def paste(canvas, img, xy):
    layer = Image.new("RGBA", canvas.size)
    layer.paste(img, xy)
    canvas.alpha_composite(layer)


def paste_rotated(canvas, img, origin_xy, target_xy, deg_ccw):
    big = Image.new("RGBA", (img.width * 4, img.height * 4))
    cx, cy = big.width // 2, big.height // 2
    big.paste(img, (cx - origin_xy[0], cy - origin_xy[1]))
    big = big.rotate(deg_ccw, resample=Image.NEAREST, center=(cx, cy))
    paste(canvas, big, (target_xy[0] - cx, target_xy[1] - cy))


def layers_for_frame(frame, facing=2, arm_offset=6):
    fy = FY[frame]
    body = crop(fb, body_rect(frame))
    bx, by, _, _ = body_rect(frame)
    pnt = tint(crop(pants, (bx, by, 16, 32)), PANTS_COLOR)
    sx, sy = SHIRT_IDX * 8 % 128, SHIRT_IDX * 8 // 128 * 32
    sh_off = {2: 0, 1: 8, 0: 24}[facing]
    shirt = crop(shirts, (sx, sy + sh_off, 8, 8))
    hair_off = {2: 0, 1: 32, 0: 64}[facing]
    hair = tint(crop(hairs, (HAIR_IDX * 16 % 128, HAIR_IDX * 16 // 128 * 96 + hair_off, 16, 32)), HAIR_COLOR)
    arm = crop(fb, (bx + arm_offset * 16, by, 16, 32))
    arm = swap_colors(arm, dict(zip(SLEEVE, sleeve_colors(SHIRT_IDX))))
    shirt_pos = {2: (4, 14 + fy), 1: (4, 14 + fy), 0: (4, 14 + fy)}[facing]
    return [
        ("body", body, (0, 0)),
        ("pants", pnt, (0, 0)),
        ("shirt", shirt, shirt_pos),
        ("hair", hair, (0, fy)),
        ("arm", arm, (0, 0)),
    ]


def tool_sprite(index):
    return crop(tools, (index * 16 % 336, index * 16 // 336 * 16, 16, 32))


def tool_down_draw(anim_index):
    idx = HOE_INDEX + (1 if anim_index >= 2 else 0)
    spr = tool_sprite(idx)
    pos = {0: (-5, -29), 1: (-3, -24), 2: (0, -16), 3: (0, -5), 4: (0, -4)}[anim_index]
    rot = {1: 7.5}.get(anim_index, 0.0)
    return spr, pos, rot


def render_frame(frame, anim_index, cell=(32, 56), body_at=(8, 24), with_tool=True, upto=None):
    canvas = Image.new("RGBA", cell)
    bx, by = body_at
    layers = layers_for_frame(frame)
    if with_tool:
        spr, pos, rot = tool_down_draw(anim_index)
        player = (bx, by + 24)
        layers.append(("tool", (spr, (0, 16), (player[0] + pos[0], player[1] + pos[1]), rot), None))
    for i, (name, img, xy) in enumerate(layers):
        if upto is not None and i > upto:
            break
        if name == "tool":
            spr, origin, target, rot = img
            paste_rotated(canvas, spr, origin, target, rot)
        else:
            paste(canvas, img, (bx + xy[0], by + xy[1]))
    return canvas, [l[0] for l in layers]


def zoom(img, s, bg=(52, 52, 52, 255)):
    big = img.resize((img.width * s, img.height * s), Image.NEAREST)
    out = Image.new("RGBA", big.size, bg)
    out.alpha_composite(big)
    return out


font = ImageFont.truetype("C:/Windows/Fonts/malgun.ttf", 14)

SWING = [66, 67, 68, 69, 70]

# 1) layer build-up on the hit frame (68)
S = 6
panels = []
frame = 68
_, names = render_frame(frame, 2)
for i in range(len(names)):
    img, _ = render_frame(frame, 2, upto=i)
    panels.append((names[i], zoom(img, S)))
w = panels[0][1].width
sheet = Image.new("RGBA", ((w + 8) * len(panels) + 8, panels[0][1].height + 40), (30, 30, 30, 255))
d = ImageDraw.Draw(sheet)
labels = {"body": "1 body(몸)", "pants": "2 pants", "shirt": "3 shirt 8x8", "hair": "4 hair", "arm": "5 arm(팔+소매)", "tool": "6 tool 16x32"}
for i, (n, p) in enumerate(panels):
    x = 8 + i * (w + 8)
    sheet.paste(p, (x, 30))
    d.text((x, 8), labels[n], fill=(230, 230, 230), font=font)
sheet.save("02_layer_order.png")

# 2) swing-down strip: parts side by side then composite
S = 5
rows = []
for k, fr in enumerate(SWING):
    body = crop(fb, body_rect(fr))
    arm = crop(fb, (body_rect(fr)[0] + 96, body_rect(fr)[1], 16, 32))
    spr, pos, rot = tool_down_draw(k)
    comp, _ = render_frame(fr, k)
    rows.append((fr, body, arm, spr, pos, rot, comp))
cw = 32 * S
strip = Image.new("RGBA", (8 + 5 * (cw + 8), 8 + 5 * (56 * S + 8) + 30), (30, 30, 30, 255))
d = ImageDraw.Draw(strip)
heads = ["frame", "body col", "arm col+6", "tool", "합성"]
for i, h in enumerate(heads):
    d.text((8 + i * (cw + 8), 8), h, fill=(230, 230, 230), font=font)
for r, (fr, body, arm, spr, pos, rot, comp) in enumerate(rows):
    y = 38 + r * (56 * S + 8)
    cellimg = lambda im: zoom(Image.new("RGBA", (32, 56)).copy(), S)
    c0 = Image.new("RGBA", (32, 56)); d0 = ImageDraw.Draw(c0)
    z0 = zoom(c0, S); ImageDraw.Draw(z0).text((6, 6), f"{fr}\nidx {r}\nfy={FY[fr]}\nrot={rot}", fill=(230, 230, 230), font=font)
    strip.paste(z0, (8, y))
    for i, im in enumerate([body, arm, spr]):
        c = Image.new("RGBA", (32, 56)); c.paste(im, (8, 12))
        strip.paste(zoom(c, S), (8 + (i + 1) * (cw + 8), y))
    strip.paste(zoom(comp, S), (8 + 4 * (cw + 8), y))
strip.save("03_swing_down.png")

# 3) godot temp sheet: 5 swing frames + 4 idle frames, 32x56 cells
IDLE = {2: 0, 1: 6, 0: 12}
sheet = Image.new("RGBA", (32 * 5, 56 * 2))
for k, fr in enumerate(SWING):
    comp, _ = render_frame(fr, k)
    sheet.paste(comp, (k * 32, 0))
for k, (facing, fr) in enumerate(IDLE.items()):
    canvas = Image.new("RGBA", (32, 56))
    for name, img, xy in layers_for_frame(fr, facing):
        paste(canvas, img, (8 + xy[0], 24 + xy[1]))
    sheet.paste(canvas, (k * 32, 56))
sheet.save("sdv_temp_player.png")
zoom(sheet, 4).save("04_temp_sheet_x4.png")
print("done")

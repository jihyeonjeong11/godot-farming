import re
import sys
from PIL import Image

TEX = "assets/apo/32x32_buildings.png"
TRES = "tilesets/shady_sands.tres"
SUB_ID = "TileSetAtlasSource_walls4"
SOURCE_ID = 7
CELL = 32
ALPHA_MIN = 128


def bands_for(col):
    out = []
    if col <= 27:
        out += [(0, 3, 3), (4, 7, 8), (9, 12, 12), (13, 16, 16), (17, 20, 21)]
    elif col <= 39:
        out += [(0, 3, 3), (4, 8, 8), (9, 12, 12), (13, 16, 16), (17, 21, 22)]
    else:
        out += [(0, 3, 3), (4, 7, 8), (9, 12, 13)]
    if col <= 55:
        lc = col % 28
        if lc >= 24:
            out += [(23, 27, 27), (28, 32, 32)]
        else:
            out += [(23, 27, 28), (29, 33, 34)]
            out += [(35, 40, 41)] if 12 <= lc <= 21 else [(35, 39, 40)]
    return out


def rects(mask, w, h):
    runs_prev = {}
    done = []
    for y in range(h):
        runs = []
        x = 0
        while x < w:
            if mask[y][x]:
                x0 = x
                while x < w and mask[y][x]:
                    x += 1
                runs.append((x0, x))
            else:
                x += 1
        cur = {}
        for r in runs:
            if r in runs_prev:
                cur[r] = runs_prev.pop(r)
            else:
                cur[r] = y
        for r, y0 in runs_prev.items():
            done.append((r[0], y0, r[1], y))
        runs_prev = cur
    for r, y0 in runs_prev.items():
        done.append((r[0], y0, r[1], h))
    return done


def build():
    im = Image.open(TEX).convert("RGBA")
    alpha = im.getchannel("A")
    cols = im.width // CELL
    lines = [
        f'[sub_resource type="TileSetAtlasSource" id="{SUB_ID}"]',
        'texture = ExtResource("5_2dgf0")',
        "texture_region_size = Vector2i(32, 32)",
    ]
    tiles = 0
    polys = 0
    for col in range(cols):
        for top, ground, last in bands_for(col):
            body = alpha.crop((col * CELL, top * CELL, col * CELL + CELL, (ground + 1) * CELL))
            if body.point(lambda v: 255 if v >= ALPHA_MIN else 0).getbbox() is None:
                continue
            h = last - top + 1
            anchor_y = (ground - top) * CELL + CELL // 2
            bw, bh = body.size
            px = body.load()
            mask = [[px[x, y] >= ALPHA_MIN for x in range(bw)] for y in range(bh)]
            k = f"{col}:{top}"
            lines += [
                f"{k}/size_in_atlas = Vector2i(1, {h})",
                f"{k}/0 = 0",
                f"{k}/0/texture_origin = Vector2i(0, {anchor_y - h * CELL // 2})",
                f"{k}/0/y_sort_origin = 16",
            ]
            for i, (x0, y0, x1, y1) in enumerate(rects(mask, bw, bh)):
                ax0, ax1 = x0 - 16, x1 - 16
                ay0, ay1 = y0 - anchor_y, y1 - anchor_y
                lines.append(
                    f"{k}/0/physics_layer_0/polygon_{i}/points = PackedVector2Array("
                    f"{ax0}, {ay0}, {ax1}, {ay0}, {ax1}, {ay1}, {ax0}, {ay1})"
                )
                polys += 1
            tiles += 1
    return "\n".join(lines) + "\n\n", tiles, polys


def main():
    block, tiles, polys = build()
    s = open(TRES, encoding="utf-8").read()
    pat = re.compile(rf'\[sub_resource type="TileSetAtlasSource" id="{SUB_ID}"\]\n.*?\n\n', re.S)
    if pat.search(s):
        s = pat.sub(lambda _: block, s, count=1)
    else:
        s = s.replace("[resource]\n", block + "[resource]\n", 1)
    line = f'sources/{SOURCE_ID} = SubResource("{SUB_ID}")\n'
    if line not in s:
        s = s.replace('sources/6 = SubResource("TileSetAtlasSource_decprops_shift")\n',
                      'sources/6 = SubResource("TileSetAtlasSource_decprops_shift")\n' + line, 1)
    if "--write" in sys.argv:
        open(TRES, "w", encoding="utf-8", newline="\n").write(s)
    print(f"tiles={tiles} polygons={polys}")


if __name__ == "__main__":
    main()

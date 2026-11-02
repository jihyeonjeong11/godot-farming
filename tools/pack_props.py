import os
import re
import subprocess
import sys
import numpy as np
from PIL import Image

TRES = "tilesets/shady_sands.tres"
GODOT = "D:/dev/Godot_v4.7.1-stable_mono_win64/Godot_v4.7.1-stable_mono_win64_console.exe"
CELL = 32
SOLID = 128
SHADOW = 8
SMALL_PX = 40
MIN_PX = 12
FLAT_PX = 24
FOOT_PX = 12
PACK_COLS = 32

SHEETS = [
    {
        "src": "assets/apo/32x32_dec_props.png",
        "out": "assets/apo/packed/dec_props_packed.png",
        "sub": "TileSetAtlasSource_decprops_packed",
        "ext_id": "15_decprops_packed",
        "source_id": 13,
        "flat_below_y": None,
        "split": [
            (64, 240, 95, 304),
            (800, 0, 864, 80), (864, 0, 896, 80), (896, 0, 928, 80),
            (800, 224, 864, 304), (864, 224, 896, 304), (896, 224, 928, 304),
            (64, 540, 95, 610),
            (404, 640, 556, 770),
        ],
    },
    {
        "src": "assets/apo/32x32_buildings_furnitures.png",
        "out": "assets/apo/packed/furnitures_packed.png",
        "sub": "TileSetAtlasSource_furniture",
        "ext_id": "14_furniture",
        "source_id": 8,
        "flat_below_y": 1056,
        "split": [
            (576, 0, 607, 128),
            (664, 0, 704, 128),
            (450, 0, 480, 128),
            (576, 136, 608, 248), (608, 136, 640, 248),
            (576, 264, 608, 384), (608, 264, 640, 384),
            (576, 392, 608, 512), (608, 392, 640, 512),
            (128, 640, 160, 830), (160, 640, 256, 830), (256, 640, 385, 740), (385, 640, 460, 740),
            (256, 740, 385, 840),
            (480, 668, 544, 770), (544, 668, 607, 770),
            (746, 870, 782, 922),
            (704, 668, 754, 770),
            (96, 830, 128, 880), (128, 830, 158, 880), (158, 830, 192, 880),
            (192, 830, 222, 880), (222, 830, 256, 880),
            (864, 668, 896, 730), (864, 732, 896, 796),
            (800, 776, 832, 832),
            (800, 832, 831, 912), (831, 832, 864, 912),
            (480, 950, 538, 1056), (538, 950, 577, 1056), (577, 950, 671, 1056), (671, 950, 737, 1056), (737, 950, 831, 1056),
        ],
    },
]


def label(mask, lab, start):
    H, W = mask.shape
    n = start
    for y in range(H):
        for x in np.where(mask[y] & (lab[y] == 0))[0]:
            if lab[y, x]:
                continue
            n += 1
            st = [(x, y)]
            lab[y, x] = n
            while st:
                cx, cy = st.pop()
                for dy in (-1, 0, 1):
                    ny = cy + dy
                    if ny < 0 or ny >= H:
                        continue
                    for dx in (-1, 0, 1):
                        nx = cx + dx
                        if 0 <= nx < W and mask[ny, nx] and not lab[ny, nx]:
                            lab[ny, nx] = n
                            st.append((nx, ny))
    return n


def grow(lab, into, steps):
    for _ in range(steps):
        z = (lab == 0) & into
        if not z.any():
            break
        best = np.zeros_like(lab)
        pad = np.pad(lab, 1)
        H, W = lab.shape
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            sh = pad[1 + dy:1 + dy + H, 1 + dx:1 + dx + W]
            best = np.where((best == 0) & (sh > 0), sh, best)
        new = z & (best > 0)
        if not new.any():
            break
        lab[new] = best[new]


def segment(rgba, splits):
    a = rgba[:, :, 3]
    solid = a >= SOLID
    lab = np.zeros(a.shape, np.int32)
    n = 0
    for x0, y0, x1, y1 in splits:
        n += 1
        region = np.zeros_like(solid)
        region[y0:y1, x0:x1] = True
        lab[region & solid & (lab == 0)] = n
    n = label(solid, lab, n)
    sizes = np.bincount(lab.ravel(), minlength=n + 1)
    small = np.isin(lab, np.where((sizes > 0) & (sizes < SMALL_PX))[0])
    keep = lab.copy()
    keep[small] = 0
    grow(keep, small, 4)
    lab = np.where(small & (keep > 0), keep, lab)
    sizes = np.bincount(lab.ravel(), minlength=n + 1)
    lab[np.isin(lab, np.where(sizes < MIN_PX)[0])] = 0
    grow(lab, (a >= SHADOW) & ~solid, 64)
    return lab


def objects(rgba, lab):
    out = []
    ids = [i for i in np.unique(lab) if i]
    for i in ids:
        ys, xs = np.nonzero(lab == i)
        x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
        img = rgba[y0:y1, x0:x1].copy()
        img[lab[y0:y1, x0:x1] != i] = 0
        out.append({"x": int(x0), "y": int(y0), "img": img})
    out.sort(key=lambda o: (o["y"] // CELL, o["x"]))
    return out


def pack(objs):
    cx = cy = row_h = 0
    for o in objs:
        h, w = o["img"].shape[:2]
        cw, ch = -(-w // CELL), -(-h // CELL)
        if cx + cw > PACK_COLS:
            cx, cy, row_h = 0, cy + row_h, 0
        o["cell"] = (cx, cy, cw, ch)
        cx += cw
        row_h = max(row_h, ch)
    sheet = np.zeros(((cy + row_h) * CELL, PACK_COLS * CELL, 4), np.uint8)
    for o in objs:
        cx, cy, cw, ch = o["cell"]
        h, w = o["img"].shape[:2]
        px = cx * CELL + (cw * CELL - w) // 2
        py = cy * CELL + ch * CELL - h
        sheet[py:py + h, px:px + w] = o["img"]
    return sheet


def tile_lines(sheet, o, flat):
    cx, cy, w, h = o["cell"]
    k = f"{cx}:{cy}"
    lines = []
    if w > 1 or h > 1:
        lines.append(f"{k}/size_in_atlas = Vector2i({w}, {h})")
    lines.append(f"{k}/0 = 0")
    if h > 1:
        lines.append(f"{k}/0/texture_origin = Vector2i(0, {(h - 1) * 16})")
    lines.append(f"{k}/0/y_sort_origin = 16")
    sub = sheet[cy * CELL:(cy + h) * CELL, cx * CELL:(cx + w) * CELL, 3] >= SOLID
    ys = np.where(sub.any(axis=1))[0]
    if flat or len(ys) == 0 or ys[-1] - ys[0] + 1 < FLAT_PX:
        return lines, False
    bottom = ys[-1] + 1
    xs = np.where(sub[bottom - FOOT_PX:bottom].any(axis=0))[0]
    ox, oy = w * 16, h * 32 - 16
    fx0, fx1 = int(xs[0]) - ox, int(xs[-1]) + 1 - ox
    fy0, fy1 = int(bottom - FOOT_PX) - oy, int(bottom) - oy
    lines.append(
        f"{k}/0/physics_layer_1/polygon_0/points = PackedVector2Array("
        f"{fx0}, {fy0}, {fx1}, {fy0}, {fx1}, {fy1}, {fx0}, {fy1})"
    )
    return lines, True


def uid_of(path):
    imp = open(path + ".import", encoding="utf-8").read()
    return re.search(r'uid="(uid://[^"]+)"', imp)[1]


def main():
    write = "--write" in sys.argv
    built = []
    for sh in SHEETS:
        rgba = np.array(Image.open(sh["src"]).convert("RGBA"))
        objs = objects(rgba, segment(rgba, sh["split"]))
        sheet = pack(objs)
        lines, solid = [], 0
        for o in objs:
            flat = sh["flat_below_y"] is not None and o["y"] >= sh["flat_below_y"]
            l, s = tile_lines(sheet, o, flat)
            lines += l
            solid += s
        print(f'{sh["src"]}: objects={len(objs)} solid={solid} sheet={sheet.shape[1]}x{sheet.shape[0]}')
        if write:
            os.makedirs(os.path.dirname(sh["out"]), exist_ok=True)
            Image.fromarray(sheet).save(sh["out"])
        built.append((sh, lines))
    if not write:
        return
    subprocess.run([GODOT, "--headless", "--path", ".", "--import"], capture_output=True)
    s = open(TRES, encoding="utf-8").read()
    for sh, lines in built:
        ext = f'[ext_resource type="Texture2D" uid="{uid_of(sh["out"])}" path="res://{sh["out"]}" id="{sh["ext_id"]}"]'
        s = re.sub(rf'\[ext_resource [^\n]*id="{sh["ext_id"]}"\]\n', "", s)
        j = s.index("\n\n[sub_resource")
        s = s[:j] + "\n" + ext + s[j:]
        head = f'[sub_resource type="TileSetAtlasSource" id="{sh["sub"]}"]\n'
        body = head + f'texture = ExtResource("{sh["ext_id"]}")\ntexture_region_size = Vector2i(32, 32)\n' + "\n".join(lines) + "\n\n"
        pat = re.compile(re.escape(head) + r".*?\n\n", re.S)
        s = pat.sub(lambda _: body, s, count=1) if pat.search(s) else s.replace("[resource]\n", body + "[resource]\n", 1)
        line = f'sources/{sh["source_id"]} = SubResource("{sh["sub"]}")\n'
        if line not in s:
            s = s.replace('sources/7 = SubResource("TileSetAtlasSource_walls4")\n',
                          'sources/7 = SubResource("TileSetAtlasSource_walls4")\n' + line, 1)
    open(TRES, "w", encoding="utf-8", newline="\n").write(s)


if __name__ == "__main__":
    main()

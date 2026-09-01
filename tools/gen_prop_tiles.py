# -*- coding: utf-8 -*-
"""프롭 아틀라스에서 오브젝트를 자동 검출해 TileSet 타일 정의와 GDScript 카탈로그를 생성한다.

아틀라스는 오브젝트가 셀 경계에 안 맞게 빽빽히 들어차 있어서 손으로 찍을 수가 없다.
알파 채널을 8px 블록으로 줄여 연결요소를 찾고, 바운딩박스를 32px 셀에 스냅한다.

  python tools/gen_prop_tiles.py           # 카탈로그만 출력
  python tools/gen_prop_tiles.py --write   # city_ruin.tres 패치 + props_catalog.gd 생성
"""
import sys, os, re
from PIL import Image
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRES = os.path.join(ROOT, 'tilesets', 'city_ruin.tres')
GD   = os.path.join(ROOT, 'scenes', 'test_scenes', 'props_catalog.gd')
CELL_PX = 32
BLOCK = 8          # 세그멘테이션 해상도. 이보다 좁은 틈은 못 가른다.
MAX_CELLS = 20     # 이보다 큰 덩어리는 쓸 게 없다 (아틀라스 배경 통짜 등)
SOLID_MIN_H = 3    # 이보다 낮으면 납작한 잔해로 보고 콜리전을 안 준다

# .tres의 sources/N -> 아틀라스 파일. 순서가 곧 GDScript의 source_id다.
SOURCES = {
    1: ('assets/apo/terrain_props_2.png',  'TileSetAtlasSource_4ochj'),  # 바위
    2: ('assets/apo/terrain_props_1.png',  'TileSetAtlasSource_jersd'),  # 나무/덤불
    3: ('assets/apo/32x32_dec_props.png',  'TileSetAtlasSource_7l7u8'),  # 도시 프롭
}


def segment(path):
    """(atlas_x, atlas_y, w, h, base_w_px) 리스트. 좌표/크기는 32px 셀 단위."""
    im = Image.open(os.path.join(ROOT, path)).convert('RGBA')
    a = np.array(im)[:, :, 3] > 8
    H, W = a.shape
    bh, bw = H // BLOCK, W // BLOCK
    blk = a[:bh * BLOCK, :bw * BLOCK].reshape(bh, BLOCK, bw, BLOCK).any(axis=(1, 3))

    seen = np.zeros_like(blk)
    out = []
    for y in range(bh):
        for x in range(bw):
            if not blk[y, x] or seen[y, x]:
                continue
            stack, cells = [(x, y)], []
            seen[y, x] = True
            while stack:
                cx, cy = stack.pop()
                cells.append((cx, cy))
                for dx, dy in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < bw and 0 <= ny < bh and blk[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        stack.append((nx, ny))
            xs = [c[0] for c in cells]; ys = [c[1] for c in cells]
            px0, py0 = min(xs) * BLOCK, min(ys) * BLOCK
            px1, py1 = (max(xs) + 1) * BLOCK, (max(ys) + 1) * BLOCK
            cx0, cy0 = px0 // CELL_PX, py0 // CELL_PX
            cx1, cy1 = -(-px1 // CELL_PX), -(-py1 // CELL_PX)   # ceil
            w, h = cx1 - cx0, cy1 - cy0
            if w > MAX_CELLS or h > MAX_CELLS:
                continue
            # 밑동 폭 = 스프라이트 최하단 32px 구간의 픽셀 가로 폭. 점유 풋프린트의 근거.
            band = a[max(py0, py1 - CELL_PX):py1, px0:px1]
            cols = np.where(band.sum(0) > 0)[0]
            base_w = int(cols[-1] - cols[0] + 1) if len(cols) else CELL_PX
            out.append((cx0, cy0, w, h, base_w))

    # Godot은 아틀라스에서 타일이 겹치는 걸 거부한다.
    # 작은 것부터 자리를 잡는다 — 스캐터에 쓸모 있는 건 작은 쪽이다.
    out.sort(key=lambda o: o[2] * o[3])
    taken, kept = set(), []
    for (cx, cy, w, h, bw) in out:
        cells = {(cx + i, cy + j) for i in range(w) for j in range(h)}
        if cells & taken:
            continue
        taken |= cells
        kept.append((cx, cy, w, h, bw))
    return sorted(kept, key=lambda o: (o[1], o[0]))


def footprint(w, h, base_w):
    """땅에 닿는 칸수. 3/4 시점이라 스프라이트 크기와 다르다."""
    fw = max(1, min(w, -(-base_w // CELL_PX)))
    fh = 1 if h >= 3 else h          # 서 있는 물건은 밑동 한 줄, 납작한 잔해는 통째로
    return fw, fh


def size_class(w, h):
    area = w * h
    if area <= 6:   return 'small'
    if area <= 40:  return 'medium'
    return 'large'


def foot_polygon(fw, fh):
    """밑동 사각형을 앵커 셀 중앙 기준 좌표로.

    스프라이트는 앵커 셀에 **가로 가운데 정렬**로 그려진다. 그러니 콜리전도 같은 축에
    맞춰야 한다 — 예전엔 x0=-(fw//2) 로 왼쪽에 붙여서 짝수 폭 프롭이 반 칸씩 어긋났다.
    세로는 아래변을 앵커 셀의 아래변에 붙인다. 그게 밑동이다.
    """
    l, r = -fw * CELL_PX // 2, fw * CELL_PX // 2
    b = CELL_PX // 2
    t = b - fh * CELL_PX
    return f"PackedVector2Array({l}, {t}, {r}, {t}, {r}, {b}, {l}, {b})"


def emit_tres_lines(props):
    lines = []
    for (cx, cy, w, h, bw) in props:
        key = f"{cx}:{cy}"
        fw, fh = footprint(w, h, bw)
        lines.append(f"{key}/next_alternative_id = 1")
        if (w, h) != (1, 1):
            lines.append(f"{key}/size_in_atlas = Vector2i({w}, {h})")
        lines.append(f"{key}/0 = 0")
        # 스프라이트를 위로 밀어 밑동을 앵커 셀 바닥에 맞춘다.
        # 멀티셀 타일은 앵커 셀 중앙 기준으로 그려지고, Godot 은 texture_origin 을
        # **빼서** 위치를 잡는다(dest = 셀중앙 - 텍스처크기/2 - texture_origin).
        # 그래서 위로 밀려면 양수다. 음수를 주면 반대로 아래로 밀려서
        # 앵커 셀이 프롭의 꼭대기가 되고, 콜리전이 머리 위에 붙는다.
        if h > 1:
            lines.append(f"{key}/0/texture_origin = Vector2i(0, {(h - 1) * 16})")
        lines.append(f"{key}/0/y_sort_origin = 16")
        # 서 있는 물건만 막는다. 납작한 잔해는 밟고 지나갈 수 있어야 한다.
        if h >= SOLID_MIN_H:
            lines.append(f"{key}/0/physics_layer_0/polygons_count = 1")
            lines.append(f"{key}/0/physics_layer_0/polygon_0/points = {foot_polygon(fw, fh)}")
    return lines


def main():
    write = '--write' in sys.argv
    all_props = {}
    for sid, (path, _) in sorted(SOURCES.items()):
        props = segment(path)
        all_props[sid] = props
        counts = {}
        for p in props:
            counts[size_class(p[2], p[3])] = counts.get(size_class(p[2], p[3]), 0) + 1
        print(f"source {sid}  {os.path.basename(path):24s} {len(props):3d} props  {counts}")
        for (cx, cy, w, h, bw) in props:
            fw, fh = footprint(w, h, bw)
            print(f"    ({cx:3d},{cy:3d}) sprite {w:2d}x{h:2d}  foot {fw}x{fh}  [{size_class(w,h)}]")

    if not write:
        print("\n(--write 를 붙이면 city_ruin.tres 패치 + props_catalog.gd 생성)")
        return

    # --- .tres 패치: 각 아틀라스 sub_resource의 texture_region_size 다음에 타일 정의를 넣는다 ---
    src = open(TRES, encoding='utf-8').read()
    for sid, (_, sub_id) in sorted(SOURCES.items()):
        block_re = re.compile(
            r'(\[sub_resource type="TileSetAtlasSource" id="%s"\]\n'
            r'texture = ExtResource\("[^"]+"\)\n'
            r'texture_region_size = Vector2i\(32, 32\)\n)(.*?)(?=\n\[|\Z)' % re.escape(sub_id),
            re.S)
        m = block_re.search(src)
        if not m:
            raise SystemExit(f"{sub_id} 블록을 못 찾음 — .tres 형식이 바뀌었다")
        body = "\n".join(emit_tres_lines(all_props[sid])) + "\n"
        src = src[:m.start()] + m.group(1) + body + src[m.end():]
    # 프롭 콜리전이 올라갈 물리 레이어. 1번 = 프로젝트의 "Ground",
    # 플레이어 collision_mask(65)가 보는 레이어다.
    if 'physics_layer_0/collision_layer' not in src:
        head = 'tile_size = Vector2i(32, 32)' + chr(10)
        src = src.replace(head, head
                          + 'physics_layer_0/collision_layer = 1' + chr(10)
                          + 'physics_layer_0/collision_mask = 0' + chr(10), 1)
    open(TRES, 'w', encoding='utf-8', newline='\n').write(src)
    print(f"\npatched {TRES}")

    # --- GDScript 카탈로그 ---
    g = ["# 자동 생성 — tools/gen_prop_tiles.py --write 로 재생성한다. 직접 수정하지 말 것.",
         "class_name PropsCatalog", "extends RefCounted", "",
         "# [source_id, atlas_coords, sprite_cells, footprint_cells]", ""]
    for cls in ('small', 'medium', 'large'):
        g.append(f"const {cls.upper()}: Array[Array] = [")
        for sid, props in sorted(all_props.items()):
            for (cx, cy, w, h, bw) in props:
                if size_class(w, h) != cls:
                    continue
                fw, fh = footprint(w, h, bw)
                g.append(f"\t[{sid}, Vector2i({cx}, {cy}), Vector2i({w}, {h}), Vector2i({fw}, {fh})],")
        g.append("]")
        g.append("")
    open(GD, 'w', encoding='utf-8', newline='\n').write("\n".join(g))
    print(f"wrote {GD}")


if __name__ == '__main__':
    main()

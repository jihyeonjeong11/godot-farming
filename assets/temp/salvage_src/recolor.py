import os, sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
DEC_PROPS = os.path.join(HERE, "..", "..", "apo", "32x32_dec_props.png")

PRESETS = {
    "drink_machine": (DEC_PROPS, (1440, 6, 1504, 118), (
        ("#22110f", "#221b15"),
        ("#43201c", "#3b3420"),
        ("#523b32", "#4f4529"),
        ("#763f36", "#7a6a34"),
        ("#83493e", "#8b7a3b"),
        ("#9d5345", "#9c8a43"),
        ("#b88479", "#b9a95f"),
    )),
    "trash_can": (DEC_PROPS, (64, 248, 96, 307), (
        ("#2f3233", "#4f4529"),
        ("#3e4a4c", "#7a6a34"),
        ("#566a71", "#9c8a43"),
        ("#899597", "#b9a95f"),
    )),
}


def hx(s):
    return tuple(int(s[i:i + 2], 16) for i in (1, 3, 5))


src, region, pairs = PRESETS[sys.argv[2]]
recolor = {hx(a): hx(b) for a, b in pairs}
img = Image.open(src).convert("RGBA").crop(region)
px = img.load()
for y in range(img.height):
    for x in range(img.width):
        r, g, b, a = px[x, y]
        if a and (r, g, b) in recolor:
            px[x, y] = recolor[(r, g, b)] + (a,)
img = img.crop(img.getbbox())
img.save(sys.argv[1])
print("size", img.size)

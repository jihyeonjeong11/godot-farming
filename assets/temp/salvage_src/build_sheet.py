import os, subprocess, sys, tempfile
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "salvage_sheet.png")
CELL_W, CELL_H = 160, 128
ENTRIES = [
    ("sedan", ["sedan.py"], ["yellow"]),
    ("curtain", ["curtain.py"], []),
    ("water_cooler", ["water_cooler.py"], []),
    ("vending_machine", ["vending_machine.py"], []),
    ("flower_pot", ["flower_pot.py"], []),
    ("drink_machine", ["recolor.py"], ["drink_machine"]),
    ("trash_can", ["recolor.py"], ["trash_can"]),
]

tmp = tempfile.mkdtemp()
sheet = Image.new("RGBA", (CELL_W * len(ENTRIES), CELL_H))
for i, (name, script, extra) in enumerate(ENTRIES):
    path = os.path.join(tmp, name + ".png")
    subprocess.run([sys.executable, "-W", "ignore", os.path.join(HERE, script[0]), path] + extra,
                   check=True, cwd=HERE, stdout=subprocess.DEVNULL)
    sprite = Image.open(path)
    x = i * CELL_W + (CELL_W - sprite.width) // 2
    y = CELL_H - sprite.height
    sheet.paste(sprite, (x, y))
    print(f"{name}: Rect2({x}, {y}, {sprite.width}, {sprite.height}) offset({-(sprite.width // 2)}, {-sprite.height})")
sheet.save(OUT)

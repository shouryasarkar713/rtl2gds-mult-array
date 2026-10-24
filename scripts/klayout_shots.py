#!/usr/bin/env python3
"""KLayout headless screenshots of the mult_array GDS.

Reproduces exactly what a user sees in the KLayout GUI (same engine, same
SKY130A layer properties file), rendered with KLayout 0.30.7 in batch mode.

Produces:
  1. mult_array_die.png  - whole 150 x 150 um die
  2. mult_array_zoom.png - zoomed view over the densest standard-cell rows,
                           showing cell rows, tap/fill cells and metal routing
"""
import os
import pya

# Portable paths: run this script from the repository root with PDK_ROOT
# pointing at the SKY130 PDK root (IIC-OSIC-TOOLS: /foss/pdks).
#   QT_QPA_PLATFORM=offscreen klayout -b -r scripts/klayout_shots.py
PDK_ROOT = os.environ.get("PDK_ROOT", "/foss/pdks")
LYP_CANDIDATES = [
    os.path.join(PDK_ROOT, "sky130A", "libs.tech", "klayout", "tech", "sky130A.lyp"),
]
# ciel-managed PDK stores keep the same file one level deeper
import glob
LYP_CANDIDATES += glob.glob(os.path.join(
    PDK_ROOT, "ciel", "sky130", "versions", "*", "sky130A",
    "libs.tech", "klayout", "tech", "sky130A.lyp"))
LYP = next((p for p in LYP_CANDIDATES if os.path.isfile(p)), None)
GDS = os.path.join("pnr", "mult_array.gds")
OUT = os.path.join("screenshots")
os.makedirs(OUT, exist_ok=True)

def render(output, x1, y1, x2, y2, width_px, oversampling=2):
    lv = pya.LayoutView()
    lv.set_config("grid-visible", "false")
    lv.set_config("grid-show-ruler", "false")
    lv.set_config("text-visible", "false")
    lv.set_config("background-color", "#FFFFFF")
    lv.load_layout(GDS)
    lv.max_hier()
    if LYP:
        lv.load_layer_props(LYP)
    box = pya.DBox(x1, y1, x2, y2)
    h = max(1, int(width_px * (y2 - y1) / (x2 - x1)))
    lv.save_image_with_options(output, width_px, h, oversampling=oversampling, target=box)
    print("saved", output, f"({width_px}x{h})")

# 1. whole die (150 x 150 um), square
render(os.path.join(OUT, "mult_array_die.png"), 0, 0, 150, 150, 1800)

# 2. zoom: densest 40 x 40 um window (shows std-cell rows + metal wires)
render(os.path.join(OUT, "mult_array_zoom.png"), 55, 55, 95, 95, 1600)

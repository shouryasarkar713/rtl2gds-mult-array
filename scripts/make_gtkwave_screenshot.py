#!/usr/bin/env python3
"""Capture a genuine GTKWave waveform screenshot and add concise latency callouts in the unused bottom area.
"""
import os
from PIL import Image, ImageDraw, ImageFont

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
RAW = os.path.join(REPO_ROOT, "screenshots", "gtkwave_raw.png")
OUT = os.path.join(REPO_ROOT, "screenshots", "waveform_example.png")

im = Image.open(RAW).convert("RGBA")
draw = ImageDraw.Draw(im)

def get_font(size, bold=False):
    candidates = [
        "/usr/share/fonts/google-carlito-fonts/Carlito-Bold.ttf" if bold else "/usr/share/fonts/google-carlito-fonts/Carlito-Regular.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
        "/usr/share/fonts/liberation-sans-fonts/LiberationSans-Bold.ttf" if bold else "/usr/share/fonts/liberation-sans-fonts/LiberationSans-Regular.ttf",
    ]
    for path in candidates:
        if os.path.isfile(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                pass
    return ImageFont.load_default()

font_bold = get_font(16, bold=True)
font_regular = get_font(14, bold=False)

# Marker x coordinates (from GTKWave capture):
xA = 822   # Stimulus at 2718 ns
xB = 943   # Rising Edge 1 at 2725 ns
xC = 1115  # Rising Edge 2 at 2735 ns

y_top = 250  # bottom of signal traces

# 1. Dotted guidelines continuing the markers into the annotation area
for y in range(y_top, 345, 6):
    draw.line([(xA, y), (xA, y + 3)], fill=(253, 224, 71, 160), width=1)
    draw.line([(xB, y), (xB, y + 3)], fill=(255, 255, 255, 180), width=1)
    draw.line([(xC, y), (xC, y + 3)], fill=(248, 113, 113, 200), width=1)

# 2. Callout cards in the blank space
# Box A: Stimulus
boxA = [(xA - 85, 260), (xA + 85, 295)]
draw.rectangle(boxA, fill=(15, 23, 42, 220), outline=(253, 224, 71), width=1)
draw.text((xA, 268), "Stimulus Applied", font=font_bold, fill=(253, 224, 71), anchor="mt")
draw.text((xA, 283), "a=8, b=7  (t = 2718 ns)", font=font_regular, fill=(241, 245, 249), anchor="mt")

# Box B: Edge 1
boxB = [(xB - 85, 305), (xB + 85, 340)]
draw.rectangle(boxB, fill=(15, 23, 42, 220), outline=(56, 189, 248), width=1)
draw.text((xB, 313), "Clock Edge 1", font=font_bold, fill=(56, 189, 248), anchor="mt")
draw.text((xB, 328), "a_reg=8, b_reg=7  (t = 2725 ns)", font=font_regular, fill=(241, 245, 249), anchor="mt")

# Box C: Edge 2
boxC = [(xC - 85, 260), (xC + 95, 295)]
draw.rectangle(boxC, fill=(15, 23, 42, 220), outline=(74, 222, 128), width=1)
draw.text((xC + 5, 268), "Clock Edge 2: Product Valid", font=font_bold, fill=(74, 222, 128), anchor="mt")
draw.text((xC + 5, 283), "p = 56 (hex 0x38)  (t = 2735 ns)", font=font_regular, fill=(241, 245, 249), anchor="mt")

# 3. Two-Cycle Latency Measurement Bracket
y_arrow = 375
# Dimension arrow from xB to xC
draw.line([(xB, y_arrow), (xC, y_arrow)], fill=(255, 255, 255), width=2)
# Arrow heads
draw.polygon([(xB, y_arrow), (xB + 8, y_arrow - 4), (xB + 8, y_arrow + 4)], fill=(255, 255, 255))
draw.polygon([(xC, y_arrow), (xC - 8, y_arrow - 4), (xC - 8, y_arrow + 4)], fill=(255, 255, 255))
# Ticks at xB and xC
draw.line([(xB, y_arrow - 8), (xB, y_arrow + 8)], fill=(255, 255, 255), width=2)
draw.line([(xC, y_arrow - 8), (xC, y_arrow + 8)], fill=(255, 255, 255), width=2)

# Bracket label centered between xB and xC
x_mid = (xB + xC) // 2
draw.rectangle([(x_mid - 140, y_arrow - 20), (x_mid + 140, y_arrow + 32)], fill=(15, 23, 42, 230), outline=(148, 163, 184), width=1)
draw.text((x_mid, y_arrow - 15), "2-CYCLE REGISTERED LATENCY", font=font_bold, fill=(248, 250, 252), anchor="mt")
draw.text((x_mid, y_arrow + 4), "1 Clock Period (10.00 ns) between Edge 1 and Edge 2", font=font_regular, fill=(148, 163, 184), anchor="mt")

# 4. Save final screenshot
im_rgb = im.convert("RGB")
im_rgb.save(OUT, "PNG", optimize=True)
print(f"Saved annotated GTKWave screenshot to {OUT} ({im_rgb.size[0]}x{im_rgb.size[1]})")

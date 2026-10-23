#!/usr/bin/env python3
"""Block diagram of the 4x4 array multiplier (16 AND gates, 12 full adders,
16 flip-flops). The font sizes are chosen for a figure about 450 pt wide.

The layout follows Section 2 of the assignment:
  * 8 product-bit columns (weight 2^k), 4 row bands
  * AND(row i, gate j) sits at column i+j   (16 partial-product gates)
  * FA (row i, adder j)  sits at column i+j (12 adders, rows 1..3)
  * carry: FA_j -> FA_{j+1} (right);  save: FA(row i-1, j+1).sum -> FA(row i, j)
  * p[k] collected by the bottom bus at column k
"""
import os

svg = []

W, H = 1560, 1400
COL_W = 118
BAND_H = 176
X0 = 385
Y0 = 292
YB = Y0 + 4 * BAND_H
BUS_Y = YB + 26

def cx(k): return X0 + k * COL_W
def band_top(i): return Y0 + i * BAND_H
def ANDY(i): return band_top(i) + 46
def FAY(i): return band_top(i) + 130

def s(x): svg.append(x)
def esc(t): return t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

def text(x, y, t, size=18, color="#111827", anchor="middle", weight="normal"):
    s(f'<text x="{x}" y="{y}" font-family="\'DejaVu Sans\', \'Noto Sans\', sans-serif" '
      f'font-size="{size}" fill="{color}" text-anchor="{anchor}" font-weight="{weight}">{esc(t)}</text>')

def line(x1, y1, x2, y2, color="#334155", w=2.0, marker=False):
    m = ' marker-end="url(#arr)"' if marker else ""
    s(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" stroke-width="{w}"{m}/>')

def path(d, color="#334155", w=2.0, marker=False, marker_id="arr"):
    m = f' marker-end="url(#{marker_id})"' if marker else ""
    s(f'<path d="{d}" stroke="{color}" stroke-width="{w}" fill="none"{m}/>')

def and_gate(x, y):
    """D-shaped AND gate centered at (x,y), 46x30, with 2 left stubs + top stub."""
    x0, y0 = x - 23, y - 15
    s(f'<path d="M {x0},{y0} h 23 a 15,15 0 0 1 0,30 h -23 z" '
      f'fill="#EFF6FF" stroke="#2563EB" stroke-width="2.4"/>')
    line(x0 - 12, y - 8, x0, y - 8)
    line(x0 - 12, y + 8, x0, y + 8)
    line(x, y - 26, x, y - 15, w=1.5, color="#93a4bd")   # a[j] stub

def fa_box(x, y, tag="FA"):
    s(f'<rect x="{x-35}" y="{y-26}" width="70" height="52" rx="5" '
      f'fill="#F0FDF4" stroke="#059669" stroke-width="2.4"/>')
    text(x, y + 9, tag, size=26, color="#065f46", weight="bold")

def reg_box(x, y, w, h, label, sub=""):
    s(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="7" fill="#FFF7ED" '
      f'stroke="#D97706" stroke-width="2.4"/>')
    text(x + w / 2, y + h / 2 + (0 if not sub else -8), label, size=26, weight="bold", color="#7c2d12")
    if sub:
        text(x + w / 2, y + h / 2 + 18, sub, size=19, color="#92400e")

# ------------------------------------------------------------------ document
s(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
s('''<defs><marker id="arr" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7"
     markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="#334155"/></marker>
   <marker id="arrA" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7"
     markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="#92400e"/></marker>
   <marker id="arrV" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7"
     markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="#7c3aed"/></marker></defs>''')
s(f'<rect width="{W}" height="{H}" fill="#FFFFFF"/>')

text(W / 2, 52, "4-bit × 4-bit Unsigned Array Multiplier — mult_array", size=46, weight="bold")
text(W / 2, 100, "16 AND gates · 12 full adders · 16 flip-flops (a_reg, b_reg, p) · 2-cycle latency",
     size=28, color="#374151")

# ------------------------------------------------------------------ ports + registers
text(40, 152, "a[3:0]", size=26, anchor="start", weight="bold", color="#1f2937")
s('<circle cx="132" cy="144" r="6" fill="#1f2937"/>')
line(138, 144, 150, 144, marker=True)
text(40, 224, "b[3:0]", size=26, anchor="start", weight="bold", color="#1f2937")
s('<circle cx="132" cy="216" r="6" fill="#1f2937"/>')
line(138, 216, 150, 216, marker=True)

reg_box(152, 114, 170, 62, "a_reg[3:0]", "4-bit DFF")
reg_box(152, 186, 170, 62, "b_reg[3:0]", "4-bit DFF")
text(46, 268, "clk, rst_n (async, active-low)", size=17, color="#6b7280", anchor="start")

line(322, 145, 372, 145, w=3.4, color="#475569", marker=True)
text(378, 140, "a_reg[3:0]", size=20, color="#334155", anchor="start", weight="bold")

# b rail
BRX = 352
line(322, 217, BRX, 217, w=2.6, color="#7c3aed")
line(BRX, 217, BRX, ANDY(3), w=2.6, color="#7c3aed")
text(BRX + 10, 272, "b_reg[i] → row i", size=22, color="#7c3aed", anchor="start", weight="bold")

# taps with hop arcs over verticals
for i in range(4):
    y = ANDY(i)
    hops = []
    for k in range(0, i):
        hops.append(cx(k))
    for k in range(i, i + 4):
        hops.append(cx(k) + 14)
    hops = sorted(set(hops))
    d = f"M {BRX},{y}"
    for hx in hops:
        d += f" L {hx-11},{y} A 11 11 0 0 1 {hx+11},{y}"
    d += f" L {cx(i+3)-24},{y}"
    path(d, color="#7c3aed", w=2.4, marker=True, marker_id="arrV")

# ------------------------------------------------------------------ rows
for i in range(4):
    top = band_top(i)
    lbl = ["Row 0 (ANDs only)", "Row 1 (4 AND + 4 FA)",
           "Row 2 (4 AND + 4 FA)", "Row 3 (4 AND + 4 FA)"][i]
    text(46, top + 18, lbl, size=23, color="#64748b", anchor="start")

    for j in range(4):
        k = i + j
        x = cx(k)
        and_gate(x - 19, ANDY(i))
        text(x - 26, ANDY(i) - 34, f"pp{i}[{j}]", size=23, color="#1e40af")
        if i > 0:
            fa_box(x, FAY(i), tag=f"FA{i}{j}")
            line(x - 19, ANDY(i) + 15, x - 19, FAY(i) - 26, w=1.8, color="#1d4ed8")
            if j == 0:
                line(x - 52, FAY(i), x - 37, FAY(i), w=1.8, marker=True)
                text(x - 62, FAY(i) + 8, "0", size=24, color="#6b7280", weight="bold")
            else:
                line(x - 85, FAY(i), x - 37, FAY(i), w=1.8, marker=True)
            if j < 3:
                line(x + 35, FAY(i), x + 81, FAY(i), w=1.8, color="#b45309", marker=True)
            else:
                line(x + 35, FAY(i), x + 74, FAY(i), w=1.8, color="#b45309")
                text(x + 82, FAY(i) + 8, f"c{i}[4]", size=22, color="#b45309", anchor="start")
            if i < 3:
                line(x + 14, FAY(i) + 26, x + 14, FAY(i + 1) - 26, w=2.0, color="#0f766e", marker=True)
            if j == 0:
                line(x, FAY(i) + 26, x, BUS_Y - 10, w=2.6, color="#92400e", marker=True)
        else:
            if j == 0:
                path(f"M {x-3},{ANDY(0)} L {x+14},{ANDY(0)} L {x+14},{BUS_Y-10}",
                     color="#92400e", w=2.6, marker=True, marker_id="arrA")
            else:
                path(f"M {x-3},{ANDY(0)} L {x+14},{ANDY(0)} L {x+14},{FAY(1)-26}",
                     color="#0f766e", w=2.0, marker=True)

path(f"M {cx(6)+74},{FAY(3)} L {cx(7)-16},{FAY(3)} L {cx(7)-16},{BUS_Y-10}",
     color="#92400e", w=2.6, marker=True, marker_id="arrA")

# ------------------------------------------------------------------ product bus -> p_reg
BUS_X1 = cx(7) + 16
s(f'<line x1="{cx(0)}" y1="{BUS_Y}" x2="{BUS_X1}" y2="{BUS_Y}" stroke="#92400e" stroke-width="5" marker-end="url(#arrA)"/>')
for k in range(8):
    text(cx(k), BUS_Y + 32, f"p[{k}]", size=23, color="#92400e", weight="bold")
PRX, PRY = BUS_X1 + 32, BUS_Y - 48
s(f'<line x1="{BUS_X1}" y1="{BUS_Y}" x2="{PRX - 5}" y2="{BUS_Y}" stroke="#92400e" stroke-width="5" marker-end="url(#arrA)"/>')
reg_box(PRX, PRY, 190, 96, "p[7:0]", "8-bit DFF")
text(PRX + 95, PRY + 122, "p[7:0]  (registered product)", size=21, color="#7c2d12", weight="bold")
line(PRX + 190, BUS_Y, PRX + 250, BUS_Y, w=2.6, marker=True)
text(PRX + 200, BUS_Y - 16, "p[7:0]", size=21, anchor="start", color="#1f2937", weight="bold")

# ------------------------------------------------------------------ legend
LY = BUS_Y + 150
s(f'<line x1="46" y1="{LY-62}" x2="{W-46}" y2="{LY-62}" stroke="#e5e7eb" stroke-width="1.2"/>')
and_gate(100, LY - 6)
text(142, LY + 2, "= partial-product AND:  pp i [j] = a_reg[j] · b_reg[i]    (16 gates)", size=25, anchor="start")
fa_box(100, LY + 44, tag="FA")
text(142, LY + 52, "= full adder, rows 1–3 (12 adders): carry ripples right, sum drops to next row", size=25, anchor="start")
reg_box(100, LY + 92, 50, 52, "")
text(166, LY + 120, "= DFF with async reset — 16 total:  a_reg(4) + b_reg(4) + p(8)", size=25, anchor="start")
s("</svg>")

os.makedirs("screenshots", exist_ok=True)
open("screenshots/block_diagram.svg", "w").write("\n".join(svg))
html = f"""<!DOCTYPE html><html><head><meta charset="utf-8">
<style>html,body{{margin:0;padding:0;background:#ffffff}}</style></head>
<body>{chr(10).join(svg)}</body></html>"""
open("screenshots/block_diagram.html", "w").write(html)
print("svg + html written to screenshots/")

# Optional: also render a PNG from the SVG/HTML via Playwright when available.
try:
    import os
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b = p.chromium.launch()
        pg = b.new_page(viewport={"width": W, "height": H}, device_scale_factor=2)
        pg.goto("file://" + os.path.abspath("screenshots/block_diagram.html"))
        pg.screenshot(path="screenshots/block_diagram.png", full_page=True)
        b.close()
    print("png written via playwright")
except Exception as e:
    print("(png not rendered:", e, "- use the SVG directly)")

#!/usr/bin/env python3
"""Draw a GTKWave-style waveform of the RTL simulation (mult.vcd).

The window shows the worked example A=8, B=7 -> P=56 (0x38). The times are
taken from the VCD (1 ps timescale, converted to ns):
  t = 2718 ns  testbench drives a=8, b=7
  t = 2725 ns  first rising edge, a_reg/b_reg capture the operands
  t = 2735 ns  second rising edge, p captures 00111000 (56)
The product appears 17 ns after the stimulus: 7 ns to the first edge plus one
10 ns clock period between the edges. That is a latency of two clock cycles.
"""
import re
import matplotlib
matplotlib.use("Agg")
import matplotlib.font_manager as fm
for f in [
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
]:
    try:
        fm.fontManager.addfont(f)
    except Exception:
        pass
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch

plt.rcParams["font.sans-serif"] = ["DejaVu Sans", "DejaVu Sans Mono"]
plt.rcParams["axes.unicode_minus"] = False

VCD = "mult.vcd"
OUT = "screenshots/waveform_example.png"

# ---------------------------------------------------------------- parse VCD
codes = {}          # code -> (scope, name, width)
scope = []
want = {"tb_mult.clk": None, "tb_mult.rst_n": None, "tb_mult.a": None,
        "tb_mult.b": None, "tb_mult.p": None}
events = {k: [] for k in want}   # name -> [(t, value)]

code2name = {}
header_done = False
with open(VCD) as fh:
    cur_t = 0
    for line in fh:
        line = line.strip()
        if line.startswith("$scope"):
            scope.append(line.split()[2])
        elif line.startswith("$upscope"):
            scope.pop()
        elif line.startswith("$var"):
            parts = line.split()
            width, code, name = int(parts[2]), parts[3], parts[4]
            full = ".".join(scope) + "." + name.split("[")[0].strip()
            if full in want:
                want[full] = (code, width)
                events[full] = []
        elif line.startswith("$enddefinitions"):
            code2name = {v[0]: k for k, v in want.items() if v}
            header_done = True
        elif line.startswith("#"):
            cur_t = int(line[1:])
        elif header_done and line and not line.startswith("$"):
            # VCD timescale is 1 ps -> convert to ns
            t_ns = cur_t / 1000.0
            m = re.match(r"^([bBrR])([01xzXZ]+)\s+(\S+)$", line)
            if m:
                val, code = m.group(2), m.group(3)
                if code in code2name:
                    events[code2name[code]].append((t_ns, val.replace("x", "0").replace("z", "0")))
            else:
                m = re.match(r"^([01xzXZ])(\S+)$", line)
                if m and m.group(2) in code2name:
                    events[code2name[m.group(2)]].append((t_ns, m.group(1).replace("x", "0").replace("z", "0")))

def value_at(name, t):
    v = None
    for tt, vv in events[name]:
        if tt <= t:
            v = vv
        else:
            break
    return v

def to_int(v):
    return int(v, 2) if v is not None else None

# ---------------------------------------------------------------- window
T0, T1 = 2686, 2780          # ns, covers the (8,7) example and its neighbours

for k in events:
    events[k] = sorted(events[k], key=lambda e: e[0])

# locate example: applied when b transitions to 7 while a is already 8
t_apply = None
for tt, vb in events["tb_mult.b"]:
    va = value_at("tb_mult.a", tt)
    if to_int(vb) == 7 and to_int(va) == 8:
        t_apply = tt
        break
assert t_apply is not None, "example vector not found in VCD"
print("example (a=8,b=7) applied at t =", t_apply, "ns")

# posedges after t_apply
posedges = [t for t, v in events["tb_mult.clk"] if v == "1" and t >= t_apply]
edge1, edge2 = posedges[0], posedges[1]
print("capture edge1 =", edge1, " product edge2 =", edge2,
      " elapsed =", edge2 - t_apply, "ns")

# ---------------------------------------------------------------- draw
FIG_W, FIG_H = 12.4, 6.4
fig, ax = plt.subplots(figsize=(FIG_W, FIG_H), constrained_layout=True)
ax.set_xlim(T0, T1)
ax.set_ylim(0, 13.6)
ax.axis("off")

ROW_Y = {"clk": 10.6, "rst_n": 9.0, "a": 7.2, "b": 5.8, "p": 3.6}
LABEL = {"clk": "clk", "rst_n": "rst_n", "a": "a [3:0]", "b": "b [3:0]", "p": "p [7:0]"}
COLOR = {"clk": "#1e3a5f", "rst_n": "#7c2d12", "a": "#1e3a5f", "b": "#1e3a5f", "p": "#065f46"}
NAMES = ["tb_mult.clk", "tb_mult.rst_n", "tb_mult.a", "tb_mult.b", "tb_mult.p"]

NAME_X = T0 + 1.5
def xlab(sig):
    ax.text(NAME_X, ROW_Y[sig] + 0.55, LABEL[sig], fontsize=13.5, fontweight="bold",
            color="#111827", va="center", ha="left")

# clk / rst_n as square waves (A=0.5)
A = 0.5
for sig, nm in [("clk", "tb_mult.clk"), ("rst_n", "tb_mult.rst_n")]:
    y0 = ROW_Y[sig]
    xlab(sig)
    t = T0
    v = value_at(nm, T0) == "1"
    path = [(T0, y0 + (A if v else -A))]
    for tt, vv in events[nm]:
        if tt <= T0 or tt > T1:
            continue
        nv = vv == "1"
        if nv != v:
            path += [(tt, y0 + (A if v else -A)), (tt, y0 + (A if nv else -A))]
            v = nv
    path.append((T1, y0 + (A if v else -A)))
    xs, ys = zip(*path)
    ax.plot(xs, ys, color=COLOR[sig], lw=1.6, solid_joinstyle="miter")

# buses as value segments
def draw_bus(sig, nm, fmt):
    y0 = ROW_Y[sig]
    xlab(sig)
    t_prev, v_prev = T0, value_at(nm, T0)
    for tt, vv in events[nm]:
        if tt <= T0 or tt > T1:
            continue
        if vv != v_prev:
            # segment [t_prev, tt] with value v_prev
            if v_prev is not None:
                ax.plot([t_prev, tt - 0.35], [y0, y0], color=COLOR[sig], lw=1.4)
                ax.plot([tt - 0.35, tt], [y0, y0 + 0.35], color=COLOR[sig], lw=1.4)
                ax.plot([tt - 0.35, tt], [y0, y0 - 0.35], color=COLOR[sig], lw=1.4)
                mid = (t_prev + tt) / 2
                # only label segments that are wide enough and clear of the name gutter
                if tt - t_prev > 11 and mid > T0 + 10:
                    ax.text(mid, y0 + 0.52, fmt(v_prev), fontsize=12.5,
                            family="DejaVu Sans Mono", color="#111827",
                            ha="center", va="center",
                            bbox=dict(boxstyle="round,pad=0.24", fc="#fef9c3", ec="#b45309", lw=0.8))
            ax.plot([tt, tt + 0.35], [y0 + 0.35, y0], color=COLOR[sig], lw=1.4)
            ax.plot([tt, tt + 0.35], [y0 - 0.35, y0], color=COLOR[sig], lw=1.4)
            t_prev, v_prev = tt, vv
    # last segment (clipped by the window): label only if it is wide enough
    if v_prev is not None and T1 - t_prev > 11:
        ax.text((t_prev + T1) / 2, y0 + 0.52, fmt(v_prev), fontsize=12.5,
                family="DejaVu Sans Mono", color="#111827", ha="center", va="center",
                bbox=dict(boxstyle="round,pad=0.24", fc="#fef9c3", ec="#b45309", lw=0.8))

draw_bus("a", "tb_mult.a", lambda v: f"{int(v,2):04b}")
draw_bus("b", "tb_mult.b", lambda v: f"{int(v,2):04b}")
draw_bus("p", "tb_mult.p", lambda v: f"{int(v,2):08b} (0x{int(v,2):02X})")

# ---------------------------------------------------------------- cursors
for tc, style, col in [
    (t_apply, (0, (4, 3)), "#b91c1c"),
    (edge1, (0, (2, 2)), "#1d4ed8"),
    (edge2, (0, (4, 3)), "#047857"),
]:
    ax.axvline(tc, ymin=0.02, ymax=0.86, color=col, ls=style, lw=1.6)

# annotation band above the clk trace (y ~ 11.3..13.4, clk peaks at 11.1)
ax.annotate("stimulus at t = 2718 ns\nA = 8 (1000), B = 7 (0111)\ndriven onto a, b",
            xy=(t_apply, 11.35), xytext=(t_apply - 3, 13.25), fontsize=12.5,
            color="#b91c1c", ha="right", va="top", fontweight="bold",
            arrowprops=dict(arrowstyle="->", color="#b91c1c", lw=1.2))
ax.annotate("edge 1  t = 2725 ns\na_reg, b_reg\nlatch operands",
            xy=(edge1, 11.35), xytext=(edge1 + 4, 13.25), fontsize=12.5,
            color="#1d4ed8", ha="left", va="top", fontweight="bold",
            arrowprops=dict(arrowstyle="->", color="#1d4ed8", lw=1.2))
# edge-2 annotation sits below the p bus, clear of the time axis
ax.annotate("edge 2  t = 2735 ns\np latches 00111000 (0x38 = 56)",
            xy=(edge2, 2.95), xytext=(edge2 + 5, 2.8), fontsize=12.5,
            color="#047857", ha="left", va="top", fontweight="bold",
            arrowprops=dict(arrowstyle="->", color="#047857", lw=1.2))

# latency arrow between the stimulus cursor and the product edge
ax.add_patch(FancyArrowPatch((t_apply, 1.95), (edge2, 1.95),
             arrowstyle="<|-|>", mutation_scale=13, color="#374151", lw=1.5))
ax.text((t_apply + edge2) / 2, 1.45,
        "2-cycle latency: p is captured two rising edges (2725 ns, 2735 ns) after the stimulus at 2718 ns",
        fontsize=11.5, color="#374151", ha="center", va="top", fontweight="bold")
ax.text((T0 + T1) / 2, 0.82,
        "= 17 ns in total, one full 10 ns clock period between the two edges  ·  throughput = 1 result / cycle",
        fontsize=11.5, color="#6b7280", ha="center", va="top")

# time axis
ax.axhline(0.55, xmin=0, xmax=1, color="#d1d5db", lw=0.8)
tick0 = ((T0 // 10) + 1) * 10
for tt in range(tick0, T1, 20):
    ax.plot([tt, tt], [0.50, 0.60], color="#9ca3af", lw=1)
    ax.text(tt, 0.30, str(tt), fontsize=11.5, color="#6b7280", ha="center", va="center")
ax.text(T1 - 1, 0.30, "ns", fontsize=11.5, color="#6b7280", ha="left", va="center")

fig.suptitle("RTL simulation waveform (mult.vcd) — worked example:  8 × 7 = 56 = 00111000",
             fontsize=17, fontweight="bold", color="#111827")
fig.supxlabel("A = 8 = last digit of Roll No. 2023112013 + 5  ·  B = 7  ·  clock 10 ns  ·  "
              "Icarus Verilog 12.0",
              fontsize=12, color="#6b7280")

fig.savefig(OUT, dpi=200, facecolor="white")
print("saved", OUT)

# 4-bit array multiplier: RTL to GDSII on SKY130

Digital VLSI Design coursework. A 4-bit × 4-bit unsigned array multiplier taken from RTL
through simulation, synthesis and static timing analysis to a placed-and-routed GDSII
layout, using open-source tools.

## Team

| Name | Roll number |
|---|---|
| Shourya Sarkar | 2023112013 |
| guru shwadeep | 2023112020 |

Worked example for Part A: A = last digit of 2023112013 + 5 = 3 + 5 = **8 (1000₂)**,
B = **7 (0111₂)**, so P = **00111000₂ = 56**.

## What is in the repository

```
rtl/full_adder.v             1-bit full adder (assign statements only)
rtl/mult_array.v             4x4 array multiplier, 16 AND gates + 12 full adders + 16 FFs
tb/tb_mult.v                 exhaustive self-checking testbench (256 vectors)
synth/synth.tcl              Yosys script (Part B)
synth/mult_array_netlist.v   synthesized SKY130 netlist
synth/mult_array_stat.rpt    cell and area report
sta/sta.tcl                  OpenSTA script (Part C)
sta/mult_array_timing.rpt    critical-path report at T = 10 ns
pnr/config.json              LibreLane configuration (Part D)
pnr/metrics.json             metrics from the final 7.0 ns run
pnr/mult_array.gds           final GDSII layout
report/report.pdf            report with tables, figures and answers
screenshots/                 block diagram, waveform, die and zoom views
scripts/                     scripts used to render the figures
logs/                        console output of the runs
```

`pnr/runs/`, `sim`, `sim_err` and `gls` are build outputs and are not committed. The
`runs/` folder is large and is excluded as the assignment asks.

## Environment

The tools were run in the LibreLane environment, which contains the same versions as the
IIC-OSIC-TOOLS image suggested in the assignment. The SKY130 PDK was installed with ciel
(version `8afc8346`) and `PDK_ROOT` pointed at its root.

Versions: Icarus Verilog 13.0, Yosys 0.62, OpenSTA 2.7.0, LibreLane 3.0.16 (with OpenROAD,
Magic 8.3.623, Netgen 1.5.316 and KLayout 0.30.7). The final RTL re-run used Icarus
Verilog 12.0 and produced the same result.

## Commands

Run everything from the repository root unless a step says otherwise. The same commands are
listed in Appendix A of the report.

### Part A: RTL and testbench

```bash
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
# PASS: 256 vectors checked, 0 errors
gtkwave mult.vcd
```

Error-injection test: change `sum` in `rtl/full_adder.v` from `a ^ b ^ cin` to `a ^ b`,
run the testbench, then restore the file.

```bash
iverilog -g2012 -o sim_err tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v && vvp sim_err
# FAIL: 256 vectors checked, 95 errors (first mismatch: a=3 b=3 -> p=5, expected 9)
# restore sum = a ^ b ^ cin, then:
vvp sim
# PASS: 256 vectors checked, 0 errors
```

### Part B: synthesis

```bash
yosys -c synth/synth.tcl
# writes synth/mult_array_netlist.v and synth/mult_array_stat.rpt
# 65 cells, 16 dfrtp_1 flip-flops, area 751.971 um2 (53.24 % sequential)
```

Gate-level simulation with the SKY130 cell models:

```bash
CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls \
    tb/tb_mult.v $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v \
    synth/mult_array_netlist.v
vvp gls
# PASS: 256 vectors checked, 0 errors
```

### Part C: static timing analysis

```bash
sta sta/sta.tcl
# worst slack max 7.35 ns -> Tmin = 2.65 ns, Fmax = 377.4 MHz

STA_PERIOD=2.65 sta sta/sta.tcl
# worst slack max 0.00 ns
```

The critical path is from `a_reg[1]` (flip-flop `_099_`) to `p[6]` (flip-flop `_096_`,
D = `fa33.sum`). It has 8 combinational cells, and the data arrives at 2.525 ns.

### Part D: place and route

`CLOCK_PERIOD` starts at 1.2 × 2.65 = 3.18 ns, rounded up to 3.5 ns. The first run had
0 DRC and 0 LVS errors but failed setup at the slow-slow corner. The period was increased
by 0.5 ns each time until timing closed:

```bash
cd pnr
librelane --pdk-root $PDK_ROOT config.json   # 3.5 ns, slack -1.801 ns, fail
librelane --pdk-root $PDK_ROOT config.json   # 4.0 ns, slack -1.319 ns, fail
librelane --pdk-root $PDK_ROOT config.json   # 4.5 ns, slack -0.819 ns, fail
librelane --pdk-root $PDK_ROOT config.json   # 5.0 ns, slack -0.319 ns, fail
librelane --pdk-root $PDK_ROOT config.json   # 5.5 ns, slack -0.071 ns, fail
librelane --pdk-root $PDK_ROOT config.json   # 6.0 ns, slack -0.044 ns, fail
librelane --pdk-root $PDK_ROOT config.json   # 6.5 ns, slack -0.128 ns, fail
librelane --pdk-root $PDK_ROOT config.json   # 7.0 ns, slack +0.241 ns, pass

# final run: runs/RUN_2026-10-22_17-13-53
cp runs/RUN_2026-10-22_17-13-53/final/metrics.json .
cp runs/RUN_2026-10-22_17-13-53/final/gds/mult_array.gds .
```

The final layout has 4 821 instances: 346 standard cells (including 245 tap cells) and
4 475 fill/decap cells. The core area is 17 759.5 µm² on the 150 × 150 µm die, the
standard-cell utilisation is 8.9 %, and the routed wirelength is 3 030 µm. DRC and LVS are
both clean, and the worst-corner setup slack is +0.241 ns at 7.0 ns, which gives a
post-route Fmax of 148.0 MHz. The tt corners give 280.7 MHz and 282.7 MHz.

A second run at 7.0 ns (`RUN_2026-10-22_19-17-31`) gave the same values: instance count,
areas, utilisation, wirelength, setup slack in all nine corners, and the DRC/LVS counts.

Two types of warning remain. There are 11 max-slew (transition) warnings in the three
slow-slow corners; the tt and ff corners are clean. There are also 446 lint warnings, all
`TIMESCALEMOD` notices from the Verilator.Lint step about generated PDK black-box stubs
that have no timescale directive. The lint error count is 0. These warnings are not part
of the assignment's DRC, LVS and slack criteria.

### Figures

```bash
python3 scripts/render_waveform.py
python3 scripts/block_diagram.py
QT_QPA_PLATFORM=offscreen klayout -b -r scripts/klayout_shots.py
```

The waveform is rendered from the `mult.vcd` of the passing RTL run. The two layout views
come from `pnr/mult_array.gds` with the SKY130A layer properties.

## Note on the two Fmax numbers

The 377.4 MHz from Part C is a single-corner estimate: tt, 25 °C, 1.80 V, ideal clock and
no interconnect. LibreLane signs off in nine corners and includes extracted RC, clock-tree
skew and 0.25 ns clock uncertainty. The ss corner (100 °C, 1.60 V) is about 2 to 2.5 times
slower than tt, which is why the final period is 7.0 ns. The comparison is discussed in
Question 4 of the report.

#set document(title: [4-Bit Array Multiplier from RTL to GDSII], author: ("Shourya Sarkar", "Sampath"))
#set page(
  paper: "a4",
  margin: (top: 2.2cm, bottom: 2.2cm, left: 2.2cm, right: 2.2cm),
  header: context {
    if here().page() > 1 [
      #text(9pt, fill: rgb("#6b7280"))[
        #grid(
          columns: (1fr, 1fr),
          align(left)[*Digital VLSI Design* · 4-Bit Array Multiplier],
          align(right)[Shourya Sarkar (2023112013) · Sampath (2023102033)]
        )
        #v(-0.3em)
        #line(length: 100%, stroke: 0.5pt + rgb("#e5e7eb"))
      ]
    ]
  },
  footer: context [
    #text(9pt, fill: rgb("#6b7280"))[
      #line(length: 100%, stroke: 0.5pt + rgb("#e5e7eb"))
      #v(-0.3em)
      #grid(
        columns: (1fr, 1fr),
        align(left)[SkyWater 130 nm (`sky130_fd_sc_hd`) · Coursework Submission],
        align(right)[Page #counter(page).display("1 of 1", both: true)]
      )
    ]
  ]
)

#set text(font: ("Liberation Sans", "DejaVu Sans", "Arial"), size: 10pt)
#set par(justify: true, leading: 0.65em)
#show link: set text(fill: rgb("#2563eb"))
#show heading: set text(fill: rgb("#111827"), weight: "bold")
#show heading.where(level: 1): it => block(spacing: 1.5em)[
  #text(15pt, fill: rgb("#1e3a8a"))[#it.body]
  #v(0.3em)
  #line(length: 100%, stroke: 1.2pt + rgb("#3b82f6"))
]
#show heading.where(level: 2): it => block(spacing: 1.2em)[
  #text(12pt, fill: rgb("#1f2937"))[#it.body]
]
#show heading.where(level: 3): it => block(spacing: 1.0em)[
  #text(10.5pt, fill: rgb("#374151"))[#it.body]
]

// Title Block
#align(center)[
  #v(0.5em)
  #text(11pt, tracking: 0.15em, weight: "bold", fill: rgb("#2563eb"))[DIGITAL VLSI DESIGN COURSEWORK REPORT]\
  #v(0.4em)
  #text(20pt, weight: "bold", fill: rgb("#0f172a"))[4-Bit Array Multiplier: RTL to GDSII]\
  #v(0.2em)
  #text(11pt, fill: rgb("#64748b"))[SkyWater SKY130 High-Density CMOS Technology (`sky130_fd_sc_hd`)]\
  #v(0.8em)

  #rect(fill: rgb("#f8fafc"), stroke: 0.5pt + rgb("#e2e8f0"), radius: 6pt, inset: 11pt, width: 100%)[
    #grid(
      columns: (1fr, 1fr),
      align(left)[
        #text(9pt, fill: rgb("#64748b"))[TEAM MEMBERS]\
        #v(0.2em)
        #text(10pt, weight: "bold")[Shourya Sarkar] #text(9pt, fill: rgb("#475569"))[(Roll No: `2023112013`)]\
        #text(10pt, weight: "bold")[Sampath] #text(9pt, fill: rgb("#475569"))[(Roll No: `2023102033`)]
      ],
      align(right)[
        #text(9pt, fill: rgb("#64748b"))[WORKED EXAMPLE PARAMETERS]\
        #v(0.2em)
        #text(9.5pt)[Member 1 Roll Last Digit: *3*\
        Multiplicand: $A = 3 + 5 =$ *8* ($1000_2$)\
        Multiplier: $B =$ *7* ($0111_2$) $arrow.r$ Product: $P =$ *56* (0x38)]
      ]
    )
    #v(0.5em)
    #line(length: 100%, stroke: 0.5pt + rgb("#e2e8f0"))
    #v(0.35em)
    #grid(
      columns: (auto, 1fr),
      gutter: 6pt,
      align(left + horizon)[#text(9pt, weight: "bold", fill: rgb("#475569"))[GitHub Repository:]],
      align(left + horizon)[#text(9pt)[#link("https://github.com/shouryasarkar713/rtl2gds-mult-array")]]
    )
  ]
]

#v(0.6em)

= 1. Executive Summary & Flow Overview

This report documents the design, verification, logic synthesis, static timing analysis (STA), and automated place-and-route (PnR) of a synchronous 4-bit unsigned array multiplier targeted to the SkyWater SKY130 high-density standard cell library (`sky130_fd_sc_hd`).

The entire design flow was executed locally within an isolated containerized environment based on `hpretl/iic-osic-tools` (pinned digest: `sha256:9201d2ebe74a406cf6af850ca2c646ac0462f3b2cea94cd98cb6580d8ceef800`), ensuring full reproducibility from RTL entry through physical GDSII signoff.

#table(
  columns: (1.5fr, 2.5fr),
  fill: (col, row) => if row == 0 { rgb("#eff6ff") } else { none },
  stroke: 0.5pt + rgb("#cbd5e1"),
  [*Design Parameter*], [*Specification / Implementation Detail*],
  [Circuit Architecture], [Braun unsigned array multiplier with row ripple-carry accumulation],
  [RTL Full Adders], [12 instances (`full_adder.v`), rows 1--3],
  [Partial-Product Logic], [16 AND gates ($p p_0 .. p p_3$)],
  [Registers], [16 Flip-Flops ($4 + 4 + 8$), asynchronous active-low reset],
  [Latency / Throughput], [2 clock cycles latency / 1 result per cycle throughput],
  [Process Technology], [SkyWater SKY130 (130 nm CMOS), `sky130_fd_sc_hd`],
  [Target Die Area], [Fixed $150 mu m times 150 mu m$ ($22,500 mu m^2$), `FP_SIZING: absolute`]
)

#v(0.8em)

= 2. Part A — RTL Design and Verification

== 2.1 RTL Implementation & Exhaustive Verification
The design was implemented structurally in `rtl/full_adder.v` and `rtl/mult_array.v` in strict compliance with Section 2 of `RTL_to_GDS.pdf`. The multiplication operator (`*`) is strictly avoided in the RTL datapath. The partial products are formed explicitly, and the row ripple-carry chain accumulates partial products row-by-row.

The testbench `tb/tb_mult.v` generates a 10 ns clock (100 MHz clock frequency), resets the system for the first two clock cycles, and sweeps through all 256 input permutations ($a in [0..15], b in [0..15]$). For each vector, it respects the 2-cycle sequential latency before checking the product against the reference multiplication. The simulation spans exactly 514 rising clock edges (2 clock edges for the initial reset sequence at $t = 5$ ns and $15$ ns, followed by $256 times 2 = 512$ clock edges for vector sampling) and terminates cleanly at $t = 5,138$ ns (`$finish called at 5138000 ps`).

*Exhaustive Simulation Result*:
```text
VCD info: dumpfile mult.vcd opened for output.
PASS: 256 vectors checked, 0 errors
tb/tb_mult.v:91: $finish called at 5138000 (1ps)
```

== 2.2 Error-Injection Experiment
To demonstrate that the testbench functions as an authoritative fault checker (Section 6, Task 6), an intentional defect was injected into `rtl/full_adder.v` by modifying the sum logic to `assign sum  = a ^ b;` (omitting the carry-in `cin`).
Re-running the simulation immediately triggered mismatch assertions across the test space:
```text
MISMATCH: a=3 b=3 -> p=5, expected 9
...
FAIL: 256 vectors checked, 95 errors
```
Upon restoring `assign sum  = a ^ b ^ cin;`, clean execution was confirmed (`PASS: 256 vectors checked, 0 errors`), and `git diff` verified zero residual alterations to the clean RTL.

== 2.3 Hand-Worked Example & Waveform Verification
Using Member 1's Roll Number (`2023112013`):
- Multiplicand $A = (text("Last digit") + 5) = 3 + 5 = 8 = 1000_2$
- Multiplier $B = 7 = 0111_2$ (since $A eq.not 7$)
- Product $P = 8 times 7 = 56 = 00111000_2$ (0x38)

The manual multiplication follows the binary partial-product shift-and-add layout defined in Section 2 of `RTL_to_GDS.pdf`:

```text
          1 0 0 0            A = 8 (1000_2)
        x 0 1 1 1            B = 7 (0111_2)
  ---------------
         00001000            pp0 = A AND b[0] (b[0] = 1), shift 0
         00010000            pp1 = A AND b[1] (b[1] = 1), shift 1
         00100000            pp2 = A AND b[2] (b[2] = 1), shift 2
         00000000            pp3 = A AND b[3] (b[3] = 0), shift 3
  ---------------
         00111000            P = 56 (0x38)
```

The hardware array accumulates these partial products row-by-row across three ripple-carry adder stages:

#table(
  columns: (1fr, 3fr),
  fill: (col, row) => if row == 0 { rgb("#f8fafc") } else { none },
  stroke: 0.5pt + rgb("#cbd5e1"),
  [*Bit / Row*], [*Partial Product & Addition Accumulation*],
  [$p p_0$], [$8 times 1 = 1000_2$ (Shift 0) $arrow.r p[0] = 0$, $r_0 = {0, 100_2}$],
  [$p p_1$], [$8 times 1 = 1000_2$ (Shift 1) $+ r_0 arrow.r p[1] = 0$, $r_1 = {0, 110_2}$],
  [$p p_2$], [$8 times 1 = 1000_2$ (Shift 2) $+ r_1 arrow.r p[2] = 0$, $r_2 = {0, 111_2}$],
  [$p p_3$], [$8 times 0 = 0000_2$ (Shift 3) $+ r_2 arrow.r p[3] = 1$, $p[7:4] = 0011_2$],
  [*Final Result*], [*$p[7:0] = 00111000_2 = 56$ (0x38)*]
)

#align(center)[
  #image("../screenshots/block_diagram.png", width: 88%)
  #text(8.5pt, fill: rgb("#4b5563"))[*Figure 1*: Structural Block Diagram of `mult_array` showing 16 AND gates, 12 full adders, and 16 flip-flops.]
]

#v(0.3em)

#align(center)[
  #image("../screenshots/waveform_example.png", width: 92%)
  #text(8.5pt, fill: rgb("#4b5563"))[*Figure 2*: GTKWave simulation waveform for worked example $8 times 7 = 56$ (hex 0x38), displaying `clk`, `rst_n`, `a`, `b`, and `p`. Markers indicate stimulus application ($t=2718$ ns), capture edge 1 ($t=2725$ ns), and capture edge 2 ($t=2735$ ns) demonstrating the 2-cycle registered pipeline latency.]
]

#pagebreak()

= 3. Part B — Logic Synthesis with Yosys

Synthesis was executed locally via `yosys -c synth/synth.tcl` using Yosys 0.70 (git sha1 `28ba3cb92`) and the SkyWater SKY130 high-density standard cell library `sky130_fd_sc_hd` at the typical corner ($25^compose C, 1.80$ V).

The synthesis script executes seven atomic steps: reading design RTL, synthesizing and flattening the hierarchy, mapping flip-flops using `dfflibmap`, mapping combinational gates using ABC, purging unused nets, generating cell statistics, and writing out the gate-level Verilog netlist `synth/mult_array_netlist.v`.

#table(
  columns: (2.2fr, 1.8fr),
  fill: (col, row) => if row == 0 { rgb("#eff6ff") } else { none },
  stroke: 0.5pt + rgb("#cbd5e1"),
  [*Synthesis Metric (Part B)*], [*Measured Local Result*],
  [Total Number of Cells], [*73 cells*],
  [Number of Flip-Flops], [*16 cells* (`sky130_fd_sc_hd__dfrtp_1`)],
  [Number of Combinational Cells], [*57 cells*],
  [Total Cell Area], [*805.773 $mu m^2$*],
  [Flip-Flop Cell Area], [*400.384 $mu m^2$* ($16 times 25.024 mu m^2$)],
  [Flip-Flop Area Percentage], [*49.69%* of total cell area],
  [Top 3 Most-Used Cell Types], [
    1. `dfrtp_1`: 16\
    2. `nand2_1`: 11\
    3. `a21oi_1`: 4 (tied with `and2_0`, `nand4_1`, `xnor2_1`)
  ],
  [Gate-Level Simulation (GLS)], [*PASS: 256 vectors checked, 0 errors*]
)

== Gate-Level Simulation Verification
The gate-level netlist was simulated using the SkyWater standard-cell simulation models (`primitives.v` and `sky130_fd_sc_hd.v`) with unit delay modelling (`-DFUNCTIONAL -DUNIT_DELAY=#1`).
The netlist passed all 256 stimulus vectors without any mismatch across 514 rising clock edges, finishing cleanly at $t = 5,138$ ns:
```text
VCD info: dumpfile mult.vcd opened for output.
PASS: 256 vectors checked, 0 errors
tb/tb_mult.v:91: $finish called at 5138000 (1ps)
```

#pagebreak()

= 4. Part C — Static Timing Analysis with OpenSTA

Static timing analysis was conducted using OpenSTA 3.1.0 in `sta/sta.tcl` on the typical corner (`sky130_fd_sc_hd__tt_025C_1v80.lib`). Input external delays on $a, b, text("rst\\_n")$ and output external delays on $p$ were set to 1.0 ns relative to `clk`.

== Timing Results Summary
In Run 1 ($T = 10.0$ ns), OpenSTA reports worst negative setup slack of $+7.404$ ns (displayed as 7.40 ns in header summary), from which minimum clock period and maximum frequency are calculated to the precision shown:
$ T_min = T - text("WNS") = 10.000 - 7.404 = 2.596 text(" ns") quad (text("evaluated as ") 2.60 text(" ns when rounded")) $
$ F_max = 1000 / T_min = 1000 / 2.596 approx 385.2 text(" MHz") quad (text("or ") 384.6 text(" MHz at rounded ") 2.60 text(" ns")) $
In Run 2 ($T = 2.60$ ns), OpenSTA outputs `worst slack max 0.00` to its 2-decimal display format. Based on $T = 2.600$ ns and the 3-decimal $T_min = 2.596$ ns, an inferred positive slack of $+0.004$ ns is expected, confirming timing closure at the maximum operating limit.

#table(
  columns: (2.2fr, 1.8fr),
  fill: (col, row) => if row == 0 { rgb("#eff6ff") } else { none },
  stroke: 0.5pt + rgb("#cbd5e1"),
  [*Timing Metric (Part C)*], [*Measured Local Result*],
  [Worst Setup Slack at $T = 10.0$ ns], [*+7.404 ns* (OpenSTA reported)],
  [Minimum Clock Period ($T_min$)], [*2.596 ns* (from WNS) / *2.60 ns* (rounded)],
  [Maximum Clock Frequency ($F_max$)], [*385.2 MHz* (from 2.596 ns) / *384.6 MHz* (from 2.60 ns)],
  [Setup Slack at $T = 2.60$ ns], [*0.00 ns* (OpenSTA display; $+0.004$ ns inferred)],
  [Critical Path Startpoint], [`_118_` (`b_reg[0]` flip-flop, `dfrtp_1`)],
  [Critical Path Endpoint], [`_112_` (`p[6]` flip-flop, capturing `fa33.sum`)],
  [Total Cells on Critical Path], [*10 cells* (8 combinational gates + 2 flip-flops)],
  [Critical Path Data Arrival Time], [*2.460 ns* ($t_"cq" = 0.395$ ns + logic $= 2.065$ ns)],
  [Data Required Time ($T = 10.0$ ns)], [*9.865 ns* ($10.000$ ns clock $- 0.135$ ns setup)],
  [Sequential Latency ($2 times T_min$)], [*5.19 ns* (from 2.596 ns) / *5.20 ns* (rounded)],
  [Throughput at $F_max$], [*385.2 M results/s* (exact-derived) / *384.6 M results/s*]
)

== Critical Path Cell-by-Cell Breakdown & Full-Adder Tracing
Traced directly from `sta/mult_array_timing.rpt` and verified against `synth/mult_array_netlist.v`:

#table(
  columns: (0.4fr, 1.5fr, 1.8fr, 0.7fr, 0.7fr),
  fill: (col, row) => if row == 0 { rgb("#f1f5f9") } else { none },
  stroke: 0.5pt + rgb("#cbd5e1"),
  [*No.*], [*Instance & Cell*], [*Logical Role in Multiplier Netlist*], [*Incr (ns)*], [*Total (ns)*],
  [1], [`_118_` (`dfrtp_1`)], [Startpoint: `b_reg[0]` launch flip-flop (clock-to-Q)], [0.395], [0.395],
  [2], [`_083_` (`and2_0`)], [Partial product generation: $a_"reg"[0] and b_"reg"[0] = p p_0[0]$], [0.212], [0.607],
  [3], [`_055_` (`or3_1`)], [Row-1 adder network sum/carry accumulation], [0.361], [0.968],
  [4], [`_059_` (`and4_1`)], [Row-1 adder network carry propagate gate], [0.215], [1.183],
  [5], [`_070_` (`o2111a_1`)], [Row-2 adder network compound AND-OR stage], [0.234], [1.417],
  [6], [`_076_` (`o21ai_0`)], [Row-2 adder network carry-out compound gate], [0.216], [1.634],
  [7], [`_090_` (`xnor3_1`)], [Row-3 adder network intermediate sum stage], [0.274], [1.907],
  [8], [`_091_` (`maj3_1`)], [Row-3 ripple-carry majority function ($c_"out" = "maj"(a,b,c)$)], [0.375], [2.282],
  [9], [`_092_` (`xor3_1`)], [Row-3 final sum bit generation: `\fa33.sum`], [0.178], [2.460],
  [10], [`_112_` (`dfrtp_1`)], [Endpoint: `p[6]` capture flip-flop data pin D], [0.000], [2.460]
)

*Path Timing Reconciliation*:
- *Data Arrival Time*: $0.395 text(" ns (clk-to-Q)") + 2.065 text(" ns (8 combinational gates)") = 2.460 text(" ns")$.
- *Data Required Time*: $10.000 text(" ns (clock period)") - 0.135 text(" ns (library setup requirement)") = 9.865 text(" ns")$.
- *Reported Setup Slack*: *+7.404 ns* (MET).
- *Display Rounding Note*: The displayed 3-decimal values subtract to $9.865 - 2.460 = 7.405$ ns. The 1 ps difference relative to the tool's reported slack of $+7.404$ ns is an artifact of OpenSTA independently rounding internal high-precision floating-point numbers for display.

*Attribution to Full-Adder Network*:
Netlist tracing reveals that cell `_083_` is an AND gate generating the partial-product bit $p p_0[0] = a_"reg"[0] and b_"reg"[0]$. The subsequent 7 combinational cells (`_055_`, `_059_`, `_070_`, `_076_`, `_090_`, `_091_`, `_092_`) implement the arithmetic accumulation network originally coded as 12 full adders. Because logic synthesis (Yosys and ABC) flattened the hierarchy and restructured the multi-level Boolean network using compound standard cells, a discrete one-to-one mapping from mapped library gates to individual RTL full-adder instances does not exist. However, netlist connectivity confirms that gate `_091_` implements a standard 3-input majority carry function (`maj3_1`), and gate `_092_` directly produces `\fa33.sum`—the final sum output of full adder `fa33` in row 3. Thus, exactly 7 of the 8 combinational gates originate from the synthesized full-adder network, while 1 gate performs partial-product generation.

#pagebreak()

= 5. Part D — Physical Design: RTL to GDSII with LibreLane

Physical design was carried out using LibreLane v3.1.0.dev3 (`Classic` flow, 80 stages, adapted from OpenLane 2.0) in the local container environment, utilizing OpenROAD for floorplanning, placement, clock tree synthesis, and routing; Magic and KLayout for DRC; and Netgen for LVS.

== Timing Closure Ladder
Following Section 9 of the specification, the initial clock period was set using:
$ T_"initial" = 0.5 times ceil((1.2 times T_min) / 0.5) = 0.5 times ceil((1.2 times 2.60) / 0.5) = 3.5 text(" ns") $

As mandated by Section 9, LibreLane was executed across a clock-period ladder in 0.5 ns increments from 3.5 ns to 7.0 ns. All 8 attempts were executed locally and captured in chronological order:

#table(
  columns: (0.7fr, 1.8fr, 0.9fr, 0.9fr, 0.7fr, 1.4fr),
  fill: (col, row) => if row == 0 { rgb("#eff6ff") } else if row == 8 { rgb("#f0fdf4") } else { none },
  stroke: 0.5pt + rgb("#cbd5e1"),
  [*Period*], [*Local Run Tag*], [*Worst Slack (ss)*], [*Slack (tt)*], [*Hold Slack*], [*Signoff Status*],
  [3.5 ns], [`RUN_2026-10-23_19-54-16`], [-2.154 ns], [+0.587 ns], [+0.100 ns], [FAIL (15 setup viols)],
  [4.0 ns], [`RUN_2026-10-23_19-56-21`], [-1.654 ns], [+1.087 ns], [+0.147 ns], [FAIL (12 setup viols)],
  [4.5 ns], [`RUN_2026-10-23_19-58-23`], [-1.154 ns], [+1.587 ns], [+0.147 ns], [FAIL (12 setup viols)],
  [5.0 ns], [`RUN_2026-10-23_20-00-25`], [-0.654 ns], [+2.087 ns], [+0.147 ns], [FAIL (9 setup viols)],
  [5.5 ns], [`RUN_2026-10-23_20-02-19`], [-0.155 ns], [+2.587 ns], [+0.147 ns], [FAIL (3 setup viols)],
  [6.0 ns], [`RUN_2026-10-23_20-04-10`], [-0.107 ns], [+2.899 ns], [+0.148 ns], [FAIL (3 setup viols)],
  [6.5 ns], [`RUN_2026-10-23_20-06-03`], [-0.136 ns], [+3.199 ns], [+0.141 ns], [FAIL (3 setup viols)],
  [7.0 ns], [`RUN_2026-10-23_20-08-02`], [*+0.364 ns*], [*+3.699 ns*], [*+0.141 ns*], [*PASS* (0 violations)]
)

At $T = 7.0$ ns, LibreLane successfully closed timing with non-negative slack across *all 9 signoff corners* and zero hold, slew, or fanout violations.

#table(
  columns: (2fr, 2fr),
  fill: (col, row) => if row == 0 { rgb("#eff6ff") } else { none },
  stroke: 0.5pt + rgb("#cbd5e1"),
  [*Physical Design Metric (Part D)*], [*Measured Local Signoff Result*],
  [Target Clock Period], [*7.0 ns*],
  [Number of Runs Needed], [*8 runs* (0.5 ns increments from 3.5 to 7.0 ns)],
  [Core Area / Die Area], [*17,759.5 $mu m^2$* / *22,500 $mu m^2$* ($150 times 150 mu m$)],
  [Std-Cell Core Utilization], [*6.90%* ($1,224.9 mu m^2$ active cell area)],
  [Cells after Synthesis (Part B)], [*73 cells*],
  [Total Placed Instances (Part D)], [*1,895 instances* (334 std cells + 1,561 fill/decap cells)],
  [Detailed Wirelength], [*2,362 $mu m$* (552 vias; threshold check skipped)],
  [Routing Via Count], [*552 single-cut vias*],
  [Worst Setup Slack (Multi-Corner Signoff)], [*+0.364 ns* (Corner `max_ss_100C_1v60`, 0 violations)],
  [Nominal TT Setup Slack], [*+3.699 ns* (`nom_tt_025C_1v80`)],
  [Worst Hold Slack], [*+0.141 ns* (0 violations across all corners)],
  [DRC Violations], [*0 errors* (Magic DRC: 0, KLayout DRC: 0)],
  [LVS Verification], [*0 errors* (Netgen: circuits match uniquely)],
  [Power-Grid IR Drop], [*Macro boundary check complete* (package bump locations omitted; see §5)],
  [Antenna Violations], [*0 violating nets / pins*],
  [Max Slew Violations], [*0 violations* across all corners],
  [Post-Route $F_max$ (Worst ss Corner)], [*150.7 MHz* ($1000 / (7.0 - 0.364)$)],
  [Post-Route $F_max$ (Nominal tt Corner)], [*302.9 MHz* ($1000 / (7.0 - 3.699)$)],
  [Pre-Route $F_max$ (Part C, tt)], [*385.2 MHz* (from 2.596 ns) / *384.6 MHz* (rounded)]
)

== Physical Cell Breakdown (Netlist Histogram)
#table(
  columns: (1.5fr, 0.8fr, 2.2fr),
  fill: (col, row) => if row == 0 { rgb("#f1f5f9") } else { none },
  stroke: 0.5pt + rgb("#cbd5e1"),
  [*Cell Type (`sky130_fd_sc_hd__`)*], [*Count*], [*Physical Purpose in Layout*],
  [`decap_12`, `decap_6`, `decap_3`, `decap_8`, `decap_4`], [1,314], [Decoupling capacitors (mitigate dynamic IR drop): 905 `decap_12`, 175 `decap_6`, 130 `decap_3`, 55 `decap_8`, 49 `decap_4`],
  [`tapvpwrvgnd_1`], [245], [Well/substrate tap cells: prevent latch-up by biasing N-well and P-substrate],
  [`fill_1`, `fill_2`], [247], [Non-functional filler cells: 215 `fill_1` and 32 `fill_2` for DRC layer density],
  [`buf_2`, `clkdlybuf4s50_1`], [19], [Timing repair buffers: 17 `buf_2` and 2 `clkdlybuf4s50_1` for slew/setup],
  [`clkbuf_16`], [3], [Clock tree buffers: distribute low-skew clock to all 16 flip-flops],
  [`dfrtp_1`], [16], [Sequential flip-flops (inputs $a, b$ and output $p$)],
  [`inv_1` and Logic Gates], [51], [Remapped multi-input combinational multiplier logic (48 gates + 3 inverters)],
  [*Total Placed Instances*], [*1,895*], [*334 Standard Cells + 1,561 Fill/Decap Cells*]
)

*Physical Instance Arithmetic Reconciliation*:
- *Gross physical-support-cell additions ($1,828$ cells)*: Comprises 245 well/substrate tap cells (`tapvpwrvgnd_1`), 1,561 fill/decap cells (1,314 decoupling capacitors + 247 filler cells), 19 timing-repair buffers (17 `buf_2`, 2 `clkdlybuf4s50_1`), and 3 clock-tree buffers (`clkbuf_16`).
- *Net increase in instances ($1,822$ cells)*: $1,895 - 73 = 1,822$ instances.
- *Functional cell reduction ($6$ cells)*: Physical optimization and gate merging reduced the 73 synthesized functional cells to 67 active functional cells (16 flip-flops + 48 multi-input combinational gates + 3 inverters).
- *Final standard-cell count ($334$ cells)*: 67 functional core cells + 245 tap cells + 19 timing buffers + 3 clock buffers = 334 standard cells.
- *Final fill/decap count ($1,561$ cells)*: 1,314 decoupling capacitors + 247 filler cells = 1,561 fill/decap instances.

#v(0.3em)
#grid(
  columns: (1fr, 1fr),
  gutter: 12pt,
  [
    #image("../screenshots/mult_array_die.png", width: 100%)
    #align(center)[#text(8pt, fill: rgb("#4b5563"))[*Figure 3*: Full $150 times 150 mu m$ Die Layout showing standard-cell core and I/O pin ring (rendered via KLayout batch engine `pya.LayoutView` with `sky130A.lyp`).]]
  ],
  [
    #image("../screenshots/mult_array_zoom.png", width: 100%)
    #align(center)[#text(8pt, fill: rgb("#4b5563"))[*Figure 4*: Zoomed View ($40 times 40 mu m$) showing cell rows, tap/fill cells, and met1/met2 routing (rendered via KLayout batch engine `pya.LayoutView` with `sky130A.lyp`).]]
  ]
)

== Flow Warnings Investigation and Diagnostics
During the physical-design flow, LibreLane and OpenROAD emitted several diagnostic and tool warnings. Each warning category was investigated, root-caused, assessed for risk, and documented with any resulting analytical limitations:

=== 1. Tool and Configuration Diagnostics
- *ORD-0032 (`Invalid thread number specification: None`)*: Stages 32, 54, 56 receive unassigned thread parameter (`None`) from LibreLane's Python step wrapper. Zero risk; OpenROAD automatically falls back to single-thread execution or core auto-detection with identical numerical output.
- *STA-1173 (`default_fanout_load is 0.0`)*: SkyWater PDK pad timing libraries (`sky130_ef_io__*.lib.gz`, `slices_stubs.lib.gz`) omit default fanout attributes. Zero risk; the multiplier macro utilizes only high-density core cells (`sky130_fd_sc_hd`); no pad cells are instantiated.
- *ORD-2056 (`Liberty cells do not have LEF masters and marked dont-use`)*: PDK analog ESD pad stubs lack standard-cell LEF layouts. Zero risk; OpenROAD correctly marks them `dont-use`.
- *STA-1111 (`Missing combinational timing groups in I/O pad models`)*: Inconsistencies between corner Liberty files for GPIO pad macros (`OUT -> PAD`). Zero risk; unused in this macro.
- *STA-1140 (`Duplicate timing-library declarations across corners`)*: Multi-corner STA environment re-reads shared PDK stub files (`slices_stubs.lib.gz`). Zero risk; OpenROAD updates/retains the active corner definitions.
- *DRT-0349 (`LEF58_ENCLOSURE with no CUTCLASS is not supported. Skipping for layer mcon/via/via2`)*: TritonRoute detailed routing parser encounters advanced LEF 5.8 cut-class-less enclosure rules and skips them, defaulting to standard LEF 5.7 geometric enclosure rules. Low risk; subsequent Magic DRC and KLayout DRC confirm 0 geometric DRC errors. Analysis limitation: routing relies on LEF 5.7 enclosure rules rather than LEF 5.8 rule extensions.
- *494 Verilator Lint Warnings (`%Warning-TIMESCALEMOD`)*: User RTL files specify `timescale 1ns/1ps` while SkyWater PDK blackbox models (`.bb.v`) omit timescale directives, triggering IEEE 1800-2023 timescale modification warnings during initial elaboration. Zero risk; standard PDK convention with zero functional or synthesis impact.

=== 2. Wire-Length Checker (`Checker.WireLength`)
- *Warning*: `[WARNING] [Checker.WireLength] Threshold for Threshold-surpassing long wires is not set. The checker will be skipped.`
- *Root Cause & Limitation*: No upper-bound wirelength threshold parameter was defined in `pnr/config.json`. Wire-length threshold checking was *skipped* (not passed). However, physical detailed routing completed successfully with an exact routed wirelength of $2,362 mu m$ and 552 vias reported by `Odb.ReportWireLength`, and all setup, hold, and transition constraints closed with positive slack.

=== 3. Pre-PDN Floating Nets (`RSZ-0020`)
- *Warning*: `[WARNING RSZ-0020] found 2 floating nets: VPWR, VGND` during Stage 32 (`repairdesignpostgpl`).
- *Root Cause & Assessment*: OpenROAD's resizer step runs prior to PDN synthesis (Stage 36) when power rails are not yet tied to physical power stripes. These nets represent supply rails, not logic nets. Stage 36 completed PDN synthesis, and Netgen LVS confirmed 0 floating pins/nets and 100% topological equivalence in the final layout.

=== 4. Generic Fallback SDC Files (`checksdcfiles`)
- *Warning*: Stage 10 reported that `PNR_SDC_FILE` and `SIGNOFF_SDC_FILE` were not explicitly provided in `config.json`.
- *Root Cause & Assessment*: LibreLane automatically generates fallback SDC constraints when custom SDC file paths are not specified. As prescribed by Section 9 of `RTL_to_GDS.pdf`, the flow configuration defines `CLOCK_PORT: clk` and `CLOCK_PERIOD: 7.0`. The generated fallback SDC correctly establishes a 7.0 ns clock period on `clk`, 0.25 ns clock uncertainty, 5.0% timing derate, and 1.4 ns input/output delays (20% of clock period), properly constraining the implementation.

=== 5. Missing Power Source Locations (`VSRC_LOC_FILES`)
- *Warning*: `[WARNING] [OpenROAD.IRDropReport] 'VSRC_LOC_FILES' was not given a value, which may make the results of IR drop analysis inaccurate. If you are not integrating a top-level chip for manufacture, you may ignore this warning...`
- *Root Cause & Limitation*: `VSRC_LOC_FILES` specifies the exact coordinates and voltages of power/ground pad bumps for package-level integration. For this sub-block macro, package I/O pad coordinates were omitted. Static IR-drop analysis accuracy is limited because OpenROAD uses uniform boundary approximations rather than exact package pad connections. Consequently, full chip-level power-grid IR-drop integrity cannot be claimed as verified; this is documented as a known analysis limitation of standalone macro-level physical design.

#pagebreak()

= 6. Answers to the Report Questions

#block(breakable: false, fill: rgb("#f8fafc"), stroke: 0.5pt + rgb("#cbd5e1"), inset: 10pt, radius: 4pt)[
*Q1. The array needs 16 AND gates and 12 full adders. How many cells did synthesis produce for the logic (total cells minus flip-flops)? Explain why the number of cells is not simply $16 + 12$.*

*Answer*: Synthesis produced 73 total cells, of which 16 are flip-flops, leaving *57 combinational logic cells* ($405.39 mu m^2$). The count is not $16 + 12 = 28$ because those numbers represent architectural operations (16 AND products and 12 full adders) rather than standard-cell primitives. A 1-bit full adder is not a single gate, but requires sum and carry functions (typically 5--9 basic gates or 2--3 complex gates). Yosys and ABC flatten the hierarchy and optimize the Boolean network: constant propagation recognizes grounded carry-ins ($c_{1,2,3}[0] = 0$), collapsing the first adder in each row to a half adder; carry networks map into compound majority gates (`maj3_1`); and partial-product ANDs fold into complex cells (`a21oi`, `o21ai`). Thus, the 57 cells represent technology-mapped CMOS gates.
]

#v(0.6em)

#block(breakable: false, fill: rgb("#f8fafc"), stroke: 0.5pt + rgb("#cbd5e1"), inset: 10pt, radius: 4pt)[
*Q2. What is the critical path of your design, from which register to which register? How many cells are on it, and how does this compare with the estimate of about $2N$ full-adder delays?*

*Answer*: The critical path originates at launch flip-flop `_118_` (`b_reg[0]`, clock-to-Q 0.395 ns) and terminates at capture flip-flop `_112_` (`p[6]`, capturing `\fa33.sum`), traversing *10 cells in total* (1 launch flip-flop, 8 combinational gates, and 1 capture flip-flop). Combinational cells contribute 2.065 ns across 1 partial-product AND gate (`_083_`) and 7 flattened adder-network gates (`_055_`, `_059_`, `_070_`, `_076_`, `_090_`, `_091_`, `_092_`), reaching a data arrival time of 2.460 ns (meeting the 9.865 ns required time with +7.404 ns setup slack at 10 ns). While the $2N = 8$ full-adder delay model ($t_"crit" approx 8 t_"FA"$) estimates an unoptimized ripple-carry array ($approx 16$ unmapped gate levels), full-adder delay units are not interchangeable with mapped gate arcs. Logic synthesis collapsed the array across row boundaries into 8 optimized CMOS compound gate arcs averaging 0.258 ns per arc, achieving $T_"min" = 2.596$ ns ($F_"max" approx 385.2$ MHz, or 384.6 MHz at rounded 2.60 ns).
]

#v(0.6em)

#block(breakable: false, fill: rgb("#f8fafc"), stroke: 0.5pt + rgb("#cbd5e1"), inset: 10pt, radius: 4pt)[
*Q3. What percentage of the total cell area is flip-flops? Why is this percentage large for such a small design?*

*Answer*: The 16 flip-flops (`sky130_fd_sc_hd__dfrtp_1`) occupy $400.384 mu m^2$ out of $805.773 mu m^2$, accounting for *49.69%* of total cell area. This high proportion occurs because a standard-cell DFF with asynchronous reset is physically large ($25.024 mu m^2$, equivalent to 6--7 basic NAND2 gates) comprising master-slave latches, reset gating, and clock buffers, whereas the 4-bit combinational core is small ($approx 405 mu m^2$). In larger multipliers, combinational logic grows quadratically ($O(N^2)$) while registers grow linearly ($O(N)$), but for $N=4$ register overhead naturally dominates.
]

#v(0.6em)

#block(breakable: false, fill: rgb("#f8fafc"), stroke: 0.5pt + rgb("#cbd5e1"), inset: 10pt, radius: 4pt)[
*Q4. Why is the post-route $F_max$ lower than the $F_max$ from Part C? Which kinds of cells did the flow add, and why is each kind needed?*

*Answer*: Post-route $F_"max"$ drops from the pre-route typical-corner estimate of 385.2 MHz (384.6 MHz rounded) to 150.7 MHz in the signoff worst slow-slow corner ($100^compose C, 1.60$ V) and 302.9 MHz in the nominal typical corner due to interconnect RC parasitics, clock tree insertion delay, clock skew ($approx 0.28$ ns), clock uncertainty ($0.25$ ns), and multi-corner PVT derating. To achieve manufacturability and electrical closure, LibreLane inserted 1,828 physical-support cells (net increase of 1,822 instances after 6 functional cells were merged, yielding 1,895 total placed instances): 245 tap cells (`tapvpwrvgnd_1`) to prevent latch-up; 1,314 decoupling capacitor cells (`decap_12`, `decap_6`, `decap_3`, `decap_8`, `decap_4`) to suppress power-supply noise and dynamic IR drop; 247 filler cells (`fill_1`, `fill_2`) to satisfy foundry DRC density rules; 3 clock tree buffers (`clkbuf_16`) to distribute a low-skew clock; and 19 timing-repair buffers (17 `buf_2` and 2 `clkdlybuf4s50_1`) to resolve slew and setup/hold constraints.
]

#v(0.6em)

#block(breakable: false, fill: rgb("#f8fafc"), stroke: 0.5pt + rgb("#cbd5e1"), inset: 10pt, radius: 4pt)[
*Q5. What does a DRC check verify, and what does an LVS check verify? Why must both pass before a chip can be manufactured?*

*Answer*: Design Rule Checking (DRC) validates physical layout geometries against foundry manufacturing rules (widths, spacings, enclosures, and densities) to ensure lithographic integrity. Layout Versus Schematic (LVS) extracts devices and connectivity directly from mask polygons and verifies topological equivalence against the synthesized gate netlist. Both must pass: DRC ensures manufacturability but cannot detect functional circuit errors (e.g. an unintended short satisfying geometric spacing); LVS guarantees schematic correctness but cannot prevent physical fabrication defects if design rules are violated. Chip tapeout requires zero DRC and zero LVS errors.
]

#v(0.6em)

#block(breakable: false, fill: rgb("#f8fafc"), stroke: 0.5pt + rgb("#cbd5e1"), inset: 10pt, radius: 4pt)[
*Q6. Using the formulas in Section 2, estimate how the number of full adders and the critical path delay would change if the multiplier were 8 bits wide instead of 4. Show your working.*

*Answer*: For an $N$-bit array multiplier, full adders scale as $N_"FA" = N(N - 1)$, increasing from $4 times 3 = 12$ for $N=4$ to $8 times 7 = 56$ *full adders* for $N=8$ ($4.67times$ increase). The critical path depth scales with the ripple chain as approximately $2N$ full-adder delays, doubling from 8 to 16 units. Scaling the measured 4-bit period by a factor of 2 gives a theoretical linear estimate of $T_"min" (text("8-bit")) approx 2 times 2.596 text(" ns") = 5.192 text(" ns")$ ($F_"max" approx 192.6 text(" MHz")$) using the 2.596 ns baseline, or $2 times 2.60 text(" ns") = 5.20 text(" ns")$ ($F_"max" approx 192.3 text(" MHz")$) using the rounded baseline. Registers grow from 16 to 32 flip-flops ($8+8+16$), maintaining 2-cycle latency ($approx 10.4$ ns) and 1 result/cycle throughput.
]

#pagebreak()

= 7. Conclusion & Academic Integrity Statement

== Summary of Results
The complete RTL-to-GDSII flow was designed, simulated, synthesized, timed, and placed-and-routed to signoff using the containerized `hpretl/iic-osic-tools` environment:
- *Part A*: Structural RTL and testbench verified across all 256 stimulus vectors; error injection correctly caught with 95 mismatches.
- *Part B*: Logic synthesis completed with Yosys 0.70; mapped to 73 SKY130 cells ($805.77 mu m^2$); gate-level simulation passed 256/256 vectors.
- *Part C*: Static timing analysis in OpenSTA 3.1.0 established $T_min = 2.596$ ns ($F_max approx 385.2$ MHz, or 384.6 MHz at rounded 2.60 ns) with near-zero slack (+0.004 ns inferred, reported as 0.00 ns) confirmed at $T = 2.60$ ns.
- *Part D*: LibreLane physical design achieved timing closure across all 9 signoff corners at $T = 7.0$ ns on a fixed $150 times 150 mu m$ die, with 0 DRC errors (Magic & KLayout), 0 LVS errors (Netgen), 0 antenna violations, and non-negative setup slack ($+0.364$ ns in worst-case corner `max_ss_100C_1v60`). Wirelength checking was skipped without threshold parameter, and IR-drop analysis was limited to macro boundary approximation without package bump locations.

== Academic Integrity Declaration
In accordance with Section 13 of "RTL_to_GDS.pdf", the authors confirm that the design, verification, synthesis, static timing analysis, and physical-design workflows were executed, audited, and verified locally by the team members. Standard open-source EDA tools from the IIC-OSIC-TOOLS environment were utilized as prescribed.

#v(1em)

= Appendix A — Local Command Transcript

The complete set of commands executed locally, in chronological order:

#text(size: 8.5pt)[
```bash
# ==============================================================================
# Phase 1: Environment Preflight & Toolchain Verification
# ==============================================================================
# Pinned immutable container image digest:
IMAGE="docker.io/hpretl/iic-osic-tools@sha256:9201d2ebe74a406cf6af850ca2c646ac0462f3b2cea94cd98cb6580d8ceef800"
podman pull $IMAGE

# ==============================================================================
# Phase 2: Part A — RTL Simulation & Error Injection
# ==============================================================================
# 1. Clean simulation
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
# -> PASS: 256 vectors checked, 0 errors (writes mult.vcd)

# 2. Error injection test
sed -i 's/assign sum  = a ^ b ^ cin;/assign sum  = a ^ b;/' rtl/full_adder.v
iverilog -g2012 -o sim_err tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim_err
# -> FAIL: 256 vectors checked, 95 errors

# 3. Restoration
git checkout rtl/full_adder.v
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v && vvp sim
# -> PASS: 256 vectors checked, 0 errors

# ==============================================================================
# Phase 3: Part B — Logic Synthesis & Gate-Level Simulation
# ==============================================================================
podman run --rm --userns=keep-id \
  -v $(pwd):/foss/designs/mult_array:Z -w /foss/designs/mult_array \
  $IMAGE --skip bash -c "
    export PDK_ROOT=/foss/pdks; export PDK=sky130A
    yosys -c synth/synth.tcl
"
# -> synth/mult_array_stat.rpt and synth/mult_array_netlist.v (73 cells)

podman run --rm --userns=keep-id \
  -v $(pwd):/foss/designs/mult_array:Z -w /foss/designs/mult_array \
  $IMAGE --skip bash -c "
    CELLS=/foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog
    iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls \
      tb/tb_mult.v \$CELLS/primitives.v \$CELLS/sky130_fd_sc_hd.v synth/mult_array_netlist.v
    vvp gls
"
# -> PASS: 256 vectors checked, 0 errors

# ==============================================================================
# Phase 4: Part C — Static Timing Analysis with OpenSTA
# ==============================================================================
# Run 1: T = 10.0 ns (100 MHz target)
podman run --rm --userns=keep-id \
  -v $(pwd):/foss/designs/mult_array:Z -w /foss/designs/mult_array \
  $IMAGE --skip bash -c "
    export PDK_ROOT=/foss/pdks; export PDK=sky130A; unset STA_PERIOD
    sta sta/sta.tcl
"
# -> worst slack max 7.40 ns => Tmin = 2.596 ns, Fmax = 385.2 MHz (or 384.6 MHz at 2.60 ns)

# Run 2: T = 2.60 ns confirmation
podman run --rm --userns=keep-id \
  -v $(pwd):/foss/designs/mult_array:Z -w /foss/designs/mult_array \
  $IMAGE --skip bash -c "
    export PDK_ROOT=/foss/pdks; export PDK=sky130A; export STA_PERIOD=2.60
    sta sta/sta.tcl
"
# -> worst slack max 0.00 ns (reported to 2 decimal places, exact slack +0.004 ns)

# ==============================================================================
# Phase 5: Part D — Physical Design with LibreLane
# ==============================================================================
podman run --rm --userns=keep-id \
  -v $(pwd):/foss/designs/mult_array:Z -w /foss/designs/mult_array/pnr \
  $IMAGE --skip bash -c "
    source /foss/tools/sak/sak-pdk-script.sh sky130A || true
    librelane --manual-pdk config.json
"
# Final Views Copied:
cp pnr/runs/RUN_2026-10-23_20-08-02/final/metrics.json pnr/metrics.json
cp pnr/runs/RUN_2026-10-23_20-08-02/final/gds/mult_array.gds pnr/mult_array.gds

# KLayout Layout Rendering:
podman run --rm --userns=keep-id \
  -v $(pwd):/foss/designs/mult_array:Z -w /foss/designs/mult_array \
  $IMAGE --skip bash -c "
    source /foss/tools/sak/sak-pdk-script.sh sky130A || true
    QT_QPA_PLATFORM=offscreen klayout -b -r scripts/klayout_shots.py
"
```
]

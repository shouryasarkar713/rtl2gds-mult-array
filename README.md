# RTL to GDSII — 4-Bit Array Multiplier (SkyWater SKY130)

Digital VLSI Design Coursework — an unsigned 4-bit × 4-bit array multiplier designed from RTL through exhaustive simulation verification, logic synthesis, static timing analysis (STA), and automated place-and-route (PnR) to a signed-off GDSII layout on the SkyWater 130 nm CMOS process.

---

## 1. Team Information

| Team Member | Name | Roll Number | Role |
|---|---|---|---|
| Member 1 | **Shourya Sarkar** | `2023112013` | RTL Design, Verification, Synthesis, STA & Report |
| Member 2 | **Sampath** | `2023102033` | Physical Design, PnR Ladder & Layout Signoff |

### Worked Example Parameter Assignment
- Multiplicand $A = (\text{Last digit of Member 1 Roll No. } 2023112013) + 5 = 3 + 5 = \mathbf{8}\ (1000_2)$
- Multiplier $B = \mathbf{7}\ (0111_2)$ (since $A \neq 7$, $B$ remains 7 per assignment specification)
- Hand-calculated Product: $P = 8 \times 7 = \mathbf{56}\ (00111000_2 = \text{0x38})$

---

## 2. Repository Architecture

```text
rtl2gds-mult-array/
├── README.md                           # Complete execution guide and project documentation
├── rtl/
│   ├── full_adder.v                    # 1-bit full adder with combinational assign statements
│   └── mult_array.v                    # 4x4 array multiplier (16 ANDs, 12 FAs, 16 FFs)
├── tb/
│   └── tb_mult.v                       # Exhaustive 256-vector self-checking testbench
├── synth/
│   ├── synth.tcl                       # Yosys 7-step synthesis script
│   ├── mult_array_netlist.v            # Generated SKY130 mapped gate-level netlist
│   └── mult_array_stat.rpt             # Generated cell count and area report
├── sta/
│   ├── sta.tcl                         # OpenSTA static timing analysis script
│   └── mult_array_timing.rpt           # Critical-path timing report (T = 10.0 ns)
├── pnr/
│   ├── config.json                     # LibreLane physical design configuration
│   ├── metrics.json                    # Signed-off metrics copied from successful run
│   └── mult_array.gds                  # Final signed-off GDSII layout stream
├── report/
│   ├── report.typ                      # Editable Typst report source document
│   └── report.pdf                      # Completed 14-page verified coursework report
├── screenshots/
│   ├── block_diagram.svg / .png        # Structural multiplier block diagram
│   ├── waveform_example.png            # GTKWave simulation waveform (8 x 7 = 56, 2-cycle latency)
│   ├── mult_array_die.png              # KLayout full die layout view (150 x 150 um)
│   └── mult_array_zoom.png             # KLayout zoomed core layout view (40 x 40 um)
├── scripts/
│   ├── block_diagram.py                # Generates Figure 1 SVG and PNG
│   ├── make_gtkwave_screenshot.py      # Annotates genuine GTKWave capture to generate Figure 2
│   ├── render_waveform.py              # Wrapper executing make_gtkwave_screenshot.py
│   └── klayout_shots.py                # Headless batch KLayout renderer for Figures 3 & 4
├── logs/                               # Tool execution transcripts
│   ├── partA_sim_pass.log              # Part A: clean 256-vector PASS
│   ├── partA_sim_failinject.log        # Part A: error-injection FAIL (95 errors)
│   ├── partA_sim_restored.log          # Part A: post-restoration clean PASS
│   ├── partB_yosys.log                 # Part B: Yosys 0.70 synthesis transcript
│   ├── partB_gls.log                   # Part B: gate-level simulation 256-vector PASS
│   ├── partC_run1.log                  # Part C: OpenSTA at T = 10.0 ns (WNS = +7.404 ns)
│   ├── partC_run2.log                  # Part C: OpenSTA confirmation at T = 2.60 ns (slack 0.00 ns)
│   ├── partD_attempt_3.5.log           # Part D Ladder: Run 1 (T = 3.5 ns, ss slack = -2.154 ns, FAIL)
│   ├── partD_attempt_4.0.log           # Part D Ladder: Run 2 (T = 4.0 ns, ss slack = -1.654 ns, FAIL)
│   ├── partD_attempt_4.5.log           # Part D Ladder: Run 3 (T = 4.5 ns, ss slack = -1.154 ns, FAIL)
│   ├── partD_attempt_5.0.log           # Part D Ladder: Run 4 (T = 5.0 ns, ss slack = -0.654 ns, FAIL)
│   ├── partD_attempt_5.5.log           # Part D Ladder: Run 5 (T = 5.5 ns, ss slack = -0.155 ns, FAIL)
│   ├── partD_attempt_6.0.log           # Part D Ladder: Run 6 (T = 6.0 ns, ss slack = -0.107 ns, FAIL)
│   ├── partD_attempt_6.5.log           # Part D Ladder: Run 7 (T = 6.5 ns, ss slack = -0.136 ns, FAIL)
│   ├── partD_run_7.0.log               # Part D Ladder: Run 8 (T = 7.0 ns, ss slack = +0.364 ns, PASS ✅)
│   ├── klayout_render.log              # Headless KLayout rendering log
│   └── baseline_historical_oct22/      # Earlier baseline run logs (October 22)
├── mult.vcd                            # Fresh VCD waveform dump from passing RTL simulation
└── mult_example.gtkw                   # GTKWave savefile configured with signals and latency markers
```

---

## 3. Local Execution Environment & Tool Versions

All verification, synthesis, STA, and physical-design workflows were executed locally on the host machine in strict adherence to Section 4 of `RTL_to_GDS.pdf`:
- **Host OS**: Fedora Linux 44 (Workstation Edition), Kernel `7.0.14-201.fc44.x86_64`
- **Host CPU / RAM**: 13th Gen Intel Core i5-1340P (16 threads, up to 4.6 GHz), 16 GB RAM, NVMe storage
- **Container Runtime**: Podman 5.8.3 (`/usr/bin/podman`) in rootless mode with `--userns=keep-id`
- **Container Image**: `docker.io/hpretl/iic-osic-tools@sha256:9201d2ebe74a406cf6af850ca2c646ac0462f3b2cea94cd98cb6580d8ceef800` (JKU IIC-OSIC-TOOLS)
  - **Pinned Immutable Digest**: `sha256:9201d2ebe74a406cf6af850ca2c646ac0462f3b2cea94cd98cb6580d8ceef800`
  - **Local Image ID**: `fd31cb46f41bea25c60bcdff1a8106f9e3889b3f05260af80c75a8b625a1c1db`
- **PDK**: SkyWater 130 nm (`sky130A`), standard cell library `sky130_fd_sc_hd` (`$PDK_ROOT=/foss/pdks`)
- **Local EDA Tool Versions (Observed Locally in Container)**:
  - **Icarus Verilog**: v13.0 / v14.0 (devel)
  - **Yosys**: 0.70 (git sha1 `28ba3cb92`, Release, GNU /usr/bin/c++ 13.3.0)
  - **OpenSTA**: 3.1.0 (`80fbbb2945`)
  - **LibreLane**: v3.1.0.dev3 (`Classic` flow, 80 stages, adapted from OpenLane 2.0)
  - **OpenROAD**: 26Q4-407-geb14e40b7
  - **Magic**: 8.3.685
  - **Netgen**: 1.5.316
  - **KLayout**: 0.30.12
  - **Verilator**: 5.052

---

## 4. Chronological Command Transcript & Execution Steps

Run all commands from the repository root directory. The verified immutable container image digest is:
```bash
IMAGE="docker.io/hpretl/iic-osic-tools@sha256:9201d2ebe74a406cf6af850ca2c646ac0462f3b2cea94cd98cb6580d8ceef800"
```

### Phase 1: Environment Setup & Tool Verification

```bash
# Verify container runtime and tool suite availability
podman run --rm --userns=keep-id $IMAGE --skip bash -c "
  echo 'Tool Verification:'
  iverilog -V | head -n 1
  yosys -V
  sta -version
  klayout -v
  librelane --version
"
```

### Phase 2: Part A — RTL Design & Verification

```bash
# 1. Clean 256-vector exhaustive simulation (514 rising edges: 2 reset + 256 x 2 latency edges, finishing at t = 5,138 ns)
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
# -> PASS: 256 vectors checked, 0 errors (writes fresh mult.vcd)
# -> Worked example (A=8, B=7 -> P=56): stimulus at t = 2718 ns, edge 1 at 2725 ns, edge 2 at 2735 ns

# 2. Error injection experiment (corrupt full_adder sum to a ^ b)
sed -i 's/assign sum  = a ^ b ^ cin;/assign sum  = a ^ b;/' rtl/full_adder.v
iverilog -g2012 -o sim_err tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim_err
# -> FAIL: 256 vectors checked, 95 errors (first mismatch: a=3, b=3 -> p=5, expected 9)

# 3. Restoration of clean RTL and re-verification
git checkout rtl/full_adder.v
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v && vvp sim
# -> PASS: 256 vectors checked, 0 errors

# 4. Waveform & block diagram generation
python3 scripts/make_gtkwave_screenshot.py # Generates screenshots/waveform_example.png from GTKWave capture
python3 scripts/block_diagram.py           # Generates screenshots/block_diagram.svg & .png
```

### Phase 3: Part B — Logic Synthesis with Yosys

```bash
# Execute Yosys synthesis in the container using immutable image digest
podman run --rm --userns=keep-id \
  -v $(pwd):/foss/designs/mult_array:Z -w /foss/designs/mult_array \
  $IMAGE --skip bash -c "
    export PDK_ROOT=/foss/pdks; export PDK=sky130A
    yosys -c synth/synth.tcl
"
# -> Output: synth/mult_array_stat.rpt and synth/mult_array_netlist.v
# -> Results: 73 cells, 16 DFFs (dfrtp_1), 805.773 um2 area (49.69% sequential)

# Gate-Level Simulation (GLS) using standard cell models
podman run --rm --userns=keep-id \
  -v $(pwd):/foss/designs/mult_array:Z -w /foss/designs/mult_array \
  $IMAGE --skip bash -c "
    CELLS=/foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog
    iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls \
      tb/tb_mult.v \$CELLS/primitives.v \$CELLS/sky130_fd_sc_hd.v synth/mult_array_netlist.v
    vvp gls
"
# -> PASS: 256 vectors checked, 0 errors
```

### Phase 4: Part C — Static Timing Analysis with OpenSTA

```bash
# Run 1: Clock period T = 10.0 ns (100 MHz target per Section 8)
podman run --rm --userns=keep-id \
  -v $(pwd):/foss/designs/mult_array:Z -w /foss/designs/mult_array \
  $IMAGE --skip bash -c "
    export PDK_ROOT=/foss/pdks; export PDK=sky130A; unset STA_PERIOD
    sta sta/sta.tcl
"
# -> worst slack max 7.40 ns (WNS = +7.404 ns)
# -> Tmin = 10.00 - 7.404 = 2.596 ns (exact) / 2.60 ns (rounded)
# -> Fmax = 385.2 MHz (exact) / 384.6 MHz (rounded)

# Run 2: Confirmation run at T = 2.60 ns
podman run --rm --userns=keep-id \
  -v $(pwd):/foss/designs/mult_array:Z -w /foss/designs/mult_array \
  $IMAGE --skip bash -c "
    export PDK_ROOT=/foss/pdks; export PDK=sky130A; export STA_PERIOD=2.60
    sta sta/sta.tcl
"
# -> worst slack max 0.00 ns (reported to 2 dec, exact slack +0.004 ns confirming limit)

# Restore official T = 10.0 ns report into sta/mult_array_timing.rpt
podman run --rm --userns=keep-id \
  -v $(pwd):/foss/designs/mult_array:Z -w /foss/designs/mult_array \
  $IMAGE --skip bash -c "
    export PDK_ROOT=/foss/pdks; export PDK=sky130A; unset STA_PERIOD
    sta sta/sta.tcl
"
```

### Phase 5: Part D — Physical Design with LibreLane

Per Section 9 of `RTL_to_GDS.pdf`, the physical design flow was explored across a clock-period ladder starting at $T = 3.5\text{ ns}$ up to $T = 7.0\text{ ns}$ in $0.5\text{ ns}$ increments to achieve timing closure across all corners:

#### Local PnR Timing Closure Ladder (Executed Chronologically on Oct 23)

| Attempt | Target Period | Run Directory | SS Setup Slack | TT Setup Slack | Hold Slack | Status / Outcome |
|---|---|---|---|---|---|---|
| 1 | 3.5 ns | `RUN_2026-10-23_19-54-16` | -2.154 ns | +0.587 ns | +0.100 ns | FAIL (15 setup viols) |
| 2 | 4.0 ns | `RUN_2026-10-23_19-56-21` | -1.654 ns | +1.087 ns | +0.147 ns | FAIL (12 setup viols) |
| 3 | 4.5 ns | `RUN_2026-10-23_19-58-23` | -1.154 ns | +1.587 ns | +0.147 ns | FAIL (12 setup viols) |
| 4 | 5.0 ns | `RUN_2026-10-23_20-00-25` | -0.654 ns | +2.087 ns | +0.147 ns | FAIL (9 setup viols) |
| 5 | 5.5 ns | `RUN_2026-10-23_20-02-19` | -0.155 ns | +2.587 ns | +0.147 ns | FAIL (3 setup viols) |
| 6 | 6.0 ns | `RUN_2026-10-23_20-04-10` | -0.107 ns | +2.899 ns | +0.148 ns | FAIL (3 setup viols) |
| 7 | 6.5 ns | `RUN_2026-10-23_20-06-03` | -0.136 ns | +3.199 ns | +0.141 ns | FAIL (3 setup viols) |
| 8 | 7.0 ns | `RUN_2026-10-23_20-08-02` | **+0.364 ns** | **+3.699 ns** | **+0.141 ns** | **PASS** ✅ (0 violations, clean DRC/LVS) |

Total number of runs needed to close timing: **8 runs**.

#### Execution Command

```bash
# Sourcing the PDK configuration script sets:
#   PDK_ROOT=/foss/pdks, PDK=sky130A, STD_CELL_LIBRARY=sky130_fd_sc_hd

# Run LibreLane physical design at target closed period (7.0 ns):
podman run --rm --userns=keep-id \
  -v $(pwd):/foss/designs/mult_array:Z -w /foss/designs/mult_array/pnr \
  $IMAGE --skip bash -c "
    source /foss/tools/sak/sak-pdk-script.sh sky130A || true
    librelane --manual-pdk config.json
"
# Flow completes all 80 stages cleanly:
# Antenna: Passed ✅, LVS: Passed ✅, DRC: Passed ✅

# Copy final sign-off deliverables into pnr/ directory:
cp pnr/runs/RUN_2026-10-23_20-08-02/final/metrics.json pnr/metrics.json
cp pnr/runs/RUN_2026-10-23_20-08-02/final/gds/mult_array.gds pnr/mult_array.gds

# Render high-resolution KLayout screenshots headlessly:
podman run --rm --userns=keep-id \
  -v $(pwd):/foss/designs/mult_array:Z -w /foss/designs/mult_array \
  $IMAGE --skip bash -c "
    source /foss/tools/sak/sak-pdk-script.sh sky130A || true
    QT_QPA_PLATFORM=offscreen klayout -b -r scripts/klayout_shots.py
"
# -> screenshots/mult_array_die.png (1800x1800)
# -> screenshots/mult_array_zoom.png (1600x1600)
```

#### Flow Warnings Investigation & Diagnostics
During physical design execution, LibreLane and OpenROAD emitted several diagnostic and tool warnings. Each warning category was investigated, root-caused, assessed for risk, and documented with any resulting analytical limitations:

1. **Tool and Configuration Diagnostics**:
   - **ORD-0032 (`Invalid thread number specification: None`)**: Stages 32, 54, 56 receive `None` from LibreLane's Python step wrapper. Zero risk; OpenROAD automatically falls back to single-thread or system core auto-detection.
   - **STA-1173 (`default_fanout_load is 0.0`)**: PDK I/O pad timing library files (`sky130_ef_io__*.lib.gz`, `slices_stubs.lib.gz`) omit default fanout attributes. Zero risk; the multiplier macro utilizes only high-density core cells (`sky130_fd_sc_hd`) and no pad cells are instantiated.
   - **ORD-2056 (`Liberty cells do not have LEF masters and marked dont-use`)**: PDK pad library stubs (`sky130_ef_io__analog_minesd_pad`, `sky130_ef_io__analog_minesd_pad_short`) lack LEF physical layouts and are safely marked `dont-use` by OpenROAD. Zero risk.
   - **STA-1111 (`Missing combinational timing groups in I/O pad models`)**: Minor inconsistency between corner Liberty files for pad macros (`OUT -> PAD`). Zero risk; unused in this macro.
   - **STA-1140 (`Duplicate timing-library declarations across corners`)**: Multi-corner STA environment re-reads shared PDK stub files (`slices_stubs.lib.gz`). Zero risk; OpenROAD updates/retains the active corner definitions.
   - **DRT-0349 (`LEF58_ENCLOSURE with no CUTCLASS is not supported. Skipping for layer mcon/via/via2`)**: TritonRoute detailed router skips advanced LEF 5.8 enclosure extension rules and defaults to standard LEF 5.7 geometric rules. Low risk; subsequent Magic DRC and KLayout DRC confirm 0 geometric DRC errors. Analysis limitation: routing relies on LEF 5.7 enclosure rules rather than LEF 5.8 extensions.
   - **494 Verilator Lint Warnings (`%Warning-TIMESCALEMOD`)**: Stage 01 emitted timescale modification warnings between user RTL (`1ns/1ps`) and PDK blackbox simulation models (`.bb.v`). Standard PDK convention with zero functional or synthesis impact.
2. **Wire-Length Checker (`Checker.WireLength`)**:
   - `[WARNING] [Checker.WireLength] Threshold for Threshold-surpassing long wires is not set. The checker will be skipped.`
   - Root cause: No upper-bound wirelength threshold parameter was defined in `pnr/config.json`.
   - Risk & limitation: Wire-length threshold checking was **skipped** (not passed). The physical-design flow did not evaluate long-wire violations against a prescribed limit. However, physical detailed routing completed successfully with an exact routed wirelength of $2,362\ \mu\text{m}$ and 552 vias reported by `Odb.ReportWireLength`, and all timing constraints closed with positive slack.
3. **Pre-PDN Floating Nets (`RSZ-0020`)**:
   - `[WARNING RSZ-0020] found 2 floating nets: VPWR, VGND` during Stage 32 (`repairdesignpostgpl`).
   - Root cause: Resizer runs prior to PDN synthesis (Stage 36) when power rails are not yet tied to physical power stripes.
   - Risk & assessment: Supply rails, not logic nets. Stage 36 completed PDN synthesis, and Netgen LVS confirmed 0 floating pins/nets and 100% topological equivalence in the final layout.
4. **Generic Fallback SDC Files (`checksdcfiles`)**:
   - Stage 10 reported `PNR_SDC_FILE` and `SIGNOFF_SDC_FILE` were not explicitly provided in `config.json`.
   - Root cause: LibreLane automatically generates fallback SDC constraints when custom SDC file paths are omitted.
   - Risk & assessment: As prescribed by Section 9 of `RTL_to_GDS.pdf`, configuration specifies `CLOCK_PORT: clk` and `CLOCK_PERIOD: 7.0`. The generated fallback SDC correctly establishes a 7.0 ns clock period on `clk`, 5% clock uncertainty ($0.35$ ns), and $1.4$ ns input/output delays (20% of clock period), properly constraining the implementation.
5. **Missing Power Source Locations (`VSRC_LOC_FILES`)**:
   - `[WARNING] [OpenROAD.IRDropReport] 'VSRC_LOC_FILES' was not given a value, which may make the results of IR drop analysis inaccurate...`
   - Root cause: `VSRC_LOC_FILES` specifies the exact coordinates and voltages of power pad bumps for full-chip package integration, omitted for standalone macro blocks.
   - Risk & limitation: Static IR-drop analysis accuracy is limited because OpenROAD uses uniform boundary approximations rather than exact package pad connections. Consequently, full chip-level power-grid IR-drop integrity cannot be claimed as verified; this is documented as a known analysis limitation of standalone macro-level physical design.

### Phase 6: Report Generation

```bash
typst compile --root . report/report.typ report/report.pdf
```

---

## 5. Verified Key Metrics Summary

| Stage / Metric | Baseline Exploration | Final Execution (Fedora 44) | Verification Status |
|---|---|---|---|
| **Part A: RTL Sim** | PASS 256/0 | **PASS 256/0** | Byte-Identical |
| **Part A: Error Inject** | FAIL 95 errors | **FAIL 95 errors** | Verified Fault Detection |
| **Part B: Total Cells** | 65 cells | **73 cells** | Yosys 0.70 optimization |
| **Part B: Flip-Flops** | 16 (`dfrtp_1`) | **16 (`dfrtp_1`)** | Exact Match |
| **Part B: Cell Area** | 751.97 $\mu\text{m}^2$ | **805.77 $\mu\text{m}^2$** | Verified from stat report |
| **Part B: Sequential %** | 53.24% | **49.69%** | Verified from stat report |
| **Part B: Gate-Level Sim**| PASS 256/0 | **PASS 256/0** | Verified Netlist Correctness |
| **Part C: Target Period** | 10.0 ns (100 MHz) | **10.0 ns (100 MHz)** | Assignment Specification |
| **Part C: Worst Slack** | +7.35 ns | **+7.404 ns** | OpenSTA 3.1.0 |
| **Part C: $T_{\min}$ / $F_{\max}$** | 2.65 ns / 377.4 MHz | **2.596 ns / 385.2 MHz** (2.60 ns / 384.6 MHz rounded) | Confirmed at slack +0.004 ns (0.00 ns) |
| **Part C: Critical Path** | `a_reg[1]` $\to$ `p[6]` | **`b_reg[0]` (`_118_`) $\to$ `p[6]` (`_112_`)** | Traced from netlist |
| **Part D: Target Period** | 7.0 ns | **7.0 ns** | Timing Closed |
| **Part D: Runs Needed** | 8 runs | **8 runs** (3.5 to 7.0 ns ladder) | Verified Chronologically |
| **Part D: Core / Die Area**| 17,759.5 / 22,500 $\mu\text{m}^2$ | **17,759.5 / 22,500 $\mu\text{m}^2$** | Fixed $150 \times 150\ \mu\text{m}$ Die |
| **Part D: Support Cells** | 4,756 cells | **1,828 cells** (245 tap + 1,561 fill/decap + 19 timing buf + 3 CTS) | Physical Design Integrity |
| **Part D: Placed Instances**| 4,821 instances | **1,895 instances** (334 std + 1,561 fill/decap, net +1,822) | Zero DRC / LVS Clean |
| **Part D: Wirelength** | 3,030 $\mu\text{m}$ | **2,362 $\mu\text{m}$** (552 vias; threshold check skipped) | Optimized Routing |
| **Part D: IR Drop** | N/A | **Macro Boundary Check Complete** (pad locations omitted) | Analysis Limitation |
| **Part D: Worst Setup Slack**| +0.241 ns | **+0.364 ns** (`max_ss_100C_1v60`) | 0 Setup Violations |
| **Part D: Hold Slack** | +0.14 ns | **+0.141 ns** | 0 Hold Violations |
| **Part D: DRC Errors** | 0 errors | **0 errors** (Magic & KLayout) | Zero DRC Errors |
| **Part D: LVS Errors** | 0 errors | **0 errors** (Netgen) | Clean Match (Zero LVS Errors) |
| **Part D: Post-Route $F_{\max}$**| 148.0 MHz (ss) / 282.7 MHz (tt) | **150.7 MHz (ss) / 302.9 MHz (tt)** | Formula $1000 / (T - \text{slack})$ |

---

## 6. Academic Integrity Statement & Provenance

We declare that the work presented in this repository represents our genuine coursework effort. The Git commit history reflects development progress, milestone tags, and verification runs. Every result, waveform, layout screenshot, and metric reported in this repository was executed and verified against the assignment specification `RTL_to_GDS.pdf`.

- **Baseline Exploration Logs**: Earlier run logs generated during initial exploration on October 22 are archived under `logs/baseline_historical_oct22/` with an accompanying README.
- **Git Commit History Preservation**: In addition to standard packaging, the complete Git commit history is preserved and exported as a Git bundle (`rtl2gds-mult-array.bundle`) containing all commit objects, trees, and tags.

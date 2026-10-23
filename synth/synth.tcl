#-----------------------------------------------------------------------------
# synth.tcl — Yosys synthesis script (Part B)
#
# Maps the array multiplier RTL onto SkyWater SKY130 (sky130_fd_sc_hd)
# standard cells.
#
# Run from the repository root:
#     yosys -c synth/synth.tcl
#
# Requires the SKY130 PDK, e.g. installed by ciel/volare with
# PDK_ROOT pointing at the PDK root directory (as in IIC-OSIC-TOOLS,
# where $PDK_ROOT is /foss/pdks and $PDK is sky130A).
#-----------------------------------------------------------------------------

# Liberty timing library, typical corner
set lib $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# 1. Read the design (both files: mult_array instantiates full_adder)
yosys read_verilog rtl/full_adder.v rtl/mult_array.v

# 2. Generic synthesis; flatten the full_adder cells into one module
yosys synth -top mult_array -flatten

# 3. Map flip-flops to SKY130 flip-flop cells (dfrtp: async reset, active low)
yosys dfflibmap -liberty $lib

# 4. Map the remaining logic to SKY130 gate cells
yosys abc -liberty $lib

# 5. Remove unused wires / cells
yosys opt_clean -purge

# 6. Write the cell and area report
yosys tee -o synth/mult_array_stat.rpt stat -liberty $lib

# 7. Write the gate-level netlist
yosys write_verilog -noattr synth/mult_array_netlist.v

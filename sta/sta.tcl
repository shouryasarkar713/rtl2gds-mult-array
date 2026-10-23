#-----------------------------------------------------------------------------
# sta.tcl — OpenSTA static timing analysis script (Part C)
#
# Analyses the synthesized netlist against the clock period T, typical
# corner only (tt_025C_1v80).
#
# Run from the repository root:
#     sta sta/sta.tcl                       (T = 10 ns, first run)
#     STA_PERIOD=<Tmin> sta sta/sta.tcl     (second run at T = Tmin,
#                                             to confirm Fmax)
#
# Requires PDK_ROOT pointing at the SKY130 PDK root.
#-----------------------------------------------------------------------------

# Liberty timing library, typical corner
set lib $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Clock period T (ns). Default 10 ns (first run). For the Fmax confirmation
# run, Tmin = 10 - WNS is passed in via the environment variable STA_PERIOD.
if { [info exists ::env(STA_PERIOD)] } {
    set T $::env(STA_PERIOD)
} else {
    set T 10.0
}

# 1. Read the cell timing library
read_liberty $lib

# 2. Read and link the gate-level netlist
read_verilog synth/mult_array_netlist.v
link_design mult_array

# 3. Define the clock with period T
create_clock -name clk -period $T [get_ports clk]

# 4. Input arrival time (all inputs except the clock itself)
set_input_delay 1.0 -clock clk [delete_from_list [all_inputs] [get_ports clk]]

# 5. Output required time
set_output_delay 1.0 -clock clk [all_outputs]

# 6. Print the worst setup slack
report_worst_slack -max

# 7. Save the full critical path report
report_checks -path_delay max -digits 3 > sta/mult_array_timing.rpt

# Exit after the batch run (keeps `sta sta/sta.tcl` non-interactive)
exit

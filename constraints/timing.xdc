# Config Bus Input Timing Constraints
set_input_delay -clock cfg_clk -max 8.000 [get_ports {cfgd[*]}]
set_input_delay -clock cfg_clk -min 2.000 [get_ports {cfgd[*]}]
set_input_delay -clock cfg_clk -max 8.000 [get_ports cfg_rdy]
set_input_delay -clock cfg_clk -min 2.000 [get_ports cfg_rdy]
set_input_delay -clock cfg_clk -max 8.000 [get_ports cfg_act]
set_input_delay -clock cfg_clk -min 2.000 [get_ports cfg_act]
set_input_delay -clock cfg_clk -max 8.000 [get_ports cfg_err]
set_input_delay -clock cfg_clk -min 2.000 [get_ports cfg_err]

# Config Bus Output Timing Constraints
# -max values are used for setup time.  2ns output_delay sets a Tco max of 8ns, since it is a 10ns cycle
# -min values are used for hold timing.  -1ns indicates that the actual output hold time requirement is 1ns
set_output_delay -clock cfg_clk -max 2.000 [get_ports {cfgd[*]}]
set_output_delay -clock cfg_clk -max 2.000 [get_ports fpga_cmdl]
set_output_delay -clock cfg_clk -max 2.000 [get_ports fpga_rdyl]
set_output_delay -clock cfg_clk -max 2.000 [get_ports stat_oel]
set_output_delay -clock cfg_clk -min -1.000 [get_ports {cfgd[*]}]
set_output_delay -clock cfg_clk -min -1.000 [get_ports fpga_cmdl]
set_output_delay -clock cfg_clk -min -1.000 [get_ports fpga_rdyl]
set_output_delay -clock cfg_clk -min -1.000 [get_ports stat_oel]

# We skew cfg_clk for the ApsMsgProc (clk_100MHz_skewed_cfg_clk_mmcm) by 1ns, so we need to add a multicycle path
# constraint so that Vivado will examine the clock edge at 11ns
set_multicycle_path 2 -setup -from [get_clocks cfg_clk] -to [get_clocks CLK_100MHZ_CCLK_MMCM]

# Disable checking on OE timing since it is enabled more than one clock ahead of using the data
set_false_path -from [get_cells main_bd_inst/CPLD_bridge_0/U0/apsmsgproc_wrapper_inst/msgproc_impl.AMP1/ACP1/CFG1/ExtOE] -to [get_ports {cfgd[*]}]
set_false_path -to [get_ports stat_oel]

#MGT reference clock
create_clock -period 8.000 -name sfp_mgt_clkp -waveform {0.000 4.000} [get_ports {sfp_mgt_clkp}]

# Define 100 MHz clock on Aux SATA input
create_clock -period 10.000 -name TAUX_CLK -waveform {0.000 5.000} [get_pins TIL1/SIN1/O]

# ostrich-style timing groups
set_clock_groups -asynchronous \
-group [get_clocks -of_objects [get_pins CK0/CLK_100MHZ]] \
-group [get_clocks -of_object [get_pins CK0/CLK_100MHZ_IN]] \
-group [get_clocks -include_generated_clocks cfg_clk] \
-group [get_clocks -of_objects [get_pins TIL1/CK1/TRIG_100MHZ]]

set_clock_groups -physically_exclusive -group [get_clocks -include_generated_clocks -of_objects [get_pins CK0/REF_100MHZ_IN]] -group [get_clocks -include_generated_clocks -of_objects [get_pins CK0/CLK_125MHZ_IN]]

# dedicated clock routing for 10MHz reference clock
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets CK1/inst/CLK_REF_REF_MMCM]

# Don't care about output timing on these signals
set_false_path -to [get_ports {dbg[*]}]
set_false_path -to [get_ports {led[*]}]

#MAC and IPv4 address are updated once so don't worry about CDC
set_false_path -through [get_pins main_bd_inst/com5402_wrapper_0/mac_addr[*]]
set_false_path -through [get_pins main_bd_inst/com5402_wrapper_0/IPv4_addr[*]]

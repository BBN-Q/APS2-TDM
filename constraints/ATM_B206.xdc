#ATM_B206.xdc
#
# APS2 Trigger Module Pin definition file for use with Vivado
#
# REVISIONS
#
# 9/17/2013 CRJ
#  A01 Created
#
# 1/2/2014 CRJ
#  A02 Updated after MGTP Wizard 14.1 changes
#
# 1/15/2014 CRJ
#  Defined SFP_TXDIS as an output
#
# 1/26/2014 CRJ
#  Added CFG_CCLK Tsu, and Th
#
# 1/30/2014
#  Added pullup to DBG8
#
# 2/1/2014 CRJ
#  Changed EXT_TRIGx to LVDS_25 inputs
#
# 6/28/2014 CRJ
#  Changed DBG4/5/6/7 to 8ma outputs to drive RG LEDs
#
# 8/5/2014 CRJ
#  Added trigger I/Os
#  Changed clock constraints to reflect using MMCM on CFG_CCLK
#
# 9/29/2014 CRJ
#  Finalized with TIO port swapping for initial release
#
# END REVISIONS
#

# Config Bus Inputs
set_property PACKAGE_PIN N23 [get_ports CFG_RDY]
set_property IOSTANDARD LVCMOS25 [get_ports CFG_RDY]
set_property PACKAGE_PIN N26 [get_ports CFG_ACT]
set_property IOSTANDARD LVCMOS25 [get_ports CFG_ACT]
set_property PACKAGE_PIN M19 [get_ports FPGA_RESETL]
set_property IOSTANDARD LVCMOS25 [get_ports FPGA_RESETL]
set_property PACKAGE_PIN P19 [get_ports CFG_ERR]
set_property IOSTANDARD LVCMOS25 [get_ports CFG_ERR]
set_property PACKAGE_PIN M21 [get_ports CFG_CCLK]
set_property IOSTANDARD LVCMOS25 [get_ports CFG_CCLK]

# Config Bus Input Timing Constraints
create_clock -period 10.000 -name CFG_CCLK [get_ports CFG_CCLK]
set_input_delay -clock CFG_CCLK -max 6.000 [get_ports {CFGD[*]}]
set_input_delay -clock CFG_CCLK -min 2.000 [get_ports {CFGD[*]}]
set_input_delay -clock CFG_CCLK -max 6.000 [get_ports CFG_RDY]
set_input_delay -clock CFG_CCLK -min 2.000 [get_ports CFG_RDY]
set_input_delay -clock CFG_CCLK -max 6.000 [get_ports CFG_ACT]
set_input_delay -clock CFG_CCLK -min 2.000 [get_ports CFG_ACT]
set_input_delay -clock CFG_CCLK -max 6.000 [get_ports CFG_ERR]
set_input_delay -clock CFG_CCLK -min 2.000 [get_ports CFG_ERR]

# Config Bus Output Timing Constraints
# -max values are used for setup time.  2ns output_delay sets a Tco max of 8ns, since it is a 10ns cycle
# -min values are used for hold timing.  -1ns indicates that the actual output hold time requirement is 1ns
set_output_delay -clock CFG_CCLK -max 2.000 [get_ports {CFGD[*]}]
set_output_delay -clock CFG_CCLK -max 2.000 [get_ports FPGA_CMDL]
set_output_delay -clock CFG_CCLK -max 2.000 [get_ports FPGA_RDYL]
set_output_delay -clock CFG_CCLK -max 2.000 [get_ports STAT_OEL]
set_output_delay -clock CFG_CCLK -min -1.000 [get_ports {CFGD[*]}]
set_output_delay -clock CFG_CCLK -min -1.000 [get_ports FPGA_CMDL]
set_output_delay -clock CFG_CCLK -min -1.000 [get_ports FPGA_RDYL]
set_output_delay -clock CFG_CCLK -min -1.000 [get_ports STAT_OEL]

# Config Bus I/O and Outputs
set_property PACKAGE_PIN P25 [get_ports FPGA_RDYL]
set_property IOSTANDARD LVCMOS25 [get_ports FPGA_RDYL]
set_property SLEW FAST [get_ports FPGA_RDYL]
set_property PACKAGE_PIN R25 [get_ports FPGA_CMDL]
set_property IOSTANDARD LVCMOS25 [get_ports FPGA_CMDL]
set_property SLEW FAST [get_ports FPGA_CMDL]
set_property PACKAGE_PIN P26 [get_ports STAT_OEL]
set_property IOSTANDARD LVCMOS25 [get_ports STAT_OEL]
set_property SLEW FAST [get_ports STAT_OEL]
set_property PACKAGE_PIN R14 [get_ports {CFGD[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {CFGD[0]}]
set_property SLEW FAST [get_ports {CFGD[0]}]
set_property PACKAGE_PIN R15 [get_ports {CFGD[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {CFGD[1]}]
set_property SLEW FAST [get_ports {CFGD[1]}]
set_property PACKAGE_PIN P14 [get_ports {CFGD[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {CFGD[2]}]
set_property SLEW FAST [get_ports {CFGD[2]}]
set_property PACKAGE_PIN N14 [get_ports {CFGD[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {CFGD[3]}]
set_property SLEW FAST [get_ports {CFGD[3]}]
set_property PACKAGE_PIN N16 [get_ports {CFGD[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {CFGD[4]}]
set_property SLEW FAST [get_ports {CFGD[4]}]
set_property PACKAGE_PIN N17 [get_ports {CFGD[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {CFGD[5]}]
set_property SLEW FAST [get_ports {CFGD[5]}]
set_property PACKAGE_PIN R16 [get_ports {CFGD[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {CFGD[6]}]
set_property SLEW FAST [get_ports {CFGD[6]}]
set_property PACKAGE_PIN R17 [get_ports {CFGD[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {CFGD[7]}]
set_property SLEW FAST [get_ports {CFGD[7]}]
set_property PACKAGE_PIN N18 [get_ports {CFGD[8]}]
set_property IOSTANDARD LVCMOS25 [get_ports {CFGD[8]}]
set_property SLEW FAST [get_ports {CFGD[8]}]
set_property PACKAGE_PIN K25 [get_ports {CFGD[9]}]
set_property IOSTANDARD LVCMOS25 [get_ports {CFGD[9]}]
set_property SLEW FAST [get_ports {CFGD[9]}]
set_property PACKAGE_PIN K26 [get_ports {CFGD[10]}]
set_property IOSTANDARD LVCMOS25 [get_ports {CFGD[10]}]
set_property SLEW FAST [get_ports {CFGD[10]}]
set_property PACKAGE_PIN M20 [get_ports {CFGD[11]}]
set_property IOSTANDARD LVCMOS25 [get_ports {CFGD[11]}]
set_property SLEW FAST [get_ports {CFGD[11]}]
set_property PACKAGE_PIN L20 [get_ports {CFGD[12]}]
set_property IOSTANDARD LVCMOS25 [get_ports {CFGD[12]}]
set_property SLEW FAST [get_ports {CFGD[12]}]
set_property PACKAGE_PIN L25 [get_ports {CFGD[13]}]
set_property IOSTANDARD LVCMOS25 [get_ports {CFGD[13]}]
set_property SLEW FAST [get_ports {CFGD[13]}]
set_property PACKAGE_PIN M24 [get_ports {CFGD[14]}]
set_property IOSTANDARD LVCMOS25 [get_ports {CFGD[14]}]
set_property SLEW FAST [get_ports {CFGD[14]}]
set_property PACKAGE_PIN M25 [get_ports {CFGD[15]}]
set_property IOSTANDARD LVCMOS25 [get_ports {CFGD[15]}]
set_property SLEW FAST [get_ports {CFGD[15]}]

# Miscellaneous Outputs
set_property PACKAGE_PIN U4 [get_ports SFP_ENH]
set_property IOSTANDARD LVCMOS25 [get_ports SFP_ENH]
set_property SLEW FAST [get_ports SFP_ENH]
set_property PACKAGE_PIN H2 [get_ports SFP_TXDIS]
set_property IOSTANDARD LVCMOS25 [get_ports SFP_TXDIS]
set_property SLEW FAST [get_ports SFP_TXDIS]
set_property PACKAGE_PIN N4 [get_ports SFP_SCL]
set_property IOSTANDARD LVCMOS25 [get_ports SFP_SCL]
set_property SLEW FAST [get_ports SFP_SCL]
set_property PACKAGE_PIN L23 [get_ports {DBG[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DBG[0]}]
set_property SLEW FAST [get_ports {DBG[0]}]
set_property PACKAGE_PIN P24 [get_ports {DBG[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DBG[1]}]
set_property SLEW FAST [get_ports {DBG[1]}]
set_property PACKAGE_PIN P23 [get_ports {DBG[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DBG[2]}]
set_property SLEW FAST [get_ports {DBG[2]}]
set_property PACKAGE_PIN M26 [get_ports {DBG[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DBG[3]}]
set_property SLEW FAST [get_ports {DBG[3]}]
set_property PACKAGE_PIN T25 [get_ports {DBG[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DBG[4]}]
set_property DRIVE 8 [get_ports {DBG[4]}]
set_property SLEW FAST [get_ports {DBG[4]}]
set_property PACKAGE_PIN T24 [get_ports {DBG[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DBG[5]}]
set_property DRIVE 8 [get_ports {DBG[5]}]
set_property SLEW FAST [get_ports {DBG[5]}]
set_property PACKAGE_PIN R23 [get_ports {DBG[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DBG[6]}]
set_property DRIVE 8 [get_ports {DBG[6]}]
set_property SLEW FAST [get_ports {DBG[6]}]
set_property PACKAGE_PIN T23 [get_ports {DBG[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DBG[7]}]
set_property DRIVE 8 [get_ports {DBG[7]}]
set_property SLEW FAST [get_ports {DBG[7]}]
set_property PACKAGE_PIN L24 [get_ports {DBG[8]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DBG[8]}]
set_property SLEW FAST [get_ports {DBG[8]}]
set_property PULLUP true [get_ports {DBG[8]}]

# Miscellaneous Inputs
set_property PACKAGE_PIN P4 [get_ports SFP_SDA]
set_property IOSTANDARD LVCMOS25 [get_ports SFP_SDA]
set_property PACKAGE_PIN H1 [get_ports SFP_FAULT]
set_property IOSTANDARD LVCMOS25 [get_ports SFP_FAULT]
set_property PACKAGE_PIN M2 [get_ports SFP_LOS]
set_property IOSTANDARD LVCMOS25 [get_ports SFP_LOS]
set_property PACKAGE_PIN L2 [get_ports SFP_PRESL]
set_property IOSTANDARD LVCMOS25 [get_ports SFP_PRESL]
set_property PACKAGE_PIN N21 [get_ports REF_FPGA]
set_property IOSTANDARD LVCMOS25 [get_ports REF_FPGA]

# Input Comparator Related Inputs
set_property PACKAGE_PIN V3 [get_ports {TRG_CMPP[0]}]
set_property PACKAGE_PIN V1 [get_ports {TRG_CMPP[1]}]
set_property PACKAGE_PIN Y2 [get_ports {TRG_CMPP[2]}]
set_property PACKAGE_PIN AA3 [get_ports {TRG_CMPP[3]}]
set_property PACKAGE_PIN AB1 [get_ports {TRG_CMPP[4]}]
set_property PACKAGE_PIN AB2 [get_ports {TRG_CMPP[5]}]
set_property PACKAGE_PIN AD1 [get_ports {TRG_CMPP[6]}]
set_property PACKAGE_PIN AE2 [get_ports {TRG_CMPP[7]}]

set_property IOSTANDARD LVDS_25 [get_ports {TRG_CMPN[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRG_CMPN[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRG_CMPN[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRG_CMPN[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRG_CMPN[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRG_CMPN[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRG_CMPN[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRG_CMPN[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRG_CMPP[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRG_CMPP[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRG_CMPP[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRG_CMPP[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRG_CMPP[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRG_CMPP[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRG_CMPP[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRG_CMPP[7]}]

# PWM Threshold Outputs
set_property PACKAGE_PIN W3 [get_ports {THR[0]}]
set_property PACKAGE_PIN Y3 [get_ports {THR[1]}]
set_property PACKAGE_PIN AC3 [get_ports {THR[2]}]
set_property PACKAGE_PIN AC4 [get_ports {THR[3]}]
set_property PACKAGE_PIN AD3 [get_ports {THR[4]}]
set_property PACKAGE_PIN AD4 [get_ports {THR[5]}]
set_property PACKAGE_PIN AE3 [get_ports {THR[6]}]
set_property PACKAGE_PIN AF3 [get_ports {THR[7]}]

set_property IOSTANDARD LVCMOS25 [get_ports {THR[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {THR[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {THR[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {THR[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {THR[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {THR[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {THR[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {THR[7]}]

# Additional Debug LEDs
set_property PACKAGE_PIN U24 [get_ports {LED[0]}]
set_property PACKAGE_PIN U25 [get_ports {LED[1]}]
set_property PACKAGE_PIN U26 [get_ports {LED[2]}]
set_property PACKAGE_PIN V26 [get_ports {LED[3]}]
set_property PACKAGE_PIN W26 [get_ports {LED[4]}]
set_property PACKAGE_PIN W25 [get_ports {LED[5]}]
set_property PACKAGE_PIN Y26 [get_ports {LED[6]}]
set_property PACKAGE_PIN Y25 [get_ports {LED[7]}]
set_property PACKAGE_PIN AA25 [get_ports {LED[8]}]
set_property PACKAGE_PIN AB26 [get_ports {LED[9]}]

set_property IOSTANDARD LVCMOS25 [get_ports {LED[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {LED[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {LED[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {LED[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {LED[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {LED[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {LED[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {LED[8]}]
set_property IOSTANDARD LVCMOS25 [get_ports {LED[9]}]

# Trigger Outputs
# TO1 = JT0
# TO2 = JT2
# TO3 = JT4
# TO4 = JT6
# TO5 = JC01
# TO6 = JT3
# TO7 = JT1
# TO8 = JT5
# TO9 = JT7
# TAUX = JT8

set_property PACKAGE_PIN A3 [get_ports {TRGCLK_OUTP[0]}]
set_property PACKAGE_PIN C2 [get_ports {TRGCLK_OUTP[1]}]
set_property PACKAGE_PIN E1 [get_ports {TRGCLK_OUTP[2]}]
set_property PACKAGE_PIN N3 [get_ports {TRGCLK_OUTP[3]}]
set_property PACKAGE_PIN R3 [get_ports {TRGCLK_OUTP[4]}]
set_property PACKAGE_PIN C26 [get_ports {TRGCLK_OUTP[5]}]
set_property PACKAGE_PIN B20 [get_ports {TRGCLK_OUTP[6]}]
set_property PACKAGE_PIN H26 [get_ports {TRGCLK_OUTP[7]}]
set_property PACKAGE_PIN AA24 [get_ports {TRGCLK_OUTP[8]}]

set_property PACKAGE_PIN C1 [get_ports {TRGDAT_OUTP[0]}]
set_property PACKAGE_PIN D3 [get_ports {TRGDAT_OUTP[1]}]
set_property PACKAGE_PIN G2 [get_ports {TRGDAT_OUTP[2]}]
set_property PACKAGE_PIN K1 [get_ports {TRGDAT_OUTP[3]}]
set_property PACKAGE_PIN R1 [get_ports {TRGDAT_OUTP[4]}]
set_property PACKAGE_PIN E26 [get_ports {TRGDAT_OUTP[5]}]
set_property PACKAGE_PIN A23 [get_ports {TRGDAT_OUTP[6]}]
set_property PACKAGE_PIN J25 [get_ports {TRGDAT_OUTP[7]}]
set_property PACKAGE_PIN AB24 [get_ports {TRGDAT_OUTP[8]}]

set_property IOSTANDARD LVDS_25 [get_ports {TRGCLK_OUTN[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGCLK_OUTN[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGCLK_OUTN[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGCLK_OUTN[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGCLK_OUTN[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGCLK_OUTN[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGCLK_OUTN[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGCLK_OUTN[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGCLK_OUTN[8]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGCLK_OUTP[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGCLK_OUTP[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGCLK_OUTP[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGCLK_OUTP[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGCLK_OUTP[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGCLK_OUTP[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGCLK_OUTP[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGCLK_OUTP[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGCLK_OUTP[8]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGDAT_OUTN[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGDAT_OUTN[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGDAT_OUTN[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGDAT_OUTN[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGDAT_OUTN[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGDAT_OUTN[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGDAT_OUTN[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGDAT_OUTN[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGDAT_OUTN[8]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGDAT_OUTP[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGDAT_OUTP[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGDAT_OUTP[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGDAT_OUTP[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGDAT_OUTP[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGDAT_OUTP[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGDAT_OUTP[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGDAT_OUTP[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRGDAT_OUTP[8]}]

# Auxiliary SATA
set_property PACKAGE_PIN AD25 [get_ports {TRIG_CTRLP[0]}]
set_property PACKAGE_PIN AE25 [get_ports {TRIG_CTRLP[1]}]

set_property IOSTANDARD LVDS_25 [get_ports {TRIG_CTRLN[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRIG_CTRLN[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRIG_CTRLP[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {TRIG_CTRLP[1]}]

set_property DIFF_TERM TRUE [get_ports {TRIG_CTRLN[0]}]
set_property DIFF_TERM TRUE [get_ports {TRIG_CTRLN[1]}]
set_property DIFF_TERM TRUE [get_ports {TRIG_CTRLP[0]}]
set_property DIFF_TERM TRUE [get_ports {TRIG_CTRLP[1]}]

# Must LOC IDELAYCTRL if there is more than one IDELAYCTRL in the design
# create_pblock pblock_TIL1
# add_cells_to_pblock [get_pblocks pblock_TIL1] [get_cells -quiet [list TIL1]]
# resize_pblock [get_pblocks pblock_TIL1] -add {CLOCKREGION_X0Y0:CLOCKREGION_X0Y0}
# set_property LOC IDELAYCTRL_X1Y2 [get_cells TIL1/IDC1]

# Define 100 MHz clock on Aux SATA input
create_clock -period 10.000 -name TAUX_CLK -waveform {0.000 5.000} [get_pins TIL1/SIN1/O]

# Extra SMA I/O pins
#set_property PACKAGE_PIN AF4  [get_ports {TRIGIO_A[0]}]
#set_property PACKAGE_PIN AF5  [get_ports {TRIGIO_A[1]}]
#set_property PACKAGE_PIN AF19 [get_ports {TRIGIO_B[0]}]
#set_property PACKAGE_PIN AF20 [get_ports {TRIGIO_B[1]}]

#set_property IOSTANDARD LVCMOS25 [get_ports {TRIGIO_A[0]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {TRIGIO_A[1]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {TRIGIO_B[0]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {TRIGIO_B[1]}]

#***********************************************************
# The following constraints target the Transceiver Physical*
# Interface which is instantiated in the Example Design.   *
#***********************************************************
#-----------------------------------------------------------
# Transceiver I/O placement:                               -
#-----------------------------------------------------------

set_property PACKAGE_PIN A7 [get_ports txn]
set_property PACKAGE_PIN E11 [get_ports gtrefclk_n]

#-----------------------------------------------------------
# PCS/PMA Clock period Constraints: please do not relax    -
#-----------------------------------------------------------
# Disable checking on OE timing since it is enabled more than one clock ahead of using the data
set_false_path -from [get_cells AC1/AMP1/ACP1/CFG1/ExtOE] -to [get_ports {CFGD[*]}]
set_false_path -to [get_ports STAT_OEL]

set_clock_groups -asynchronous \
-group [get_clocks -of_objects [get_pins CK0/CLK_100MHZ]] \
-group [get_clocks clkout0]

# Don't care about output timing on these signals
set_false_path -to [get_ports {DBG[*]}]
set_false_path -to [get_ports {LED[*]}]

set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS25} [get_ports fpga_resetl]
set_property -dict {PACKAGE_PIN N21 IOSTANDARD LVCMOS25} [get_ports ref_fpga]

# SFP transceiver
set_property PACKAGE_PIN B11 [get_ports sfp_rxp]
set_property PACKAGE_PIN B7 [get_ports sfp_txp]
set_property PACKAGE_PIN F11 [get_ports sfp_mgt_clkp]

#### Debug Header / front panel LEDs ####
set_property PACKAGE_PIN L23 [get_ports dbg[0]]
set_property PACKAGE_PIN P24 [get_ports dbg[1]]
set_property PACKAGE_PIN P23 [get_ports dbg[2]]
set_property PACKAGE_PIN M26 [get_ports dbg[3]]
set_property PACKAGE_PIN T25 [get_ports dbg[4]]
set_property PACKAGE_PIN T24 [get_ports dbg[5]]
set_property PACKAGE_PIN R23 [get_ports dbg[6]]
set_property PACKAGE_PIN T23 [get_ports dbg[7]]
set_property PACKAGE_PIN L24 [get_ports dbg[8]]
set_property IOSTANDARD LVCMOS25 [get_ports dbg[*]]
set_property SLEW FAST [get_ports dbg[*]]
set_property DRIVE 8 [get_ports -regexp {dbg\[[4-7]\]}]
set_property PULLUP true [get_ports dbg[8]]


#### SFP control ports ####

set_property PACKAGE_PIN U4 [get_ports sfp_enh]
set_property PACKAGE_PIN H2 [get_ports sfp_txdis]
set_property PACKAGE_PIN N4 [get_ports sfp_scl]
set_property PACKAGE_PIN M2 [get_ports sfp_los]
set_property PACKAGE_PIN L2 [get_ports sfp_presl]
set_property IOSTANDARD LVCMOS25 [get_ports -regexp {sfp_(enh|txdis|scl|los|presl)}]
set_property SLEW FAST [get_ports -regexp {sfp_(enh|txdis|scl)}]

## unused ports
set_property PACKAGE_PIN N4 [get_ports sfp_scl]
set_property PACKAGE_PIN P4 [get_ports sfp_sda]
set_property PACKAGE_PIN H1 [get_ports sfp_fault]
set_property IOSTANDARD LVCMOS25 [get_ports -regexp {sfp_(scl|sda|fault)}]

#### CPLD interface ####

set_property PACKAGE_PIN N23 [get_ports cfg_rdy]
set_property PACKAGE_PIN N26 [get_ports cfg_act]
set_property PACKAGE_PIN M19 [get_ports fpga_resetl]
set_property PACKAGE_PIN P19 [get_ports cfg_err]
set_property PACKAGE_PIN M21 [get_ports cfg_clk]
set_property PACKAGE_PIN P25 [get_ports fpga_rdyl]
set_property PACKAGE_PIN R25 [get_ports fpga_cmdl]
set_property PACKAGE_PIN P26 [get_ports stat_oel]
set_property IOSTANDARD LVCMOS25 [get_ports {cfg_rdy cfg_act fpga_resetl cfg_err cfg_clk fpga_rdyl fpga_cmdl stat_oel}]
set_property SLEW FAST [get_ports {fpga_rdyl fpga_cmdl stat_oel}]

set_property PACKAGE_PIN R14 [get_ports {cfgd[0]}]
set_property PACKAGE_PIN R15 [get_ports {cfgd[1]}]
set_property PACKAGE_PIN P14 [get_ports {cfgd[2]}]
set_property PACKAGE_PIN N14 [get_ports {cfgd[3]}]
set_property PACKAGE_PIN N16 [get_ports {cfgd[4]}]
set_property PACKAGE_PIN N17 [get_ports {cfgd[5]}]
set_property PACKAGE_PIN R16 [get_ports {cfgd[6]}]
set_property PACKAGE_PIN R17 [get_ports {cfgd[7]}]
set_property PACKAGE_PIN N18 [get_ports {cfgd[8]}]
set_property PACKAGE_PIN K25 [get_ports {cfgd[9]}]
set_property PACKAGE_PIN K26 [get_ports {cfgd[10]}]
set_property PACKAGE_PIN M20 [get_ports {cfgd[11]}]
set_property PACKAGE_PIN L20 [get_ports {cfgd[12]}]
set_property PACKAGE_PIN L25 [get_ports {cfgd[13]}]
set_property PACKAGE_PIN M24 [get_ports {cfgd[14]}]
set_property PACKAGE_PIN M25 [get_ports {cfgd[15]}]
set_property IOSTANDARD LVCMOS25 [get_ports cfgd[*]]
set_property SLEW FAST [get_ports cfgd[*]]

# Input Comparator Related Inputs
set_property PACKAGE_PIN V3 [get_ports {trg_cmpp[0]}]
set_property PACKAGE_PIN V1 [get_ports {trg_cmpp[1]}]
set_property PACKAGE_PIN Y2 [get_ports {trg_cmpp[2]}]
set_property PACKAGE_PIN AA3 [get_ports {trg_cmpp[3]}]
set_property PACKAGE_PIN AB1 [get_ports {trg_cmpp[4]}]
set_property PACKAGE_PIN AB2 [get_ports {trg_cmpp[5]}]
set_property PACKAGE_PIN AD1 [get_ports {trg_cmpp[6]}]
set_property PACKAGE_PIN AE2 [get_ports {trg_cmpp[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {trg_cmpp[*]}]

# PWM Threshold Outputs
set_property PACKAGE_PIN W3 [get_ports {thr[0]}]
set_property PACKAGE_PIN Y3 [get_ports {thr[1]}]
set_property PACKAGE_PIN AC3 [get_ports {thr[2]}]
set_property PACKAGE_PIN AC4 [get_ports {thr[3]}]
set_property PACKAGE_PIN AD3 [get_ports {thr[4]}]
set_property PACKAGE_PIN AD4 [get_ports {thr[5]}]
set_property PACKAGE_PIN AE3 [get_ports {thr[6]}]
set_property PACKAGE_PIN AF3 [get_ports {thr[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {thr[*]}]

# Additional Debug LEDs
set_property PACKAGE_PIN U24 [get_ports {led[0]}]
set_property PACKAGE_PIN U25 [get_ports {led[1]}]
set_property PACKAGE_PIN U26 [get_ports {led[2]}]
set_property PACKAGE_PIN V26 [get_ports {led[3]}]
set_property PACKAGE_PIN W26 [get_ports {led[4]}]
set_property PACKAGE_PIN W25 [get_ports {led[5]}]
set_property PACKAGE_PIN Y26 [get_ports {led[6]}]
set_property PACKAGE_PIN Y25 [get_ports {led[7]}]
set_property PACKAGE_PIN AA25 [get_ports {led[8]}]
set_property PACKAGE_PIN AB26 [get_ports {led[9]}]
set_property IOSTANDARD LVCMOS25 [get_ports {led[*]}]

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

set_property PACKAGE_PIN A3 [get_ports {trgclk_outp[0]}]
set_property PACKAGE_PIN C2 [get_ports {trgclk_outp[1]}]
set_property PACKAGE_PIN E1 [get_ports {trgclk_outp[2]}]
set_property PACKAGE_PIN N3 [get_ports {trgclk_outp[3]}]
set_property PACKAGE_PIN R3 [get_ports {trgclk_outp[4]}]
set_property PACKAGE_PIN C26 [get_ports {trgclk_outp[5]}]
set_property PACKAGE_PIN B20 [get_ports {trgclk_outp[6]}]
set_property PACKAGE_PIN H26 [get_ports {trgclk_outp[7]}]
set_property PACKAGE_PIN AA24 [get_ports {trgclk_outp[8]}]
set_property IOSTANDARD LVDS_25 [get_ports {trgclk_outp[*]}]

set_property PACKAGE_PIN C1 [get_ports {trgdat_outp[0]}]
set_property PACKAGE_PIN D3 [get_ports {trgdat_outp[1]}]
set_property PACKAGE_PIN G2 [get_ports {trgdat_outp[2]}]
set_property PACKAGE_PIN K1 [get_ports {trgdat_outp[3]}]
set_property PACKAGE_PIN R1 [get_ports {trgdat_outp[4]}]
set_property PACKAGE_PIN E26 [get_ports {trgdat_outp[5]}]
set_property PACKAGE_PIN A23 [get_ports {trgdat_outp[6]}]
set_property PACKAGE_PIN J25 [get_ports {trgdat_outp[7]}]
set_property PACKAGE_PIN AB24 [get_ports {trgdat_outp[8]}]
set_property IOSTANDARD LVDS_25 [get_ports {trgdat_outp[*]}]

# Auxiliary SATA
set_property PACKAGE_PIN AD25 [get_ports {trig_ctrlp[0]}]
set_property PACKAGE_PIN AE25 [get_ports {trig_ctrlp[1]}]

set_property IOSTANDARD LVDS_25 [get_ports {trig_ctrln[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {trig_ctrln[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {trig_ctrlp[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {trig_ctrlp[1]}]

set_property DIFF_TERM TRUE [get_ports {trig_ctrln[0]}]
set_property DIFF_TERM TRUE [get_ports {trig_ctrln[1]}]
set_property DIFF_TERM TRUE [get_ports {trig_ctrlp[0]}]
set_property DIFF_TERM TRUE [get_ports {trig_ctrlp[1]}]


# Extra SMA I/O pins
#set_property PACKAGE_PIN AF4  [get_ports {trigio_a[0]}]
#set_property PACKAGE_PIN AF5  [get_ports {trigio_a[1]}]
#set_property PACKAGE_PIN AF19 [get_ports {trigio_b[0]}]
#set_property PACKAGE_PIN AF20 [get_ports {trigio_b[1]}]

#set_property IOSTANDARD LVCMOS25 [get_ports {trigio_a[0]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {trigio_a[1]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {trigio_b[0]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {trigio_b[1]}]


#Set configuration voltages to avoid DRC issue
#Also set consistent IOSTANDARD for vp/vn from XADC which are hard-wired to Bank 0 which is used for config
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 2.5 [current_design]
set_property IOSTANDARD LVCMOS25 [get_ports vp]
set_property IOSTANDARD LVCMOS25 [get_ports vn]


################################################################
# This is a generated script based on design: main_bd
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2016.3
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source main_bd_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# TDM_CSR, UDP_responder, com5402_wrapper, eprom_cfg_reader, eth_mac_1g_fifo_wrapper, tcp_bridge

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7a200tfbg676-2
}


# CHANGE DESIGN NAME HERE
set design_name main_bd

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set sfp [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:sfp_rtl:1.0 sfp ]
  set sfp_mgt_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sfp_mgt_clk ]

  # Create ports
  set SATA_status [ create_bd_port -dir I -from 31 -to 0 SATA_status ]
  set build_timestamp [ create_bd_port -dir I -from 31 -to 0 build_timestamp ]
  set cfg_act [ create_bd_port -dir I cfg_act ]
  set cfg_clk [ create_bd_port -dir I -type clk cfg_clk ]
  set cfg_err [ create_bd_port -dir I cfg_err ]
  set cfg_rdy [ create_bd_port -dir I cfg_rdy ]
  set cfg_reader_done [ create_bd_port -dir O cfg_reader_done ]
  set cfgd [ create_bd_port -dir IO -from 15 -to 0 cfgd ]
  set clk_125 [ create_bd_port -dir O -type clk clk_125 ]
  set_property -dict [ list \
CONFIG.ASSOCIATED_RESET {rst_udp_responder:rst_comblock:rst_eth_mac} \
 ] $clk_125
  set clk_axi [ create_bd_port -dir I -type clk clk_axi ]
  set_property -dict [ list \
CONFIG.ASSOCIATED_RESET {rstn_axi:rst_cfg_reader:rst_tcp_bridge:rst_cpld_bridge:rst_cpld_bridge} \
 ] $clk_axi
  set clk_ref_200 [ create_bd_port -dir I -type clk clk_ref_200 ]
  set comms_active [ create_bd_port -dir O comms_active ]
  set control [ create_bd_port -dir O -from 31 -to 0 control ]
  set ethernet_mm2s_err [ create_bd_port -dir O ethernet_mm2s_err ]
  set ethernet_s2mm_err [ create_bd_port -dir O ethernet_s2mm_err ]
  set fpga_cmdl [ create_bd_port -dir O fpga_cmdl ]
  set fpga_rdyl [ create_bd_port -dir O fpga_rdyl ]
  set gateway_ip_addr [ create_bd_port -dir I -from 31 -to 0 gateway_ip_addr ]
  set git_sha1 [ create_bd_port -dir I -from 31 -to 0 git_sha1 ]
  set ifg_delay [ create_bd_port -dir I -from 7 -to 0 ifg_delay ]
  set pcs_pma_an_adv_config_vector [ create_bd_port -dir I -from 15 -to 0 pcs_pma_an_adv_config_vector ]
  set pcs_pma_an_restart_config [ create_bd_port -dir I pcs_pma_an_restart_config ]
  set pcs_pma_configuration_vector [ create_bd_port -dir I -from 4 -to 0 pcs_pma_configuration_vector ]
  set pcs_pma_mmcm_locked [ create_bd_port -dir O pcs_pma_mmcm_locked ]
  set pcs_pma_status_vector [ create_bd_port -dir O -from 15 -to 0 pcs_pma_status_vector ]
  set resets [ create_bd_port -dir O -from 31 -to 0 resets ]
  set rst_cfg_reader [ create_bd_port -dir I -type rst rst_cfg_reader ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $rst_cfg_reader
  set rst_comblock [ create_bd_port -dir I -type rst rst_comblock ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $rst_comblock
  set rst_cpld_bridge [ create_bd_port -dir I -type rst rst_cpld_bridge ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $rst_cpld_bridge
  set rst_eth_mac [ create_bd_port -dir I -type rst rst_eth_mac ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $rst_eth_mac
  set rst_pcs_pma [ create_bd_port -dir I -type rst rst_pcs_pma ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $rst_pcs_pma
  set rst_tcp_bridge [ create_bd_port -dir I -type rst rst_tcp_bridge ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $rst_tcp_bridge
  set rst_udp_responder [ create_bd_port -dir I -type rst rst_udp_responder ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $rst_udp_responder
  set rstn_axi [ create_bd_port -dir I -type rst rstn_axi ]
  set sfp_signal_detect [ create_bd_port -dir I sfp_signal_detect ]
  set stat_oel [ create_bd_port -dir O stat_oel ]
  set subnet_mask [ create_bd_port -dir I -from 31 -to 0 subnet_mask ]
  set tcp_port [ create_bd_port -dir I -from 15 -to 0 tcp_port ]
  set tdm_version [ create_bd_port -dir I -from 31 -to 0 tdm_version ]
  set temperature [ create_bd_port -dir I -from 31 -to 0 temperature ]
  set trigger_interval [ create_bd_port -dir O -from 31 -to 0 trigger_interval ]
  set trigger_word [ create_bd_port -dir I -from 31 -to 0 trigger_word ]
  set udp_port [ create_bd_port -dir I -from 15 -to 0 udp_port ]
  set uptime_nanoseconds [ create_bd_port -dir I -from 31 -to 0 uptime_nanoseconds ]
  set uptime_seconds [ create_bd_port -dir I -from 31 -to 0 uptime_seconds ]

  # Create instance: CPLD_bridge_0, and set properties
  set CPLD_bridge_0 [ create_bd_cell -type ip -vlnv bbn.com:bbn:CPLD_bridge:1.0 CPLD_bridge_0 ]
  set_property -dict [ list \
CONFIG.BOARD_TYPE {"00000001"} \
 ] $CPLD_bridge_0

  # Create instance: TDM_CSR_0, and set properties
  set block_name TDM_CSR
  set block_cell_name TDM_CSR_0
  if { [catch {set TDM_CSR_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $TDM_CSR_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: UDP_responder_0, and set properties
  set block_name UDP_responder
  set block_cell_name UDP_responder_0
  if { [catch {set UDP_responder_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $UDP_responder_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axi_datamover_0, and set properties
  set axi_datamover_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_datamover:5.1 axi_datamover_0 ]

  # Create instance: com5402_wrapper_0, and set properties
  set block_name com5402_wrapper
  set block_cell_name com5402_wrapper_0
  if { [catch {set com5402_wrapper_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $com5402_wrapper_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: eprom_cfg_reader_0, and set properties
  set block_name eprom_cfg_reader
  set block_cell_name eprom_cfg_reader_0
  if { [catch {set eprom_cfg_reader_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $eprom_cfg_reader_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: eth_mac_1g_fifo_wrapper_0, and set properties
  set block_name eth_mac_1g_fifo_wrapper
  set block_cell_name eth_mac_1g_fifo_wrapper_0
  if { [catch {set eth_mac_1g_fifo_wrapper_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $eth_mac_1g_fifo_wrapper_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: gig_ethernet_pcs_pma_0, and set properties
  set gig_ethernet_pcs_pma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:gig_ethernet_pcs_pma:16.0 gig_ethernet_pcs_pma_0 ]
  set_property -dict [ list \
CONFIG.Management_Interface {false} \
CONFIG.Physical_Interface {Transceiver} \
CONFIG.Standard {1000BASEX} \
CONFIG.SupportLevel {Include_Shared_Logic_in_Core} \
 ] $gig_ethernet_pcs_pma_0

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]

  # Create instance: tcp_bridge_0, and set properties
  set block_name tcp_bridge
  set block_cell_name tcp_bridge_0
  if { [catch {set tcp_bridge_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $tcp_bridge_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create interface connections
  connect_bd_intf_net -intf_net CPLD_bridge_0_tx [get_bd_intf_pins CPLD_bridge_0/tx] [get_bd_intf_pins eprom_cfg_reader_0/tx_in]
  connect_bd_intf_net -intf_net UDP_responder_0_udp_tx [get_bd_intf_pins UDP_responder_0/udp_tx] [get_bd_intf_pins com5402_wrapper_0/udp_tx]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXIS_MM2S [get_bd_intf_pins axi_datamover_0/M_AXIS_MM2S] [get_bd_intf_pins tcp_bridge_0/MM2S]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXIS_MM2S_STS [get_bd_intf_pins axi_datamover_0/M_AXIS_MM2S_STS] [get_bd_intf_pins tcp_bridge_0/MM2S_STS]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXIS_S2MM_STS [get_bd_intf_pins axi_datamover_0/M_AXIS_S2MM_STS] [get_bd_intf_pins tcp_bridge_0/S2MM_STS]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXI_MM2S [get_bd_intf_pins axi_datamover_0/M_AXI_MM2S] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXI_S2MM [get_bd_intf_pins axi_datamover_0/M_AXI_S2MM] [get_bd_intf_pins smartconnect_0/S01_AXI]
  connect_bd_intf_net -intf_net com5402_wrapper_0_mac_tx [get_bd_intf_pins com5402_wrapper_0/mac_tx] [get_bd_intf_pins eth_mac_1g_fifo_wrapper_0/tx_axis]
  connect_bd_intf_net -intf_net com5402_wrapper_0_tcp_rx [get_bd_intf_pins com5402_wrapper_0/tcp_rx] [get_bd_intf_pins tcp_bridge_0/tcp_rx]
  connect_bd_intf_net -intf_net com5402_wrapper_0_udp_rx [get_bd_intf_pins UDP_responder_0/udp_rx] [get_bd_intf_pins com5402_wrapper_0/udp_rx]
  connect_bd_intf_net -intf_net eprom_cfg_reader_0_rx_out [get_bd_intf_pins CPLD_bridge_0/rx] [get_bd_intf_pins eprom_cfg_reader_0/rx_out]
  connect_bd_intf_net -intf_net eprom_cfg_reader_0_tx_out [get_bd_intf_pins eprom_cfg_reader_0/tx_out] [get_bd_intf_pins tcp_bridge_0/cpld_tx]
  connect_bd_intf_net -intf_net eth_mac_1g_fifo_wrapper_0_gmii [get_bd_intf_pins eth_mac_1g_fifo_wrapper_0/gmii] [get_bd_intf_pins gig_ethernet_pcs_pma_0/gmii_pcs_pma]
  connect_bd_intf_net -intf_net eth_mac_1g_fifo_wrapper_0_rx_axis [get_bd_intf_pins com5402_wrapper_0/mac_rx] [get_bd_intf_pins eth_mac_1g_fifo_wrapper_0/rx_axis]
  connect_bd_intf_net -intf_net gig_ethernet_pcs_pma_0_sfp [get_bd_intf_ports sfp] [get_bd_intf_pins gig_ethernet_pcs_pma_0/sfp]
  connect_bd_intf_net -intf_net gtrefclk_in_1 [get_bd_intf_ports sfp_mgt_clk] [get_bd_intf_pins gig_ethernet_pcs_pma_0/gtrefclk_in]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins TDM_CSR_0/s_axi] [get_bd_intf_pins smartconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net tcp_bridge_0_MM2S_CMD [get_bd_intf_pins axi_datamover_0/S_AXIS_MM2S_CMD] [get_bd_intf_pins tcp_bridge_0/MM2S_CMD]
  connect_bd_intf_net -intf_net tcp_bridge_0_S2MM [get_bd_intf_pins axi_datamover_0/S_AXIS_S2MM] [get_bd_intf_pins tcp_bridge_0/S2MM]
  connect_bd_intf_net -intf_net tcp_bridge_0_S2MM_CMD [get_bd_intf_pins axi_datamover_0/S_AXIS_S2MM_CMD] [get_bd_intf_pins tcp_bridge_0/S2MM_CMD]
  connect_bd_intf_net -intf_net tcp_bridge_0_cpld_rx [get_bd_intf_pins eprom_cfg_reader_0/rx_in] [get_bd_intf_pins tcp_bridge_0/cpld_rx]
  connect_bd_intf_net -intf_net tcp_bridge_0_tcp_tx [get_bd_intf_pins com5402_wrapper_0/tcp_tx] [get_bd_intf_pins tcp_bridge_0/tcp_tx]

  # Create port connections
  connect_bd_net -net ARESETN_1 [get_bd_ports rstn_axi] [get_bd_pins TDM_CSR_0/s_axi_aresetn] [get_bd_pins axi_datamover_0/m_axi_mm2s_aresetn] [get_bd_pins axi_datamover_0/m_axi_s2mm_aresetn] [get_bd_pins axi_datamover_0/m_axis_mm2s_cmdsts_aresetn] [get_bd_pins axi_datamover_0/m_axis_s2mm_cmdsts_aresetn] [get_bd_pins smartconnect_0/aresetn]
  connect_bd_net -net CPLD_bridge_0_fpga_cmdl [get_bd_ports fpga_cmdl] [get_bd_pins CPLD_bridge_0/fpga_cmdl]
  connect_bd_net -net CPLD_bridge_0_fpga_rdyl [get_bd_ports fpga_rdyl] [get_bd_pins CPLD_bridge_0/fpga_rdyl]
  connect_bd_net -net CPLD_bridge_0_stat_oel [get_bd_ports stat_oel] [get_bd_pins CPLD_bridge_0/stat_oel]
  connect_bd_net -net Net [get_bd_ports cfgd] [get_bd_pins CPLD_bridge_0/cfgd]
  connect_bd_net -net SATA_status_1 [get_bd_ports SATA_status] [get_bd_pins TDM_CSR_0/SATA_status]
  connect_bd_net -net TDM_CSR_0_control [get_bd_ports control] [get_bd_pins TDM_CSR_0/control]
  connect_bd_net -net TDM_CSR_0_resets [get_bd_ports resets] [get_bd_pins TDM_CSR_0/resets]
  connect_bd_net -net TDM_CSR_0_trigger_interval [get_bd_ports trigger_interval] [get_bd_pins TDM_CSR_0/trigger_interval]
  connect_bd_net -net UDP_responder_0_dest_ip_addr [get_bd_pins UDP_responder_0/dest_ip_addr] [get_bd_pins com5402_wrapper_0/udp_tx_dest_ip_addr]
  connect_bd_net -net UDP_responder_0_rst_tcp [get_bd_pins UDP_responder_0/rst_tcp] [get_bd_pins com5402_wrapper_0/tcp_rst]
  connect_bd_net -net an_adv_config_vector_1 [get_bd_ports pcs_pma_an_adv_config_vector] [get_bd_pins gig_ethernet_pcs_pma_0/an_adv_config_vector]
  connect_bd_net -net an_restart_config_1 [get_bd_ports pcs_pma_an_restart_config] [get_bd_pins gig_ethernet_pcs_pma_0/an_restart_config]
  connect_bd_net -net axi_datamover_0_mm2s_err [get_bd_ports ethernet_mm2s_err] [get_bd_pins axi_datamover_0/mm2s_err]
  connect_bd_net -net axi_datamover_0_s2mm_err [get_bd_ports ethernet_s2mm_err] [get_bd_pins axi_datamover_0/s2mm_err]
  connect_bd_net -net build_timestamp_1 [get_bd_ports build_timestamp] [get_bd_pins TDM_CSR_0/build_timestamp]
  connect_bd_net -net cfg_act_1 [get_bd_ports cfg_act] [get_bd_pins CPLD_bridge_0/cfg_act]
  connect_bd_net -net cfg_clk_1 [get_bd_ports cfg_clk] [get_bd_pins CPLD_bridge_0/cfg_clk]
  connect_bd_net -net cfg_err_1 [get_bd_ports cfg_err] [get_bd_pins CPLD_bridge_0/cfg_err]
  connect_bd_net -net cfg_rdy_1 [get_bd_ports cfg_rdy] [get_bd_pins CPLD_bridge_0/cfg_rdy]
  connect_bd_net -net clk_1 [get_bd_ports clk_axi] [get_bd_pins CPLD_bridge_0/clk] [get_bd_pins TDM_CSR_0/s_axi_aclk] [get_bd_pins axi_datamover_0/m_axi_mm2s_aclk] [get_bd_pins axi_datamover_0/m_axi_s2mm_aclk] [get_bd_pins axi_datamover_0/m_axis_mm2s_cmdsts_aclk] [get_bd_pins axi_datamover_0/m_axis_s2mm_cmdsts_awclk] [get_bd_pins eprom_cfg_reader_0/clk] [get_bd_pins smartconnect_0/aclk] [get_bd_pins tcp_bridge_0/clk]
  connect_bd_net -net com5402_wrapper_0_rx_src_ip_addr [get_bd_pins UDP_responder_0/src_ip_addr] [get_bd_pins com5402_wrapper_0/rx_src_ip_addr]
  connect_bd_net -net com5402_wrapper_0_udp_rx_src_port [get_bd_pins UDP_responder_0/udp_src_port] [get_bd_pins com5402_wrapper_0/udp_rx_src_port]
  connect_bd_net -net com5402_wrapper_0_udp_tx_ack [get_bd_pins UDP_responder_0/udp_tx_ack] [get_bd_pins com5402_wrapper_0/udp_tx_ack]
  connect_bd_net -net com5402_wrapper_0_udp_tx_nack [get_bd_pins UDP_responder_0/udp_tx_nack] [get_bd_pins com5402_wrapper_0/udp_tx_nack]
  connect_bd_net -net configuration_vector_1 [get_bd_ports pcs_pma_configuration_vector] [get_bd_pins gig_ethernet_pcs_pma_0/configuration_vector]
  connect_bd_net -net eprom_cfg_reader_0_dhcp_enable [get_bd_pins com5402_wrapper_0/dhcp_enable] [get_bd_pins eprom_cfg_reader_0/dhcp_enable]
  connect_bd_net -net eprom_cfg_reader_0_done [get_bd_ports cfg_reader_done] [get_bd_pins eprom_cfg_reader_0/done]
  connect_bd_net -net eprom_cfg_reader_0_ip_addr [get_bd_pins com5402_wrapper_0/IPv4_addr] [get_bd_pins eprom_cfg_reader_0/ip_addr]
  connect_bd_net -net eprom_cfg_reader_0_mac_addr [get_bd_pins com5402_wrapper_0/mac_addr] [get_bd_pins eprom_cfg_reader_0/mac_addr]
  connect_bd_net -net gateway_ip_addr_1 [get_bd_ports gateway_ip_addr] [get_bd_pins com5402_wrapper_0/gateway_ip_addr]
  connect_bd_net -net gig_ethernet_pcs_pma_0_mmcm_locked_out [get_bd_ports pcs_pma_mmcm_locked] [get_bd_pins gig_ethernet_pcs_pma_0/mmcm_locked_out]
  connect_bd_net -net gig_ethernet_pcs_pma_0_status_vector [get_bd_ports pcs_pma_status_vector] [get_bd_pins gig_ethernet_pcs_pma_0/status_vector]
  connect_bd_net -net gig_ethernet_pcs_pma_0_userclk2_out [get_bd_ports clk_125] [get_bd_pins UDP_responder_0/clk] [get_bd_pins com5402_wrapper_0/clk] [get_bd_pins eth_mac_1g_fifo_wrapper_0/logic_clk] [get_bd_pins eth_mac_1g_fifo_wrapper_0/rx_clk] [get_bd_pins eth_mac_1g_fifo_wrapper_0/tx_clk] [get_bd_pins gig_ethernet_pcs_pma_0/userclk2_out] [get_bd_pins tcp_bridge_0/clk_tcp]
  connect_bd_net -net git_sha1_1 [get_bd_ports git_sha1] [get_bd_pins TDM_CSR_0/git_sha1]
  connect_bd_net -net ifg_delay_1 [get_bd_ports ifg_delay] [get_bd_pins eth_mac_1g_fifo_wrapper_0/ifg_delay]
  connect_bd_net -net independent_clock_bufg_1 [get_bd_ports clk_ref_200] [get_bd_pins gig_ethernet_pcs_pma_0/independent_clock_bufg]
  connect_bd_net -net reset_1 [get_bd_ports rst_pcs_pma] [get_bd_pins gig_ethernet_pcs_pma_0/reset]
  connect_bd_net -net rst [get_bd_ports rst_comblock] [get_bd_pins com5402_wrapper_0/rst] [get_bd_pins tcp_bridge_0/rst_tcp]
  connect_bd_net -net rst_1 [get_bd_ports rst_cfg_reader] [get_bd_pins eprom_cfg_reader_0/rst]
  connect_bd_net -net rst_2 [get_bd_ports rst_udp_responder] [get_bd_pins UDP_responder_0/rst]
  connect_bd_net -net rst_3 [get_bd_ports rst_tcp_bridge] [get_bd_pins tcp_bridge_0/rst]
  connect_bd_net -net rst_4 [get_bd_ports rst_cpld_bridge] [get_bd_pins CPLD_bridge_0/rst]
  connect_bd_net -net rx_rst_1 [get_bd_ports rst_eth_mac] [get_bd_pins eth_mac_1g_fifo_wrapper_0/logic_rst] [get_bd_pins eth_mac_1g_fifo_wrapper_0/rx_rst] [get_bd_pins eth_mac_1g_fifo_wrapper_0/tx_rst]
  connect_bd_net -net signal_detect_1 [get_bd_ports sfp_signal_detect] [get_bd_pins gig_ethernet_pcs_pma_0/signal_detect]
  connect_bd_net -net subnet_mask_1 [get_bd_ports subnet_mask] [get_bd_pins com5402_wrapper_0/subnet_mask]
  connect_bd_net -net tcp_bridge_0_comms_active [get_bd_ports comms_active] [get_bd_pins tcp_bridge_0/comms_active]
  connect_bd_net -net tcp_port_1 [get_bd_ports tcp_port] [get_bd_pins com5402_wrapper_0/tcp_port]
  connect_bd_net -net tdm_version_1 [get_bd_ports tdm_version] [get_bd_pins TDM_CSR_0/tdm_version]
  connect_bd_net -net temperature_1 [get_bd_ports temperature] [get_bd_pins TDM_CSR_0/temperature]
  connect_bd_net -net trigger_word_1 [get_bd_ports trigger_word] [get_bd_pins TDM_CSR_0/trigger_word]
  connect_bd_net -net udp_rx_dest_port_1 [get_bd_ports udp_port] [get_bd_pins com5402_wrapper_0/udp_rx_dest_port] [get_bd_pins com5402_wrapper_0/udp_tx_dest_port] [get_bd_pins com5402_wrapper_0/udp_tx_src_port]
  connect_bd_net -net uptime_nanoseconds_1 [get_bd_ports uptime_nanoseconds] [get_bd_pins TDM_CSR_0/uptime_nanoseconds]
  connect_bd_net -net uptime_seconds_1 [get_bd_ports uptime_seconds] [get_bd_pins TDM_CSR_0/uptime_seconds]

  # Create address segments
  create_bd_addr_seg -range 0x00010000 -offset 0x44A00000 [get_bd_addr_spaces axi_datamover_0/Data_MM2S] [get_bd_addr_segs TDM_CSR_0/s_axi/reg0] SEG_TDM_CSR_0_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x44A00000 [get_bd_addr_spaces axi_datamover_0/Data_S2MM] [get_bd_addr_segs TDM_CSR_0/s_axi/reg0] SEG_TDM_CSR_0_reg0

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   guistr: "# # String gsaved with Nlview 6.6.5b  2016-09-06 bk=1.3687 VDI=39 GEI=35 GUI=JA:1.6
#  -string -flagsOSRD
preplace port ethernet_mm2s_err -pg 1 -y 500 -defaultsOSRD
preplace port sfp_signal_detect -pg 1 -y 1100 -defaultsOSRD
preplace port rst_cpld_bridge -pg 1 -y 190 -defaultsOSRD
preplace port cfg_err -pg 1 -y 170 -defaultsOSRD
preplace port sfp_mgt_clk -pg 1 -y 980 -defaultsOSRD
preplace port rst_udp_responder -pg 1 -y 10 -defaultsOSRD
preplace port rst_eth_mac -pg 1 -y 800 -defaultsOSRD
preplace port rst_tcp_bridge -pg 1 -y 50 -defaultsOSRD
preplace port cfg_act -pg 1 -y 90 -defaultsOSRD
preplace port cfg_clk -pg 1 -y 70 -defaultsOSRD
preplace port ethernet_s2mm_err -pg 1 -y 480 -defaultsOSRD
preplace port cfg_reader_done -pg 1 -y 460 -defaultsOSRD
preplace port rst_pcs_pma -pg 1 -y 1080 -defaultsOSRD
preplace port fpga_rdyl -pg 1 -y 670 -defaultsOSRD
preplace port rstn_axi -pg 1 -y 1490 -defaultsOSRD
preplace port sfp -pg 1 -y 850 -defaultsOSRD
preplace port comms_active -pg 1 -y 530 -defaultsOSRD
preplace port pcs_pma_mmcm_locked -pg 1 -y 1030 -defaultsOSRD
preplace port stat_oel -pg 1 -y 690 -defaultsOSRD
preplace port fpga_cmdl -pg 1 -y 650 -defaultsOSRD
preplace port rst_cfg_reader -pg 1 -y 360 -defaultsOSRD
preplace port pcs_pma_an_restart_config -pg 1 -y 1060 -defaultsOSRD
preplace port clk_ref_200 -pg 1 -y 1000 -defaultsOSRD
preplace port clk_125 -pg 1 -y 330 -defaultsOSRD
preplace port rst_comblock -pg 1 -y 130 -defaultsOSRD
preplace port clk_axi -pg 1 -y 1470 -defaultsOSRD
preplace port cfg_rdy -pg 1 -y 210 -defaultsOSRD
preplace portBus git_sha1 -pg 1 -y 1430 -defaultsOSRD
preplace portBus ifg_delay -pg 1 -y 860 -defaultsOSRD
preplace portBus build_timestamp -pg 1 -y 1450 -defaultsOSRD
preplace portBus tdm_version -pg 1 -y 1390 -defaultsOSRD
preplace portBus temperature -pg 1 -y 1410 -defaultsOSRD
preplace portBus gateway_ip_addr -pg 1 -y 150 -defaultsOSRD
preplace portBus trigger_interval -pg 1 -y 1410 -defaultsOSRD
preplace portBus pcs_pma_status_vector -pg 1 -y 1090 -defaultsOSRD
preplace portBus uptime_seconds -pg 1 -y 1350 -defaultsOSRD
preplace portBus uptime_nanoseconds -pg 1 -y 1370 -defaultsOSRD
preplace portBus tcp_port -pg 1 -y 110 -defaultsOSRD
preplace portBus control -pg 1 -y 1390 -defaultsOSRD
preplace portBus subnet_mask -pg 1 -y 30 -defaultsOSRD
preplace portBus pcs_pma_configuration_vector -pg 1 -y 1020 -defaultsOSRD
preplace portBus pcs_pma_an_adv_config_vector -pg 1 -y 1040 -defaultsOSRD
preplace portBus SATA_status -pg 1 -y 1330 -defaultsOSRD
preplace portBus udp_port -pg 1 -y 770 -defaultsOSRD
preplace portBus trigger_word -pg 1 -y 1310 -defaultsOSRD
preplace portBus resets -pg 1 -y 1370 -defaultsOSRD
preplace portBus cfgd -pg 1 -y 630 -defaultsOSRD
preplace inst tcp_bridge_0 -pg 1 -lvl 2 -y 640 -defaultsOSRD
preplace inst UDP_responder_0 -pg 1 -lvl 2 -y 110 -defaultsOSRD
preplace inst TDM_CSR_0 -pg 1 -lvl 5 -y 1390 -defaultsOSRD
preplace inst smartconnect_0 -pg 1 -lvl 4 -y 1180 -defaultsOSRD
preplace inst eth_mac_1g_fifo_wrapper_0 -pg 1 -lvl 4 -y 810 -defaultsOSRD
preplace inst com5402_wrapper_0 -pg 1 -lvl 3 -y 200 -defaultsOSRD
preplace inst eprom_cfg_reader_0 -pg 1 -lvl 1 -y 330 -defaultsOSRD
preplace inst axi_datamover_0 -pg 1 -lvl 1 -y 590 -defaultsOSRD
preplace inst CPLD_bridge_0 -pg 1 -lvl 5 -y 650 -defaultsOSRD
preplace inst gig_ethernet_pcs_pma_0 -pg 1 -lvl 5 -y 1030 -defaultsOSRD
preplace netloc rx_rst_1 1 0 4 NJ 800 NJ 800 NJ 800 1770
preplace netloc CPLD_bridge_0_fpga_rdyl 1 5 1 NJ
preplace netloc tcp_bridge_0_cpld_rx 1 0 3 60 200 620J 270 1120
preplace netloc subnet_mask_1 1 0 3 NJ 30 680J 220 1190J
preplace netloc eprom_cfg_reader_0_ip_addr 1 1 2 N 340 1200J
preplace netloc com5402_wrapper_0_udp_rx 1 1 3 710 430 NJ 430 1740
preplace netloc tcp_bridge_0_S2MM 1 0 3 70 230 530J 370 1100
preplace netloc com5402_wrapper_0_udp_tx_ack 1 1 3 720 440 NJ 440 1720
preplace netloc rst_1 1 0 1 NJ
preplace netloc gig_ethernet_pcs_pma_0_mmcm_locked_out 1 5 1 NJ
preplace netloc configuration_vector_1 1 0 5 NJ 1020 NJ 1020 NJ 1020 NJ 1020 NJ
preplace netloc CPLD_bridge_0_stat_oel 1 5 1 NJ
preplace netloc rst_2 1 0 2 NJ 10 690J
preplace netloc cfg_clk_1 1 0 5 NJ 70 660J 300 1150J 640 NJ 640 2130J
preplace netloc rst_3 1 0 2 NJ 50 590J
preplace netloc axi_datamover_0_mm2s_err 1 1 5 560J 500 NJ 500 NJ 500 NJ 500 NJ
preplace netloc UDP_responder_0_udp_tx 1 2 1 N
preplace netloc rst_4 1 0 5 10J 430 530J 460 1140J 630 NJ 630 NJ
preplace netloc cfg_rdy_1 1 0 5 20J 190 550J 310 1160J 600 NJ 600 2140J
preplace netloc CPLD_bridge_0_tx 1 0 6 30 0 NJ 0 NJ 0 NJ 0 NJ 0 2570
preplace netloc eprom_cfg_reader_0_done 1 1 5 NJ 380 1180J 460 NJ 460 NJ 460 NJ
preplace netloc gtrefclk_in_1 1 0 5 NJ 980 NJ 980 NJ 980 NJ 980 NJ
preplace netloc gig_ethernet_pcs_pma_0_sfp 1 5 1 NJ
preplace netloc com5402_wrapper_0_udp_rx_src_port 1 1 3 750 410 NJ 410 1700
preplace netloc uptime_nanoseconds_1 1 0 5 NJ 1370 NJ 1370 NJ 1370 NJ 1370 NJ
preplace netloc an_adv_config_vector_1 1 0 5 NJ 1040 NJ 1040 NJ 1040 NJ 1040 NJ
preplace netloc ifg_delay_1 1 0 4 NJ 860 NJ 860 NJ 860 NJ
preplace netloc smartconnect_0_M00_AXI 1 4 1 2090
preplace netloc axi_datamover_0_M_AXIS_MM2S 1 1 1 570
preplace netloc axi_datamover_0_M_AXIS_S2MM_STS 1 1 1 510
preplace netloc com5402_wrapper_0_tcp_rx 1 1 3 740 400 NJ 400 1730
preplace netloc rst 1 0 3 NJ 130 540 240 1120
preplace netloc an_restart_config_1 1 0 5 NJ 1060 NJ 1060 NJ 1060 NJ 1060 NJ
preplace netloc uptime_seconds_1 1 0 5 NJ 1350 NJ 1350 NJ 1350 NJ 1350 NJ
preplace netloc axi_datamover_0_M_AXIS_MM2S_STS 1 1 1 580
preplace netloc com5402_wrapper_0_udp_tx_nack 1 1 3 730 450 NJ 450 1710
preplace netloc axi_datamover_0_M_AXI_S2MM 1 1 3 490 1170 NJ 1170 NJ
preplace netloc git_sha1_1 1 0 5 NJ 1430 NJ 1430 NJ 1430 NJ 1430 NJ
preplace netloc SATA_status_1 1 0 5 NJ 1330 NJ 1330 NJ 1330 NJ 1330 NJ
preplace netloc UDP_responder_0_dest_ip_addr 1 2 1 1210
preplace netloc TDM_CSR_0_trigger_interval 1 5 1 NJ
preplace netloc tcp_bridge_0_MM2S_CMD 1 0 3 50 220 600J 250 1110
preplace netloc eprom_cfg_reader_0_tx_out 1 1 1 520
preplace netloc Net 1 5 1 NJ
preplace netloc eprom_cfg_reader_0_mac_addr 1 1 2 N 320 1180J
preplace netloc eth_mac_1g_fifo_wrapper_0_gmii 1 4 1 2100
preplace netloc UDP_responder_0_rst_tcp 1 2 1 1110
preplace netloc signal_detect_1 1 0 5 NJ 1100 NJ 1100 NJ 1100 NJ 1100 NJ
preplace netloc build_timestamp_1 1 0 5 NJ 1450 NJ 1450 NJ 1450 NJ 1450 NJ
preplace netloc TDM_CSR_0_control 1 5 1 NJ
preplace netloc independent_clock_bufg_1 1 0 5 NJ 1000 NJ 1000 NJ 1000 NJ 1000 NJ
preplace netloc tcp_bridge_0_comms_active 1 2 4 1270J 530 NJ 530 NJ 530 NJ
preplace netloc tdm_version_1 1 0 5 NJ 1390 NJ 1390 NJ 1390 NJ 1390 NJ
preplace netloc axi_datamover_0_s2mm_err 1 1 5 550J 480 NJ 480 NJ 480 NJ 480 NJ
preplace netloc eprom_cfg_reader_0_dhcp_enable 1 1 2 N 360 1250J
preplace netloc gateway_ip_addr_1 1 0 3 NJ 150 670J 230 NJ
preplace netloc CPLD_bridge_0_fpga_cmdl 1 5 1 NJ
preplace netloc udp_rx_dest_port_1 1 0 3 NJ 770 NJ 770 1260
preplace netloc tcp_port_1 1 0 3 NJ 110 630J 350 NJ
preplace netloc eprom_cfg_reader_0_rx_out 1 1 4 N 280 1230J 590 NJ 590 NJ
preplace netloc eth_mac_1g_fifo_wrapper_0_rx_axis 1 2 3 1280 540 NJ 540 2090
preplace netloc temperature_1 1 0 5 NJ 1410 NJ 1410 NJ 1410 NJ 1410 NJ
preplace netloc com5402_wrapper_0_rx_src_ip_addr 1 1 3 760 420 NJ 420 1690
preplace netloc cfg_err_1 1 0 5 NJ 170 640J 290 1220J 580 NJ 580 2150J
preplace netloc cfg_act_1 1 0 5 NJ 90 650J 330 1190J 570 NJ 570 2160J
preplace netloc com5402_wrapper_0_mac_tx 1 3 1 1750
preplace netloc ARESETN_1 1 0 5 60 1490 NJ 1490 NJ 1490 1760 1490 N
preplace netloc tcp_bridge_0_tcp_tx 1 2 1 1170
preplace netloc gig_ethernet_pcs_pma_0_userclk2_out 1 1 5 700 390 1240 650 1760 390 2110 390 2580
preplace netloc reset_1 1 0 5 NJ 1080 NJ 1080 NJ 1080 NJ 1080 NJ
preplace netloc gig_ethernet_pcs_pma_0_status_vector 1 5 1 NJ
preplace netloc TDM_CSR_0_resets 1 5 1 NJ
preplace netloc tcp_bridge_0_S2MM_CMD 1 0 3 40 210 610J 260 1130
preplace netloc axi_datamover_0_M_AXI_MM2S 1 1 3 500 1150 NJ 1150 NJ
preplace netloc trigger_word_1 1 0 5 NJ 1310 NJ 1310 NJ 1310 NJ 1310 NJ
preplace netloc clk_1 1 0 5 20 1470 650 1470 NJ 1470 1710 1470 2120
levelinfo -pg 1 -10 290 930 1490 1930 2370 2620 -top -10 -bot 1540
",
}

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""



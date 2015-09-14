
################################################################
# This is a generated script based on design: Memory
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2015.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   puts "ERROR: This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source Memory_script.tcl

# If you do not already have a project created,
# you can create a project using the following command:
#    create_project project_1 myproj -part xc7a200tfbg676-2

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   puts "ERROR: Please open or create a project!"
   return 1
}



# CHANGE DESIGN NAME HERE
set design_name Memory

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

   set errMsg "ERROR: Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      puts "INFO: Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   puts "INFO: Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "ERROR: Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "ERROR: Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   puts "INFO: Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   puts "INFO: Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

puts "INFO: Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   puts $errMsg
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     puts "ERROR: Unable to find parent cell <$parentCell>!"
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set CSR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 CSR ]
  set_property -dict [ list CONFIG.ADDR_WIDTH {32} CONFIG.DATA_WIDTH {32} CONFIG.FREQ_HZ {100000000} CONFIG.PROTOCOL {AXI4LITE}  ] $CSR
  set ethernet_mm2s [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 ethernet_mm2s ]
  set_property -dict [ list CONFIG.FREQ_HZ {100000000}  ] $ethernet_mm2s
  set ethernet_mm2s_cmd [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 ethernet_mm2s_cmd ]
  set_property -dict [ list CONFIG.FREQ_HZ {100000000} CONFIG.HAS_TKEEP {0} CONFIG.HAS_TLAST {0} CONFIG.HAS_TREADY {1} CONFIG.HAS_TSTRB {0} CONFIG.LAYERED_METADATA {undef} CONFIG.PHASE {0.000} CONFIG.TDATA_NUM_BYTES {9} CONFIG.TDEST_WIDTH {0} CONFIG.TID_WIDTH {0} CONFIG.TUSER_WIDTH {0}  ] $ethernet_mm2s_cmd
  set ethernet_mm2s_sts [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 ethernet_mm2s_sts ]
  set_property -dict [ list CONFIG.FREQ_HZ {100000000}  ] $ethernet_mm2s_sts
  set ethernet_s2mm [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 ethernet_s2mm ]
  set_property -dict [ list CONFIG.FREQ_HZ {100000000} CONFIG.HAS_TKEEP {1} CONFIG.HAS_TLAST {1} CONFIG.HAS_TREADY {1} CONFIG.HAS_TSTRB {0} CONFIG.LAYERED_METADATA {undef} CONFIG.PHASE {0.000} CONFIG.TDATA_NUM_BYTES {4} CONFIG.TDEST_WIDTH {0} CONFIG.TID_WIDTH {0} CONFIG.TUSER_WIDTH {0}  ] $ethernet_s2mm
  set ethernet_s2mm_cmd [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 ethernet_s2mm_cmd ]
  set_property -dict [ list CONFIG.FREQ_HZ {100000000} CONFIG.HAS_TKEEP {0} CONFIG.HAS_TLAST {0} CONFIG.HAS_TREADY {1} CONFIG.HAS_TSTRB {0} CONFIG.LAYERED_METADATA {undef} CONFIG.PHASE {0.000} CONFIG.TDATA_NUM_BYTES {9} CONFIG.TDEST_WIDTH {0} CONFIG.TID_WIDTH {0} CONFIG.TUSER_WIDTH {0}  ] $ethernet_s2mm_cmd
  set ethernet_s2mm_sts [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 ethernet_s2mm_sts ]
  set_property -dict [ list CONFIG.FREQ_HZ {100000000}  ] $ethernet_s2mm_sts

  # Create ports
  set AXI_resetn [ create_bd_port -dir O -from 0 -to 0 -type rst AXI_resetn ]
  set clk_axi [ create_bd_port -dir I -type clk clk_axi ]
  set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {CSR:ethernet_mm2s:ethernet_mm2s_cmd:ethernet_mm2s_sts:ethernet_s2mm:ethernet_s2mm_cmd:ethernet_s2mm_sts} CONFIG.FREQ_HZ {100000000}  ] $clk_axi
  set clk_axi_locked [ create_bd_port -dir I clk_axi_locked ]
  set ethernet_mm2s_err [ create_bd_port -dir O ethernet_mm2s_err ]
  set ethernet_s2mm_err [ create_bd_port -dir O ethernet_s2mm_err ]
  set reset [ create_bd_port -dir I -type rst reset ]
  set_property -dict [ list CONFIG.POLARITY {ACTIVE_HIGH}  ] $reset

  # Create instance: DataMover_Ethernet, and set properties
  set DataMover_Ethernet [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_datamover:5.1 DataMover_Ethernet ]

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list CONFIG.NUM_MI {1} CONFIG.NUM_SI {2} CONFIG.STRATEGY {2}  ] $axi_interconnect_0

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]
  set_property -dict [ list CONFIG.C_AUX_RESET_HIGH {1}  ] $proc_sys_reset_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list CONFIG.CONST_VAL {0}  ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net DataMover_Ethernet_M_AXIS_MM2S [get_bd_intf_ports ethernet_mm2s] [get_bd_intf_pins DataMover_Ethernet/M_AXIS_MM2S]
  connect_bd_intf_net -intf_net DataMover_Ethernet_M_AXIS_MM2S_STS [get_bd_intf_ports ethernet_mm2s_sts] [get_bd_intf_pins DataMover_Ethernet/M_AXIS_MM2S_STS]
  connect_bd_intf_net -intf_net DataMover_Ethernet_M_AXIS_S2MM_STS [get_bd_intf_ports ethernet_s2mm_sts] [get_bd_intf_pins DataMover_Ethernet/M_AXIS_S2MM_STS]
  connect_bd_intf_net -intf_net DataMover_Ethernet_M_AXI_MM2S [get_bd_intf_pins DataMover_Ethernet/M_AXI_MM2S] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net ETHERNET_MM2S_CMD_1 [get_bd_intf_ports ethernet_mm2s_cmd] [get_bd_intf_pins DataMover_Ethernet/S_AXIS_MM2S_CMD]
  connect_bd_intf_net -intf_net ETHERNET_S2MM_1 [get_bd_intf_ports ethernet_s2mm] [get_bd_intf_pins DataMover_Ethernet/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net ETHERNET_S2MM_CMD_1 [get_bd_intf_ports ethernet_s2mm_cmd] [get_bd_intf_pins DataMover_Ethernet/S_AXIS_S2MM_CMD]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins DataMover_Ethernet/M_AXI_S2MM] [get_bd_intf_pins axi_interconnect_0/S01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_ports CSR] [get_bd_intf_pins axi_interconnect_0/M00_AXI]

  # Create port connections
  connect_bd_net -net CLK_AXI_1 [get_bd_ports clk_axi] [get_bd_pins DataMover_Ethernet/m_axi_mm2s_aclk] [get_bd_pins DataMover_Ethernet/m_axi_s2mm_aclk] [get_bd_pins DataMover_Ethernet/m_axis_mm2s_cmdsts_aclk] [get_bd_pins DataMover_Ethernet/m_axis_s2mm_cmdsts_awclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_0/S01_ACLK] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
  connect_bd_net -net DataMover_Ethernet_mm2s_err [get_bd_ports ethernet_mm2s_err] [get_bd_pins DataMover_Ethernet/mm2s_err]
  connect_bd_net -net DataMover_Ethernet_s2mm_err [get_bd_ports ethernet_s2mm_err] [get_bd_pins DataMover_Ethernet/s2mm_err]
  connect_bd_net -net RESET_1 [get_bd_ports reset] [get_bd_pins proc_sys_reset_0/ext_reset_in]
  connect_bd_net -net clk_axi_locked_1 [get_bd_ports clk_axi_locked] [get_bd_pins proc_sys_reset_0/dcm_locked]
  connect_bd_net -net proc_sys_reset_0_interconnect_aresetn [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_ports AXI_resetn] [get_bd_pins DataMover_Ethernet/m_axi_mm2s_aresetn] [get_bd_pins DataMover_Ethernet/m_axi_s2mm_aresetn] [get_bd_pins DataMover_Ethernet/m_axis_mm2s_cmdsts_aresetn] [get_bd_pins DataMover_Ethernet/m_axis_s2mm_cmdsts_aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_0/S01_ARESETN] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins proc_sys_reset_0/aux_reset_in] [get_bd_pins proc_sys_reset_0/mb_debug_sys_rst] [get_bd_pins xlconstant_0/dout]

  # Create address segments
  create_bd_addr_seg -range 0x1000 -offset 0x44A00000 [get_bd_addr_spaces DataMover_Ethernet/Data_MM2S] [get_bd_addr_segs CSR/Reg] SEG_Memory_Reg
  create_bd_addr_seg -range 0x1000 -offset 0x44A00000 [get_bd_addr_spaces DataMover_Ethernet/Data_S2MM] [get_bd_addr_segs CSR/Reg] SEG_Memory_Reg
  

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""



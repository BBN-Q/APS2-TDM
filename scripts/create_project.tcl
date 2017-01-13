##################################################################
# Tcl script to create the TDM HDL Vivado project for implementation to bitfile
#
# Usage: at the Tcl console manually set the argv to set the PROJECT_DIR and PROJECT_NAME and
# then source this file. E.g.
#
# set argv [list "/home/cryan/Programming/FPGA" "TDM-impl"] or
# or  set argv [list "C:/Users/qlab/Documents/Xilinx Projects/" "TDM-impl"]
# source create_project.tcl
#
# from Vivado batch mode use the -tclargs to pass argv
# vivado -mode batch -source create_project.tcl -tclargs "/home/cryan/Programming/FPGA" "TDM-impl"
#
##################################################################

#parse arguments
set PROJECT_DIR [lindex $argv 0]
set PROJECT_NAME [lindex $argv 1]
set FIXED_IP [lindex $argv 2]

# figure out the script path
set SCRIPT_PATH [file normalize [info script]]
set REPO_PATH [file dirname $SCRIPT_PATH]/../

create_project -force $PROJECT_NAME $PROJECT_DIR/$PROJECT_NAME -part xc7a200tfbg676-2

# set project properties
set obj [get_projects TDM-impl]
set_property "corecontainer.enable" "1" $obj
set_property "default_lib" "xil_defaultlib" $obj
set_property "ip_cache_permissions" "disable" $obj
set_property "sim.ip.auto_export_scripts" "1" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "VHDL" $obj
set_property "xpm_libraries" "XPM_CDC XPM_MEMORY" $obj

# add VHDL sources
add_files -norecurse $REPO_PATH/src

# constraints
add_files -fileset constrs_1 -norecurse $REPO_PATH/constraints
add_files -fileset constrs_1 -norecurse $REPO_PATH/deps/VHDL-Components/constraints/synchronizer.tcl
set_property target_constrs_file $REPO_PATH/constraints/timing.xdc [current_fileset -constrset]

# ip cores
set ip_srcs [glob $REPO_PATH/src/ip/*.xci]
import_ip $ip_srcs

# APS2-Comms files
source $REPO_PATH/deps/APS2-Comms/scripts/add_verilog_deps.tcl
source $REPO_PATH/deps/APS2-Comms/scripts/add_comblocks_files.tcl
source $REPO_PATH/deps/APS2-Comms/scripts/add_files_to_project.tcl

# has timing specific to aps comms bd
remove_files -fileset constrs_1 $REPO_PATH/deps/APS2-Comms//constraints/timing.xdc

# main BD
source $REPO_PATH/src/bd/main_bd.tcl -quiet
regenerate_bd_layout
validate_bd_design
save_bd_design
generate_target all [get_files main_bd.bd] -quiet
close_bd_design [get_bd_designs main_bd]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

#Get headerless bit file output
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

# update version generics every run
set_property STEPS.SYNTH_DESIGN.TCL.PRE $REPO_PATH/scripts/update_version_generics.tcl [get_runs synth_1]

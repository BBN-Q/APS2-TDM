# create project

###########################################################

# Update these for the local machine

set project_dir "C:/Users/qlab/Documents/Xilinx Projects"
set project_name "APS2-Trigger"

############################################################

set scriptPath [file normalize [info script]]
set source_dir [file dirname $scriptPath]/../

create_project -force $project_name $project_dir/$project_name -part xc7a200tfbg676-2
set_property target_language VHDL [current_project]

# add VHDL and NGC sources
add_files -norecurse $source_dir $source_dir/UDP
set ngc_srcs [glob $source_dir/ip/*.ngc]
add_files -norecurse $ngc_srcs

#testbenches
add_files -norecurse -fileset sim_1 $source_dir/testbenches

# constraints
add_files -fileset constrs_1 -norecurse $source_dir/constraints
set_property target_constrs_file $source_dir/constraints/ATM_B206.xdc [current_fileset -constrset]

# ip cores
set ip_srcs [glob $source_dir/ip/*.xci]
import_ip $ip_srcs
#Now the TEMAC from 2014.4
import_files $SOURCE_DIR/ip/GIGE_MAC/GIGE_MAC.xci

#Memory BD
source $source_dir/scripts/Memory.tcl
regenerate_bd_layout
validate_bd_design
save_bd_design
generate_target all [get_files  $project_dir/$project_name/$project_name.srcs/sources_1/bd/Memory/Memory.bd]
close_bd_design [get_bd_designs Memory]
#make it out-of-context to speed up synthesis
create_fileset -blockset -define_from Memory Memory

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# simulation generics
set_property generic "APS_REPO_PATH=\"$source_dir\"" [get_filesets sim_1]

#Get headerless bit file output
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

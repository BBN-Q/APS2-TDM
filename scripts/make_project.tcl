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

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# simulation generics
set_property generic "APS_REPO_PATH=\"$source_dir\"" [get_filesets sim_1]

# use spread logic implementation strategy to overcome overlapping nodes
set_property strategy Congestion_SpreadLogic_medium [get_runs impl_1]

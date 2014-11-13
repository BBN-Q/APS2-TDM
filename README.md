APS2 TopLevel Firmware

Adding submodules:

Two submodules need to be added to the source directory. The make_project.tcl 
expects the submodules at specific paths

submodules are added using:

git submodule add <PATH_TO RESPOSOITORY> <LOCAL PATH>

Add the pulse-sequencer and cache-controller using:

git submodule add $GIT/APS2-Sequencer.git pulse-sequencer
git submodule add $GIT/APS2-CacheController.git cache-controller

This will checkout the two submodules into ./pulse-sequencer and ./cache-controller


Creating Vivado project:

To create a Vivado project to build the APS2 firmware, open
scripts/make_project.tcl in a text editor. Update the names and paths at the top
of the file. Then, from a Vivado tcl console execute:

source path-to-this-directory/scripts/make_project.tcl

Note that this will copy IP cores into the project, so if you edit them, you
will want to copy the XCI files back into the repository. If you edit the memory
block design, you also need to regenerate the corresponding tcl script with:

write_bd_tcl path-to-this-directory/scripts/memory_bd.tcl
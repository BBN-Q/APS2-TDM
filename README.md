APS2 Trigger Module Firmware

Creating Vivado project:

To create a Vivado project to build the APS2 firmware, open
scripts/make_project.tcl in a text editor. Update the names and paths at the top
of the file. Then, from a Vivado tcl console execute:

source path-to-this-directory/scripts/make_project.tcl

Note that this will copy IP cores into the project, so if you edit them, you
will want to copy the XCI files back into the repository.

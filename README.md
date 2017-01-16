# APS2 Trigger Distribution Module Firmware

This project provides the source HDL for the APS2 Trigger Distribution Module
firmware.

## Project Creation Script

There is a tcl script `create_project.tcl` that will create the Vivado project
from scratch. See the top of script for examples of how to invoke. For example:

```shell
cd /path/to/APS2-TDM/scripts
vivado -mode batch -source create_project.tcl -tclargs "/home/cryan/Programming/FPGA" "TDM-impl"
```

Note that this will copy IP cores into the project, so if you edit them, you
will want to copy the XCI files back into the repository.

## License

The project is licensed under Mozilla Public License Version 2.0. See the
LICENSE.md file for more information.

## Funding

This software was funded in part by the Office of the Director of National
Intelligence (ODNI), Intelligence Advanced Research Projects Activity (IARPA),
through the Army Research Office contract No. W911NF-10-1-0324 and No.
W911NF-14-1-0124. All statements of fact, opinion or conclusions contained
herein are those of the authors and should not be construed as representing the
official views or policies of IARPA, the ODNI, or the US Government.

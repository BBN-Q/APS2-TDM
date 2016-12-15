# Create the TDM CSR module
#
# Bit Maps
# ---------------------
#
# resets
# 	0 : Internal Trigger
# 	1 : open
# 	2 : open
# 	3 : open
#
# trigger_control:
#
# 	0 : trigger source (0 internal, 1 software)
# 	2 : software trigger toggle
#
#
# Original author: Colm Ryan
# Copyright 2016, Raytheon BBN Technologies

import sys, os

# add VHDL-Components to path
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "deps",  "VHDL-Components", "src"))
from axi_csr import Register, write_axi_csr

if __name__ == '__main__':

	registers = [
				Register(0, "resets",  "write"),
				Register(1, "control", "write"),
				Register(11, "trigger_word",  "read"), # shift register of last 4 bytes broadcast out on SATA
				Register(12, "trigger_interval", "write", initial_value=0x000493e0), # trigger interval (1ms = 300,000 clock cycles)
				Register(18, "SATA_status", "read"),
				Register(20, "uptime_seconds", "read"),
				Register(21, "uptime_nanoseconds", "read"),
				Register(22, "tdm_version", "read"),
				Register(23, "temperature", "read"), # 11-0
				Register(24, "git_sha1", "read"),
				Register(25, "build_timestamp", "read")
			]

	write_axi_csr(os.path.join(os.path.dirname(__file__), "..", "src", "tdm_csr.vhd"), registers, module_name="TDM_CSR")

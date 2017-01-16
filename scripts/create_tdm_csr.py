# Create the TDM CSR module
#
# Bit Maps
# ---------------------
#
# clock_status:
#  0 : mgt_clk_locked - if low we probably won't be able to read anyways
#  1 : cfg_clk_mmcm_locked - if low we probably won't be able to read anyways
#  2 : ref_clk_mmcm_locked - determines what drives the sys clk
#  3 : sys_clk_mmcm_locked
#  4 : sys_clk_mmcm_reset
#
# control:
#  4 : trigger enabled (active high)
#  3 : software trigger toggle
#  2 : trigger source (0 internal, 1 software)
#
# SATA_status:
# 8-0  : TrigWr
# 17-9 : TrigOutFull
# 20   : ext_valid
# 24   : TrigLocked
# 25   : TrigClkErr
# 26   : TrigOvflErr
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
				Register(0, "status", "read"),
				Register(8, "resets",  "write"),
				Register(9, "control", "write"),
				Register(11, "trigger_word",  "read"), # shift register of last 4 bytes broadcast out on SATA
				Register(12, "trigger_interval", "write", initial_value=0x000186a0), # trigger interval (1ms = 100,000 clock cycles)
				Register(18, "SATA_status", "read"),
				Register(20, "uptime_seconds", "read"),
				Register(21, "uptime_nanoseconds", "read"),
				Register(22, "tdm_version", "read"),
				Register(23, "temperature", "read"), # 11-0
				Register(24, "git_sha1", "read"),
				Register(25, "build_timestamp", "read")
			]

	write_axi_csr(os.path.join(os.path.dirname(__file__), "..", "src", "tdm_csr.vhd"), registers, module_name="TDM_CSR")

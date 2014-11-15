-- ApsCfgConstants.vhd
--
-- This provides menmonic definitions for the Config interface
--
--
-- REVISIONS
--
--  7/9/2013  CRJ
--    Created
--
--  8/13/2013 CRJ
--    Initial release
--
-- END REVISIONS
--

library ieee;
use ieee.std_logic_1164.all;

package ApsCfgConstants is

-- Constants used for the configuration I/O interface

-- Config Command Word Format:
--
-- D<15:8>  Command Dependent
-- D<7>     R/!W
-- D<6:4>   Target: 000 = EPROM, 001 = DRAM, 010 = Control/Status Registers, others = reserved.
-- D<3:0>   Command Code

-- Commands Processed by the Config Chip.  The command code uses the above fields to define the command
-- This interface is only available to ZRL code in the FPGA.  All other code goes through the ZRL code,
-- so user commands are translated into this format.
-- These definitions are required by the ApsMsgProc module

-- Define the bit fields in the command word
constant CFG_RW_BIT : natural := 7;
subtype CFG_CMD_RANGE is natural range 3 downto 0;
subtype CFG_TARG_RANGE is natural range 6 downto 4;

-- R/W EPROM
constant CFG_READ_NVM    : std_logic_vector(7 downto 0) := x"91";
constant CFG_WRITE_NVM   : std_logic_vector(7 downto 0) := x"11";
constant CFG_ERASE_NVM   : std_logic_vector(7 downto 0) := x"92"; -- Non-write, so mark as a read
constant CFG_RUN_NVM     : std_logic_vector(7 downto 0) := x"98"; -- MSB of command code set for non R/W command
constant CFG_LDFRM_NVM   : std_logic_vector(7 downto 0) := x"99";

-- R/W DRAM
constant CFG_READ_DRAM   : std_logic_vector(7 downto 0) := x"A1";
constant CFG_WRITE_DRAM  : std_logic_vector(7 downto 0) := x"21";
constant CFG_CAL_DRAM    : std_logic_vector(7 downto 0) := x"A8"; -- MSB of command code set for non R/W command
constant CFG_LDFRM_DRAM  : std_logic_vector(7 downto 0) := x"A9";

-- LDFRM from either DRAM or EPROM is the same in the LSB.  Saves logic for checking
constant CFG_LDFRM       : std_logic_vector(3 downto 0) := x"9";

-- R/W Registers.  Not used on APS
constant CFG_READ_REG    : std_logic_vector(7 downto 0) := x"B1";
constant CFG_WRITE_REG   : std_logic_vector(7 downto 0) := x"31";

-- Encoded SPI command.  Data portion contains one or more 32 bit command/data words from the FPGA.
-- Address fields not used, since taget is in the SPI data packets
-- Subsequent read returns any pending read data store in a FIFO.
-- Only used on APS
constant CFG_SPI_READ    : std_logic_vector(7 downto 0) := x"C1";
constant CFG_SPI_CMD     : std_logic_vector(7 downto 0) := x"41";

-- Chip Packet Command Format:
-- D[31..24] = Target
-- D[23..16] = Data/Cnt.  Data for single byte command, count of bytes for multi byte command
-- D[15..0] = SPI Instruction
-- Next DWORDs = Data if not single byte instruction

-- Target codes for the Config I/O packet data from the host
-- 0x00 ........................Pause commands stream for 100ns times the count in D<23:0> 
-- 0xC0/0xC8 ...................DAC Channel 0 Access (AD9736) 
-- 0xC1/0xC9 ...................DAC Channel 1 Access (AD9736) 
-- 0xD0/0xD8 ...................PLL Clock Generator Access (AD518-1) 
-- 0xE0 ........................VCXO Controller Access (CDC7005) 
-- 0xFF ........................End of list 

constant TARG_BYTE : natural := 3;  -- Bit 3 set if it is a single byte command with the data in the count field

-- Defined so that you upper 3 bits decodes the target
constant TARG_PAUSE     : std_logic_vector(7 downto 0) := x"00";
constant TARG_DAC       : std_logic_vector(7 downto 0) := x"C0";  -- Bit 0 = 0 for DAC0 and 1 for DAC1
constant TARG_DAC_BYTE  : std_logic_vector(7 downto 0) := x"C8";  -- Bit 0 = 0 for DAC0 and 1 for DAC1
constant TARG_PLL       : std_logic_vector(7 downto 0) := x"D0";
constant TARG_PLL_BYTE  : std_logic_vector(7 downto 0) := x"D8";
constant TARG_VCXO      : std_logic_vector(7 downto 0) := x"E0";
constant TARG_EOL       : std_logic_vector(7 downto 0) := x"FF";

-- Bit definitions for the status that is driven when STAT_OE is asserted
-- These bits are returned as part of the Status command
constant DAC0_IRQ_BIT   : natural := 0;
constant DAC1_IRQ_BIT   : natural := 1;
constant PLL_STATUS_BIT : natural := 2;
constant PLL_REFMON_BIT : natural := 3;
constant PLL_LD_BIT     : natural := 4;
constant VCXO_LOCK_BIT  : natural := 5;
constant VCXO_REF_BIT   : natural := 6;
constant VCXO_VCXO_BIT  : natural := 7;

end package ApsCfgConstants;

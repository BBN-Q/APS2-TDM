-- ApsCmdConstants.vhd
--
-- This provides menmonic definitions for the command word fields
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

package ApsCmdConstants is

-- Constants used in the command packets from the host

-- Command Word Format:
--
-- D<31>    ACK Flag
-- D<30>    SEQ Error Flag
-- D<29>    Channel select 0/1
-- D<28>    R/!W
-- D<27:24> CMD<3:0>, Command
-- D<23:16> MODE from host (command mode) / STAT from APS (command completion status)
-- D<15:0>  CNT<15:0>, 32-bit read or write count.  For writes, CNT data words follow the address

-- Define the bit fields in the command word
constant APS_ACK_BIT   : natural := 31;
constant APS_SEQ_BIT   : natural := 30;
constant APS_CHAN_BIT  : natural := 29;
constant APS_RW_BIT    : natural := 28;
constant APS_NOACK_BIT : natural := 27;

-- Define the bit ranges in the command word
subtype APS_CMD_RANGE  is natural range 26 downto 24;
subtype APS_MODE_RANGE is natural range 23 downto 16;
subtype APS_STAT_RANGE is natural range 23 downto 16;
subtype APS_CNT_RANGE  is natural range 15 downto 0;

-- Define the bit ranges in the User CIF
subtype CIF_CNT_RANGE is natural range 15 downto 0;
subtype CIF_MODE_RANGE is natural range 23 downto 16;
subtype CIF_ADDR_RANGE is natural range 56 downto 25;
constant CIF_RW_BIT : natural := 24;

-- Define the bit ranges in the User COF
subtype COF_CNT_RANGE is natural range 15 downto 0;
subtype COF_STAT_RANGE is natural range 23 downto 16;

-- Define the command values
constant APS_PKT_RESET        : std_logic_vector(2 downto 0) := "000";
constant APS_PKT_USRIO        : std_logic_vector(2 downto 0) := "001";
constant APS_PKT_EPIO         : std_logic_vector(2 downto 0) := "010";
constant APS_PKT_CFGIO        : std_logic_vector(2 downto 0) := "011";
constant APS_PKT_CFGRUN       : std_logic_vector(2 downto 0) := "100";
constant APS_PKT_CFGDAT       : std_logic_vector(2 downto 0) := "101";
constant APS_PKT_CFGCTL       : std_logic_vector(2 downto 0) := "110";
constant APS_PKT_STAT         : std_logic_vector(2 downto 0) := "111";
                              
end package ApsCmdConstants;

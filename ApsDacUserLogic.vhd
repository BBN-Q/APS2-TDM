-- ApsUserLogic.vhd
--
-- Example User Logic code.
--
-- For User I/O reads, the code returns incremental read data starting at the specified address.
-- For User I/O writes, the code returns the incoming write data XORed with the specified address
--
-- REVISIONS
--
--  8/1/2013  CRJ
--    Created
--
--  8/13/2013 CRJ
--    Initial release
--
--  1/31/2014 CRJ
--    Added DAC control outputs
--
--  2/27/2014 CRJ
--    Added USER_STATUS output of WF Mode and Amplitude
--
-- END REVISIONS
--

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity ApsDacUserLogic is
port
(
  -- User Logic Connections
  USER_CLK       : in std_logic;                       -- Clock for User side of FIFO interface
  USER_RST       : in std_logic;                       -- User Logic global reset, synchronous to USER_CLK
  USER_VERSION   : out std_logic_vector(31 downto 0);  -- User Logic Firmware Version.  Returned in Status message
  USER_STATUS    : out std_logic_vector(31 downto 0);  -- User Status Word.  Returned in Status message

  USER_DIF       : in std_logic_vector(31 downto 0);   -- User Data Input FIFO output
  USER_DIF_RD    : out std_logic;                      -- User Data Onput FIFO Read Enable

  USER_CIF_EMPTY : in std_logic;                       -- Low when there is data available
  USER_CIF_RD    : out std_logic;                      -- Command Input FIFO Read Enable
  USER_CIF_RW    : in std_logic;                       -- High for read, low for write
  USER_CIF_MODE  : in std_logic_vector(7 downto 0) ;   -- MODE field from current User I/O command
  USER_CIF_CNT   : in std_logic_vector(15 downto 0);   -- CNT field from current User I/O command
  USER_CIF_ADDR  : in std_logic_vector(31 downto 0);   -- Address for the current command

  USER_DOF       : out std_logic_vector(31 downto 0);  -- User Data Onput FIFO input
  USER_DOF_WR    : out std_logic;                      -- User Data Onput FIFO Write Enable

  USER_COF_STAT  : out std_logic_vector(7 downto 0);  -- STAT value to return for current User I/O command
  USER_COF_CNT   : out std_logic_vector(15 downto 0);  -- Number of words written to DOF for current User I/O command
  USER_COF_AFULL : in std_logic;                       -- User Control Output FIFO Almost Full
  USER_COF_WR    : out std_logic;                       -- User Control Onput FIFO Write Enable

  DAC0_WF_MODE   : out std_logic_vector(1 downto 0);   -- Channel 0 waveform mode select.  00 = DC, 01 = Square, 02 = Ramp, 03 = Exponential
  DAC0_AMPLITUDE : out std_logic_vector(13 downto 0);  -- Channel 0 amplitude for DC and Square modes
  DAC1_WF_MODE   : out std_logic_vector(1 downto 0);   -- Channel 1 waveform mode select.  00 = DC, 01 = Square, 02 = Ramp, 03 = Exponential
  DAC1_AMPLITUDE : out std_logic_vector(13 downto 0)   -- Channel 1 amplitude for DC and Square modes
);
end ApsDacUserLogic;


architecture behavior of ApsDacUserLogic is

type CS_STATE is (CS_IDLE, CS_READ, CS_WRITE, CS_DONE);
signal CmdState : CS_STATE;

signal DataCnt : std_logic_vector(15 downto 0);
signal DataOut : std_logic_vector(31 downto 0);
signal CmdCnt : std_logic_vector(7 downto 0);
signal USER_DOF_WR_q : std_logic;
signal USER_COF_WR_q : std_logic;

signal DAC0_WF_MODE_i   : std_logic_vector(1 downto 0);
signal DAC0_AMPLITUDE_i : std_logic_vector(13 downto 0);
signal DAC1_WF_MODE_i   : std_logic_vector(1 downto 0);
signal DAC1_AMPLITUDE_i : std_logic_vector(13 downto 0);

begin
  -- Conect internal signals to outputs
  DAC0_WF_MODE   <= DAC0_WF_MODE_i;
  DAC0_AMPLITUDE <= DAC0_AMPLITUDE_i;
  DAC1_WF_MODE   <= DAC1_WF_MODE_i;  
  DAC1_AMPLITUDE <= DAC1_AMPLITUDE_i;

  USER_VERSION <= x"00000A02";

  -- Return current settings of WF select and Amplitude in the status field
  USER_STATUS  <=  DAC1_WF_MODE_i & DAC1_AMPLITUDE_i & DAC0_WF_MODE_i & DAC0_AMPLITUDE_i;

  -- Drive DOF with DataOut register
  USER_DOF <= DataOut;

  -- These connect ports to internal signals
  USER_DOF_WR <= USER_DOF_WR_q;
  USER_COF_WR <= USER_COF_WR_q;
  USER_CIF_RD <= USER_COF_WR_q; -- Advance the CIF when you write the COF


  process(USER_CLK, USER_RST)
  begin
    if USER_RST = '1' then
      CmdCnt <= x"00";
      DataCnt <= x"0000";
      DataOut <= x"00000000";
      USER_DIF_RD <= '0';
      USER_COF_STAT <= x"00";
      USER_COF_CNT <= x"0000";
      USER_COF_WR_q <= '0';
      USER_DOF_WR_q <= '0';
      CmdState <= CS_IDLE;
      DAC0_WF_MODE_i <= "00";  -- DC
      DAC0_AMPLITUDE_i <= (others => '0');
      DAC1_WF_MODE_i <= "00";  -- DC
      DAC1_AMPLITUDE_i <= (others => '0');
    elsif rising_edge(USER_CLK) then

      case CmdState is

        when CS_IDLE =>
          -- Load the starting data value for reads
          DataOut <= USER_CIF_ADDR;

          -- Load the data counter
          DataCnt <= USER_CIF_CNT;
          
          -- Wait for a User I/O command from the host
          if USER_CIF_EMPTY = '0' then
            if USER_CIF_RW = '1' then
              -- Proceed to read command processing state
              CmdState <= CS_READ;
            else
              -- Enable reading the DIF data for use in the CS_WRITE state as long as CNT is non-zero
              if USER_CIF_CNT /= 0 then
                USER_DIF_RD <= '1';
              end if;

              -- Proceed to write command processing state
              CmdState <= CS_WRITE;
            end if;
          end if;
          

        when CS_READ =>
          -- Count down the number of data words read/written
          DataCnt <= DataCnt - 1;

          -- For reads, return incremental data starting at the address loaded on entry to this state
          if USER_DOF_WR_q = '1' then
            DataOut <= DataOut + 1;
          end if;

          -- Write data for DataCnt-1 .. 0          
          if DataCnt /= 0 then
            -- Enable writing the DOF with DataOut Value
            USER_DOF_WR_q <= '1';
          else
            USER_DOF_WR_q <= '0';
            CmdState <= CS_DONE;
          end if;
        

        when CS_WRITE =>
          -- Count down the number of data words read/written
          -- Note that DIF Read Enable is set on entry to this state
          DataCnt <= DataCnt - 1;
          DataOut <= USER_CIF_ADDR xor USER_DIF;  -- Return write data selectively inverted by the address value

          -- Write data for DataCnt = CNT-1 .. 0          
          if DataCnt /= 0 then
            -- Enable writing the DOF with pipelined DataOut Value
            USER_DOF_WR_q <= '1';
          else
            USER_DOF_WR_q <= '0';
            CmdState <= CS_DONE;
          end if;
        
          -- Read DIF for DataCnt = CNT .. 1
          if DataCnt = 1 then
            USER_DIF_RD <= '0';
          end if;


        when CS_DONE =>
          -- All of the data has been written to the DOF, so write the COF with the results
          USER_COF_STAT <= CmdCnt;  -- Send command count as the status
          USER_COF_CNT <= USER_CIF_CNT;

          -- Only write ACK info if the COF isn't full
          if USER_COF_AFULL = '0' then
            USER_COF_WR_q <= '1';
          end if;

          -- Once COF entry is written and CIF is advanced, return to IDLE state
          if USER_COF_WR_q = '1' then
            CmdCnt <= CmdCnt + 1;  -- Increment global command count that is returned as STAT
            USER_COF_WR_q <= '0';
            CmdState <= CS_IDLE;
          end if;
          
        when others =>
          null;

      end case;

      -- Piggyback DAC output waveform control on the addresses that are written
      -- Writing address 0xDAC0XXXX sets the DAC0 control
      -- Writing address 0xDAC1XXXX sets the DAC1 control
      -- D[13:0] sets the amplitude, two's compliment
      -- D[15:14] sets the mode: 00 = DC, 01 = Square, 02 = Ramp, 03 = Exponential
      if USER_CIF_ADDR(31 downto 16) = x"DAC0" and USER_COF_WR_q = '1' and USER_CIF_RW = '0' then
        DAC0_AMPLITUDE_i <= USER_CIF_ADDR(13 DOWNTO 0);
        DAC0_WF_MODE_i <= USER_CIF_ADDR(15 DOWNTO 14);
      end if;
  
      if USER_CIF_ADDR(31 downto 16) = x"DAC1" and USER_COF_WR_q = '1' and USER_CIF_RW = '0' then
        DAC1_AMPLITUDE_i <= USER_CIF_ADDR(13 DOWNTO 0);
        DAC1_WF_MODE_i <= USER_CIF_ADDR(15 DOWNTO 14);
      end if;

    end if;
  end process;

end behavior;

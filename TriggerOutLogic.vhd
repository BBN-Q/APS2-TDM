-- TriggerOutLogic.vhd
--
-- Serializes the triggers written to the input FIFO by the User Logic.
-- The FIFO allows the trigger output logic and the User Logic clock to have independent clocks.
--
-- REVISIONS
--
-- 3/6/2014  CRJ
--   Created
--
-- 7/30/2014 CRJ
--   Updated comments
--
-- 7/31/2014 CRJ
--   Modified to allow use of I/O buffer for loopback
--
-- 8/5/2014 CRJ
--   Unmodified
--
-- 8/28/2014 CRJ
--   Changed back to 0xF0 clock, since now bit slipping in logic versus the input cell
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

entity TriggerOutLogic is
port
(
  USER_CLK   : in  std_logic;  -- Clock for the output side of the FIFO
  
  -- These clocks are usually generated from an MMCM driven by the CFG_CCLK.
  CLK_100MHZ : in std_logic;      -- 100 MHz trigger output serial clock, must be from same MMCM as CLK_400MHZ
  CLK_400MHZ : in std_logic;      -- 400 MHz DDR serial output clock
  RESET      : in  std_logic;  -- Asynchronous reset for the trigger logic and FIFO

  TRIG_TX    : in std_logic_vector(7 downto 0);  -- Current trigger value, synchronous to USER_CLK
  TRIG_WR    : in  std_logic;   -- Write TRIG_TX to FIFO
  TRIG_AFULL : out std_logic;   -- Trigger FIFO almost full.  Asserted durng the last write

  TRIG_CLKP  : out  std_logic;  -- 100MHz Serial Clock
  TRIG_CLKN  : out  std_logic;
  TRIG_DATP  : out  std_logic;  -- 800 Mbps Serial Data
  TRIG_DATN  : out  std_logic
);
end TriggerOutLogic;


architecture behavior of TriggerOutLogic is

COMPONENT SEROUT8
PORT
(
  data_out_to_pins_p : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
  data_out_to_pins_n : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);

  clk_in : IN STD_LOGIC;
  clk_div_in : IN STD_LOGIC;

  data_out_from_device : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
  io_reset : IN STD_LOGIC
);
END COMPONENT;

COMPONENT TRIG_FIFO
PORT
(
  rst : IN STD_LOGIC;
  wr_clk : IN STD_LOGIC;
  rd_clk : IN STD_LOGIC;
  din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
  wr_en : IN STD_LOGIC;
  rd_en : IN STD_LOGIC;
  dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
  full : OUT STD_LOGIC;
  empty : OUT STD_LOGIC;
  prog_full : OUT STD_LOGIC
);
END COMPONENT;

COMPONENT TIO_FIFO
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    prog_full : OUT STD_LOGIC
  );
END COMPONENT;

ATTRIBUTE SYN_BLACK_BOX : BOOLEAN;
ATTRIBUTE SYN_BLACK_BOX OF SEROUT8 : COMPONENT IS TRUE;
ATTRIBUTE SYN_BLACK_BOX OF TRIG_FIFO : COMPONENT IS TRUE;
ATTRIBUTE SYN_BLACK_BOX OF TIO_FIFO : COMPONENT IS TRUE;

ATTRIBUTE BLACK_BOX_PAD_PIN : STRING;
ATTRIBUTE BLACK_BOX_PAD_PIN OF SEROUT8 : COMPONENT IS "data_out_to_pins_p[0:0],data_out_to_pins_n[0:0],clk_in,clk_div_in,data_out_from_device[7:0],io_reset";
ATTRIBUTE BLACK_BOX_PAD_PIN OF TRIG_FIFO : COMPONENT IS "rst,wr_clk,rd_clk,din[7:0],wr_en,rd_en,dout[7:0],full,empty,prog_full";
ATTRIBUTE BLACK_BOX_PAD_PIN OF TIO_FIFO : COMPONENT IS "rst,wr_clk,rd_clk,din[7:0],wr_en,rd_en,dout[7:0],full,empty,prog_full";

signal ClkOutP     : STD_LOGIC_VECTOR(0 DOWNTO 0);
signal ClkOutN     : STD_LOGIC_VECTOR(0 DOWNTO 0);
signal DatOutP     : STD_LOGIC_VECTOR(0 DOWNTO 0);
signal DatOutN     : STD_LOGIC_VECTOR(0 DOWNTO 0);
signal DataOut     : STD_LOGIC_VECTOR(1 DOWNTO 0);
signal SerTrigIn   : std_logic_vector(7 downto 0);
signal SerTrigOut  : std_logic_vector(7 downto 0);
signal SerDatOut   : std_logic_vector(15 downto 0);

signal dTRIG_WR    : std_logic;

signal TrigEmpty  : STD_LOGIC;
signal TrigRd     : STD_LOGIC;
signal TrigDat    : std_logic_vector(7 downto 0);

attribute MARK_DEBUG : string;
attribute MARK_DEBUG of SerTrigOut : signal is "true";
attribute MARK_DEBUG of TrigEmpty : signal is "true";

begin

  -- Connect serial output vectors to output pins
  TRIG_CLKP <= ClkOutP(0);
  TRIG_CLKN <= ClkOutN(0);
  TRIG_DATP <= DatOutP(0);
  TRIG_DATN <= DatOutN(0);

  -- Data sent externally LSB first. Bits are swapped so that the trigger is readable on a scope.
  -- On receive, the data is swapped again so that it ends up the the correct order at the output of the trigger receive FIFO
  -- 4 LS bits set for clock.  Reads as parallel 0xF0 at the receiver

  SCLK1 : SEROUT8
  port map
  (
    data_out_to_pins_p   => ClkOutP,
    data_out_to_pins_n   => ClkOutN,
    clk_in               => CLK_400MHZ,
    clk_div_in           => CLK_100MHZ,
    data_out_from_device => "00001111",   -- Fixed clock data pattern, sent LSB first.
    io_reset             => RESET
  );

  SDAT1 : SEROUT8
  port map
  (
    data_out_to_pins_p   => DatOutP,
    data_out_to_pins_n   => DatOutN,
    clk_in               => CLK_400MHZ,
    clk_div_in           => CLK_100MHZ,
    data_out_from_device => SerTrigOut(0) & SerTrigOut(1) & SerTrigOut(2) & SerTrigOut(3) & SerTrigOut(4) & SerTrigOut(5) & SerTrigOut(6) & SerTrigOut(7), -- Swapped Trigger Byte
    io_reset             => RESET
  );

  -- One level of input data pipelining to allow for easier routing  
  process(USER_CLK, RESET)
  begin
    if RESET = '1' then
      SerTrigIn <= (others => '0');
      dTRIG_WR <= '0';
    elsif rising_edge(USER_CLK) then
      SerTrigIn <= TRIG_TX;
      dTRIG_WR <= TRIG_WR;
    end if;
  end process;

  -- One level of output data pipelining to allow for easier routing  
  process(CLK_100MHZ, RESET)
  begin
    if RESET = '1' then
      SerTrigOut <= (others => '0');
      TrigRd <= '0';
    elsif rising_edge(CLK_100MHZ) then
      -- Read triggers as they are received
      -- For as yet undetermined reasons, registered TrigRd is required to make the Xilinx FIFO IP work.
      -- This sets a maximum 50% duty cycle output trigger rate
      TrigRd <= not TrigRd and not TrigEmpty;

      -- Only present non-zero data when there is a valid FIFO output
      -- The output is ALWAYS writing.  When there are not triggers, it writes zero
      -- This ignores zeros written by the host and non-zero outputs that are due to an empty FIFO
      if TrigEmpty = '0' and TrigRd = '1' then
        SerTrigOut <= TrigDat;
      else
        SerTrigOut <= "00000000";
      end if;
    end if;
  end process;


  TFFO : TIO_FIFO
  port map
  (
    rst         => RESET,
    wr_clk      => USER_CLK,
    rd_clk      => CLK_100MHZ,
    din         => SerTrigIn,
    wr_en       => dTRIG_WR,
    rd_en       => TrigRd,
    dout        => TrigDat,
    full        => open ,
    empty       => TrigEmpty,
    prog_full  => TRIG_AFULL
  );
  
end behavior;




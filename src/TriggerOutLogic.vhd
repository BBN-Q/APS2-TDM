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
use ieee.numeric_std.all;

entity TriggerOutLogic is
port
(
  -- These clocks are usually generated from SYS_MMCM.
  CLK_100MHZ : in std_logic;    -- 100 MHz trigger output serial clock, must be from same MMCM as CLK_400MHZ
  CLK_400MHZ : in std_logic;    -- 400 MHz DDR serial output clock
  RESET      : in  std_logic;   -- Asynchronous reset for the trigger logic

  TRIG_TX    : in std_logic_vector(7 downto 0);  -- Current trigger value, synchronous to CLK_100MHZ
  TRIG_VALID : in  std_logic;   -- Valid flag for TRIG_TX

  TRIG_CLKP  : out  std_logic;  -- 100MHz Serial Clock
  TRIG_CLKN  : out  std_logic;
  TRIG_DATP  : out  std_logic;  -- 800 Mbps Serial Data
  TRIG_DATN  : out  std_logic
);
end TriggerOutLogic;


architecture behavior of TriggerOutLogic is

signal ClkOutP     : STD_LOGIC_VECTOR(0 DOWNTO 0);
signal ClkOutN     : STD_LOGIC_VECTOR(0 DOWNTO 0);
signal DatOutP     : STD_LOGIC_VECTOR(0 DOWNTO 0);
signal DatOutN     : STD_LOGIC_VECTOR(0 DOWNTO 0);
signal DataOut     : STD_LOGIC_VECTOR(1 DOWNTO 0);
signal SerTrigIn   : std_logic_vector(7 downto 0);
signal SerTrigOut  : std_logic_vector(7 downto 0);
signal SerDatOut   : std_logic_vector(15 downto 0);

signal dTRIG_VALID : std_logic;

function reverse(a: in std_logic_vector) return std_logic_vector is
  variable result: std_logic_vector(a'range);
  alias aa: std_logic_vector(a'reverse_range) is a;
begin
  for i in aa'range loop
    result(i) := aa(i);
  end loop;
  return result;
end; -- function reverse

begin

  -- Connect serial output vectors to output pins
  TRIG_CLKP <= ClkOutP(0);
  TRIG_CLKN <= ClkOutN(0);
  TRIG_DATP <= DatOutP(0);
  TRIG_DATN <= DatOutN(0);

  -- Data sent externally LSB first. Bits are swapped so that the trigger is readable on a scope.
  -- On receive, the data is swapped again so that it ends up the the correct order at the output of the trigger receive FIFO
  -- 4 LS bits set for clock.  Reads as parallel 0xF0 at the receiver

  -- Note: SelectIO wizard IP internally assigns the LSB to D1 of the OSERDESE2

  SCLK1 : entity work.SEROUT8
  port map
  (
    data_out_to_pins_p   => ClkOutP,
    data_out_to_pins_n   => ClkOutN,
    clk_in               => CLK_400MHZ,
    clk_div_in           => CLK_100MHZ,
    data_out_from_device => "00001111",   -- Fixed clock data pattern, sent LSB first.
    io_reset             => RESET
  );

  SDAT1 : entity work.SEROUT8
  port map
  (
    data_out_to_pins_p   => DatOutP,
    data_out_to_pins_n   => DatOutN,
    clk_in               => CLK_400MHZ,
    clk_div_in           => CLK_100MHZ,
    data_out_from_device => reverse(SerTrigOut), -- Swapped Trigger Byte
    io_reset             => RESET
  );

  -- One level of input data pipelining to allow for easier routing
  process(CLK_100MHZ, RESET)
  begin
    if RESET = '1' then
      SerTrigIn <= (others => '0');
      dTRIG_VALID <= '0';
    elsif rising_edge(CLK_100MHZ) then
      SerTrigIn <= TRIG_TX;
      dTRIG_VALID <= TRIG_VALID;
    end if;
  end process;

  -- Only present non-zero data when there is a valid input
  -- The output is ALWAYS writing.  When there are not triggers, it writes 0xFF
  SerTrigOut <= SerTrigIn when dTRIG_VALID = '1' else x"ff";


end behavior;

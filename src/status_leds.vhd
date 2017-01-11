-- Drive front-panel LED status indicators
--
---- Comms is top LED(3 downto 2):
-- No connection - dark
-- Idle connection - heartbeat green
-- Packet recieved or sent - flash green
-- Error in Ethernet DMA - red
--
-- SATA connections are bottom LED(1 downto 0)
-- Idle - dark
-- Valid recevied - flash green

-- Original author: Colm Ryan
-- Copyright 2016 Raytheon BBN Technologies

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity status_leds is
	port (
		clk                    : in std_logic;
		rst                    : in std_logic;
		link_established       : in std_logic;
		comms_active           : in std_logic;
		comms_error            : in std_logic;

		leds                   : out std_logic_vector(3 downto 0)
	);
end entity;

architecture behavioral of status_leds is

	-- LED output: drive "10" for RED and "01" for GREEN.
constant RED : std_logic_vector(1 downto 0) := "10";
constant GREEN : std_logic_vector(1 downto 0) := "01";
constant DARK : std_logic_vector(1 downto 0) := "00";

--Clock frequencies
constant CLK_FREQ : natural := 100_000_000; --Assume clocked off AXI clock at 100MHz
constant PWM_FREQ : natural := 256_000; -- modulate the LED at 1kHz
constant HEARTBEAT_FREQ : natural := 256/4; -- step through the heart beat in 4 seconds

signal enablePWM, enableHB : boolean := false;

signal hbGreen : std_logic_vector(1 downto 0);

signal comms_led, seq_led : std_logic_vector(1 downto 0) := DARK;

--status signals synced to module clock
signal link_established_int, comms_active_int, comms_error_int : std_logic;


signal khz_enable : boolean := false;
constant KHZ_COUNT : natural := CLK_FREQ/1000;

-- Sinusoidal modulation of LED dimming.
-- Actually 1 - abs(sin(x)) for x in 0 to pi
-- May need correction for eye non-linearity
type byteArray is array (integer range <>) of unsigned(7 downto 0) ;
constant sineData : byteArray(0 to 255) := (
	x"ff", x"fc", x"f9", x"f6", x"f2", x"ef", x"ec", x"e9", x"e6", x"e3",
	x"e0", x"dd", x"d9", x"d6", x"d3", x"d0", x"cd", x"ca", x"c7", x"c4",
	x"c1", x"be", x"bb", x"b8", x"b5", x"b2", x"af", x"ac", x"a9", x"a6",
	x"a3", x"a0", x"9d", x"9a", x"97", x"94", x"92", x"8f", x"8c", x"89",
	x"86", x"84", x"81", x"7e", x"7b", x"79", x"76", x"73", x"71", x"6e",
	x"6c", x"69", x"67", x"64", x"62", x"5f", x"5d", x"5a", x"58", x"56",
	x"53", x"51", x"4f", x"4c", x"4a", x"48", x"46", x"44", x"41", x"3f",
	x"3d", x"3b", x"39", x"37", x"35", x"34", x"32", x"30", x"2e", x"2c",
	x"2a", x"29", x"27", x"25", x"24", x"22", x"21", x"1f", x"1e", x"1c",
	x"1b", x"19", x"18", x"17", x"15", x"14", x"13", x"12", x"11", x"10",
	x"0e", x"0d", x"0c", x"0c", x"0b", x"0a", x"09", x"08", x"07", x"07",
	x"06", x"05", x"05", x"04", x"04", x"03", x"03", x"02", x"02", x"01",
	x"01", x"01", x"01", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
	x"00", x"00", x"00", x"01", x"01", x"01", x"01", x"02", x"02", x"03",
	x"03", x"04", x"04", x"05", x"05", x"06", x"07", x"07", x"08", x"09",
	x"0a", x"0b", x"0c", x"0c", x"0d", x"0e", x"10", x"11", x"12", x"13",
	x"14", x"15", x"17", x"18", x"19", x"1b", x"1c", x"1e", x"1f", x"21",
	x"22", x"24", x"25", x"27", x"29", x"2a", x"2c", x"2e", x"30", x"32",
	x"34", x"35", x"37", x"39", x"3b", x"3d", x"3f", x"41", x"44", x"46",
	x"48", x"4a", x"4c", x"4f", x"51", x"53", x"56", x"58", x"5a", x"5d",
	x"5f", x"62", x"64", x"67", x"69", x"6c", x"6e", x"71", x"73", x"76",
	x"79", x"7b", x"7e", x"81", x"84", x"86", x"89", x"8c", x"8f", x"92",
	x"94", x"97", x"9a", x"9d", x"a0", x"a3", x"a6", x"a9", x"ac", x"af",
	x"b2", x"b5", x"b8", x"bb", x"be", x"c1", x"c4", x"c7", x"ca", x"cd",
	x"d0", x"d3", x"d6", x"d9", x"dd", x"e0", x"e3", x"e6", x"e9", x"ec",
	x"ef", x"f2", x"f6", x"f9", x"fc", x"ff");


begin

leds(1 downto 0) <= comms_led;
leds(3 downto 2) <= seq_led;

--Divide down the AXI clock to something on the human timescale
enableGenerator : process( clk )
variable ctPWM, ctHB : natural;
begin
	if rising_edge(clk) then
		if rst = '1' then
			enablePWM <= false;
			enableHB <= false;
			ctPWM := 0;
			ctHB := 0;
		else
			enablePWM <= false;
			enableHB <= false;
			ctPWM := ctPWM + 1;
			ctHB := ctHB + 1;

			if ctPWM = CLK_FREQ/PWM_FREQ then
				enablePWM <= true;
				ctPWM := 0;
			end if;

			if ctHB = CLK_FREQ/HEARTBEAT_FREQ then
				enableHB <= true;
				ctHB := 0;
			end if;
		end if;
	end if ;
end process ; -- enableGenerator


heart_beat_pro : process( clk )
variable ctHB, ctPWM : unsigned(7 downto 0);
begin
	if rising_edge(clk) then
		if rst = '1' then
			ctPWM := (others => '0');
			ctHB := (others => '0');
			hbGreen <= DARK;
		else
			if enableHB then
				ctHB := ctHB + 1;
			end if;

			--Drive a green version
			if enablePWM then
				ctPWM := ctPWM + 1;
				if ctPWM <= sineData(to_integer(ctHB)) then
					hbGreen <= GREEN;
				else
					hbGreen <= DARK;
				end if;
			end if;

		end if ;
	end if ;
end process ; -- heart_beat_pro

--Divide clock down to 1kHz for blinking counts
khz_enable_pro : process(clk)
	variable ct : natural range 0 to KHZ_COUNT := 0;
begin
	if rising_edge(clk) then
		if rst = '1' then
			ct := 0;
			khz_enable <= false;
		else
			if ct = KHZ_COUNT then
				ct := 0;
				khz_enable <= true;
			else
				ct := ct + 1;
				khz_enable <= false;
			end if;
		end if;
	end if;
end process;

--Synchronize comms signals
sync_link_established: entity work.synchronizer
	port map ( rst => rst, clk => clk, data_in => link_established, data_out => link_established_int);

sync_comms_active: entity work.synchronizer
	port map ( rst => rst, clk => clk, data_in => comms_active, data_out => comms_active_int);

sync_comms_error: entity work.synchronizer
	port map ( rst => rst, clk => clk, data_in => comms_error, data_out => comms_error_int);

--Comms logic
commsLogic : process( clk )
	type state_t is (IDLE, BLINK_DARK, BLINK_GREEN);
	variable state : state_t := IDLE;
	variable blink_ct : natural range 0 to 1000;
begin
	if rising_edge(clk) then
		--No connection heart beat
		if link_established_int = '0' then
			comms_led <= hbGreen;
			state := IDLE;
		elsif comms_error_int = '1' then
			comms_led <= RED;
			state := IDLE;
		else
			case( state ) is

				when IDLE =>
					comms_led <= GREEN;
					blink_ct := 0;

					--catch packet transmission
					if comms_active_int = '1' then
						state := BLINK_DARK;
					end if;

				when BLINK_DARK =>
					comms_led <= DARK;
					if blink_ct = 50 then
						blink_ct := 0;
						state := BLINK_GREEN;
					elsif khz_enable then
						blink_ct := blink_ct + 1;
					end if;

				when BLINK_GREEN =>
					comms_led <= GREEN;
					if blink_ct = 50 then
						blink_ct := 0;
						state := IDLE;
					elsif khz_enable then
						blink_ct := blink_ct + 1;
					end if;

			end case ;
		end if ;
	end if ;
end process ; -- commsLogic


end architecture;

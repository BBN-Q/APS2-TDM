-- Original author: Graham Rowlands
-- Copyright 2016, Raytheon BBN Technologies
-- Test bench for SATA input from other boards

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SATA_in_tb is
end;

architecture Behavioral of SATA_in_tb is

	constant clk100_period: time := 10 ns;
	constant clk200_period: time := 5 ns;
	constant clk400_period: time := 2.5 ns;

	signal clk_user, clk_sata     : std_logic := '1';
	signal clk400_tdm, clk200_tdm, clk100_tdm : std_logic := '1';
	signal stop_the_clock         : boolean;

	signal rst_tdm           : std_logic := '0';
	signal twisted_pair_a_p  : std_logic := '0';
	signal twisted_pair_a_n  : std_logic := '0';
	signal twisted_pair_b_p  : std_logic := '0';
	signal twisted_pair_b_n  : std_logic := '0';

	signal tdm_tx     : std_logic_vector(7 downto 0) := (others => '0');

	signal aps2_next   : std_logic := '0';
	signal aps2_locked : std_logic := '0';
	signal aps2_err    : std_logic := '0';
	signal aps2_ovfl   : std_logic := '0';
	signal aps2_ready  : std_logic := '0';
	signal aps2_rx     : std_logic_vector(7 downto 0) := (others => '0');

	signal tdm_tx_valid : std_logic := '0';
	signal tdm_tx_afull : std_logic := '0';

begin

	clk_user   <= not clk_user after clk100_period / 2 when not stop_the_clock;
	clk100_tdm <= not clk100_tdm after clk100_period / 2 when not stop_the_clock;
	clk200_tdm <= not clk200_tdm after clk200_period / 2 when not stop_the_clock;
	clk400_tdm <= not clk400_tdm after clk400_period / 2 when not stop_the_clock;

	-- Perpetually flush the buffer
	aps2_next  <= aps2_ready;

	trig_in_logic_uut : entity work.TriggerInLogic
	port map
	(
		USER_CLK   =>  clk_user,     -- Clock for the output side of the FIFO
		CLK_200MHZ =>  clk200_tdm,   -- Delay calibration clock
		RESET      =>  rst_tdm,      -- Reset for the trigger logic and FIFO

		TRIG_CLKP  =>  twisted_pair_a_p,  -- 100MHz Serial Clock, clocks input side of FIFO
		TRIG_CLKN  =>  twisted_pair_a_n,
		TRIG_DATP  =>  twisted_pair_b_p,  -- 800 Mbps Serial Data
		TRIG_DATN  =>  twisted_pair_b_n,

		TRIG_NEXT  =>  aps2_next,  -- Advance the FIFO output to the next trigger, must be synchronous to USER_CLK

		TRIG_LOCKED => aps2_locked, -- Set when locked and aligned to the received trigger clock, synchronous to USER_CLK
		TRIG_ERR    => aps2_err,    -- Set if unaligned clock received after clock locked and aligned, synchronous to USER_CLK
		TRIG_RX     => aps2_rx,     -- Current trigger value, synchronous to USER_CLK
		TRIG_OVFL   => aps2_ovfl,   -- Set if trigger FIFO overflows, cleared by RESET, synchronous to USER_CLK
		TRIG_READY  => aps2_ready   -- FIFO output valid flag, set when TRIG_RX is valid, synchronous to USER_CLK
	);

	trig_out_logic_uut : entity work.TriggerOutLogic
	port map
	(
		USER_CLK   => clk_user,

		-- These clocks are usually generated from an MMCM driven by the CFG_CCLK.
		CLK_100MHZ => clk100_tdm,
		CLK_400MHZ => clk400_tdm,
		RESET      => rst_tdm,

		TRIG_TX    => tdm_tx,
		TRIG_WR    => tdm_tx_valid,
		TRIG_AFULL => tdm_tx_afull,

		TRIG_CLKP  => twisted_pair_a_p,
		TRIG_CLKN  => twisted_pair_a_n,
		TRIG_DATP  => twisted_pair_b_p,
		TRIG_DATN  => twisted_pair_b_n
	);

	stimulus: process
	begin

		-- Give some time for reset
		rst_tdm <= '1';
		wait for 30 ns;
		rst_tdm <= '0';
		wait until aps2_locked = '1';
		wait for 100 ns;

		-- Throw some data through the twisted pairs
		for i in 0 to 7 loop
			wait until rising_edge(clk_user);
			tdm_tx <= std_logic_vector(to_unsigned(i, 8));
			tdm_tx_valid <= '1';
		end loop;

		-- Turn off transmission and wait.
		wait until rising_edge(clk_user);
		tdm_tx_valid <= '0';
		wait for 1000 ns;

		-- Stop
		stop_the_clock <= true;
		wait;

	end process;

end Behavioral;

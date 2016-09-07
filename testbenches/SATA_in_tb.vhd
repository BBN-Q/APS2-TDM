-- Original author: Graham Rowlands
-- Copyright 2016, Raytheon BBN Technologies
-- Test bench for SATA input from other boards

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SATA_in_tb is
end;

architecture Behavioral of SATA_in_tb is

	constant test_vec : std_logic_vector(32 downto 0) := b"01101101_11101101_01101111_00100101";

	constant clk100_period: time := 10 ns;
	constant clk200_period: time := 5 ns;
	constant clk_sata_period: time := 10.01 ns;
	constant clk_sata_skew: time := 1 ns;

	signal clk_user, clk_sata     : std_logic := '0';
	signal clk200_tdm, clk100_tdm : std_logic := '0';
	signal stop_the_clock         : boolean;

	signal rst_tdm           : std_logic := '0';
	signal twisted_pair_a_p  : std_logic := '0';
	signal twisted_pair_a_n  : std_logic := '0';
	signal twisted_pair_b_p  : std_logic := '0';
	signal twisted_pair_b_n  : std_logic := '0';

	signal tdm_locked : std_logic := '0';
	signal tdm_err    : std_logic := '0';
	signal tdm_ovfl   : std_logic := '0';
	signal tdm_ready  : std_logic := '0';
	signal tdm_rx     : std_logic_vector(7 downto 0) := (others => '0');

begin

	clk_user       <= not clk_user after clk100_period / 2 when not stop_the_clock;
	clk_sata       <= not clk_sata after clk_sata_period / 2 when not stop_the_clock;
	clk100_ref_tdm <= not clk100_ref_tdm after clk100_period / 2 when not stop_the_clock;
	clk200_ref_tdm <= not clk200_ref_tdm after clk200_period / 2 when not stop_the_clock;

	trig_in_logic_uut : entity work.TriggerInLogic
	port
	(
		USER_CLK   =>  clk100_tdm,   -- Clock for the output side of the FIFO
		CLK_200MHZ =>  clk200_tdm,   -- Delay calibration clock
		RESET      =>  rst_tdm,      -- Asynchronous reset for the trigger logic and FIFO

		TRIG_CLKP  =>  twisted_pair_a_p,  -- 100MHz Serial Clock, clocks input side of FIFO
		TRIG_CLKN  =>  twisted_pair_a_n,
		TRIG_DATP  =>  twisted_pair_b_p,  -- 800 Mbps Serial Data
		TRIG_DATN  =>  twisted_pair_b_n,

		TRIG_NEXT  =>  tdm_next,  -- Advance the FIFO output to the next trigger, must be synchronous to USER_CLK

		TRIG_LOCKED => tdm_locked, -- Set when locked and aligned to the received trigger clock, synchronous to USER_CLK
		TRIG_ERR    => tdm_err,    -- Set if unaligned clock received after clock locked and aligned, synchronous to USER_CLK
		TRIG_RX     => tdm_rx,     -- Current trigger value, synchronous to USER_CLK
		TRIG_OVFL   => tdm_ovfl,   -- Set if trigger FIFO overflows, cleared by RESET, synchronous to USER_CLK
		TRIG_READY  => tdm_ready   -- FIFO output valid flag, set when TRIG_RX is valid, synchronous to USER_CLK
	);

	stimulus: process
	begin

		-- Give some time for reset
		rst_tdm <= '1';
		wait for 10 ns;
		reset <= '0';
		
		-- Wait for the trigger logic to become ready
		wait until tdm_ready;

		-- Throw some data through the twisted pairs
		for ct in 1 to 32 loop
			wait until rising_edge(clk_sata); -- May be at a different frequency
			wait for clk_sata_skew;           -- May be offset from the local 100MHz reference
			
			-- Push the clock
			twisted_pair_a_p <= not twisted_pair_a_p;
			twisted_pair_a_n <= not twisted_pair_a_p;
			-- Push the data
			twisted_pair_b_p <= test_vec(i);
			twisted_pair_b_p <= not test_vec(i);
		end loop;
		wait for 10 ns;

		stop_the_clock <= true;
		wait;

	end process;

end Behavioral;
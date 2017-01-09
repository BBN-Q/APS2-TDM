-- ATM_top.vhd
--
-- This is the top level module of the ATM firmware.
-- It instantiates the main BD with the comms., 9 SATA outputs, and one SATA input.

-- Original authors: Colm Ryan and Blake Johnson
-- Copyright 2015,2016 Raytheon BBN Technologies

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.or_reduce;

library unisim;
use unisim.vcomponents.all;

use work.AtmIPCores.all;
use work.ATMConstants.all;

entity ATM_top is
port
(
	ref_fpga    : in std_logic;  -- Global 10MHz reference
	fpga_resetl : in  std_logic;  -- Global reset from config FPGA

	-- Temp Diode Pins
	vp_in      : in  std_logic;
	vn_in      : in  std_logic;

	-- Config Bus Connections
	cfg_clk   : in  std_logic;  -- 100 MHZ clock from the Config CPLD
	cfgd       : inout std_logic_vector(15 downto 0);  -- Config Data bus from CPLD
	fpga_cmdl  : out  std_logic;  -- Command strobe from FPGA
	fpga_rdyl  : out  std_logic;  -- Ready Strobe from FPGA
	cfg_rdy    : in  std_logic;  -- Ready to complete current transfer.  Connected to CFG_RDWR_B
	cfg_err    : in  std_logic;  -- Error during current command.  Connecte to CFG_CSI_B
	cfg_act    : in  std_logic;  -- Current transaction is complete
	stat_oel   : out std_logic;  -- Enable CPLD to drive status onto CFGD

	-- SFP Tranceiver Interface
	sfp_mgt_clkp : in std_logic;		-- 125 MHz reference
	sfp_mgt_clkn : in std_logic;
	sfp_txp      : out std_logic;	 -- TX out to SFP
	sfp_txn      : out std_logic;
	sfp_rxp      : in std_logic;		-- RX in from SPF
	sfp_rxn      : in std_logic;

	-- SFP control signals
	sfp_enh   : buffer std_logic; -- sfp enable high
	sfp_scl   : out std_logic;    -- sfp serial clock - unused
	sfp_txdis : buffer std_logic; -- sfp disable laser
	sfp_sda   : in std_logic;     -- sfp serial data - unused
	sfp_fault : in std_logic;     -- sfp tx fault -unused
	sfp_los   : in std_logic; -- sfp loss of signal input laser power too low; also goes high when ethernet jack disconnected; low when plugged in -unused
	sfp_presl : in std_logic;	-- sfp present low ??? doesn't seem to be in spec.

	-- External trigger comparator related signals
	trg_cmpn : in std_logic_vector(7 downto 0);
	trg_cmpp : in std_logic_vector(7 downto 0);
	thr      : out std_logic_vector(7 downto 0);

	-- Trigger Outputs
	trgclk_outn : out std_logic_vector(8 downto 0);
	trgclk_outp : out std_logic_vector(8 downto 0);
	trgdat_outn : out std_logic_vector(8 downto 0);
	trgdat_outp : out std_logic_vector(8 downto 0);

	-- Trigger input
	trig_ctrln : in std_logic_vector(1 downto 0);
	trig_ctrlp : in std_logic_vector(1 downto 0);

	-- Internal Status LEDs
	led      : out  std_logic_vector(9 downto 0);

	-- Debug LEDs / configuration jumpers
	dbg        : inout  std_logic_vector(8 downto 0)
);
end ATM_top;


architecture behavior of ATM_top is

	--- Constants ---
	constant SUBNET_MASK : std_logic_vector(31 downto 0) := x"ffffff00"; -- 255.255.255.0
	constant TCP_PORT : std_logic_vector(15 downto 0) := x"bb4e"; -- BBN
	constant UDP_PORT : std_logic_vector(15 downto 0) := x"bb4f"; -- BBN + 1
	constant GATEWAY_IP_ADDR : std_logic_vector(31 downto 0) := x"c0a80201"; -- TODO: what this should be?
	constant IFG_DELAY : std_logic_vector(7 downto 0) := x"0c"; --interframe gap of 12 -standard is 96 bits (12 bytes) see https://en.wikipedia.org/wiki/Interpacket_gap
	constant PCS_PMA_AN_ADV_CONFIG_VECTOR : std_logic_vector(15 downto 0) := x"0020"; --full-duplex see Table 2-55 (pg. 74) of PG047 November 18, 2015
	constant PCS_PMA_CONFIGURATION_VECTOR : std_logic_vector(4 downto 0) := b"10000"; --auto-negotiation enabled see Table 2-54 (pg. 73) of PG047 November 18, 2015


	--- clocks
	signal clk_100 : std_logic;
	signal clk_100_skewed : std_logic;
	signal clk_125 : std_logic;
	signal clk_200 : std_logic;
	signal clk_400 : std_logic;
	signal ref_100 : std_logic;

	signal cfg_clk_mmcm_locked : std_logic;
	signal ref_locked          : std_logic;
	signal ref_locked_s        : std_logic;
	signal ref_locked_d        : std_logic;
	signal sys_clk_mmcm_locked : std_logic;

	-- Resets
	signal rst_comm_stack, rst_cfg_reader, rst_comblock,
				 rst_cpld_bridge, rst_eth_mac, rst_pcs_pma, rst_tcp_bridge,
				 rst_udp_responder, rstn_axi,
				 rst_sync_clk125, rst_sync_clk100,
				 rst_sata : std_logic := '0';

	signal cfg_reader_done : std_logic;

	--SFP
	signal mgt_clk_locked : std_logic;
	signal pcs_pma_status_vector : std_logic_vector(15 downto 0);
	alias link_established : std_logic is pcs_pma_status_vector(0);
	signal pcs_pma_an_restart_config : std_logic;
	signal comms_active : std_logic;

	signal ExtTrig : std_logic_vector(7 downto 0);
	signal sys_clk_mmcm_reset   : std_logic := '0';

	-- Trigger signals
	type BYTE_ARRAY is array (0 to 8) of std_logic_vector(7 downto 0);
	signal TrigOutDat     : BYTE_ARRAY;
	signal TrigWr         : std_logic_vector(8 downto 0);
	signal TrigOutFull    : std_logic_vector(8 downto 0);

	signal TrigInDat      : std_logic_vector(7 downto 0);
	signal TrigClkErr     : std_logic;
	signal TrigOvflErr    : std_logic;
	signal TrigLocked     : std_logic;
	signal TrigInReady    : std_logic;
	signal TrigInRd       : std_logic;
	signal TrigFull       : std_logic;

	signal latched_trig_word : std_logic_vector(31 downto 0);
	signal ext_valid      : std_logic;
	signal ext_valid_d    : std_logic;
	signal ext_valid_re   : std_logic;
	signal CMP : std_logic_vector(7 downto 0);

	-- Internal trigger signals
	signal trigger          : std_logic;
	signal trigger_interval : std_logic_vector(31 downto 0);
	signal trigger_control  : std_logic_vector(31 downto 0);


	--CSR registers
	signal resets : std_logic_vector(31 downto 0);


begin

--------------------------------------------------------------------------------
-- clocking
--------------------------------------------------------------------------------

	sync_reflocked : entity work.synchronizer
	port map ( rst => not(fpga_resetl), clk => clk_125, data_in => ref_locked, data_out => ref_locked_s );

	-- need to reset SYS_MMCM on rising or falling edge of RefLocked
	sys_mmcm_reset : process( mgt_clk_locked, clk_125 )
	begin
		if mgt_clk_locked = '0' then
			sys_clk_mmcm_reset <= '1';
		elsif rising_edge(clk_125) then
			ref_locked_d <= ref_locked_s;
			if (ref_locked_d xor ref_locked_s) = '1' then
				sys_clk_mmcm_reset <= '1';
			else
				sys_clk_mmcm_reset <= '0';
			end if;
		end if;
	end process ; -- sys_mmcm_reset

	-- multiply reference clock up to 100 MHz
	CK1: REF_MMCM
	port map (
		CLK_REF => ref_fpga,

		-- clock out ports
		CLK_100MHZ => ref_100,

		-- status and control signals
		RESET      => not fpga_resetl,
		LOCKED     => ref_locked
	);

	-- Create aligned 100 and 400 MHz clocks for SATA in/out logic
	-- from either the 10 MHz reference or the 125 MHz sfp clock
	CK0 : SYS_MMCM
	port map
	(
		-- Clock in ports
		REF_100MHZ_IN => ref_100,
		CLK_125MHZ_IN    => clk_125,
		CLK_IN_SEL    => ref_locked, -- choose ref_100 when HIGH

		-- Clock out ports
		CLK_100MHZ    => clk_100,
		CLK_200MHZ    => open,
		CLK_400MHZ    => clk_400,

		-- Status and control signals
		RESET         => sys_clk_mmcm_reset,
		LOCKED        => sys_clk_mmcm_locked
	);

	-- create a skewed copy of the cfg_clk to meet bus timing
	-- also use for 200 MHz IODELAY reference calibration
	CK2 : CCLK_MMCM
	port map (
		CLK_100MHZ_IN => cfg_clk,
		CLK_100MHZ    => clk_100_skewed,
		CLK_200MHZ    => clk_200,
		RESET         => not fpga_resetl,
		LOCKED        => cfg_clk_mmcm_locked
	);

--------------------------------------------------------------------------------
-- resets
--------------------------------------------------------------------------------
	--Disable SFP when not present
	sfp_enh <= '0' when sfp_presl = '1' or fpga_resetl = '0' else '1';
	sfp_txdis <= '1' when sfp_presl = '1' or fpga_resetl = '0' else '0';

	-- tie-off unused ports
	sfp_scl <= '0';

	-- SFP may take up to 300ms to initialize after power up according to spec.
	-- Chris used only 100ms
	-- wait that long and then reset the autonegotiation
	sfp_an_reset_proc : process( clk_125, cfg_clk_mmcm_locked, mgt_clk_locked )
		variable reset_ct : unsigned(24 downto 0) := (others => '0');
	begin
		--Wait until all the clocks are locked
		if cfg_clk_mmcm_locked = '0' or mgt_clk_locked = '0' then
			reset_ct := to_unsigned(12_500_000, reset_ct'length); --100ms at 125MHz ignoring off-by-one issues
			pcs_pma_an_restart_config <= '0';
		elsif rising_edge( clk_125 ) then
			if reset_ct(reset_ct'high) = '1' then
				pcs_pma_an_restart_config <= '1';
			else
				reset_ct := reset_ct - 1;
			end if;
		end if;
	end process;

	-- Reset sequencing:
	-- 1. CFG clock is reset by FPGA_RESETL and everything waits on CFG clock to lock
	-- 2. Once CFG clock is up release CPLD bridge to let APS Msg processor come up and PCS/PMA layer
	-- 3. Wait ???? after ApsMsgProc released from reset to issue configuration read command
	-- 3. Wait 100 ms after boot for SFP to come up (see above)
	-- 4. Wait for cfg_reader_done with timeout of ??? to release rest of comms stack
	-- 5. Release everything else

	--Wait until cfg_clk_mmcm_locked so that we have 200MHz reference before deasserting pcs/pma and MIG reset
	rst_pcs_pma <= not cfg_clk_mmcm_locked;

	--once we have CFG clock we can talk to CPLD
	reset_synchronizer_clk_100 : entity work.synchronizer
	generic map(RESET_VALUE => '1')
	port map(rst => not cfg_clk_mmcm_locked, clk => clk_100, data_in => '0', data_out => rst_sync_clk100);
	rst_cpld_bridge <= rst_sync_clk100;
	rst_sata <= rst_sync_clk100;

	--Config reader reset and wait for done
	cfg_reader_wait : process(sys_clk_mmcm_locked, clk_100)
		variable reset_ct : unsigned(24 downto 0) := (others => '0');
		variable wait_ct	: unsigned(24 downto 0) := (others => '0');
		type state_t is (WAIT_FOR_RESET, WAIT_FOR_DONE, FINISHED);
		variable state : state_t;
	begin
		if sys_clk_mmcm_locked = '0' then
			state := WAIT_FOR_RESET;
			reset_ct := to_unsigned(10_100_000, reset_ct'length); --101ms at 125MHz ignoring off-by-one issues
			wait_ct := to_unsigned(10_000_000, wait_ct'length); --100ms at 125MHz ignoring off-by-one issues
			rst_cfg_reader <= '1';
			rst_comm_stack <= '1';
		elsif rising_edge( clk_100) then
			case( state ) is

				when WAIT_FOR_RESET =>
					if reset_ct(reset_ct'high) = '1' then
						state := WAIT_FOR_DONE;
					else
						reset_ct := reset_ct - 1;
					end if;

				when WAIT_FOR_DONE =>
					rst_cfg_reader <= '0';
					if cfg_reader_done = '1' or wait_ct(wait_ct'high) = '1' then
						state := FINISHED;
					else
						wait_ct := wait_ct - 1;
					end if;

				when FINISHED =>
					rst_comm_stack <= '0';

			end case;

		end if;
	end process;

	rst_tcp_bridge <= rst_comm_stack;

	-- synchronize resets to appropriate clock domains
	reset_synchronizer_clk_125Mhz : entity work.synchronizer
	generic map(RESET_VALUE => '1')
	port map(rst => rst_comm_stack, clk => clk_125, data_in => '0', data_out => rst_sync_clk125);

	rst_udp_responder <= rst_sync_clk125;
	rst_comblock <= rst_sync_clk125;
	rst_eth_mac <= rst_sync_clk125;

	--for now also reset memory with comms stack
	rstn_axi <= not rst_comm_stack;

-------------------------------------------------------------------------------
-- comparator inputs
-------------------------------------------------------------------------------

	CBF1 : for i in 0 to 7 generate
		-- External trigger input from LVDS comparator.  Must be differentially termianted
		IBX : IBUFDS
		generic map
		(
			DIFF_TERM => TRUE, -- Differential Termination
			IBUF_LOW_PWR => FALSE -- Low power (TRUE) vs. performance (FALSE) setting for refernced I/O standards
		)
		port map
		(
			O  => CMP(i),      -- Drive the LED output
			I  => TRG_CMPP(i), -- Diff_p buffer input (connect directly to top-level port)
			IB => TRG_CMPN(i)  -- Diff_n buffer input (connect directly to top-level port)
		);

		PWMX : entity work.PWMA8
		port map
		(
			CLK => clk_100,
			RESET => rst_sata,
			DIN => x"52",  -- Fix at 0.8V for now.  Eventually drive from a status register
			PWM_OUT => THR(i)
		);

	end generate;

	-- Send output status to LEDs for checking
	-- TODO
	led <= (others => '0');

-------------------------------------------------------------------------------
-- SATA connections
-------------------------------------------------------------------------------


	-- basic logic to broadcast input triggers to all output triggers
	-- VALID on rising edge of CMP(7) or internal trigger
	-- sync external valid on CLK_100MHZ
	sync_valid : entity work.synchronizer
	port map ( rst => rst_sata, clk => clk_100, data_in => CMP(7), data_out => ext_valid );

	-- DATA is CMP(6 downto 0) except when internal trigger fires, in which case we send 0xFE
	ext_valid_re <= ext_valid and not ext_valid_d;
	process(clk_100)
	begin
		if rising_edge(clk_100) then
			ext_valid_d <= ext_valid;
			if trigger = '1' then
				TrigOutDat <= (others => x"fe");
			else
				TrigOutDat <= (others => '0' & CMP(6 downto 0));
			end if;
			if rst_sata = '1' or or_reduce(TrigOutFull) = '1' then
				TrigWr <= (others => '0');
			else
				TrigWr <= (others => ext_valid_re or trigger);
			end if;
		end if;
	end process;

	process (clk_100)
	begin
		if rising_edge(clk_100) then
			if TrigWr(0) = '1' then
				latched_trig_word <= latched_trig_word(23 downto 0) & TrigOutDat(0);
			end if;
		end if;
	end process;

	TO1 : for i in 0 to 8 generate
		-- Externally, cable routing requires a non sequential JTx to TOx routing.
		-- The cables are routed from the PCB connectors to the front panel as shown below.
		-- The mapping is performed by changing the pin definitions in the XDC file.
		--
		-- TO1 = JT0
		-- TO2 = JT2
		-- TO3 = JT4
		-- TO4 = JT6
		-- TO5 = JC01
		-- TO6 = JT3
		-- TO7 = JT1
		-- TO8 = JT5
		-- TO9 = JT7
		-- TAUX = JT8
		TOLX : entity work.TriggerOutLogic
		port map
		(
			USER_CLK   => clk_100,

			-- These clocks are usually generated from an MMCM driven by the CFG_CCLK.
			CLK_100MHZ => clk_100,
			CLK_400MHZ => CLK_400,
			RESET      => rst_sata,

			TRIG_TX    => TrigOutDat(i),
			TRIG_WR    => TrigWr(i),
			TRIG_AFULL => TrigOutFull(i),

			TRIG_CLKP  => TRGCLK_OUTP(i),
			TRIG_CLKN  => TRGCLK_OUTN(i),
			TRIG_DATP  => TRGDAT_OUTP(i),
			TRIG_DATN  => TRGDAT_OUTN(i)
		);
	end generate;

	-- Instantiate LVDS 8:1 logic on auxiliary SATA port
	TIL1 : entity work.TriggerInLogic
	port map
	(
		USER_CLK   => clk_100,
		CLK_200MHZ => clk_200,
		RESET      => rst_sata,

		TRIG_CLKP  => TRIG_CTRLP(0),
		TRIG_CLKN  => TRIG_CTRLN(0),
		TRIG_DATP  => TRIG_CTRLP(1),
		TRIG_DATN  => TRIG_CTRLN(1),

		TRIG_NEXT  => TrigInRd,  -- Always read data when it is available

		TRIG_LOCKED => TrigLocked,
		TRIG_ERR   => TrigClkErr,
		TRIG_RX    => TrigInDat,
		TRIG_OVFL  => TrigOvflErr,
		TRIG_READY => TrigInReady
	);

	-- Continually drain the input FIFO
	TrigInRd <= TrigInReady;


	IntTrig : entity work.InternalTrig
	port map (
		RESET => resets(0),
		CLK => clk_100,
		triggerInterval => trigger_interval,
		triggerSource => trigger_control(0),
		softTrigToggle => trigger_control(2),
		trigger => trigger
	);

-- wrap the main block design
main_bd_inst : entity work.main_bd
	port map (
		--configuration constants
		gateway_ip_addr              => GATEWAY_IP_ADDR,
		ifg_delay                    => IFG_DELAY,
		subnet_mask                  => SUBNET_MASK,
		tcp_port                     => TCP_PORT,
		udp_port                     => UDP_PORT,
		pcs_pma_an_adv_config_vector => PCS_PMA_AN_ADV_CONFIG_VECTOR,
		pcs_pma_configuration_vector => PCS_PMA_CONFIGURATION_VECTOR,

		--clocks
		clk_125           => clk_125,
		clk_axi           => clk_100,
		clk_ref_200       => clk_200,
		sfp_mgt_clk_clk_n => sfp_mgt_clkn,
		sfp_mgt_clk_clk_p => sfp_mgt_clkp,

		--resets
		rst_pcs_pma       => rst_pcs_pma,
		rst_eth_mac       => rst_eth_mac,
		rst_cpld_bridge   => rst_cpld_bridge,
		rst_cfg_reader    => rst_cfg_reader,
		rst_comblock      => rst_comblock,
		rst_tcp_bridge    => rst_tcp_bridge,
		rst_udp_responder => rst_udp_responder,
		rstn_axi          => rstn_axi,
		cfg_reader_done => cfg_reader_done,

		--SFP
		sfp_signal_detect         => not sfp_los,
		pcs_pma_mmcm_locked       => mgt_clk_locked,
		pcs_pma_status_vector     => pcs_pma_status_vector,
		pcs_pma_an_restart_config => pcs_pma_an_restart_config,
		sfp_rxn                   => sfp_rxn,
		sfp_rxp                   => sfp_rxp,
		sfp_txn                   => sfp_txn,
		sfp_txp                   => sfp_txp,
		comms_active              => comms_active,

		--CPLD interface
		cfg_act   => cfg_act,
		cfg_clk   => clk_100_skewed,
		cfg_err   => cfg_err,
		cfg_rdy   => cfg_rdy,
		cfgd      => cfgd(15 downto 0),
		fpga_cmdl => fpga_cmdl,
		fpga_rdyl => fpga_rdyl,
		stat_oel  => stat_oel,

		-- CSR registers
		control => open,
		resets => resets,
		trigger_interval => trigger_interval,

		SATA_status        => (others => '0'),
		build_timestamp    => (others => '0'),
		git_sha1           => (others => '0'),
		tdm_version        => (others => '0'),
		temperature        => (others => '0'),
		trigger_word       => (others => '0'),
		uptime_nanoseconds => (others => '0'),
		uptime_seconds     => (others => '0')
	);

end behavior;

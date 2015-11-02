-- AtmTop.vhd
--
-- This is the top level ATM module of the ATM test firmware.
-- It instantiates the Host Logic, the User Logic, 9 trigger outputs, and one trigger input.
-- The UserLogic is the same as for the APS II test software.
-- There are no DACs for the User Logic to control, but the DAC0 amplitude is used as a trigger output enable.
--
-- REVISIONS
--
-- 8/5/2014  CRJ
--   Created based on ApsTop
--
-- 9/03/2013 CRJ
--   Cleaned up for initial release
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
use ieee.std_logic_misc.or_reduce;

use work.AtmIPCores.all;
use work.ATMConstants.all;

entity AtmTop is
port
(
	REF_FPGA    : in std_logic;  -- Global 10MHz reference
	FPGA_RESETL : in  STD_LOGIC;  -- Global reset from config FPGA

	-- Temp Diode Pins
	VP_IN      : in  STD_LOGIC;
	VN_IN      : in  STD_LOGIC;

	-- Config Bus Connections
	CFG_CCLK   : in  STD_LOGIC;  -- 100 MHZ clock from the Config CPLD
	CFGD       : inout std_logic_vector(15 downto 0);  -- Config Data bus from CPLD
	FPGA_CMDL  : out  STD_LOGIC;  -- Command strobe from FPGA
	FPGA_RDYL  : out  STD_LOGIC;  -- Ready Strobe from FPGA
	CFG_RDY    : in  STD_LOGIC;  -- Ready to complete current transfer.  Connected to CFG_RDWR_B
	CFG_ERR    : in  STD_LOGIC;  -- Error during current command.  Connecte to CFG_CSI_B
	CFG_ACT    : in  STD_LOGIC;  -- Current transaction is complete
	STAT_OEL   : out std_logic;  -- Enable CPLD to drive status onto CFGD

	-- SFP Tranceiver Interface
	gtrefclk_p : in std_logic;    -- 125 MHz reference
	gtrefclk_n : in std_logic;
	txp        : out std_logic;   -- TX out to SFP
	txn        : out std_logic;
	rxp        : in std_logic;    -- RX in from SPF
	rxn        : in std_logic;

	-- SFP Signals
	SFP_ENH    : out std_logic;
	SFP_SCL    : out std_logic;
	SFP_SDA    : in std_logic;
	SFP_FAULT  : in std_logic;
	SFP_LOS    : in std_logic;
	SFP_PRESL  : in std_logic;
	SFP_TXDIS  : out std_logic;

	-- External trigger comparator related signals
	TRG_CMPN : in std_logic_vector(7 downto 0);
	TRG_CMPP : in std_logic_vector(7 downto 0);
	THR      : out std_logic_vector(7 downto 0);

	-- Internal Status LEDs
	LED      : out  std_logic_vector(9 downto 0);

	-- Trigger Outputs
	TRGCLK_OUTN : out std_logic_vector(8 downto 0);
	TRGCLK_OUTP : out std_logic_vector(8 downto 0);
	TRGDAT_OUTN : out std_logic_vector(8 downto 0);
	TRGDAT_OUTP : out std_logic_vector(8 downto 0);

	-- Trigger input
	TRIG_CTRLN : in std_logic_vector(1 downto 0);
	TRIG_CTRLP : in std_logic_vector(1 downto 0);

	-- Debug LEDs / configuration jumpers
	DBG        : inout  std_logic_vector(8 downto 0)
);
end AtmTop;


architecture behavior of AtmTop is

type TEMP_STATE is (TS_INIT, TS_READ, TS_WAIT);
signal TempState : TEMP_STATE;

signal CFG_CLK       : std_logic;
signal CLK_100MHZ    : std_logic;
signal CLK_125MHZ    : std_logic;
signal CLK_200MHZ    : std_logic;
signal CLK_400MHZ    : std_logic;
signal REF_100MHZ    : std_logic;

signal AXI_resetn    : std_logic;

signal ExtTrig : std_logic_vector(7 downto 0);
signal GlobalReset   : std_logic;
signal SysClkReset   : std_logic := '0';
signal STATUS : std_logic_vector(4 downto 0);

	-- User Logic Connections
signal USER_RST       : std_logic;
signal USER_STATUS    : std_logic_vector(31 downto 0) := (others => '0');

signal USER_DIF       : std_logic_vector(31 downto 0);
signal USER_DIF_RD    : std_logic;

signal USER_CIF_EMPTY : std_logic;
signal USER_CIF_RD    : std_logic;
signal USER_CIF_RW    : std_logic;
signal USER_CIF_MODE  : std_logic_vector(7 downto 0);
signal USER_CIF_CNT   : std_logic_vector(15 downto 0);
signal USER_CIF_ADDR  : std_logic_vector(31 downto 0);

signal USER_DOF       : std_logic_vector(31 downto 0);
signal USER_DOF_WR    : std_logic;

signal USER_COF_STAT  : std_logic_vector(7 downto 0);
signal USER_COF_CNT   : std_logic_vector(15 downto 0);
signal USER_COF_AFULL : std_logic;
signal USER_COF_WR    : std_logic;

signal UseInputs    : std_logic;
signal CfgLocked    : std_logic;
signal RefLocked    : std_logic;
signal RefLocked_s  : std_logic;
signal RefLocked_d  : std_logic;
signal SysLocked    : std_logic;
signal SfpTimer     : std_logic_vector(24 downto 0);
signal mgt_locked   : std_logic;

signal LedToggle : std_logic_vector(27 downto 0);
signal LedRed : std_logic;
signal ChannelOn      : std_logic;

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

-- Temperature signals
signal DrpData : std_logic_vector(15 downto 0);
signal CurTemp : std_logic_vector(15 downto 0);
signal DrpEn : std_logic;
signal DrpRdy : std_logic;
signal DrpBusy : std_logic;

--CSR AXI Lite
signal CSR_araddr :  std_logic_vector ( 31 downto 0 );
signal CSR_arprot :  std_logic_vector ( 2 downto 0 );
signal CSR_arready : std_logic;
signal CSR_arvalid : std_logic;
signal CSR_awaddr :  std_logic_vector ( 31 downto 0 );
signal CSR_awprot :  std_logic_vector ( 2 downto 0 );
signal CSR_awready : std_logic;
signal CSR_awvalid : std_logic;
signal CSR_bready :  std_logic;
signal CSR_bresp : std_logic_vector ( 1 downto 0 );
signal CSR_bvalid : std_logic;
signal CSR_rdata : std_logic_vector ( 31 downto 0 );
signal CSR_rready :  std_logic;
signal CSR_rresp : std_logic_vector ( 1 downto 0 );
signal CSR_rvalid : std_logic;
signal CSR_wdata :  std_logic_vector ( 31 downto 0 );
signal CSR_wready : std_logic;
signal CSR_wstrb :  std_logic_vector ( 3 downto 0 );
signal CSR_wvalid :  std_logic;

--CSR registers
signal resets : std_logic_vector(31 downto 0);


--Ethernet DataMover command/status and streams
signal ethernet_mm2s_tdata : std_logic_vector ( 31 downto 0 ) := (others => '0');
signal ethernet_mm2s_tkeep : std_logic_vector ( 3 downto 0 ) := (others => '0');
signal ethernet_mm2s_tlast : std_logic := '0';
signal ethernet_mm2s_tready : std_logic := '0';
signal ethernet_mm2s_tvalid : std_logic := '0';
signal ethernet_s2mm_tdata : std_logic_vector ( 31 downto 0 ) := (others => '0');
signal ethernet_s2mm_tkeep : std_logic_vector ( 3 downto 0 ) := (others => '1'); -- assuming 32bit words
signal ethernet_s2mm_tlast : std_logic := '0';
signal ethernet_s2mm_tvalid : std_logic := '0';
signal ethernet_s2mm_tready : std_logic := '0';

signal ethernet_s2mm_sts_tdata : std_logic_vector ( 7 downto 0 ) := (others => '0');
signal ethernet_s2mm_sts_tkeep : std_logic_vector ( 0 to 0 );
signal ethernet_s2mm_sts_tlast : std_logic := '0';
signal ethernet_s2mm_sts_tready : std_logic := '0';
signal ethernet_s2mm_sts_tvalid : std_logic := '0';
signal ethernet_mm2s_sts_tdata : std_logic_vector ( 7 downto 0 ) := (others => '0');
signal ethernet_mm2s_sts_tkeep : std_logic_vector ( 0 to 0 );
signal ethernet_mm2s_sts_tlast : std_logic := '0';
signal ethernet_mm2s_sts_tready : std_logic := '0';
signal ethernet_mm2s_sts_tvalid : std_logic := '0';
signal ethernet_s2mm_cmd_tdata : std_logic_vector ( 71 downto 0 ) := (others => '0');
signal ethernet_s2mm_cmd_tready : std_logic := '0';
signal ethernet_s2mm_cmd_tvalid : std_logic := '0';
signal ethernet_mm2s_cmd_tdata : std_logic_vector ( 71 downto 0 ) := (others => '0');
signal ethernet_mm2s_cmd_tready : std_logic := '0';
signal ethernet_mm2s_cmd_tvalid : std_logic := '0';
signal ethernet_s2mm_err : std_logic := '0';
signal ethernet_mm2s_err : std_logic := '0';

begin
	-- Avoid Xilinx errors for unused pins in the XDC file
	UseInputs <= SFP_SDA and SFP_FAULT and SFP_LOS and SFP_PRESL;

	-- Force use of UserInputs
	SFP_SCL <= '1' when (FPGA_RESETL = '0' and UseInputs = '1') else '0';

	-- Reset SFP module for at least 100ms when GlobalReset is deasserted
	process(CLK_100MHZ, FPGA_RESETL)
	begin
		if FPGA_RESETL = '0' then
			SfpTimer <= (others => '0');
			SFP_ENH <= '0';
			SFP_TXDIS <= '1';
			LedToggle <= (others => '0');
			LedRed <= '1';
			TempState <= TS_INIT;
			DrpEn <= '0';
			CurTemp <= (others => '0');
		elsif rising_edge(CLK_100MHZ) then
			LedToggle <= LedToggle + 1;

			if SFP_PRESL = '0' then
				-- Enable 250ms after the module is present and GlobalReset deasserted.  Longer so that you can seed RED LED at start for testing LEDs
				if SfpTimer(24) = '0'then
					SfpTimer <= SfpTimer + 1;
				else
					SFP_ENH <= '1';
					SFP_TXDIS <= '0';
					LedRed <= '0';
				end if;
			else
				-- Disable things when the module is not present
				SFP_ENH <= '0';
				SFP_TXDIS <= '1';
				SfpTimer <= (others => '0');
				LedRed <= '1';
			end if;

			-- Run a read of the temperature every time that LedToggle rolls over the 1M boundary
			case TempState is
	
				when TS_INIT =>
					-- Wait for start of a conversion so that you can read when it completes
					if LedToggle(20) = '1' and DrpBusy = '1' then
						TempState <= TS_READ;
					end if;
						
				when TS_READ =>
					-- Wait for end of conversion
					if DrpBusy = '0' then
						DrpEn <= '1';
						TempState <= TS_WAIT;
					end if;
					
				when TS_WAIT =>
					DrpEn <= '0';
					-- Wait for a bit until reading again
					-- Store data when DrpRdy asserted
					if LedToggle(20) = '0' then
						TempState <= TS_INIT;
					end if;
	
				when others =>
					null;
					
			end case;
			
			-- Record the temperature when it is ready after the read
			if DrpRdy = '1' then
				CurTemp <= DrpData;
			end if;
				
		end if;
	end process;

	XADC1 : XADC_TEMPERATURE
	PORT MAP
	(
		di_in         => x"0000",
		daddr_in      => "0000000", -- Temperature sensor
		den_in        => DrpEn,
		dwe_in        => '0',
		drdy_out      => DrpRdy,
		do_out        => DrpData,
		dclk_in       => CLK_100MHZ,
		reset_in      => GlobalReset,
		vp_in         => VP_IN,
		vn_in         => VN_IN,
		busy_out      => DrpBusy
	);

	-- All DGB(x) LEDs are active low
	-- DBG(0) Matching Ethernet Packet Toggle
	-- DBG(1) Non-Matching Ethernet Packet Toggle
	-- DBG(2) Ehernet Link Stauts, lit when link to SFP is active
	-- DBG(3) Lights during SFP link initialization and when External Trigger input is high
	-- DBG(4/DBG(5)) GRN = MIG Test Pass, RED = test fail, off = waiting for calibration to complete
	-- DBG(5) Turns off when MIG Calibration successfully completes
	-- DBG(6) PLL Lock for DAC Channel 0
	-- DBG(7) PLL Lock for DAC Channel 1
	 
	-- Pass STATUS to Debug LEDs
	DBG(2 downto 0) <= STATUS(2 downto 0);

	-- Combine Link LED with external Trigger inputs.  Link only active during initial syncing
	DBG(3) <= '0' when (STATUS(3) = '0'
	              or (TrigLocked = '1' and LedToggle(25) = '1'))  -- Slow blink if locked w/o errors, off if not locked
	           else '1';

	-- Black wire = pin 1 = RED cathode.  Red = pin 2 = GRN cathode.
	-- Assume Black to 6 and Red to 7.  Then 7H/6L = RED, 7L/6H = GRN

	-- Display Trigger test status.  Blink green if locked and running.  Blink red if it is locked and failing.  Off if not locked
	-- Host can enable individual channels for send to verify front panel connectivity
	-- Also red when SFP_ENH is low for testing red
	DBG(6) <= '0' when LedRed = '1' else '1' when (TrigLocked = '1' and LedToggle(25) = '0') else 'Z' when (TrigLocked = '0' or LedToggle(25) = '1') else '0';
	DBG(7) <= '1' when LedRed = '1' else '0' when (TrigLocked = '1' and LedToggle(25) = '0') else 'Z' when (TrigLocked = '0' or LedToggle(25) = '1') else '1';

	-- Black wire = pin 1 = RED cathode.  Red = pin 2 = GRN cathode.
	-- Assume Black to 4 and Red to 5.  Then 5H/4L = RED, 5L/4H = GRN
	-- Display Trigger input status
	-- Off = No trigger received
	-- Green blinks indicate which single trigger input is active
	DBG(4) <= '0' when LedRed = '1' else '1' when ChannelOn = '1' else 'Z';
	DBG(5) <= '1' when LedRed = '1' else '0' when ChannelOn = '1' else 'Z';

	-- Blink N+1 times when trigger N is high
	ChannelOn <= '1' when (LedToggle(27) = '1' and LedToggle(23 downto 22) = "11" and CMP = "00000001" and LedToggle(26 downto 24)  = "000")
	                 or (LedToggle(27) = '1' and LedToggle(23 downto 22) = "11" and CMP = "00000010" and LedToggle(26 downto 24) <= "001")
	                 or (LedToggle(27) = '1' and LedToggle(23 downto 22) = "11" and CMP = "00000100" and LedToggle(26 downto 24) <= "010")
	                 or (LedToggle(27) = '1' and LedToggle(23 downto 22) = "11" and CMP = "00001000" and LedToggle(26 downto 24) <= "011")
	                 or (LedToggle(27) = '1' and LedToggle(23 downto 22) = "11" and CMP = "00010000" and LedToggle(26 downto 24) <= "100")
	                 or (LedToggle(27) = '1' and LedToggle(23 downto 22) = "11" and CMP = "00100000" and LedToggle(26 downto 24) <= "101")
	                 or (LedToggle(27) = '1' and LedToggle(23 downto 22) = "11" and CMP = "01000000" and LedToggle(26 downto 24) <= "110")
	                 or (LedToggle(27) = '1' and LedToggle(23 downto 22) = "11" and CMP = "10000000")
	             else '0';

	sync_reflocked : entity work.synchronizer
	port map ( reset => not(FPGA_RESETL), clk => CLK_125MHZ, i_data => RefLocked, o_data => RefLocked_s );

	-- need to reset SYS_MMCM on rising or falling edge of RefLocked
	sys_mmcm_reset : process( mgt_locked, CLK_125MHZ )
	begin
		if mgt_locked = '0' then
			SysClkReset <= '1';
		elsif rising_edge(CLK_125MHZ) then
			RefLocked_d <= RefLocked_s;
			if (RefLocked_d xor RefLocked_s) = '1' then
				SysClkReset <= '1';
			else
				SysClkReset <= '0';
			end if;	
		end if;
	end process ; -- sys_mmcm_reset

	-- multiply reference clock up to 100 MHz
	CK1: REF_MMCM
	port map (
		CLK_REF => REF_FPGA,

		-- clock out ports
		CLK_100MHZ => REF_100MHZ,

		-- status and control signals
		RESET      => not FPGA_RESETL,
		LOCKED     => RefLocked
	);

	-- Create aligned 100 and 400 MHz clocks for SATA in/out logic.
	-- 200 MHz clock is used for delay calibration
	CK0 : SYS_MMCM
	port map
	(
		-- Clock in ports
		REF_100MHZ_IN  => REF_100MHZ,
		CLK_125MHZ_IN  => CLK_125MHZ,
		CLK_IN_SEL     => RefLocked, -- choose REF_100MHZ when HIGH
	
		-- Clock out ports
		CLK_100MHZ     => CLK_100MHZ,
		CLK_200MHZ     => CLK_200MHZ,
		CLK_400MHZ     => CLK_400MHZ,
	
		-- Status and control signals
		RESET          => SysClkReset,
		LOCKED         => SysLocked
	);


	GlobalReset <= not SysLocked;  -- Use lock status of the PLL driven by REF_100MHZ and reset by FPGA_RESETL as the global reset

	CK2 : CCLK_MMCM
	port map (
		CLK_100MHZ_IN => CFG_CCLK,
		CLK_100MHZ    => CFG_CLK,
		RESET         => not FPGA_RESETL,
		LOCKED        => CfgLocked
	);

	USER_STATUS(15 downto 0) <= CurTemp;

	-- All of the APS Host Logic is contained within this component
	AC1 : entity work.ApsControl
	port map
	(
		-- asynchronous reset
		RESET                => not(CfgLocked),

		-- Clocks
		CLK_200MHZ           => CLK_200MHZ,
		CLK_125MHZ           => CLK_125MHZ,
		mmcm_locked          => mgt_locked,

		-- MGTP Connections
		gtrefclk_p           => gtrefclk_p,
		gtrefclk_n           => gtrefclk_n,
		txp                  => txp,
		txn                  => txn,
		rxp                  => rxp,
		rxn                  => rxn,

		-- Config Bus Connections
		CFG_CLK        => CFG_CLK,
		CFGD           => CFGD,
		FPGA_CMDL      => FPGA_CMDL,
		FPGA_RDYL      => FPGA_RDYL,
		CFG_RDY        => CFG_RDY,
		CFG_ERR        => CFG_ERR,
		CFG_ACT        => CFG_ACT,
		STAT_OEL       => STAT_OEL,

		-- User Logic Connections
		USER_CLK       => CLK_100MHZ,
		USER_RST       => USER_RST,
		USER_VERSION   => USER_VERSION,
		USER_STATUS    => USER_STATUS,

		USER_DIF       => USER_DIF,
		USER_DIF_RD    => USER_DIF_RD,

		USER_CIF_EMPTY => USER_CIF_EMPTY,
		USER_CIF_RD    => USER_CIF_RD,
		USER_CIF_RW    => USER_CIF_RW,
		USER_CIF_MODE  => USER_CIF_MODE,
		USER_CIF_CNT   => USER_CIF_CNT,
		USER_CIF_ADDR  => USER_CIF_ADDR,

		USER_DOF       => USER_DOF,
		USER_DOF_WR    => USER_DOF_WR,

		USER_COF_STAT  => USER_COF_STAT,
		USER_COF_CNT   => USER_COF_CNT,
		USER_COF_AFULL => USER_COF_AFULL,
		USER_COF_WR    => USER_COF_WR,

		-- GPIO for status and control
		STATUS       => STATUS
	);

	myMemory : Memory
	port map (

	    reset => GlobalReset,
	    clk_axi => CLK_100MHZ,
	    clk_axi_locked => SysLocked,
	    AXI_resetn(0) => AXI_resetn,

		------------------------------------------------------------------
		-- CSR AXI
		CSR_araddr => CSR_araddr, 
		CSR_arprot => CSR_arprot, 
		CSR_arready => CSR_arready, 
		CSR_arvalid => CSR_arvalid, 
		CSR_awaddr => CSR_awaddr, 
		CSR_awprot => CSR_awprot, 
		CSR_awready => CSR_awready, 
		CSR_awvalid => CSR_awvalid, 
		CSR_bready => CSR_bready, 
		CSR_bresp => CSR_bresp, 
		CSR_bvalid => CSR_bvalid, 
		CSR_rdata => CSR_rdata, 
		CSR_rready => CSR_rready, 
		CSR_rresp => CSR_rresp, 
		CSR_rvalid => CSR_rvalid, 
		CSR_wdata => CSR_wdata, 
		CSR_wready => CSR_wready, 
		CSR_wstrb => CSR_wstrb, 
		CSR_wvalid => CSR_wvalid, 


		------------------------------------------------------------------
		--Ethernet DMA
		ethernet_mm2s_tdata  => ethernet_mm2s_tdata,
		ethernet_mm2s_tkeep  => ethernet_mm2s_tkeep,
		ethernet_mm2s_tlast  => ethernet_mm2s_tlast,
		ethernet_mm2s_tready => ethernet_mm2s_tready,
		ethernet_mm2s_tvalid => ethernet_mm2s_tvalid,
		ethernet_s2mm_tdata  => ethernet_s2mm_tdata,
		ethernet_s2mm_tkeep  => ethernet_s2mm_tkeep,
		ethernet_s2mm_tlast  => ethernet_s2mm_tlast,
		ethernet_s2mm_tvalid  => ethernet_s2mm_tvalid,
		ethernet_s2mm_tready => ethernet_s2mm_tready,
		ethernet_mm2s_sts_tdata => ethernet_mm2s_sts_tdata,
		ethernet_mm2s_sts_tkeep => ethernet_mm2s_sts_tkeep,
		ethernet_mm2s_sts_tlast => ethernet_mm2s_sts_tlast,
		ethernet_mm2s_sts_tready => ethernet_mm2s_sts_tready,
		ethernet_mm2s_sts_tvalid => ethernet_mm2s_sts_tvalid,
		ethernet_s2mm_sts_tdata => ethernet_s2mm_sts_tdata,
		ethernet_s2mm_sts_tkeep => ethernet_s2mm_sts_tkeep,
		ethernet_s2mm_sts_tlast => ethernet_s2mm_sts_tlast,
		ethernet_s2mm_sts_tready => ethernet_s2mm_sts_tready,
		ethernet_s2mm_sts_tvalid => ethernet_s2mm_sts_tvalid,
		ethernet_mm2s_cmd_tdata => ethernet_mm2s_cmd_tdata,
		ethernet_mm2s_cmd_tready => ethernet_mm2s_cmd_tready,
		ethernet_mm2s_cmd_tvalid => ethernet_mm2s_cmd_tvalid,
		ethernet_s2mm_cmd_tdata => ethernet_s2mm_cmd_tdata,
		ethernet_s2mm_cmd_tready => ethernet_s2mm_cmd_tready,
		ethernet_s2mm_cmd_tvalid => ethernet_s2mm_cmd_tvalid,
		ethernet_s2mm_err => ethernet_s2mm_err,
		ethernet_mm2s_err => ethernet_mm2s_err
	);

	-- Instantiate the APSMsgProc - AXI bridge
	AXIbridge_inst : entity work.AXIBridge
	port map (
		RST => GlobalReset,

		-- User Logic Connections
		USER_CLK  => CLK_100MHZ,                        -- Clock for User side of FIFO interface
		USER_RST => GlobalReset,

		USER_DIF => USER_DIF,  -- User Data Input FIFO output
		USER_DIF_RD => USER_DIF_RD,  -- User Data Onput FIFO Read Enable

		USER_CIF_EMPTY => USER_CIF_EMPTY,                    -- Low when there is data available
		USER_CIF_RD  => USER_CIF_RD,   -- Command Input FIFO Read Enable
		USER_CIF_RW    => USER_CIF_RW,                       -- High for read, low for write
		USER_CIF_MODE  => USER_CIF_MODE,   -- MODE field from current User I/O command
		USER_CIF_CNT   => USER_CIF_CNT,   -- CNT field from current User I/O command
		USER_CIF_ADDR  => USER_CIF_ADDR,   -- Address for the current command

		USER_DOF       => USER_DOF,  -- User Data Onput FIFO input
		USER_DOF_WR    => USER_DOF_WR,    -- User Data Onput FIFO Write Enable

		USER_COF_STAT  => USER_COF_STAT,  -- STAT value to return for current User I/O command
		USER_COF_CNT   => USER_COF_CNT,   -- Number of words written to DOF for current User I/O command
		USER_COF_AFULL => USER_COF_AFULL,  -- User Control Output FIFO Almost Full
		USER_COF_WR    => USER_COF_WR,     -- User Control Onput FIFO Write Enable

		MM2S_STS_tdata => ethernet_mm2s_sts_tdata,
		MM2S_STS_tkeep => ethernet_mm2s_sts_tkeep,
		MM2S_STS_tlast => ethernet_mm2s_sts_tlast,
		MM2S_STS_tready => ethernet_mm2s_sts_tready,
		MM2S_STS_tvalid => ethernet_mm2s_sts_tvalid,

		MM2S_tdata => ethernet_mm2s_tdata,
		MM2S_tkeep => ethernet_mm2s_tkeep,
		MM2S_tlast => ethernet_mm2s_tlast,
		MM2S_tready => ethernet_mm2s_tready,
		MM2S_tvalid => ethernet_mm2s_tvalid,

		S2MM_STS_tdata => ethernet_s2mm_sts_tdata,
		S2MM_STS_tkeep => ethernet_s2mm_sts_tkeep,
		S2MM_STS_tlast => ethernet_s2mm_sts_tlast,
		S2MM_STS_tready => ethernet_s2mm_sts_tready,
		S2MM_STS_tvalid => ethernet_s2mm_sts_tvalid,

		MM2S_CMD_tdata => ethernet_mm2s_cmd_tdata,
		MM2S_CMD_tready => ethernet_mm2s_cmd_tready,
		MM2S_CMD_tvalid => ethernet_mm2s_cmd_tvalid,

		S2MM_CMD_tdata => ethernet_s2mm_cmd_tdata,
		S2MM_CMD_tready => ethernet_s2mm_cmd_tready,
		S2MM_CMD_tvalid => ethernet_s2mm_cmd_tvalid,

		S2MM_tdata => ethernet_s2mm_tdata,
		S2MM_tkeep => ethernet_s2mm_tkeep,
		S2MM_tlast => ethernet_s2mm_tlast,
		S2MM_tready => ethernet_s2mm_tready,
		S2MM_tvalid => ethernet_s2mm_tvalid
	);

	-- CSR
	CSR : entity work.APS2_CSR
	port map (

		sys_clk => CLK_100MHZ,

		resets => resets,
		controls => open,
		trigger_word => latched_trig_word,
		trigger_interval => trigger_interval,
		trigger_control => trigger_control,
		dummy_status(31 downto 8) => x"1234567",
		dummy_status(7 downto 2) => (others => '0'),
		dummy_status(1) => CfgLocked,
		dummy_status(0) => RefLocked,

		S_AXI_ACLK => CLK_100MHZ,
		S_AXI_ARESETN => AXI_resetn,
		S_AXI_AWADDR => CSR_awaddr(7 downto 0),
		S_AXI_AWPROT => CSR_awprot,
		S_AXI_AWVALID => CSR_awvalid,
		S_AXI_AWREADY => CSR_awready,
		S_AXI_WDATA => CSR_wdata,
		S_AXI_WSTRB => CSR_wstrb,
		S_AXI_WVALID => CSR_wvalid,
		S_AXI_WREADY => CSR_wready,
		S_AXI_BRESP => CSR_bresp,
		S_AXI_BVALID => CSR_bvalid,
		S_AXI_BREADY => CSR_bready,
		S_AXI_ARADDR => CSR_araddr(7 downto 0),
		S_AXI_ARPROT => CSR_arprot,
		S_AXI_ARVALID => CSR_arvalid,
		S_AXI_ARREADY => CSR_arready,
		S_AXI_RDATA => CSR_rdata,
		S_AXI_RRESP => CSR_rresp,
		S_AXI_RVALID  => CSR_rvalid,
		S_AXI_RREADY  => CSR_rready
	);

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
	end generate;

	-- Send output status to LEDs for checking
	LED(4 downto 0) <= (others => 'Z');
	LED(7 downto 5) <=      "000" when CMP = "00000001"
	                   else "001" when CMP = "00000010" 
	                   else "010" when CMP = "00000100" 
	                   else "011" when CMP = "00001000" 
	                   else "100" when CMP = "00010000" 
	                   else "101" when CMP = "00100000" 
	                   else "110" when CMP = "01000000" 
	                   else "111" when CMP = "10000000" 
	                   else "000";

	LED(8) <=      LedToggle(25) when CMP = "00000001"
	          else LedToggle(25) when CMP = "00000010" 
	          else LedToggle(25) when CMP = "00000100" 
	          else LedToggle(25) when CMP = "00001000" 
	          else LedToggle(25) when CMP = "00010000" 
	          else LedToggle(25) when CMP = "00100000" 
	          else LedToggle(25) when CMP = "01000000" 
	          else LedToggle(25) when CMP = "10000000" 
	          else '0';


	LED(9) <= TrigClkErr or TrigOvflErr;

	-- basic logic to broadcast input triggers to all output triggers
	-- VALID on rising edge of CMP(7) or internal trigger
	-- sync external valid on CLK_100MHZ
	sync_valid : entity work.synchronizer
	port map ( reset => USER_RST, clk => CLK_100MHZ, i_data => CMP(7), o_data => ext_valid );

	-- DATA is CMP(6 downto 0) except when internal trigger fires, in which case we send 0xFE
	ext_valid_re <= ext_valid and not ext_valid_d;
	process(CLK_100MHZ, USER_RST)
	begin
		if rising_edge(CLK_100MHZ) then
			ext_valid_d <= ext_valid;
			if trigger = '1' then
				TrigOutDat <= (others => x"fe");
			else
				TrigOutDat <= (others => '0' & CMP(6 downto 0));
			end if;
			if USER_RST = '1' or or_reduce(TrigOutFull) = '1' then
				TrigWr <= (others => '0');
			else
				TrigWr <= (others => ext_valid_re or trigger);
			end if;
		end if;
	end process;

	process (CLK_100MHZ)
	begin
		if rising_edge(CLK_100MHZ) then
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
			USER_CLK   => CLK_100MHZ,
			
			-- These clocks are usually generated from an MMCM driven by the CFG_CCLK.
			CLK_100MHZ => CLK_100MHZ,
			CLK_400MHZ => CLK_400MHZ,
			RESET      => USER_RST,
		
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
		USER_CLK   => CLK_100MHZ,
		CLK_200MHZ => CLK_200MHZ,
		RESET      => USER_RST,
	
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

	-- 8 channels of PWM 
	PWM1 : for i in 0 to 7 generate
		PWMX : entity work.PWMA8
		port map
		(
			CLK => CLK_100MHZ,
			RESET => USER_RST,
			DIN => x"52",  -- Fix at 0.8V for now.  Eventually drive from a status register
			PWM_OUT => THR(i)
		);
	end generate;

	IntTrig : entity work.InternalTrig
	port map (
		RESET => resets(0),
		CLK => CLK_100MHZ,
		triggerInterval => trigger_interval,
		triggerSource => trigger_control(0),
		softTrigToggle => trigger_control(2),
		trigger => trigger
	);
 
end behavior;

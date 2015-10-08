library IEEE;
use IEEE.STD_LOGIC_1164.all;
-- use ieee.numeric_std.all;
use work.ATMConstants.all;

package AtmIPCores is

	ATTRIBUTE SYN_BLACK_BOX : BOOLEAN;
	ATTRIBUTE BLACK_BOX_PAD_PIN : STRING;

	component PWMA8
	port
	(
		CLK : in std_logic;
		RESET : in std_logic;
		DIN : in std_logic_vector (7 downto 0) := "00000000";
		PWM_OUT : out std_logic
	);
	end component;

	component SYS_MMCM
	port
	 (-- Clock in ports
	  REF_100MHZ_IN           : in     std_logic;
	  CLK_125MHZ_IN           : in     std_logic;
	  CLK_IN_SEL           : in     std_logic;
	  -- Clock out ports
	  CLK_100MHZ          : out    std_logic;
	  CLK_200MHZ          : out    std_logic;
	  CLK_400MHZ          : out    std_logic;
	  -- Status and control signals
	  RESET             : in     std_logic;
	  LOCKED            : out    std_logic
	 );
	end component;
	ATTRIBUTE SYN_BLACK_BOX OF SYS_MMCM : COMPONENT IS TRUE;
	ATTRIBUTE BLACK_BOX_PAD_PIN OF SYS_MMCM : COMPONENT IS "REF_100MHZ_IN,CLK_125MHZ_IN,CLK_IN_SEL,CLK_100MHZ,CLK_200MHZ,CLK_400MHZ,RESET,LOCKED";

	component TRIG_MMCM
	port
	(
		-- Clock in ports
		CLK_100MHZ_IN     : in     std_logic;

		-- Clock out ports
		TRIG_100MHZ       : out    std_logic;
		TRIG_400MHZ       : out    std_logic;

		-- Status and control signals
		RESET             : in     std_logic;
		LOCKED            : out    std_logic
	);
	end component;
	ATTRIBUTE SYN_BLACK_BOX OF TRIG_MMCM : COMPONENT IS TRUE;
	ATTRIBUTE BLACK_BOX_PAD_PIN OF TRIG_MMCM : COMPONENT IS "CLK_100MHZ_IN,TRIG_100MHZ,TRIG_400MHZ,RESET,LOCKED";

	component REF_MMCM
	port
	 (-- Clock in ports
	  CLK_REF           : in     std_logic;
	  -- Clock out ports
	  CLK_100MHZ          : out    std_logic;
	  -- Status and control signals
	  reset             : in     std_logic;
	  locked            : out    std_logic
	 );
	end component;
	ATTRIBUTE SYN_BLACK_BOX OF REF_MMCM : COMPONENT IS TRUE;
	ATTRIBUTE BLACK_BOX_PAD_PIN OF REF_MMCM : COMPONENT IS "CLK_REF,CLK_100MHZ,reset,locked";

	component CCLK_MMCM
	port
	(
		-- Clock in ports
		CLK_100MHZ_IN     : in     std_logic;

		-- Clock out ports
		CLK_100MHZ       : out    std_logic;

		-- Status and control signals
		RESET             : in     std_logic;
		LOCKED            : out    std_logic
	);
	end component;
	ATTRIBUTE SYN_BLACK_BOX OF CCLK_MMCM : COMPONENT IS TRUE;
	ATTRIBUTE BLACK_BOX_PAD_PIN OF CCLK_MMCM : COMPONENT IS "CLK_100MHZ_IN,CLK_100MHZ,RESET,LOCKED";

	component TIO_FIFO
	port (
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
	end component;
	ATTRIBUTE SYN_BLACK_BOX OF TIO_FIFO : COMPONENT IS TRUE;
	ATTRIBUTE BLACK_BOX_PAD_PIN OF TIO_FIFO : COMPONENT IS "rst,wr_clk,rd_clk,din[7:0],wr_en,rd_en,dout[7:0],full,empty,prog_full";

	component SEROUT8
	port (
		data_out_to_pins_p : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
		data_out_to_pins_n : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);

		clk_in : IN STD_LOGIC;
		clk_div_in : IN STD_LOGIC;

		data_out_from_device : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		io_reset : IN STD_LOGIC
	);
	end component;
	ATTRIBUTE SYN_BLACK_BOX OF SEROUT8 : COMPONENT IS TRUE;
	ATTRIBUTE BLACK_BOX_PAD_PIN OF SEROUT8 : COMPONENT IS "data_out_to_pins_p[0:0],data_out_to_pins_n[0:0],clk_in,clk_div_in,data_out_from_device[7:0],io_reset";
	
	COMPONENT SFP_GIGE
    PORT (
		gtrefclk_p : IN STD_LOGIC;
		gtrefclk_n : IN STD_LOGIC;
		gtrefclk_out : OUT STD_LOGIC;
		txn : OUT STD_LOGIC;
		txp : OUT STD_LOGIC;
		rxn : IN STD_LOGIC;
		rxp : IN STD_LOGIC;
		independent_clock_bufg : IN STD_LOGIC;
		userclk_out : OUT STD_LOGIC;
		userclk2_out : OUT STD_LOGIC;
		rxuserclk_out : OUT STD_LOGIC;
		rxuserclk2_out : OUT STD_LOGIC;
		resetdone : OUT STD_LOGIC;
		pma_reset_out : OUT STD_LOGIC;
		mmcm_locked_out : OUT STD_LOGIC;
		gmii_txd : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		gmii_tx_en : IN STD_LOGIC;
		gmii_tx_er : IN STD_LOGIC;
		gmii_rxd : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		gmii_rx_dv : OUT STD_LOGIC;
		gmii_rx_er : OUT STD_LOGIC;
		gmii_isolate : OUT STD_LOGIC;
		configuration_vector : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
		an_interrupt : OUT STD_LOGIC;
		an_adv_config_vector : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		an_restart_config : IN STD_LOGIC;
		status_vector : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		reset : IN STD_LOGIC;
		signal_detect : IN STD_LOGIC;
		gt0_pll0outclk_out : OUT STD_LOGIC;
		gt0_pll0outrefclk_out : OUT STD_LOGIC;
		gt0_pll1outclk_out : OUT STD_LOGIC;
		gt0_pll1outrefclk_out : OUT STD_LOGIC;
		gt0_pll0lock_out : OUT STD_LOGIC;
		gt0_pll0refclklost_out : OUT STD_LOGIC
    );
	END COMPONENT;
	ATTRIBUTE SYN_BLACK_BOX OF SFP_GIGE : COMPONENT IS TRUE;
	ATTRIBUTE BLACK_BOX_PAD_PIN OF SFP_GIGE : COMPONENT IS "gtrefclk_p,gtrefclk_n,gtrefclk_out,txn,txp,rxn,rxp,independent_clock_bufg,userclk_out,userclk2_out,rxuserclk_out,rxuserclk2_out,resetdone,pma_reset_out,mmcm_locked_out,gmii_txd[7:0],gmii_tx_en,gmii_tx_er,gmii_rxd[7:0],gmii_rx_dv,gmii_rx_er,gmii_isolate,configuration_vector[4:0],an_interrupt,an_adv_config_vector[15:0],an_restart_config,status_vector[15:0],reset,signal_detect,gt0_pll0outclk_out,gt0_pll0outrefclk_out,gt0_pll1outclk_out,gt0_pll1outrefclk_out,gt0_pll0lock_out,gt0_pll0refclklost_out";


	COMPONENT GIGE_MAC
    PORT (
		gtx_clk : IN STD_LOGIC;
		glbl_rstn : IN STD_LOGIC;
		rx_axi_rstn : IN STD_LOGIC;
		tx_axi_rstn : IN STD_LOGIC;
		rx_statistics_vector : OUT STD_LOGIC_VECTOR(27 DOWNTO 0);
		rx_statistics_valid : OUT STD_LOGIC;
		rx_mac_aclk : OUT STD_LOGIC;
		rx_reset : OUT STD_LOGIC;
		rx_axis_mac_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		rx_axis_mac_tvalid : OUT STD_LOGIC;
		rx_axis_mac_tlast : OUT STD_LOGIC;
		rx_axis_mac_tuser : OUT STD_LOGIC;
		tx_ifg_delay : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		tx_statistics_vector : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		tx_statistics_valid : OUT STD_LOGIC;
		tx_mac_aclk : OUT STD_LOGIC;
		tx_reset : OUT STD_LOGIC;
		tx_axis_mac_tdata : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		tx_axis_mac_tvalid : IN STD_LOGIC;
		tx_axis_mac_tlast : IN STD_LOGIC;
		tx_axis_mac_tuser : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
		tx_axis_mac_tready : OUT STD_LOGIC;
		pause_req : IN STD_LOGIC;
		pause_val : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		speedis100 : OUT STD_LOGIC;
		speedis10100 : OUT STD_LOGIC;
		gmii_txd : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		gmii_tx_en : OUT STD_LOGIC;
		gmii_tx_er : OUT STD_LOGIC;
		gmii_rxd : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		gmii_rx_dv : IN STD_LOGIC;
		gmii_rx_er : IN STD_LOGIC;
		rx_configuration_vector : IN STD_LOGIC_VECTOR(79 DOWNTO 0);
		tx_configuration_vector : IN STD_LOGIC_VECTOR(79 DOWNTO 0)
	);
	END COMPONENT;
	ATTRIBUTE SYN_BLACK_BOX OF GIGE_MAC : COMPONENT IS TRUE;
	ATTRIBUTE BLACK_BOX_PAD_PIN OF GIGE_MAC : COMPONENT IS "gtx_clk,glbl_rstn,rx_axi_rstn,tx_axi_rstn,rx_statistics_vector[27:0],rx_statistics_valid,rx_mac_aclk,rx_reset,rx_axis_mac_tdata[7:0],rx_axis_mac_tvalid,rx_axis_mac_tlast,rx_axis_mac_tuser,tx_ifg_delay[7:0],tx_statistics_vector[31:0],tx_statistics_valid,tx_mac_aclk,tx_reset,tx_axis_mac_tdata[7:0],tx_axis_mac_tvalid,tx_axis_mac_tlast,tx_axis_mac_tuser[0:0],tx_axis_mac_tready,pause_req,pause_val[15:0],speedis100,speedis10100,gmii_txd[7:0],gmii_tx_en,gmii_tx_er,gmii_rxd[7:0],gmii_rx_dv,gmii_rx_er,rx_configuration_vector[79:0],tx_configuration_vector[79:0]";

	--buffer to recieve outgoing packets so we can get their size
	COMPONENT UDPOutputBufferFIFO
	  PORT (
	    s_aclk : IN std_logic;
	    s_aresetn : IN std_logic;
	    s_axis_tvalid : IN std_logic;
	    s_axis_tready : OUT std_logic;
	    s_axis_tdata : IN std_logic_vector(7 DOWNTO 0);
	    s_axis_tlast : IN std_logic;
	    m_axis_tvalid : OUT std_logic;
	    m_axis_tready : IN std_logic;
	    m_axis_tdata : OUT std_logic_vector(7 DOWNTO 0);
	    m_axis_tlast : OUT std_logic;
	    axis_data_count : OUT std_logic_vector(11 DOWNTO 0)
	  );
	end COMPONENT;
	ATTRIBUTE SYN_BLACK_BOX OF UDPOutputBufferFIFO : COMPONENT IS TRUE;
	ATTRIBUTE BLACK_BOX_PAD_PIN OF UDPOutputBufferFIFO : COMPONENT IS "s_aclk,s_aresetn,s_axis_tvalid,s_axis_tready,s_axis_tdata[7:0],s_axis_tlast,m_axis_tvalid,m_axis_tready,m_axis_tdata[7:0],m_axis_tlast,axis_data_count[11:0]";

	COMPONENT UDPOutputBufferFIFO2
	  PORT (
	    s_aclk : IN std_logic;
	    s_aresetn : IN std_logic;
	    s_axis_tvalid : IN std_logic;
	    s_axis_tready : OUT std_logic;
	    s_axis_tdata : IN std_logic_vector(7 DOWNTO 0);
	    s_axis_tlast : IN std_logic;
	    m_axis_tvalid : OUT std_logic;
	    m_axis_tready : IN std_logic;
	    m_axis_tdata : OUT std_logic_vector(7 DOWNTO 0);
	    m_axis_tlast : OUT STD_LOGIC
	  );
	end COMPONENT;
	ATTRIBUTE SYN_BLACK_BOX OF UDPOutputBufferFIFO2 : COMPONENT IS TRUE;
	ATTRIBUTE BLACK_BOX_PAD_PIN OF UDPOutputBufferFIFO2 : COMPONENT IS "s_aclk,s_aresetn,s_axis_tvalid,s_axis_tready,s_axis_tdata[7:0],s_axis_tlast,m_axis_tvalid,m_axis_tready,m_axis_tdata[7:0],m_axis_tlast";

	COMPONENT XADC_TEMPERATURE
	PORT (
		di_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		daddr_in : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
		den_in : IN STD_LOGIC;
		dwe_in : IN STD_LOGIC;
		drdy_out : OUT STD_LOGIC;
		do_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		dclk_in : IN STD_LOGIC;
		reset_in : IN STD_LOGIC;
		vp_in : IN STD_LOGIC;
		vn_in : IN STD_LOGIC;
		channel_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
		eoc_out : OUT STD_LOGIC;
		alarm_out : OUT STD_LOGIC;
		eos_out : OUT STD_LOGIC;
		busy_out : OUT STD_LOGIC
	);
	END COMPONENT;
	ATTRIBUTE SYN_BLACK_BOX OF XADC_TEMPERATURE : COMPONENT IS TRUE;
	ATTRIBUTE BLACK_BOX_PAD_PIN OF XADC_TEMPERATURE : COMPONENT IS "di_in[15:0],daddr_in[6:0],den_in,dwe_in,drdy_out,do_out[15:0],dclk_in,reset_in,vp_in,vn_in,channel_out[4:0],eoc_out,alarm_out,eos_out,busy_out";

	component ApsMsgProc
	port
	(
		-- Interface to MAC to get Ethernet packets
		MAC_CLK       : in std_logic;                             -- Clock for command FIFO interface
		RESET         : in std_logic;                             -- Reset for Command Interface

		MAC_RXD       : in std_logic_vector(7 downto 0);  -- Data read from input FIFO
		MAC_RX_VALID  : in std_logic;                     -- Set when input fifo empty
		MAC_RX_EOP    : in std_logic;                     -- Marks the end of a receive packet in Ethernet RX FIFO
		MAC_BAD_FCS   : in std_logic;                     -- Set during EOP/VALID received packet had CRC error

		MAC_TXD       : out std_logic_vector(7 downto 0); -- Data to write to output FIFO
		MAC_TX_RDY    : in std_logic;                     -- Set when MAC can accept data
		MAC_TX_VALID  : out std_logic;                    -- Set to write the Ethernet TX FIFO
		MAC_TX_EOP    : out std_logic;                    -- Marks the end of a transmit packet to the Ethernet TX FIFO

		-- Non-volatile Data
		NV_DATA       : out std_logic_vector(63 downto 0);  -- NV Data from Multicast Address Words
		MAC_ADDRESS   : out std_logic_vector(47 downto 0);  -- MAC Address from EPROM

		-- Board Type
		BOARD_TYPE    : in std_logic_vector(7 downto 0) := x"01";    -- Board type returned in D<31:24> of Host firmware version, default to ATM.  0x01 = Trigger

		-- User Logic Connections
		USER_CLK       : in std_logic;                      -- Clock for User side of FIFO interface
		USER_RST       : out std_logic;                     -- User Logic global reset, synchronous to USER_CLK
		USER_VERSION   : in std_logic_vector(31 downto 0);  -- User Logic Firmware Version.  Passed back in status packets
		USER_STATUS    : in std_logic_vector(31 downto 0);  -- User Status Word.  Passed back in status packets

		USER_DIF       : out std_logic_vector(31 downto 0); -- User Data Input FIFO output
		USER_DIF_RD    : in std_logic;                      -- User Data Onput FIFO Read Enable

		USER_CIF_EMPTY : out std_logic;                     -- Low when there is data available
		USER_CIF_RD    : in std_logic;                      -- Command Input FIFO Read Enable
		USER_CIF_RW    : out std_logic;                     -- High for read, low for write
		USER_CIF_MODE  : out std_logic_vector(7 downto 0);  -- MODE field from current User I/O command
		USER_CIF_CNT   : out std_logic_vector(15 downto 0); -- CNT field from current User I/O command
		USER_CIF_ADDR  : out std_logic_vector(31 downto 0); -- Address for the current command

		USER_DOF       : in std_logic_vector(31 downto 0);  -- User Data Onput FIFO input
		USER_DOF_WR    : in std_logic;                      -- User Data Onput FIFO Write Enable

		USER_COF_STAT  : in std_logic_vector(7 downto 0);   -- STAT value to return for current User I/O command
		USER_COF_CNT   : in std_logic_vector(15 downto 0);  -- Number of words written to DOF for current User I/O command
		USER_COF_AFULL : out std_logic;                     -- User Control Output FIFO Almost Full
		USER_COF_WR    : in std_logic;                       -- User Control Onput FIFO Write Enable

		-- Config CPLD Data Bus for reading status when STAT_OE is asserted
		CFG_CLK    : in  STD_LOGIC;  -- 100 MHZ clock from the Config CPLD
		CFGD       : inout std_logic_vector(15 downto 0);  -- Config Data bus from CPLD
		FPGA_CMDL  : out  STD_LOGIC;  -- Command strobe from FPGA
		FPGA_RDYL  : out  STD_LOGIC;  -- Ready Strobe from FPGA
		CFG_RDY    : in  STD_LOGIC;  -- Ready to complete current transfer
		CFG_ERR    : in  STD_LOGIC;  -- Error during current command
		CFG_ACT    : in  STD_LOGIC;  -- Current transaction is complete
		STAT_OEL   : out std_logic; -- Enable CPLD to drive status onto CFGD

		-- Status to top level
		GOOD_TOGGLE   : out std_logic;
		BAD_TOGGLE    : out std_logic
		);
	end component;

	component Memory is
	port (
		AXI_resetn : out STD_LOGIC_VECTOR ( 0 to 0 );
		clk_axi : in STD_LOGIC;
		clk_axi_locked : in STD_LOGIC;
		ethernet_mm2s_err : out STD_LOGIC;
		ethernet_s2mm_err : out STD_LOGIC;
		reset : in STD_LOGIC;
		ethernet_mm2s_tdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
		ethernet_mm2s_tkeep : out STD_LOGIC_VECTOR ( 3 downto 0 );
		ethernet_mm2s_tlast : out STD_LOGIC;
		ethernet_mm2s_tready : in STD_LOGIC;
		ethernet_mm2s_tvalid : out STD_LOGIC;
		ethernet_mm2s_sts_tdata : out STD_LOGIC_VECTOR ( 7 downto 0 );
		ethernet_mm2s_sts_tkeep : out STD_LOGIC_VECTOR ( 0 to 0 );
		ethernet_mm2s_sts_tlast : out STD_LOGIC;
		ethernet_mm2s_sts_tready : in STD_LOGIC;
		ethernet_mm2s_sts_tvalid : out STD_LOGIC;
		ethernet_s2mm_sts_tdata : out STD_LOGIC_VECTOR ( 7 downto 0 );
		ethernet_s2mm_sts_tkeep : out STD_LOGIC_VECTOR ( 0 to 0 );
		ethernet_s2mm_sts_tlast : out STD_LOGIC;
		ethernet_s2mm_sts_tready : in STD_LOGIC;
		ethernet_s2mm_sts_tvalid : out STD_LOGIC;
		ethernet_mm2s_cmd_tdata : in STD_LOGIC_VECTOR ( 71 downto 0 );
		ethernet_mm2s_cmd_tready : out STD_LOGIC;
		ethernet_mm2s_cmd_tvalid : in STD_LOGIC;
		ethernet_s2mm_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
		ethernet_s2mm_tkeep : in STD_LOGIC_VECTOR ( 3 downto 0 );
		ethernet_s2mm_tlast : in STD_LOGIC;
		ethernet_s2mm_tready : out STD_LOGIC;
		ethernet_s2mm_tvalid : in STD_LOGIC;
		ethernet_s2mm_cmd_tdata : in STD_LOGIC_VECTOR ( 71 downto 0 );
		ethernet_s2mm_cmd_tready : out STD_LOGIC;
		ethernet_s2mm_cmd_tvalid : in STD_LOGIC;
		CSR_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
		CSR_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
		CSR_awvalid : out STD_LOGIC;
		CSR_awready : in STD_LOGIC;
		CSR_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
		CSR_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
		CSR_wvalid : out STD_LOGIC;
		CSR_wready : in STD_LOGIC;
		CSR_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
		CSR_bvalid : in STD_LOGIC;
		CSR_bready : out STD_LOGIC;
		CSR_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
		CSR_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
		CSR_arvalid : out STD_LOGIC;
		CSR_arready : in STD_LOGIC;
		CSR_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
		CSR_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
		CSR_rvalid : in STD_LOGIC;
		CSR_rready : out STD_LOGIC
	);
	end component Memory;

end AtmIPCores;

package body AtmIPCores is

end AtmIPCores;
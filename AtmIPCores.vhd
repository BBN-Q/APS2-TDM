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

	component CCLK_MMCM
	port
	(
		CLK_100MHZ_IN  : in     std_logic;

		-- Clock out ports
		CLK_100MHZ     : out    std_logic;
		CLK_200MHZ     : out    std_logic;
		CLK_400MHZ     : out    std_logic;

		-- Status and control signals
		RESET          : in     std_logic;
		LOCKED         : out    std_logic
	);
	end component;
	ATTRIBUTE SYN_BLACK_BOX OF CCLK_MMCM : COMPONENT IS TRUE;
	ATTRIBUTE BLACK_BOX_PAD_PIN OF CCLK_MMCM : COMPONENT IS "CLK_100MHZ_IN,CLK_100MHz,CLK_200MHz,CLK_400MHz,reset,locked";

	component TEST_MMCM
	port
	(
		CLK_100MHZ_IN  : in     std_logic;

		-- Clock out ports
		CLK_100MHZ     : out    std_logic;
		CLK_125MHZ     : out    std_logic;

		-- Status and control signals
		RESET          : in     std_logic;
		LOCKED         : out    std_logic
	);
	end component;

	component TRIG_FIFO
	port
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
	end component;
	ATTRIBUTE SYN_BLACK_BOX OF TRIG_FIFO : COMPONENT IS TRUE;
	ATTRIBUTE BLACK_BOX_PAD_PIN OF TRIG_FIFO : COMPONENT IS "rst,wr_clk,rd_clk,din[7:0],wr_en,rd_en,dout[7:0],full,empty,prog_full";

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

	COMPONENT XADC_Temperature
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
	ATTRIBUTE SYN_BLACK_BOX OF XADC_Temperature : COMPONENT IS TRUE;
	ATTRIBUTE BLACK_BOX_PAD_PIN OF XADC_Temperature : COMPONENT IS "di_in[15:0],daddr_in[6:0],den_in,dwe_in,drdy_out,do_out[15:0],dclk_in,reset_in,vp_in,vn_in,channel_out[4:0],eoc_out,alarm_out,eos_out,busy_out";



end AtmIPCores;

package body AtmIPCores is

end AtmIPCores;
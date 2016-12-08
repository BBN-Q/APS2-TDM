-- ApsControl.vhd
--
-- This instantiates the Xilinx MAC and PCS/PMA logic and connects it to the Host Logic
--
--
-- REVISIONS
--
-- 7/9/2013  CRJ
--   Created
--
-- 8/13/2013 CRJ
--   Initial release
--
-- 1/8/2014 CRJ
--   Changed to active low LEDs
--
-- 1/30/2014 CRJ
--   Added debug record
--
-- END REVISIONS
--

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.AtmIPCores.all;

entity ApsControl is
port
(
  -- asynchronous reset
  RESET          : in  std_logic;

  -- Clocks
  CLK_200MHZ     : in   std_logic;  -- Free Running Control Clock.  Required for MGTP initialization
  CLK_125MHZ     : out  std_logic;  -- 125 MHz MGTP synchronous clock available for user code
  mmcm_locked    : out  std_logic;  -- SFP PCS/PCM core locked to 125MHz reference

  -- MGTP Connections
  gtrefclk_p     : in std_logic;    -- 125 MHz reference
  gtrefclk_n     : in std_logic;
  txp            : out std_logic;   -- TX out to SFP
  txn            : out std_logic;
  rxp            : in std_logic;    -- RX in from SPF
  rxn            : in std_logic;

  -- Config Bus Connections
  CFG_CLK        : in  STD_LOGIC;  -- 100 MHZ clock from the Config CPLD
  CFGD           : inout std_logic_vector(15 downto 0);  -- Config Data bus from CPLD
  FPGA_CMDL      : out  STD_LOGIC;  -- Command strobe from FPGA
  FPGA_RDYL      : out  STD_LOGIC;  -- Ready Strobe from FPGA
  CFG_RDY        : in  STD_LOGIC;  -- Ready to complete current transfer
  CFG_ERR        : in  STD_LOGIC;  -- Error during current command
  CFG_ACT        : in  STD_LOGIC;  -- Current transaction is complete
  STAT_OEL       : out std_logic; -- Enable CPLD to drive status onto CFGD

  -- User Logic Connections
  USER_CLK       : in std_logic;                      -- Clock for User side of FIFO interface
  USER_RST       : out std_logic;                     -- User Logic global reset, synchronous to USER_CLK
  USER_VERSION   : in std_logic_vector(31 downto 0);  -- User Logic Firmware Version.  Passed back in status packets
  USER_STATUS    : in std_logic_vector(31 downto 0);  -- User Status Word.  Passed back in status packets

  USER_CIF_EMPTY : out std_logic;                     -- Low when there is data available
  USER_DIF       : out std_logic_vector(31 downto 0); -- User Data Input FIFO output
  USER_DIF_RD    : in std_logic;                      -- User Data Onput FIFO Read Enable

  USER_CIF_RD    : in std_logic;                      -- Command Input FIFO Read Enable
  USER_CIF_RW    : out std_logic;                     -- High for read, low for write
  USER_CIF_MODE  : out std_logic_vector(7 downto 0);  -- MODE field from current User I/O command
  USER_CIF_CNT   : out std_logic_vector(15 downto 0); -- CNT field from current User I/O command
  USER_CIF_ADDR  : out std_logic_vector(31 downto 0);   -- Address for the current command

  USER_DOF       : in std_logic_vector(31 downto 0);  -- User Data Onput FIFO input
  USER_DOF_WR    : in std_logic;                      -- User Data Onput FIFO Write Enable

  USER_COF_STAT  : in std_logic_vector(7 downto 0);   -- STAT value to return for current User I/O command
  USER_COF_CNT   : in std_logic_vector(15 downto 0);  -- Number of words written to DOF for current User I/O command
  USER_COF_AFULL : out std_logic;                     -- User Control Output FIFO Almost Full
  USER_COF_WR    : in std_logic;                      -- User Control Onput FIFO Write Enable

  STATUS         : out std_logic_vector(4 downto 0)
);
end ApsControl;

architecture behavior of ApsControl is

signal msg_rst : std_logic;

-- RX MAC Configuration Vector
signal rx_configuration_vector : std_logic_vector(79 downto 0)
       := x"0605040302DA" -- RX Pause Addr
        & x"0000"         -- Max Frame Length (zero since Max Frame is disabled)
        & '0'             -- Resv
        & '0'             -- RX Max Frame Enable
        & "10"            -- MAC Receive Speed = 1Gb
        & '1'             -- Promiscous Mode Enable
        & '0'             -- Resv
        & '0'             -- Control Frame Length Check Disable
        & '0'             -- Length/Check Check Disable
        & '0'             -- Resv
        & '0'             -- Half Duplex Enable
        & '1'             -- Inhibit Transmitter when flow control frame received
        & '0'             -- Jumbo Frame Enable
        & '0'             -- FCS In Band Enable
        & '0'             -- VLAN Receive Enable
        & '1'             -- RX Enable
        & '0';            -- RX Reset

-- TX MAC Configuration Vector
signal tx_configuration_vector : std_logic_vector(79 downto 0)
       := x"0605040302DA" -- TX Pause Addr
        & x"0000"         -- TX Max Frame Length (zero since Max Frame is disabled)
        & '0'             -- Resv
        & '0'             -- TX Max Frame Enable
        & "10"            -- MAC Transmit Speed = 1Gb
        & '0'             -- Resv
        & '0'             -- Resv
        & '0'             -- Resv
        & '0'             -- TX Interframe Gap Adjust Enable
        & '0'             -- Resv
        & '0'             -- Half Duplex Enable
        & '1'             -- Enable sending Pause Frames when Pause asserted
        & '0'             -- Jumbo Frame Enable
        & '0'             -- FCS In Band Enable
        & '0'             -- VLAN Frame Transmit Enable
        & '1'             -- TX Enable
        & '0';            -- TX Reset

-- clock generation signals for tranceiver
signal gtrefclk              : std_logic;                    -- Route gtrefclk through an IBUFG.
signal resetdone             : std_logic;                    -- To indicate that the GT transceiver has completed its reset cycle
signal mmcm_reset            : std_logic;                    -- MMCM reset signal.
signal clkfbout              : std_logic;                    -- MMCM feedback clock
signal clkout0               : std_logic;                    -- MMCM clock0 output (62.5MHz).
signal clkout1               : std_logic;                    -- MMCM clock1 output (125MHz).
signal userclk               : std_logic;                    -- 62.5MHz clock for GT transceiver Tx/Rx user clocks
signal userclk2              : std_logic;                    -- 125MHz clock for core reference clock.

-- GMII signals
signal gmii_isolate          : std_logic;                    -- Internal gmii_isolate signal.
signal gmii_txd_int          : std_logic_vector(7 downto 0); -- Internal gmii_txd signal.
signal gmii_tx_en_int        : std_logic;                    -- Internal gmii_tx_en signal.
signal gmii_tx_er_int        : std_logic;                    -- Internal gmii_tx_er signal.
signal gmii_rxd_int          : std_logic_vector(7 downto 0); -- Internal gmii_rxd signal.
signal gmii_rx_dv_int        : std_logic;                    -- Internal gmii_rx_dv signal.
signal gmii_rx_er_int        : std_logic;                    -- Internal gmii_rx_er signal.

-- Extra registers to ease IOB placement
signal status_vector_int : std_logic_vector(15 downto 0);

signal configuration_vector : std_logic_vector(4 downto 0) := "10000";  -- Enable Auto Negotiation See table 12-37 of UG155.
signal an_interrupt         : std_logic;                    -- Interrupt to processor to signal that Auto-Negotiation has completed
signal an_adv_config_vector : std_logic_vector(15 downto 0) := x"0020"; -- Alternate interface to program REG4 (AN ADV)
signal an_restart_config    : std_logic := '0';                     -- Alternate signal to modify AN restart bit in REG0
signal link_timer_value     : std_logic_vector(8 downto 0) := "100000000";  -- Programmable Auto-Negotiation Link Timer Control

--Fake MAC signals for injected UDP interface
signal MAC_RXD_trimac       : std_logic_vector(7 downto 0) := (others => '0');
signal MAC_RX_VALID_trimac  : std_logic := '0';
signal MAC_RX_EOP_trimac    : std_logic := '0';
signal MAC_BAD_FCS_trimac   : std_logic := '0';

signal MAC_TXD_trimac       : std_logic_vector(7 downto 0) := (others => '0');
signal MAC_TX_RDY_trimac    : std_logic := '0';
signal MAC_TX_VALID_trimac  : std_logic := '0';
signal MAC_TX_EOP_trimac    : std_logic := '0';

signal MAC_RXD_msgproc : std_logic_vector(7 downto 0) := (others => '0');
signal MAC_RX_VALID_msgproc  : std_logic := '0';
signal MAC_RX_EOP_msgproc    : std_logic := '0';
signal MAC_BAD_FCS_msgproc   : std_logic := '0';

signal MAC_TXD_msgproc : std_logic_vector(7 downto 0) := (others => '0');
signal MAC_TX_RDY_msgproc : std_logic := '0';
signal MAC_TX_VALID_msgproc : std_logic := '0';
signal MAC_TX_EOP_msgproc : std_logic := '0';


 ------------------------------------------------------------------------------
 -- internal signals used in this top level wrapper.
 ------------------------------------------------------------------------------

-- example design clocks
signal gtx_clk_bufg                       : std_logic;
signal rx_mac_aclk                        : std_logic;
signal tx_mac_aclk                        : std_logic;

-- RX Statistics serialisation signals
signal rx_statistics_valid                : std_logic;
signal rx_statistics_valid_reg            : std_logic;
signal rx_statistics_vector               : std_logic_vector(27 downto 0);

-- TX Statistics serialisation signals
signal tx_statistics_valid                : std_logic;
signal tx_statistics_valid_reg            : std_logic;
signal tx_statistics_vector               : std_logic_vector(31 downto 0);

-- MAC receiver client I/F
signal rx_axis_mac_tdata    : std_logic_vector(7 downto 0);
signal rx_axis_mac_tvalid   : std_logic;
signal rx_axis_mac_tlast    : std_logic;
signal rx_axis_mac_tuser    : std_logic;

-- MAC transmitter client I/F
signal tx_axis_mac_tdata    : std_logic_vector(7 downto 0);
signal tx_axis_mac_tvalid   : std_logic;
signal tx_axis_mac_tready   : std_logic;
signal tx_axis_mac_tlast    : std_logic;
signal tx_axis_mac_tuser    : std_logic_vector(0 downto 0);

signal GoodToggle : std_logic;
signal BadToggle : std_logic;

signal NV_DATA : std_logic_vector(63 downto 0);
signal ip_addr : std_logic_vector(31 downto 0) := x"c0a80102"; -- 192.168.1.2 default address
signal mac_addr : std_logic_vector(47 downto 0) := x"4651DB112233"; -- BBN OUI is 44-51-DB -> 46-51-DB for locally administered

begin

  -- Send 125 MHz GTP clock up for user code to potentialy use
  CLK_125MHZ <= userclk2;

  -- Status signals
  STATUS(0) <= GoodToggle;
  STATUS(1) <= BadToggle;
  STATUS(2) <= status_vector_int(0);  -- High when link is established
  STATUS(3) <= (MAC_RX_VALID_trimac or MAC_TX_VALID_trimac);
  STATUS(4) <= (MAC_RX_VALID_msgproc or MAC_TX_VALID_msgproc);

  ip_addr <= NV_DATA(63 downto 32);
  -- ip_addr <= x"c0a80505";

  -----------------------------------------------------------------------------
  -- Transceiver PMA reset circuitry
  -----------------------------------------------------------------------------

  -- GIGE PCS/PMA attached to the AC701 SFP Port
  core_wrapper : SFP_GIGE
  port map
  (
    gtrefclk_p          => gtrefclk_p,
    gtrefclk_n          => gtrefclk_n,
    txp                  => txp,
    txn                  => txn,
    rxp                  => rxp,
    rxn                  => rxn,
    independent_clock_bufg => CLK_200MHZ,
    userclk_out          => userclk,
    userclk2_out         => userclk2,
    mmcm_locked_out      => mmcm_locked,

    -- Connect to the GMII on the MAC
    gmii_txd             => gmii_txd_int,
    gmii_tx_en           => gmii_tx_en_int,
    gmii_tx_er           => gmii_tx_er_int,
    gmii_rxd             => gmii_rxd_int,
    gmii_rx_dv           => gmii_rx_dv_int,
    gmii_rx_er           => gmii_rx_er_int,
    gmii_isolate         => gmii_isolate,

    configuration_vector => configuration_vector,
    an_interrupt         => an_interrupt,
    an_adv_config_vector => an_adv_config_vector,
    an_restart_config    => an_restart_config,
    status_vector        => status_vector_int,
    reset                => RESET,
    signal_detect        => '1'  -- SFP SERDES port is always active
  );

  ------------------------------------------------------------------------------
  -- Instantiate the Tri-Mode EMAC Block wrapper
  ------------------------------------------------------------------------------
  trimac_block : GIGE_MAC
  port map
  (
    gtx_clk               => userclk2,

    -- asynchronous reset
    glbl_rstn             => "not"(RESET),
    rx_axi_rstn           => '1',  -- separate RX reset
    tx_axi_rstn           => '1',  -- separate TX reset

    -- Client Receiver Interface
    rx_statistics_vector  => open ,
    rx_statistics_valid   => open ,
    tx_statistics_vector  => open ,
    tx_statistics_valid   => open ,

    -- AXI Stream Receive Data from MAC
    rx_mac_aclk           => open ,  -- driven by gtx_clk internal to the logic
    rx_reset              => open,  -- Output
    rx_axis_mac_tdata     => MAC_RXD_trimac,
    rx_axis_mac_tvalid    => MAC_RX_VALID_trimac,
    rx_axis_mac_tlast     => MAC_RX_EOP_trimac,
    rx_axis_mac_tuser     => MAC_BAD_FCS_trimac,  -- Carries FCS status

    -- AXI Stream Transmit Data into MAC
    tx_mac_aclk           => open ,  -- driven by gtx_clk internal to the logic
    tx_reset              => open,  -- Output
    tx_axis_mac_tdata     => MAC_TXD_trimac ,
    tx_axis_mac_tvalid    => MAC_TX_VALID_trimac,
    tx_axis_mac_tlast     => MAC_TX_EOP_trimac,
    tx_axis_mac_tuser     => "0",  -- User to force an error in the packet
    tx_axis_mac_tready    => MAC_TX_RDY_trimac,

    -- Programmable Interframe gap.  Disabled by config vector
    tx_ifg_delay          => x"00",

    -- Flow Control
    pause_req             => '0' ,
    pause_val             => x"0000" ,

    speedis100            => open ,
    speedis10100          => open ,

    -- GMII Interface
    gmii_txd              => gmii_txd_int,
    gmii_tx_en            => gmii_tx_en_int,
    gmii_tx_er            => gmii_tx_er_int,
    gmii_rxd              => gmii_rxd_int,
    gmii_rx_dv            => gmii_rx_dv_int,
    gmii_rx_er            => gmii_rx_er_int,

    -- Hard Coded Configuration Vector
    rx_configuration_vector  => rx_configuration_vector,
    tx_configuration_vector  => tx_configuration_vector
  );


--Instantiate UDP interface
  udp: entity work.UDP_Interface
  port map (
    MAC_CLK => userclk2,
    RST =>RESET,
    --real MAC signals to/from the TRIMAC
    MAC_RXD_trimac => MAC_RXD_trimac,
    MAC_RX_VALID_trimac => MAC_RX_VALID_trimac,
    MAC_RX_EOP_trimac => MAC_RX_EOP_trimac,
    MAC_BAD_FCS_trimac => MAC_BAD_FCS_trimac,
    MAC_TXD_trimac => MAC_TXD_trimac,
    MAC_TX_RDY_trimac => MAC_TX_RDY_trimac,
    MAC_TX_VALID_trimac => MAC_TX_VALID_trimac,
    MAC_TX_EOP_trimac => MAC_TX_EOP_trimac,

  --fake MAC signals to/from the APSMsgProc
    MAC_RXD_msgproc => MAC_RXD_msgproc,
    MAC_RX_VALID_msgproc => MAC_RX_VALID_msgproc,
    MAC_RX_EOP_msgproc => MAC_RX_EOP_msgproc,
    MAC_BAD_FCS_msgproc => MAC_BAD_FCS_msgproc,
    MAC_TXD_msgproc => MAC_TXD_msgproc,
    MAC_TX_RDY_msgproc => MAC_TX_RDY_msgproc,
    MAC_TX_VALID_msgproc => MAC_TX_VALID_msgproc,
    MAC_TX_EOP_msgproc => MAC_TX_EOP_msgproc,

    --MAC and IP address
    mac_addr => mac_addr,
    ip_addr => ip_addr
  );

  -- This encapsulates all of the packet and message processing
  AMP1 : ApsMsgProc
  port map
  (
  -- Interface to MAC to get Ethernet packets
    MAC_CLK       => userclk2,
    RESET         => RESET,

    MAC_RXD       => MAC_RXD_msgproc,
    MAC_RX_VALID  => MAC_RX_VALID_msgproc,
    MAC_RX_EOP    => MAC_RX_EOP_msgproc,
    MAC_BAD_FCS   => MAC_BAD_FCS_msgproc,

    MAC_TXD       => MAC_TXD_msgproc,
    MAC_TX_RDY    => MAC_TX_RDY_msgproc,
    MAC_TX_VALID  => MAC_TX_VALID_msgproc,
    MAC_TX_EOP    => MAC_TX_EOP_msgproc,

    NV_DATA       => NV_DATA,
    MAC_ADDRESS   => mac_addr,

    -- User Logic Connections
    USER_CLK       => USER_CLK,
    USER_RST       => msg_rst,
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

    -- Config Bus Connections
    CFG_CLK        => CFG_CLK,
    CFGD           => CFGD,
    FPGA_CMDL      => FPGA_CMDL,
    FPGA_RDYL      => FPGA_RDYL,
    CFG_RDY        => CFG_RDY,
    CFG_ERR        => CFG_ERR,
    CFG_ACT        => CFG_ACT,
    STAT_OEL       => STAT_OEL,

    -- Status to top level
    GOOD_TOGGLE   => GoodToggle,
    BAD_TOGGLE    => BadToggle
  );

-- msg processor doesn't properly synchronize USER_RST to USER_CLK domain
sync_user_rst : entity work.synchronizer
port map ( reset => RESET, clk => USER_CLK, i_data => msg_rst, o_data => USER_RST);

end behavior;

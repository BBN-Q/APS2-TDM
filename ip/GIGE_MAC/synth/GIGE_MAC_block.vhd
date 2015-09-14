--------------------------------------------------------------------------------
-- File       : GIGE_MAC_block.vhd
-- Author     : Xilinx Inc.
-- -----------------------------------------------------------------------------
-- (c) Copyright 2004-2013 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES. 
-- -----------------------------------------------------------------------------
-- Description: This is the block level VHDL design for the Tri-Mode
--              Ethernet MAC Example Design.
--
--              This block level:
--
--              * instantiates appropriate PHY interface module (GMII/MII/RGMII)
--                as required based on the user configuration;
--
--              Please refer to the Datasheet, Getting Started Guide, and
--              the Tri-Mode Ethernet MAC User Gude for further information.
--
--
--              -----------------------------------------|
--              | BLOCK LEVEL WRAPPER                    |
--              |                                        |
--              |    ---------------------               |
--              |    | ETHERNET MAC      |               |
--              |    | CORE              |               |
--              |    |                   |               |
--            --|--->| Tx            Tx  |-------------->|
--              |    | AXI           PHY |               |
--              |    | I/F           I/F |               |
--              |    |                   |               |
--              |    |                   |               |
--              |    |                   |               |
--              |    | Rx            Rx  |               |
--              |    | AXI           PHY |               |
--            <-|----| I/F           I/F |<--------------|
--              |    |                   |               |
--              |    ---------------------               |
--              |                                        |
--              -----------------------------------------|
--


library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;

library tri_mode_ethernet_mac_v8_3;
use tri_mode_ethernet_mac_v8_3.all;


--------------------------------------------------------------------------------
-- The entity declaration for the block level example design.
--------------------------------------------------------------------------------

entity GIGE_MAC_block is
   port(
      gtx_clk                    : in  std_logic;
      -- asynchronous reset
      glbl_rstn                  : in  std_logic;
      rx_axi_rstn                : in  std_logic;
      tx_axi_rstn                : in  std_logic;

      -- Receiver Interface
      ----------------------------
      rx_statistics_vector       : out std_logic_vector(27 downto 0);
      rx_statistics_valid        : out std_logic;

      rx_mac_aclk                : out std_logic;
      rx_reset                   : out std_logic;
      rx_axis_mac_tdata          : out std_logic_vector(7 downto 0);
      rx_axis_mac_tvalid         : out std_logic;
      rx_axis_mac_tlast          : out std_logic;
      rx_axis_mac_tuser          : out std_logic;

      -- Transmitter Interface
      -------------------------------

      tx_ifg_delay               : in  std_logic_vector(7 downto 0);
      tx_statistics_vector       : out std_logic_vector(31 downto 0);
      tx_statistics_valid        : out std_logic;

      tx_mac_aclk                : out std_logic;
      tx_reset                   : out std_logic;
      tx_axis_mac_tdata          : in  std_logic_vector(7 downto 0);
      tx_axis_mac_tvalid         : in  std_logic;
      tx_axis_mac_tlast          : in  std_logic;
      tx_axis_mac_tuser          : in  std_logic_vector(0 downto 0);
      tx_axis_mac_tready         : out std_logic;

      -- MAC Control Interface
      ------------------------
      pause_req                  : in  std_logic;
      pause_val                  : in  std_logic_vector(15 downto 0);

      -- Speed Interface
      -----------------
      speedis100                 : out std_logic;
      speedis10100               : out std_logic;

      -- GMII Interface
      -----------------
      gmii_txd                   : out std_logic_vector(7 downto 0);
      gmii_tx_en                 : out std_logic;
      gmii_tx_er                 : out std_logic;
      gmii_rxd                   : in  std_logic_vector(7 downto 0);
      gmii_rx_dv                 : in  std_logic;
      gmii_rx_er                 : in  std_logic;

      -- Configuration Vector
      -----------------------
      rx_configuration_vector    : in  std_logic_vector(79 downto 0);
      tx_configuration_vector    : in  std_logic_vector(79 downto 0)
   );
end GIGE_MAC_block;


architecture wrapper of GIGE_MAC_block is


   -----------------------------------------------------------------------------
   -- Component Declaration for TEMAC (the Tri-Mode EMAC core).
   -----------------------------------------------------------------------------
   component tri_mode_ethernet_mac_v8_3
    generic (
      C_S_AXI_ADDR_WIDTH          : integer := 12;
      C_PHYSICAL_INTERFACE        : string  := "INTERNAL";
      C_HALF_DUPLEX               : integer := 0;
      C_HAS_HOST                  : integer := 0;
      C_ADD_FILTER                : integer := 1;
      C_AT_ENTRIES                : integer := 0;
      C_FAMILY                    : string  := "artix7";
      C_MAC_SPEED                 : string  := "SPEED_1000_MBPS";
      C_HAS_STATS                 : integer := 0;
      C_NUM_STATS                 : integer := 34;
      C_CNTR_RST                  : integer := 1;
      C_STATS_WIDTH               : integer := 64;
      C_AVB                       : integer := 0;
      C_RX_VEC_WIDTH              : integer := 79;
      C_TX_VEC_WIDTH              : integer := 79;
      C_1588                      : integer := 0;
      C_PFC                       : integer := 0;
      C_HAS_MDIO                  : integer := 0
    );
    port(
      glbl_rstn                   : in  std_logic;
      rx_axi_rstn                 : in  std_logic;
      tx_axi_rstn                 : in  std_logic;

      -- 1588 Timer input
      ----------------------------
      systemtimer_s_field         : in  std_logic_vector(47 downto 0);
      systemtimer_ns_field        : in  std_logic_vector(31 downto 0);
      correction_timer            : in  std_logic_vector(63 downto 0);

      -- Receiver Interface
      ----------------------------
      rx_axi_clk                  : in  std_logic;
      rx_reset_out                : out std_logic;
      rx_axis_mac_tdata           : out std_logic_vector(7 downto 0);
      rx_axis_mac_tvalid          : out std_logic;
      rx_axis_mac_tlast           : out std_logic;
      rx_axis_mac_tuser           : out std_logic;

      rx_enable                   : in  std_logic;
      rx_axis_filter_tuser        : out std_logic_vector(0 downto 0);
      rx_statistics_vector        : out std_logic_vector(31 downto 0);
      rx_statistics_valid         : out std_logic;

      rx_ts_axis_tvalid           : out std_logic;
      rx_ts_axis_tdata            : out std_logic_vector(127 downto 0);
      rxphy_s_field               : in  std_logic_vector(47 downto 0);
      rxphy_ns_field              : in  std_logic_vector(31 downto 0);
      rxphy_correction_timer      : in  std_logic_vector(63 downto 0);

      -- Transmitter Interface
      -------------------------------
      tx_axi_clk                  : in  std_logic;
      tx_reset_out                : out std_logic;
      tx_axis_mac_tdata           : in  std_logic_vector(7 downto 0);
      tx_axis_mac_tvalid          : in  std_logic;
      tx_axis_mac_tlast           : in  std_logic;
      tx_axis_mac_tuser           : in  std_logic_vector(127 downto 0);
      tx_axis_mac_tready          : out std_logic;

      tx_retransmit               : out std_logic;
      tx_collision                : out std_logic;
      tx_ifg_delay                : in  std_logic_vector(7 downto 0);
      tx_enable                   : in  std_logic;
      tx_statistics_vector        : out std_logic_vector(39 downto 0);
      tx_statistics_valid         : out std_logic;

      tx_ts_axis_tvalid           : out std_logic;
      tx_ts_axis_tdata            : out std_logic_vector(127 downto 0);

      --  Statistics Interface
      --------------------------------
      stats_ref_clk               : in  std_logic;
      increment_vector            : in  std_logic_vector(4 to 33);

      -- AVB AV interface
      -------------------------------
      tx_axis_av_tdata            : in  std_logic_vector(7 downto 0);
      tx_axis_av_tvalid           : in  std_logic;
      tx_axis_av_tlast            : in  std_logic;
      tx_axis_av_tuser            : in  std_logic;
      tx_axis_av_tready           : out std_logic;

      rx_axis_av_tdata            : out std_logic_vector(7 downto 0);
      rx_axis_av_tvalid           : out std_logic;
      rx_axis_av_tlast            : out std_logic;
      rx_axis_av_tuser            : out std_logic;

      -- AVB RTC Interface
      --------------------------------
      rtc_nanosec_field           : out std_logic_vector(31 downto 0);
      rtc_sec_field               : out std_logic_vector(47 downto 0);

      clk8k                       : out std_logic;

      rtc_clk                     : in  std_logic;

      rtc_nanosec_field_1722      : out std_logic_vector(31 downto 0);

      interrupt_ptp_timer         : out std_logic;
      interrupt_ptp_rx            : out std_logic;
      interrupt_ptp_tx            : out std_logic;

      -- MAC Control Interface
      ------------------------
      pause_req                   : in  std_logic;
      pause_val                   : in  std_logic_vector(15 downto 0);
      tx_pfc_p0_tvalid            : in  std_logic;
      tx_pfc_p1_tvalid            : in  std_logic;
      tx_pfc_p2_tvalid            : in  std_logic;
      tx_pfc_p3_tvalid            : in  std_logic;
      tx_pfc_p4_tvalid            : in  std_logic;
      tx_pfc_p5_tvalid            : in  std_logic;
      tx_pfc_p6_tvalid            : in  std_logic;
      tx_pfc_p7_tvalid            : in  std_logic;
      rx_pfc_p0_tvalid            : out std_logic;
      rx_pfc_p1_tvalid            : out std_logic;
      rx_pfc_p2_tvalid            : out std_logic;
      rx_pfc_p3_tvalid            : out std_logic;
      rx_pfc_p4_tvalid            : out std_logic;
      rx_pfc_p5_tvalid            : out std_logic;
      rx_pfc_p6_tvalid            : out std_logic;
      rx_pfc_p7_tvalid            : out std_logic;
      rx_pfc_p0_tready            : in  std_logic;
      rx_pfc_p1_tready            : in  std_logic;
      rx_pfc_p2_tready            : in  std_logic;
      rx_pfc_p3_tready            : in  std_logic;
      rx_pfc_p4_tready            : in  std_logic;
      rx_pfc_p5_tready            : in  std_logic;
      rx_pfc_p6_tready            : in  std_logic;
      rx_pfc_p7_tready            : in  std_logic;

      -- Current Speed Indication
      ---------------------------
      speed_is_100                : out std_logic;
      speed_is_10_100             : out std_logic;

      -- Physical Interface of the core
      --------------------------------
      gmii_tx_clken               : in  std_logic;
      gmii_txd                    : out std_logic_vector(7 downto 0);
      gmii_tx_en                  : out std_logic;
      gmii_tx_er                  : out std_logic;
      gmii_col                    : in  std_logic;
      gmii_crs                    : in  std_logic;
      gmii_rxd                    : in  std_logic_vector(7 downto 0);
      gmii_rx_dv                  : in  std_logic;
      gmii_rx_er                  : in  std_logic;

      -- MDIO Interface
      -----------------
      mdc_out                     : out std_logic;
      mdio_in                     : in  std_logic;
      mdio_out                    : out std_logic;
      mdio_tri                    : out std_logic;

      -- IPIC Interface
      -----------------
      bus2ip_clk                  : in  std_logic;
      bus2ip_reset                : in  std_logic;
      bus2ip_addr                 : in  std_logic_vector(11 downto 0);
      bus2ip_cs                   : in  std_logic;
      bus2ip_rdce                 : in  std_logic;
      bus2ip_wrce                 : in  std_logic;
      bus2ip_data                 : in  std_logic_vector(31 downto 0);
      ip2bus_data                 : out std_logic_vector(31 downto 0);
      ip2bus_wrack                : out std_logic;
      ip2bus_rdack                : out std_logic;
      ip2bus_error                : out std_logic;

      mac_irq                     : out std_logic;

      -- Configuration Vector
      -----------------------
      rx_mac_config_vector        : in  std_logic_vector(79 downto 0);
      tx_mac_config_vector        : in  std_logic_vector(79 downto 0)
   );
   end component;


  ------------------------------------------------------------------------------
  -- Component declaration for the synchronisation flip-flop pair
  ------------------------------------------------------------------------------
  component GIGE_MAC_block_sync_block
  port (
    clk                    : in  std_logic;    -- clock to be sync'ed to
    data_in                : in  std_logic;    -- Data to be 'synced'
    data_out               : out std_logic     -- synced data
    );
  end component;


  ------------------------------------------------------------------------------
  -- Component declaration for the reset synchroniser
  ------------------------------------------------------------------------------
  component GIGE_MAC_block_reset_sync
  port (
    reset_in               : in  std_logic;    -- Active high asynchronous reset
    enable                 : in  std_logic;
    clk                    : in  std_logic;    -- clock to be sync'ed to
    reset_out              : out std_logic     -- "Synchronised" reset signal
    );
  end component;

  ------------------------------------------------------------------------------
  -- internal signals used in this block level wrapper.
  ------------------------------------------------------------------------------

  signal gmii_tx_en_int           : std_logic;                     -- Internal gmii_tx_en signal.
  signal gmii_tx_er_int           : std_logic;                     -- Internal gmii_tx_er signal.
  signal gmii_txd_int             : std_logic_vector(7 downto 0);  -- Internal gmii_txd signal.
  signal gmii_rx_dv_int           : std_logic;                     -- gmii_rx_dv registered in IOBs.
  signal gmii_rx_er_int           : std_logic;                     -- gmii_rx_er registered in IOBs.
  signal gmii_rxd_int             : std_logic_vector(7 downto 0);  -- gmii_rxd registered in IOBs.
  signal speedis100_int           : std_logic;                     -- Asserted when speed is 100Mb/s.
  signal speedis10100_int         : std_logic;                     -- Asserted when speed is 10Mb/s or 100Mb/s.
  signal rx_mac_aclk_int          : std_logic;                     -- Internal receive gmii/mii clock signal.
  signal tx_mac_aclk_int          : std_logic;                     -- Internal transmit gmii/mii clock signal.
  signal tx_reset_int             : std_logic;                     -- Synchronous reset in the MAC and rgmii Tx domain
  signal rx_reset_int             : std_logic;                     -- Synchronous reset in the MAC and rgmii Rx domain
  signal rx_statistics_vector_int : std_logic_vector(31 downto 0);
  signal rx_statistics_valid_int  : std_logic;
  signal tx_statistics_vector_int : std_logic_vector(39 downto 0);
  signal tx_statistics_valid_int  : std_logic;
  signal tx_axis_mac_tuser_int    : std_logic_vector(127 downto 0) := (others => '0');

begin


   -----------------------------------------------------------------------------
   -- Assign internal to external connections
   -----------------------------------------------------------------------------

   -- assign the internal reset signals to output ports
   rx_reset <= rx_reset_int;
   tx_reset <= tx_reset_int;

   rx_mac_aclk <= rx_mac_aclk_int;
   tx_mac_aclk <= tx_mac_aclk_int;

   -- Other signal assignments
   speedis100   <= speedis100_int;
   speedis10100 <= speedis10100_int;
   tx_axis_mac_tuser_int(127 downto 1) <= (others => '0');
   tx_axis_mac_tuser_int(0)            <= tx_axis_mac_tuser(0);

   rx_mac_aclk_int <= gtx_clk after 1 ps;
   tx_mac_aclk_int <= gtx_clk after 1 ps;


   rx_statistics_vector <= rx_statistics_vector_int(27 downto 0);
   rx_statistics_valid  <= rx_statistics_valid_int;
   tx_statistics_vector <= tx_statistics_vector_int(31 downto 0);
   tx_statistics_valid  <= tx_statistics_valid_int;

   -----------------------------------------------------------------------------
   -- Assign the signals of the internal GMII
   -----------------------------------------------------------------------------
   gmii_tx_en           <= gmii_tx_en_int;
   gmii_tx_er           <= gmii_tx_er_int;
   gmii_txd             <= gmii_txd_int;
   gmii_rx_dv_int       <= gmii_rx_dv;
   gmii_rx_er_int       <= gmii_rx_er;
   gmii_rxd_int         <= gmii_rxd;


   -----------------------------------------------------------------------------
   -- Instantiate the TEMAC  encrypted HDL
   -- DO NOT MODIFY this instantiation
   -----------------------------------------------------------------------------
   GIGE_MAC_core : tri_mode_ethernet_mac_v8_3
   generic map (
      C_S_AXI_ADDR_WIDTH      => 12,
      C_PHYSICAL_INTERFACE    => "INTERNAL",
      C_HALF_DUPLEX           => 0,
      C_HAS_HOST              => 0,
      C_ADD_FILTER            => 1,
      C_AT_ENTRIES            => 0,
      C_FAMILY                => "artix7",
      C_MAC_SPEED             => "SPEED_1000_MBPS",
      C_HAS_STATS             => 0,
      C_NUM_STATS             => 34,
      C_CNTR_RST              => 1,
      C_STATS_WIDTH           => 64,
      C_AVB                   => 0,
      C_RX_VEC_WIDTH          => 79,
      C_TX_VEC_WIDTH          => 79,
      C_1588                  => 0,
      C_PFC                   => 0,
      C_HAS_MDIO              => 0
   )
   port map (

      -- asynchronous reset
      glbl_rstn               => glbl_rstn,
      rx_axi_rstn             => rx_axi_rstn,
      tx_axi_rstn             => tx_axi_rstn,

      systemtimer_s_field     => (others => '0'),
      systemtimer_ns_field    => (others => '0'),
      correction_timer        => (others => '0'),

      -- Receiver Interface
      rx_axi_clk              => rx_mac_aclk_int,
      rx_reset_out            => rx_reset_int,
      rx_axis_mac_tdata       => rx_axis_mac_tdata,
      rx_axis_mac_tvalid      => rx_axis_mac_tvalid,
      rx_axis_mac_tlast       => rx_axis_mac_tlast,
      rx_axis_mac_tuser       => rx_axis_mac_tuser,
      rx_enable               => '1',
      -- Receiver Statistics
      rx_statistics_vector    => rx_statistics_vector_int,
      rx_statistics_valid     => rx_statistics_valid_int,

      rx_axis_filter_tuser    => open,
      -- 1588 Rx timestamping (unused)
      rx_ts_axis_tvalid       => open,
      rx_ts_axis_tdata        => open,
      rxphy_s_field           => (others => '0'),
      rxphy_ns_field          => (others => '0'),
      rxphy_correction_timer  => (others => '0'),

      -- Transmitter Interface
      tx_axi_clk              => tx_mac_aclk_int,
      tx_reset_out            => tx_reset_int,
      tx_axis_mac_tdata       => tx_axis_mac_tdata,
      tx_axis_mac_tvalid      => tx_axis_mac_tvalid,
      tx_axis_mac_tlast       => tx_axis_mac_tlast,
      tx_axis_mac_tuser       => tx_axis_mac_tuser_int,
      tx_axis_mac_tready      => tx_axis_mac_tready,

      tx_collision            => open,
      tx_retransmit           => open,
      tx_ifg_delay            => tx_ifg_delay,
      tx_enable               => '1',

      -- Transmitter Statistics
      tx_statistics_vector    => tx_statistics_vector_int,
      tx_statistics_valid     => tx_statistics_valid_int,
      tx_ts_axis_tvalid       => open,
      tx_ts_axis_tdata        => open,

      -- AVB Interface (unused)
      tx_axis_av_tdata        => (others => '0'),
      tx_axis_av_tvalid       => '0',
      tx_axis_av_tlast        => '0',
      tx_axis_av_tuser        => '0',
      tx_axis_av_tready       => open,
      rx_axis_av_tdata        => open,
      rx_axis_av_tvalid       => open,
      rx_axis_av_tlast        => open,
      rx_axis_av_tuser        => open,
      rtc_clk                 => '0',
      rtc_nanosec_field       => open,
      rtc_sec_field           => open,
      clk8k                   => open,
      rtc_nanosec_field_1722  => open,
      interrupt_ptp_timer     => open,
      interrupt_ptp_rx        => open,
      interrupt_ptp_tx        => open,

      -- Statistics Interface (unused)
      stats_ref_clk           => '0',
      increment_vector        => (others => '0'),
      -- MAC Control Interface
      pause_req               => pause_req,
      pause_val               => pause_val,
      tx_pfc_p0_tvalid        => '0',
      tx_pfc_p1_tvalid        => '0',
      tx_pfc_p2_tvalid        => '0',
      tx_pfc_p3_tvalid        => '0',
      tx_pfc_p4_tvalid        => '0',
      tx_pfc_p5_tvalid        => '0',
      tx_pfc_p6_tvalid        => '0',
      tx_pfc_p7_tvalid        => '0',
      rx_pfc_p0_tvalid        => open,
      rx_pfc_p1_tvalid        => open,
      rx_pfc_p2_tvalid        => open,
      rx_pfc_p3_tvalid        => open,
      rx_pfc_p4_tvalid        => open,
      rx_pfc_p5_tvalid        => open,
      rx_pfc_p6_tvalid        => open,
      rx_pfc_p7_tvalid        => open,
      rx_pfc_p0_tready        => '0',
      rx_pfc_p1_tready        => '0',
      rx_pfc_p2_tready        => '0',
      rx_pfc_p3_tready        => '0',
      rx_pfc_p4_tready        => '0',
      rx_pfc_p5_tready        => '0',
      rx_pfc_p6_tready        => '0',
      rx_pfc_p7_tready        => '0',


      -- Current Speed Indication
      speed_is_100            => speedis100_int,
      speed_is_10_100         => speedis10100_int,

      -- Physical Interface of the core
      gmii_tx_clken           => '1',
      gmii_txd                => gmii_txd_int,
      gmii_tx_en              => gmii_tx_en_int,
      gmii_tx_er              => gmii_tx_er_int,
      gmii_crs                => '0',
      gmii_col                => '0',
      gmii_rxd                => gmii_rxd_int,
      gmii_rx_dv              => gmii_rx_dv_int,
      gmii_rx_er              => gmii_rx_er_int,

      -- MDIO Interface (unused)
      mdc_out                 => open,
      mdio_in                 => '0',
      mdio_out                => open,
      mdio_tri                => open,
      -- IPIC Interface (unused)
      bus2ip_clk              => '0',
      bus2ip_reset            => '0',
      bus2ip_addr             => (others => '0'),
      bus2ip_cs               => '0',
      bus2ip_rdce             => '0',
      bus2ip_wrce             => '0',
      bus2ip_data             => (others => '0'),
      ip2bus_data             => open,
      ip2bus_wrack            => open,
      ip2bus_rdack            => open,
      ip2bus_error            => open,

      mac_irq                 => open,
      -- Configuration Vectors
      rx_mac_config_vector    => rx_configuration_vector,
      tx_mac_config_vector    => tx_configuration_vector


      );


end wrapper;

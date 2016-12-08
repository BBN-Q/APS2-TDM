// Copyright 1986-2014 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2014.4 (lin64) Build 1071353 Tue Nov 18 16:47:07 MST 2014
// Date        : Fri May 15 09:26:11 2015
// Host        : cryan-Latitude-E6420 running 64-bit Linux Mint 17.1 Rebecca
// Command     : write_verilog -force -mode synth_stub
//               /home/cryan/Programming/FPGA/GIGE_MAC_2014.4/GIGE_MAC_2014.4.srcs/sources_1/ip/GIGE_MAC/GIGE_MAC_stub.v
// Design      : GIGE_MAC
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tfbg676-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "tri_mode_ethernet_mac_v8_3,Vivado 2014.4" *)
module GIGE_MAC(gtx_clk, glbl_rstn, rx_axi_rstn, tx_axi_rstn, rx_statistics_vector, rx_statistics_valid, rx_mac_aclk, rx_reset, rx_axis_mac_tdata, rx_axis_mac_tvalid, rx_axis_mac_tlast, rx_axis_mac_tuser, tx_ifg_delay, tx_statistics_vector, tx_statistics_valid, tx_mac_aclk, tx_reset, tx_axis_mac_tdata, tx_axis_mac_tvalid, tx_axis_mac_tlast, tx_axis_mac_tuser, tx_axis_mac_tready, pause_req, pause_val, speedis100, speedis10100, gmii_txd, gmii_tx_en, gmii_tx_er, gmii_rxd, gmii_rx_dv, gmii_rx_er, rx_configuration_vector, tx_configuration_vector)
/* synthesis syn_black_box black_box_pad_pin="gtx_clk,glbl_rstn,rx_axi_rstn,tx_axi_rstn,rx_statistics_vector[27:0],rx_statistics_valid,rx_mac_aclk,rx_reset,rx_axis_mac_tdata[7:0],rx_axis_mac_tvalid,rx_axis_mac_tlast,rx_axis_mac_tuser,tx_ifg_delay[7:0],tx_statistics_vector[31:0],tx_statistics_valid,tx_mac_aclk,tx_reset,tx_axis_mac_tdata[7:0],tx_axis_mac_tvalid,tx_axis_mac_tlast,tx_axis_mac_tuser[0:0],tx_axis_mac_tready,pause_req,pause_val[15:0],speedis100,speedis10100,gmii_txd[7:0],gmii_tx_en,gmii_tx_er,gmii_rxd[7:0],gmii_rx_dv,gmii_rx_er,rx_configuration_vector[79:0],tx_configuration_vector[79:0]" */;
  input gtx_clk;
  input glbl_rstn;
  input rx_axi_rstn;
  input tx_axi_rstn;
  output [27:0]rx_statistics_vector;
  output rx_statistics_valid;
  output rx_mac_aclk;
  output rx_reset;
  output [7:0]rx_axis_mac_tdata;
  output rx_axis_mac_tvalid;
  output rx_axis_mac_tlast;
  output rx_axis_mac_tuser;
  input [7:0]tx_ifg_delay;
  output [31:0]tx_statistics_vector;
  output tx_statistics_valid;
  output tx_mac_aclk;
  output tx_reset;
  input [7:0]tx_axis_mac_tdata;
  input tx_axis_mac_tvalid;
  input tx_axis_mac_tlast;
  input [0:0]tx_axis_mac_tuser;
  output tx_axis_mac_tready;
  input pause_req;
  input [15:0]pause_val;
  output speedis100;
  output speedis10100;
  output [7:0]gmii_txd;
  output gmii_tx_en;
  output gmii_tx_er;
  input [7:0]gmii_rxd;
  input gmii_rx_dv;
  input gmii_rx_er;
  input [79:0]rx_configuration_vector;
  input [79:0]tx_configuration_vector;
endmodule

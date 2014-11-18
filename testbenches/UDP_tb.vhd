-- Test bench for read/writes via UDP ethernet frames

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.EthernetFrame.all;
use work.IPv4Header.all;

entity UDP_tb is
generic (
    SIM_SEQ_FILE : string := "";
    APS_REPO_PATH : string := ""
);
end UDP_tb;

architecture Behavioral of UDP_tb is

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


--Clocks and resets
constant USER_CLK_PERIOD : time := 10 ns;
constant MAC_CLK_PERIOD : time := 8 ns;
constant SYS_CLK_PERIOD : time := 3.33333333333333333 ns;
constant CFG_CLK_PERIOD : time := 10.1 ns;

signal SYS_CLK       : std_logic := '0';                     
signal USER_CLK       : std_logic := '0';                     
signal CFG_CLK       : std_logic := '0';                     
signal MAC_CLK 		 : std_logic := '0';

signal USER_RST       : std_logic := '0';                    
signal RESET         : std_logic := '0';

--Interposing MAC signals between the Xilinx trimac and the APSMsgProc
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

--APSMsgProc user signals
signal USER_STATUS    : std_logic_vector(31 downto 0) := (others => '0'); 

signal USER_DIF       : std_logic_vector(31 downto 0) := (others => '0');
signal USER_DIF_RD    : std_logic := '0';                     

signal USER_CIF_EMPTY : std_logic := '0';                    
signal USER_CIF_RD    : std_logic := '0';                     
signal USER_CIF_RW    : std_logic := '0';                    
signal USER_CIF_MODE  : std_logic_vector(7 downto 0)  := (others => '0'); 
signal USER_CIF_CNT   : std_logic_vector(15 downto 0) := (others => '0');
signal USER_CIF_ADDR  : std_logic_vector(31 downto 0) := (others => '0');

signal USER_DOF       : std_logic_vector(31 downto 0) := (others => '0'); 
signal USER_DOF_WR    : std_logic := '0';                     

signal USER_COF_STAT  : std_logic_vector(7 downto 0) := (others => '0');  
signal USER_COF_CNT   : std_logic_vector(15 downto 0) := (others => '0'); 
signal USER_COF_AFULL : std_logic := '0';                    
signal USER_COF_WR    : std_logic := '0';                     

signal GoodToggle, BadToggle : std_logic := '0';

--CSR AXI Lite

signal CSR_araddr :  STD_LOGIC_VECTOR ( 31 downto 0 );
signal CSR_arprot :  STD_LOGIC_VECTOR ( 2 downto 0 );
signal CSR_arready : STD_LOGIC;
signal CSR_arvalid : STD_LOGIC;
signal CSR_awaddr :  STD_LOGIC_VECTOR ( 31 downto 0 );
signal CSR_awprot :  STD_LOGIC_VECTOR ( 2 downto 0 );
signal CSR_awready : STD_LOGIC;
signal CSR_awvalid : STD_LOGIC;
signal CSR_bready :  STD_LOGIC;
signal CSR_bresp : STD_LOGIC_VECTOR ( 1 downto 0 );
signal CSR_bvalid : STD_LOGIC;
signal CSR_rdata : STD_LOGIC_VECTOR ( 31 downto 0 );
signal CSR_rready :  STD_LOGIC;
signal CSR_rresp : STD_LOGIC_VECTOR ( 1 downto 0 );
signal CSR_rvalid : STD_LOGIC;
signal CSR_wdata :  STD_LOGIC_VECTOR ( 31 downto 0 );
signal CSR_wready : STD_LOGIC;
signal CSR_wstrb :  STD_LOGIC_VECTOR ( 3 downto 0 );
signal CSR_wvalid :  STD_LOGIC;

--Ethernet DataMover command and status
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

--Status register responses
signal HOST_FIRMWARE_VER, USER_FIRMWARE_VER : std_logic_vector(31 downto 0) := (others => '0');
signal CONFIG_SOURCE : std_logic_vector(31 downto 0) := (others => '0');
signal USER_STATUS_RESPONSE, DAC0_STATUS, DAC1_STATUS, PLL_STATUS : std_logic_vector(31 downto 0) := (others => '0');
signal FPGA_TEMPERATURE : std_logic_vector(31 downto 0) := (others => '0');
signal SEND_PKT_COUNT, RECV_PKT_COUNT, SKIP_PKT_COUNT, DUP_PKT_COUNT, FCS_ERR_COUNT, OVERRUN_COUNT : natural := 0; 
signal UPTIME_SEC, UPTIME_NSEC : natural := 0;

--CSR inputs/outputs
signal resets, controls : std_logic_vector(31 downto 0) ;
signal AXI_resetn : std_logic;

type TestbenchStates_t is (RESETTING, ARP_QUERY, STATUS_REQUEST, SINGLE_WORD_WRITE, SINGLE_WORD_READ, 
								WRONG_IP_PACKET, MULTI_WORD_WRITE, MULTI_WORD_READ, BAD_FRAME_TEST, 
								SEQUENCE_NUMBERING, CSR_WRITE, CSR_READ, WRITE_MULTIPLE_PACKETS, FINISHED);
signal testbenchState : TestbenchStates_t;

begin

--Clock processes

mac_clk_process :process
begin
	MAC_CLK <= '0';
	wait for MAC_CLK_PERIOD/2;
	MAC_CLK <= '1';
	wait for MAC_CLK_PERIOD/2;
end process;

user_clk_process :process
begin
	USER_CLK <= '0';
	wait for USER_CLK_PERIOD/2;
	USER_CLK <= '1';
	wait for USER_CLK_PERIOD/2;
end process;

cfg_clk_process :process
begin
	CFG_CLK <= '0';
	wait for CFG_CLK_PERIOD/2;
	CFG_CLK <= '1';
	wait for CFG_CLK_PERIOD/2;
end process;

sys_clk_process :process
begin
	SYS_CLK <= '0';
	wait for SYS_CLK_PERIOD/2;
	SYS_CLK <= '1';
	wait for SYS_CLK_PERIOD/2;
end process;

tx_rdy : process( MAC_CLK )
begin
	if rising_edge(MAC_CLK) then
		if MAC_TX_VALID_trimac = '1' then
			MAC_TX_RDY_trimac <= '1';
		else
			MAC_TX_RDY_trimac <= '0';
		end if;
	end if ;
end process ; -- tx_rdy

-- Stimulus process
stim_proc: process

variable srcMAC, destMAC : MACAddr_t := (others => (others => '0'));
variable myCommand : APSCommand_t := (ack => '0', seq => '0', sel => '0', rw => '0', cmd => (others => '0'), mode => (others => '0'), cnt => x"0000");
variable myFrameHeader : APSEthernetFrameHeader_t;
variable myIPHeader : IPv4Header_t;
variable myUDPHeader : UDPHeader_t;

variable emptyPayload : APSPayload_t(0 to -1);
variable testData1 : APSPayload_t(0 to 3);
variable testData2 : APSPayload_t(0 to 255);
variable testData3 : APSPayload_t(0 to 1023);
variable byteCount : natural := 0;

--Procedure to read status registers off of returning MAC byte stream
procedure update_status_registers is
	variable tmpWord : std_logic_vector(31 downto 0) ;

	procedure byte2word is
	begin
		for ct in 4 downto 1 loop
			wait until rising_edge(MAC_CLK);
			tmpWord(ct*8 - 1 downto (ct-1)*8) := MAC_TXD_trimac;
		end loop;
	end procedure byte2word ;

begin
	--Read through the header bytes 
	byteCount := 0;
	while ( byteCount < (14+20+8+16+4)) loop
		wait until rising_edge(MAC_CLK);
		if MAC_TX_VALID_trimac = '1' and MAC_TX_RDY_trimac = '1' then
			byteCount := byteCount+1;
		end if;
	end loop;

	--Now clock through the status words
	byte2word; HOST_FIRMWARE_VER <= tmpWord;
	byte2word; USER_FIRMWARE_VER <= tmpWord;
	byte2word; CONFIG_SOURCE <= tmpWord;
	byte2word; USER_STATUS_RESPONSE <= tmpWord;
	byte2word; DAC0_STATUS <= tmpWord;
	byte2word; DAC1_STATUS <= tmpWord;
	byte2word; PLL_STATUS <= tmpWord;
	byte2word; FPGA_TEMPERATURE <= tmpWord;
	byte2word; SEND_PKT_COUNT <= to_integer(unsigned(tmpWord));
	byte2word; RECV_PKT_COUNT <= to_integer(unsigned(tmpWord));
	byte2word; SKIP_PKT_COUNT <= to_integer(unsigned(tmpWord));
	byte2word; DUP_PKT_COUNT <= to_integer(unsigned(tmpWord));
	byte2word; FCS_ERR_COUNT <= to_integer(unsigned(tmpWord));
	byte2word; OVERRUN_COUNT <= to_integer(unsigned(tmpWord));
	byte2word; UPTIME_SEC <= to_integer(unsigned(tmpWord));
	byte2word; UPTIME_NSEC <= to_integer(unsigned(tmpWord));
end procedure update_status_registers;

--Procedure to check read data 
procedure check_read_data(testArray : in APSPayload_t) is
variable allGood : boolean := true ;

begin
	--Read through the header bytes 
	byteCount := 0;
	while ( byteCount < (14+20+8+16+4)) loop
		wait until rising_edge(MAC_CLK);
		if MAC_TX_VALID_trimac = '1' and MAC_TX_RDY_trimac = '1' then
			byteCount := byteCount+1;
		end if;
	end loop;

	--Now clock through the data and check every byte
	for ct in testArray'range loop
		wait until rising_edge(MAC_CLK);
		assert testArray(ct) = MAC_TXD_trimac report "Read data did not match expected!";
	end loop;

end procedure check_read_data;

--Wrapper procedure to clock in a complete Etherent frame using the above variables
procedure write_complete_frame(payLoad : in APSPayload_t; seqNum : in natural := 0; badFCS : in boolean := false) is
	
begin
	MAC_RX_VALID_trimac <= '1';
	write_ethernet_frame_header(destMAC, srcMAC, x"0800", MAC_RXD_trimac, MAC_CLK);
	write_IPv4Header(myIPHeader, MAC_RXD_trimac, MAC_CLK);
	write_UDPHeader(myUDPHeader, MAC_RXD_trimac, MAC_CLK);

	write_APSEthernet_frame(myFrameHeader, payLoad, MAC_RXD_trimac, MAC_CLK, MAC_RX_VALID_trimac, 
								MAC_RX_EOP_trimac, seqNum, badFCS, MAC_BAD_FCS_trimac);

end procedure write_complete_frame;


begin
	testbenchState <= RESETTING;
	wait for 100ns;
	RESET <= '1'; 
	wait for 200ns;
	RESET <= '0';
	wait for 100ns;
	wait until rising_edge(MAC_CLK);

	srcMAC := (x"BA", x"AD", x"BA", x"AD", x"BA", x"AD");
	destMAC := (x"FF", x"FF", x"FF", x"FF", x"FF", x"FF");

	wait until rising_edge(MAC_CLK);

	----------------------------------------------------------------------------------------------

	testbenchState <= ARP_QUERY;

	--ARP request who has 192.168.5.9? Tell 192.168.5.1";
	MAC_RX_VALID_trimac <= '1';

	write_ethernet_frame_header(destMAC, srcMAC, x"0806", MAC_RXD_trimac, MAC_CLK);

	-- HW type
	MAC_RXD_trimac <= x"00"; wait until rising_edge(MAC_CLK);
	MAC_RXD_trimac <= x"01"; wait until rising_edge(MAC_CLK);

	-- Protocol type
	MAC_RXD_trimac <= x"08"; wait until rising_edge(MAC_CLK);
	MAC_RXD_trimac <= x"00"; wait until rising_edge(MAC_CLK);

	-- HW size
	MAC_RXD_trimac <= x"06"; wait until rising_edge(MAC_CLK);

	-- protocol size
	MAC_RXD_trimac <= x"04"; wait until rising_edge(MAC_CLK);

	-- Opcode
	MAC_RXD_trimac <= x"00"; wait until rising_edge(MAC_CLK);
	MAC_RXD_trimac <= x"01"; wait until rising_edge(MAC_CLK);

	-- Sender MAC
	write_MAC_addr(srcMAC, MAC_RXD_trimac, MAC_CLK);

	-- Sender IP
	write_IPv4_addr((x"c0", x"a8", x"05", x"01"), MAC_RXD_trimac, MAC_CLK);

	-- Target MAC
	write_MAC_addr((x"00", x"00", x"00", x"00", x"00", x"00"), MAC_RXD_trimac, MAC_CLK);

	-- Target IP
	write_IPv4_addr((x"c0", x"a8", x"05", x"09"), MAC_RXD_trimac, MAC_CLK);

	--Bonus zeros
	MAC_RXD_trimac <= x"00"; wait until rising_edge(MAC_CLK);
	MAC_RXD_trimac <= x"00"; wait until rising_edge(MAC_CLK);
	MAC_RXD_trimac <= x"00"; wait until rising_edge(MAC_CLK);
	MAC_RX_VALID_trimac <= '0';
	MAC_RXD_trimac <= x"00"; wait until rising_edge(MAC_CLK);
	for ct in 1 to 4 loop
		wait until rising_edge(MAC_CLK);
	end loop;
	MAC_RX_EOP_trimac <= '1';
	MAC_RX_VALID_trimac <= '1';
	wait until rising_edge(MAC_CLK);
	MAC_RX_EOP_trimac <= '0';
	MAC_RX_VALID_trimac <= '0';
	wait until rising_edge(MAC_CLK);

	--Wait for ARP response to come back
	--TODO: error check
	wait until rising_edge(MAC_TX_EOP_trimac);
	wait until rising_edge(MAC_CLK);

	------------------------------------------------------------------------------------

	-- Clock in a enumerating UDP status request
	testbenchState <= STATUS_REQUEST;

	--Update MAC address for specific test instrument
	destMAC := (x"00", x"11", x"22", x"33", x"44", x"55");

	--Setup IPv4 and UDP header entries
	myIPHeader.srcIP := (x"c0", x"a8", x"05", x"01");
	myIPHeader.destIP := (x"c0", x"a8", x"05", x"09");
	--20 bytes ipv4 + 8 bytes UDP + 14 bytes APSEthernet fake Ethernet frame + 10 bytes aps seq. num,  command and addr
	myIPHeader.totalLength := 20+8+14+10;
	myIPHeader.protocol := x"11";

	myUDPHeader.srcPort := 47950;
	myUDPHeader.destPort := 47950;
	myUDPHeader.totalLength := 8+14+10;

	-- user data is APSEthernetFrame
	myFrameHeader.destMAC := (x"FF", x"FF", x"FF", x"FF", x"FF", x"FF");
	myFrameHeader.srcMAC := (x"BA", x"AD", x"BA", x"AD", x"BA", x"AD");
	myFrameHeader.command := myCommand;
	myFrameHeader.command.rw := '1';
	myFrameHeader.command.cmd := x"7";
	myFrameHeader.addr := (others => '0');

	write_complete_frame(emptyPayload);

	--APSMsgProc will send back status registers
	update_status_registers;
	--Error checking after one clock cycle to catch last register updates
	wait until rising_edge(MAC_CLK);
	assert (HOST_FIRMWARE_VER = x"00000a01") report "Status registers: HOST_FIRMWARE_VER incorrect";
	assert (USER_FIRMWARE_VER = x"00000212") report "Status registers: USER_FIRMWARE_VER incorrect";
	assert (CONFIG_SOURCE = x"bbbbbbbb") report "Status registers: CONFIG_SOURCE incorrect";
	assert (SEND_PKT_COUNT = 0) report "Status registers: SEND_PKT_COUNT incorrect";
	assert (RECV_PKT_COUNT = 1) report "Status registers: RECV_PKT_COUNT incorrect";
	assert (FCS_ERR_COUNT = 0) report "Status registers: FCS_ERR_COUNT incorrect";
	assert (UPTIME_SEC = 0) report "Status registers: UPTIME_SEC incorrect";
	assert (UPTIME_NSEC = 1536) report "Status registers: UPTIME_NSEC incorrect";


	---------------------------------------------------------------------------------------------------------

	-- Clock in a control word write to controls

	testbenchState <= CSR_WRITE;

	--Fix-up headers
	myFrameHeader.command.rw := '0';
	myFrameHeader.command.cmd := x"9";
	myFrameHeader.command.cnt := std_logic_vector( to_unsigned(1, 16));
	myFrameHeader.addr := x"44A00008";
	testData1(0) := x"AB"; 	testData1(1) := x"CD"; 	testData1(2) := x"EF"; 	testData1(3) := x"FE";
	myIPHeader.totalLength := 20+8+14+10+testData1'length;
	myUDPHeader.totalLength := 8+14+10+testData1'length;

	write_complete_frame(testData1);

	--Check the data showed up on the register
	wait until rising_edge(MAC_TX_EOP_trimac);
	assert controls = x"ABCDEFFE" report "CSR control write failed.";

	-------------------------------------------------------------------------------------------------

	-- Ask for the dummy status

	testbenchState <= CSR_READ;

	--Fix-up headers
	myFrameHeader.command.rw := '1';
	myFrameHeader.command.cnt := std_logic_vector( to_unsigned(1, 16));
	myFrameHeader.addr := x"44A00004";
	myIPHeader.totalLength := 20+8+14+10;
	myUDPHeader.totalLength := 8+14+10;

	write_complete_frame(emptyPayload);

	--Check the data is returned correctly
	report "Checking read data for CSR read test.";
	check_read_data((x"12", x"34", x"56", x"78"));
	
	testbenchState <= FINISHED;
	wait;


end process;


--Instantiate UDP interface
udp: entity work.UDP_Interface
    port map (
    	MAC_CLK => MAC_CLK,
		RST => RESET,
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

		mac_addr => x"001122334455",
		ip_addr => x"c0a80509"
	);


--And the ZRL message processor 
AMP1 : entity work.ApsMsgProc
port map
(
	-- Interface to MAC to get Ethernet packets
	MAC_CLK       => MAC_CLK,
	RESET         => RESET,

	MAC_RXD       => MAC_RXD_msgproc,
	MAC_RX_VALID  => MAC_RX_VALID_msgproc,
	MAC_RX_EOP    => MAC_RX_EOP_msgproc,
	MAC_BAD_FCS   => MAC_BAD_FCS_msgproc,

	MAC_TXD       => MAC_TXD_msgproc,
	MAC_TX_RDY    => MAC_TX_RDY_msgproc,
	MAC_TX_VALID  => MAC_TX_VALID_msgproc,
	MAC_TX_EOP    => MAC_TX_EOP_msgproc,

	-- User Logic Connections
	USER_CLK       => USER_CLK,
	USER_RST       => USER_RST,
	USER_VERSION   => x"12345678",
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

	-- Interface to Config CPLD
	CFG_CLK       => CFG_CLK,
	CFGD_IN       => x"AAAA",  -- Temporary for Status command testing
	CFGD_OUT      => open ,    -- Eventually connected to CPLD
	CFGD_OE       => open ,    -- Eventually connected to CPLD
	STAT_OE       => open ,    -- Eventually connected to CPLD

	-- Status to top level
	GOOD_TOGGLE   => GoodToggle,
	BAD_TOGGLE    => BadToggle
);

-- Instantiate the APSMsgProc - AXI bridge
AXIbridge : entity work.AXIBridge
port map ( 
    RST => RESET,

	-- User Logic Connections
	USER_CLK  => USER_CLK,                        -- Clock for User side of FIFO interface
	USER_RST => USER_RST,

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
	S2MM_tvalid => ethernet_s2mm_tvalid);


	--Instantiate the memory BD
    myMemory : Memory
	port map (

	    reset => RESET,
	    clk_axi => USER_CLK,
	    clk_axi_locked => "not"(RESET),
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

  	-- CSR
	CSR : entity work.APS2_CSR
	port map (

		sys_clk => USER_CLK,

		resets => resets,
		controls => controls,
		dummyStatus => x"12345678",
		dummyStatus2 => x"87654321",

		S_AXI_ACLK => USER_CLK,
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
    
end Behavioral;

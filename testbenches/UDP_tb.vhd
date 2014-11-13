-- Test bench for read/writes via UDP ethernet frames

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.EthernetFrame.all;
use work.IPv4Header.all;

entity UDP_tb is
end UDP_tb;

architecture Behavioral of UDP_tb is

--Clocks and resets
constant USER_CLK_PERIOD : time := 10 ns;
constant MAC_CLK_PERIOD : time := 8 ns;
constant SYS_CLK_PERIOD : time := 3.33333333333333333 ns;

signal SYS_CLK       : std_logic := '0';                     
signal USER_CLK       : std_logic := '0';                     
signal USER_RST       : std_logic := '0';                    

signal MAC_CLK 		 : std_logic := '0';
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
signal USER_VERSION   : std_logic_vector(31 downto 0) := (others => '0'); 
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

--Ethernet DataMover command and status
signal ETHERNET_MM2S_tdata : STD_LOGIC_VECTOR ( 31 downto 0 ) := (others => '0');
signal ETHERNET_MM2S_tkeep : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others => '0');
signal ETHERNET_MM2S_tlast : STD_LOGIC := '0';
signal ETHERNET_MM2S_tready : STD_LOGIC := '0';
signal ETHERNET_MM2S_tvalid : STD_LOGIC := '0';
signal ETHERNET_S2MM_tdata : STD_LOGIC_VECTOR ( 31 downto 0 ) := (others => '0');
signal ETHERNET_S2MM_tkeep : STD_LOGIC_VECTOR ( 3 downto 0 ) := (others => '1'); -- assuming 32bit words 
signal ETHERNET_S2MM_tlast : STD_LOGIC := '0';
signal ETHERNET_S2MM_tvalid : STD_LOGIC := '0';
signal ETHERNET_S2MM_tready : STD_LOGIC := '0';

signal ETHERNET_S2MM_STS_tdata : STD_LOGIC_VECTOR ( 7 downto 0 ) := (others => '0');
signal ETHERNET_S2MM_STS_tkeep : STD_LOGIC_VECTOR ( 0 to 0 );
signal ETHERNET_S2MM_STS_tlast : STD_LOGIC := '0';
signal ETHERNET_S2MM_STS_tready : STD_LOGIC := '0';
signal ETHERNET_S2MM_STS_tvalid : STD_LOGIC := '0';
signal ETHERNET_MM2S_STS_tdata : STD_LOGIC_VECTOR ( 7 downto 0 ) := (others => '0');
signal ETHERNET_MM2S_STS_tkeep : STD_LOGIC_VECTOR ( 0 to 0 );
signal ETHERNET_MM2S_STS_tlast : STD_LOGIC := '0';
signal ETHERNET_MM2S_STS_tready : STD_LOGIC := '0';
signal ETHERNET_MM2S_STS_tvalid : STD_LOGIC := '0';
signal ETHERNET_S2MM_CMD_tdata : STD_LOGIC_VECTOR ( 71 downto 0 ) := (others => '0');
signal ETHERNET_S2MM_CMD_tready : STD_LOGIC := '0';
signal ETHERNET_S2MM_CMD_tvalid : STD_LOGIC := '0';
signal ETHERNET_MM2S_CMD_tdata : STD_LOGIC_VECTOR ( 71 downto 0 ) := (others => '0');
signal ETHERNET_MM2S_CMD_tready : STD_LOGIC := '0';
signal ETHERNET_MM2S_CMD_tvalid : STD_LOGIC := '0';

--Status register responses
signal HOST_FIRMWARE_VER, USER_FIRMWARE_VER : std_logic_vector(31 downto 0) := (others => '0');
signal CONFIG_SOURCE : std_logic_vector(31 downto 0) := (others => '0');
signal USER_STATUS_RESPONSE, DAC0_STATUS, DAC1_STATUS, PLL_STATUS : std_logic_vector(31 downto 0) := (others => '0');
signal FPGA_TEMPERATURE : std_logic_vector(31 downto 0) := (others => '0');
signal SEND_PKT_COUNT, RECV_PKT_COUNT, SKIP_PKT_COUNT, DUP_PKT_COUNT, FCS_ERR_COUNT, OVERRUN_COUNT : natural := 0; 
signal UPTIME_SEC, UPTIME_NSEC : natural := 0;

--Pass through signals from block design to BRAMs
signal wfA_en : STD_LOGIC;
signal wfA_dout : STD_LOGIC_VECTOR ( 127 downto 0 );
signal wfA_din : STD_LOGIC_VECTOR ( 127 downto 0 );
signal wfA_we : STD_LOGIC_VECTOR ( 15 downto 0 );
signal wfA_addr : STD_LOGIC_VECTOR ( 14 downto 0 );
signal wfA_clk : STD_LOGIC;
signal wfA_rst : STD_LOGIC;

signal wfB_en : STD_LOGIC;
signal wfB_dout : STD_LOGIC_VECTOR ( 127 downto 0 );
signal wfB_din : STD_LOGIC_VECTOR ( 127 downto 0 );
signal wfB_we : STD_LOGIC_VECTOR ( 15 downto 0 );
signal wfB_addr : STD_LOGIC_VECTOR ( 14 downto 0 );
signal wfB_clk : STD_LOGIC;
signal wfB_rst : STD_LOGIC;

signal SEQ_en : STD_LOGIC;
signal SEQ_dout : STD_LOGIC_VECTOR ( 127 downto 0 );
signal SEQ_din : STD_LOGIC_VECTOR ( 127 downto 0 );
signal SEQ_we : STD_LOGIC_VECTOR ( 15 downto 0 );
signal SEQ_addr : STD_LOGIC_VECTOR ( 14 downto 0 );
signal SEQ_clk : STD_LOGIC;
signal SEQ_rst : STD_LOGIC;

--CSR outputs
signal cache_status : STD_LOGIC_VECTOR ( 31 downto 0 ) := (others => '0');
signal cache_control : STD_LOGIC_VECTOR ( 31 downto 0 );
signal wfa_offset : STD_LOGIC_VECTOR ( 31 downto 0 );
signal wfb_offset : STD_LOGIC_VECTOR ( 31 downto 0 );
signal seq_offset : STD_LOGIC_VECTOR ( 31 downto 0 );
signal sequencer_control : STD_LOGIC_VECTOR ( 31 downto 0 );


--Cache BRAM signals
signal SEQ_doutb : std_logic_vector(127 downto 0) := (others => '0');
signal SEQ_addrb : std_logic_vector(10 downto 0) := (others => '0');

signal WFA_doutb : std_logic_vector(63 downto 0) := (others => '0');
signal WFA_addrb : std_logic_vector(11 downto 0) := (others => '0');

signal WFB_doutb : std_logic_vector(63 downto 0) := (others => '0');
signal WFB_addrb : std_logic_vector(11 downto 0) := (others => '0');


type TestbenchStates_t is (RESETTING, ARP_QUERY, STATUS_REQUEST, SINGLE_WORD_WRITE, SINGLE_WORD_READ, 
								WRONG_IP_PACKET, MULTI_WORD_WRITE, MULTI_WORD_READ, BAD_FRAME_TEST, 
								SEQUENCE_NUMBERING, CSR_WRITE, CSR_READ, FINISHED);
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
	assert (USER_FIRMWARE_VER = x"00000a02") report "Status registers: USER_FIRMWARE_VER incorrect";
	assert (CONFIG_SOURCE = x"bbbbbbbb") report "Status registers: CONFIG_SOURCE incorrect";
	assert (SEND_PKT_COUNT = 0) report "Status registers: SEND_PKT_COUNT incorrect";
	assert (RECV_PKT_COUNT = 1) report "Status registers: RECV_PKT_COUNT incorrect";
	assert (FCS_ERR_COUNT = 0) report "Status registers: FCS_ERR_COUNT incorrect";
	assert (UPTIME_SEC = 0) report "Status registers: UPTIME_SEC incorrect";
	assert (UPTIME_NSEC = 1536) report "Status registers: UPTIME_NSEC incorrect";

--Doesn't seem to work....
	-- -- Clock in a soft reset
	-- MAC_RX_VALID_trimac <= '1';
	-- write_MAC_addr(destMAC, MAC_RXD_trimac, MAC_CLK);
	-- write_MAC_addr(srcMAC, MAC_RXD_trimac, MAC_CLK);
	-- -- frame type
	-- MAC_RXD_trimac <= x"08"; wait until rising_edge(MAC_CLK);
	-- MAC_RXD_trimac <= x"00"; wait until rising_edge(MAC_CLK);

	-- myIPHeader.srcIP := (x"c0", x"a8", x"05", x"01");
	-- myIPHeader.destIP := (x"c0", x"a8", x"05", x"09");
	-- myIPHeader.totalLength := 64;
	-- myIPHeader.protocol := x"11";
	-- write_IPv4Header(myIPHeader, MAC_RXD_trimac, MAC_CLK);

	-- myUDPHeader.srcPort := 47950;
	-- myUDPHeader.destPort := 47950;
	-- myUDPHeader.totalLength := 48;
	-- write_UDPHeader(myUDPHeader, MAC_RXD_trimac, MAC_CLK);

	-- -- user data is APSEthernetFrame
	-- myFrameHeader.destMAC := (x"FF", x"FF", x"FF", x"FF", x"FF", x"FF");
	-- myFrameHeader.srcMAC := (x"BA", x"AD", x"BA", x"AD", x"BA", x"AD");
	-- --command
	-- myFrameHeader.command := myCommand;
	-- myFrameHeader.command.rw := '0';
	-- myFrameHeader.command.cmd := x"0";
	-- myFrameHeader.command.mode := x"02";
	-- myFrameHeader.command.cnt := std_logic_vector( to_unsigned(0, 16));
	-- myFrameHeader.addr := (others => '0');
	
	-- write_APSEthernet_frame(myFrameHeader, emptyPayload, MAC_RXD_trimac, MAC_CLK, MAC_RX_VALID_trimac, MAC_RX_EOP_trimac);


	-- --APSMsgProc will send back status registers
	-- --TODO: error checking
	-- wait until rising_edge(MAC_TX_EOP_trimac);


	---------------------------------------------------------------------------------------------------------

	-- Clock in a single word UDP write
	-- user data is APSEthernetFrame
	--command

	testbenchState <= SINGLE_WORD_WRITE;

	myFrameHeader.command.rw := '0';
	myFrameHeader.command.cmd := x"9";
	myFrameHeader.command.cnt := std_logic_vector( to_unsigned(1, 16));
	myFrameHeader.command.mode := x"00";
	myFrameHeader.addr := x"2000" & std_logic_vector(to_unsigned(4, 16));
	testData1(0) := x"12"; 	testData1(1) := x"34"; 	testData1(2) := x"56"; 	testData1(3) := x"78";

	myFrameHeader.destMAC := (x"00", x"22", x"33", x"44", x"55", x"66");

	myIPHeader.totalLength := 20+8+14+10+testData1'length;
	myUDPHeader.totalLength := 8+14+10+testData1'length;

	write_complete_frame(testData1);

	---------------------------------------------------------------------------------------------------------

	-- Clock in a packet to a different IP from a different IP to make sure it is filtered

	testbenchState <= WRONG_IP_PACKET;

	myIPHeader.destIP := (x"aa", x"bb", x"cc", x"dd");	
	myIPHeader.srcIP := (x"ba", x"ad", x"ba", x"ad");	
	myFrameHeader.destMAC := (x"BA", x"AD", x"F0", x"0F", x"BA", x"AD");

	write_complete_frame(testData1);

	--TODO: error checking
	wait until rising_edge(MAC_TX_EOP_trimac);

	---------------------------------------------------------------------------------------------------------

	-- Clock in a single word UDP read request

	testbenchState <= SINGLE_WORD_READ;

	--Fix-up headers
	myIPHeader.destIP := (x"c0", x"a8", x"05", x"09");
	myIPHeader.srcIP := (x"c0", x"a8", x"05", x"01");
	myFrameHeader.destMAC := (x"00", x"22", x"33", x"44", x"55", x"66");
	myFrameHeader.command.rw := '1';
	myIPHeader.totalLength := 20+8+14+10;
	myUDPHeader.totalLength := 8+14+10;

	write_complete_frame(emptyPayload);

	--Check the data came back
	check_read_data(testData1);


	---------------------------------------------------------------------------------------------------------

	-- Clock in a control word write to wfA offset

	testbenchState <= CSR_WRITE;

	--Fix-up headers
	myFrameHeader.command.rw := '0';
	myFrameHeader.command.cmd := x"9";
	myFrameHeader.command.cnt := std_logic_vector( to_unsigned(1, 16));
	myFrameHeader.addr := x"44A00014";
	testData1(0) := x"AB"; 	testData1(1) := x"CD"; 	testData1(2) := x"EF"; 	testData1(3) := x"FE";
	myIPHeader.totalLength := 20+8+14+10+testData1'length;
	myUDPHeader.totalLength := 8+14+10+testData1'length;

	write_complete_frame(testData1);

	--Check the data showed up on the register
	wait until rising_edge(MAC_TX_EOP_trimac);
	assert wfa_offset = x"ABCDEFFE" report "CSR control write failed.";

	-------------------------------------------------------------------------------------------------

	-- Ask for the cache status

	testbenchState <= CSR_READ;

	--Fix-up headers
	myFrameHeader.command.rw := '1';
	myFrameHeader.command.cnt := std_logic_vector( to_unsigned(1, 16));
	myFrameHeader.addr := x"44A0000C";
	myIPHeader.totalLength := 20+8+14+10;
	myUDPHeader.totalLength := 8+14+10;

	cache_status <= x"BADDBAAD";
	write_complete_frame(emptyPayload);

	--Check the data is returned correctly
	check_read_data((x"BA", x"DD", x"BA", x"AD"));

	--------------------------------------------------------------------------------------------------

	-- Clock in a multi-word UDP write

	testbenchState <= MULTI_WORD_WRITE;

	myFrameHeader.command.rw := '0';
	myFrameHeader.command.cnt := std_logic_vector( to_unsigned(256/4, 16));
	myFrameHeader.addr := x"20" & std_logic_vector(to_unsigned(0, 24)); 
	for ct in 0 to 255 loop
		testData2(ct) := std_logic_vector( to_unsigned(ct, 8));
	end loop;

	myIPHeader.totalLength := 20+8+14+10+testData2'length;
	myUDPHeader.totalLength := 8+14+10+testData2'length;

	write_complete_frame(testData2);

	--APSMsgProc will send back ACK
	--TODO: error checking
	wait until rising_edge(MAC_TX_EOP_trimac);

	---------------------------------------------------------------------------------------------------------

	-- Clock in multi-word read request
	testbenchState <= MULTI_WORD_READ;

	myFrameHeader.command.rw := '1';
	myIPHeader.totalLength := 20+8+14+10;
	myUDPHeader.totalLength := 8+14+10;

	write_complete_frame(emptyPayload);

	--Check the data came back correctly
	check_read_data(testData2);

	---------------------------------------------------------------------------------------------------------

	-- Clock in a write request with a bad FCS flag going high to make sure is is filtered
	testbenchState <= BAD_FRAME_TEST;

	myFrameHeader.command.rw := '0';
	myFrameHeader.command.cmd := x"9";
	myFrameHeader.command.cnt := std_logic_vector( to_unsigned(1, 16));

	myIPHeader.totalLength := 20+8+14+10+testData1'length;
	myUDPHeader.totalLength := 8+14+10+testData1'length;

	write_complete_frame(testData1, badFCS => true);

	---------------------------------------------------------------------------------------------------------

	-- Clock in a UDP status request to check the packet counts

	testbenchState <= STATUS_REQUEST;

	myFrameHeader.command.rw := '1';
	myFrameHeader.command.cmd := x"7";
	myFrameHeader.addr := (others => '0');
	myIPHeader.totalLength := 20+8+14+10;
	myUDPHeader.totalLength := 8+14+10;

	write_complete_frame(emptyPayload);

	--APSMsgProc will send back status registers
	--TODO: error checking
	update_status_registers;

	-------------------------------------------------------------------------------------------------

	--Send a sequence of packets and make sure a missed packet causes a halt

	testbenchState <= SEQUENCE_NUMBERING;

	myFrameHeader.command.rw := '0';
	myFrameHeader.command.cmd := x"9";
	myFrameHeader.command.cnt := std_logic_vector( to_unsigned(256/4, 16));
	myFrameHeader.addr := x"20" & std_logic_vector(to_unsigned(0, 24)); 
	myIPHeader.totalLength := 20+8+14+10+testData2'length;
	myUDPHeader.totalLength := 8+14+10+testData2'length;

	write_complete_frame(testData2);

	--APSMsgProc will send back ACK
	--TODO: error checking
	wait until rising_edge(MAC_TX_EOP_trimac);

	write_complete_frame(testData2, seqNum => 1);

	--APSMsgProc will send back ACK
	--TODO: error checking
	wait until rising_edge(MAC_TX_EOP_trimac);

	write_complete_frame(testData2, seqNum => 3);

	--No ack from this but setting sequence number back to zero should

	wait until rising_edge(MAC_CLK);
	MAC_RX_VALID_trimac <= '1';
	write_complete_frame(testData2, seqNum => 0);

	--APSMsgProc will send back ACK
	--TODO: error checking
	wait until rising_edge(MAC_TX_EOP_trimac);


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

	-- Interface to Config CPLD
	CFG_CLK       => USER_CLK,
	CFGD_IN       => x"AAAA",  -- Temporary for Status command testing
	CFGD_OUT      => open ,    -- Eventually connected to CPLD
	CFGD_OE       => open ,    -- Eventually connected to CPLD
	STAT_OE       => open ,    -- Eventually connected to CPLD

	-- Status to top level
	GOOD_TOGGLE   => GoodToggle,
	BAD_TOGGLE    => BadToggle
);

-- Instantiate the APSMsgProc - AXI bridge
AXIbridge : entity work.APSUserLogic
port map ( 
    RST => RESET,

	-- User Logic Connections
	USER_CLK  => USER_CLK,                        -- Clock for User side of FIFO interface
	USER_RST => USER_RST,
	USER_VERSION => USER_VERSION,-- User Logic Firmware Version.  Returned in Status message
	USER_STATUS => USER_STATUS,  -- User Status Word.  Returned in Status message

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

	MM2S_STS_tdata => ETHERNET_MM2S_STS_tdata, 
	MM2S_STS_tkeep => ETHERNET_MM2S_STS_tkeep,
	MM2S_STS_tlast => ETHERNET_MM2S_STS_tlast,
	MM2S_STS_tready => ETHERNET_MM2S_STS_tready,
	MM2S_STS_tvalid => ETHERNET_MM2S_STS_tvalid,

	MM2S_tdata => ETHERNET_MM2S_tdata,
	MM2S_tkeep => ETHERNET_MM2S_tkeep,
	MM2S_tlast => ETHERNET_MM2S_tlast, 
	MM2S_tready => ETHERNET_MM2S_tready, 
	MM2S_tvalid => ETHERNET_MM2S_tvalid,

	S2MM_STS_tdata => ETHERNET_S2MM_STS_tdata, 
	S2MM_STS_tkeep => ETHERNET_S2MM_STS_tkeep, 
	S2MM_STS_tlast => ETHERNET_S2MM_STS_tlast, 
	S2MM_STS_tready => ETHERNET_S2MM_STS_tready, 
	S2MM_STS_tvalid => ETHERNET_S2MM_STS_tvalid, 

	MM2S_CMD_tdata => ETHERNET_MM2S_CMD_tdata,
	MM2S_CMD_tready => ETHERNET_MM2S_CMD_tready,
	MM2S_CMD_tvalid => ETHERNET_MM2S_CMD_tvalid,

	S2MM_CMD_tdata => ETHERNET_S2MM_CMD_tdata,
	S2MM_CMD_tready => ETHERNET_S2MM_CMD_tready,
	S2MM_CMD_tvalid => ETHERNET_S2MM_CMD_tvalid,

	S2MM_tdata => ETHERNET_S2MM_tdata,
	S2MM_tkeep => ETHERNET_S2MM_tkeep,
	S2MM_tlast => ETHERNET_S2MM_tlast,
	S2MM_tready => ETHERNET_S2MM_tready,
	S2MM_tvalid => ETHERNET_S2MM_tvalid);


--Instantiate the memory BD
    myMemory: entity work.Memory_bram
    port map (
        AXICLK => USER_CLK,
        sys_clk => SYS_CLK,
        AXIRESETN => not RESET,

        ------------------------------------------------------------------
        --DMA DataMover
        DMA_MM2S_STS_tdata => open,
        DMA_MM2S_STS_tkeep => open,
        DMA_MM2S_STS_tlast => open,
        DMA_MM2S_STS_tready => '0',
        DMA_MM2S_STS_tvalid => open,
        DMA_S2MM_STS_tdata => open,
        DMA_S2MM_STS_tkeep => open,
        DMA_S2MM_STS_tlast => open,
        DMA_S2MM_STS_tready => '0',
        DMA_S2MM_STS_tvalid => open,
        DMA_MM2S_CMD_tdata => (others => '0'),
        DMA_MM2S_CMD_tready => open,
        DMA_MM2S_CMD_tvalid => '0',
        DMA_S2MM_CMD_tdata => (others => '0'),
        DMA_S2MM_CMD_tready => open,
        DMA_S2MM_CMD_tvalid => '0',

        ------------------------------------------------------------------
        --Ethernet DMA
        ETHERNET_MM2S_tdata  => ETHERNET_MM2S_tdata,
        ETHERNET_MM2S_tkeep  => ETHERNET_MM2S_tkeep,
        ETHERNET_MM2S_tlast  => ETHERNET_MM2S_tlast,
        ETHERNET_MM2S_tready => ETHERNET_MM2S_tready,
        ETHERNET_MM2S_tvalid => ETHERNET_MM2S_tvalid,
        ETHERNET_S2MM_tdata  => ETHERNET_S2MM_tdata,
        ETHERNET_S2MM_tkeep  => ETHERNET_S2MM_tkeep,
        ETHERNET_S2MM_tlast  => ETHERNET_S2MM_tlast,
        ETHERNET_S2MM_tvalid  => ETHERNET_S2MM_tvalid,
        ETHERNET_S2MM_tready => ETHERNET_S2MM_tready,      
        ETHERNET_MM2S_STS_tdata => ETHERNET_MM2S_STS_tdata,
        ETHERNET_MM2S_STS_tkeep => ETHERNET_MM2S_STS_tkeep,
        ETHERNET_MM2S_STS_tlast => ETHERNET_MM2S_STS_tlast,
        ETHERNET_MM2S_STS_tready => ETHERNET_MM2S_STS_tready,
        ETHERNET_MM2S_STS_tvalid => ETHERNET_MM2S_STS_tvalid,
        ETHERNET_S2MM_STS_tdata => ETHERNET_S2MM_STS_tdata,
        ETHERNET_S2MM_STS_tkeep => ETHERNET_S2MM_STS_tkeep,
        ETHERNET_S2MM_STS_tlast => ETHERNET_S2MM_STS_tlast,
        ETHERNET_S2MM_STS_tready => ETHERNET_S2MM_STS_tready,
        ETHERNET_S2MM_STS_tvalid => ETHERNET_S2MM_STS_tvalid,
        ETHERNET_MM2S_CMD_tdata => ETHERNET_MM2S_CMD_tdata,
        ETHERNET_MM2S_CMD_tready => ETHERNET_MM2S_CMD_tready,
        ETHERNET_MM2S_CMD_tvalid => ETHERNET_MM2S_CMD_tvalid,
        ETHERNET_S2MM_CMD_tdata => ETHERNET_S2MM_CMD_tdata,
        ETHERNET_S2MM_CMD_tready => ETHERNET_S2MM_CMD_tready,
        ETHERNET_S2MM_CMD_tvalid => ETHERNET_S2MM_CMD_tvalid,

        ------------------------------------------------------------------

        WF_A_addr => wfA_addr,
        WF_A_clk => wfA_clk,
        WF_A_din => wfA_din,
        WF_A_dout => wfA_dout,
        WF_A_en => wfA_en,
        WF_A_rst => wfA_rst,
        WF_A_we => wfA_we,
        WF_B_addr => wfB_addr,
        WF_B_clk => wfB_clk,
        WF_B_din => wfB_din,
        WF_B_dout => wfB_dout,
        WF_B_en => wfB_en,
        WF_B_rst => wfB_rst,
        WF_B_we => wfB_we,

        SEQ_addr => SEQ_addr,
        SEQ_clk  => SEQ_clk,
        SEQ_din  => SEQ_din,
        SEQ_dout => SEQ_dout,
        SEQ_en   => SEQ_en,
        SEQ_rst  => SEQ_rst,
        SEQ_we   => SEQ_we,
        ------------------------------------------------------------------
        cache_status => cache_status,
        cache_control => cache_control,
        wfa_offset => wfa_offset,
        wfb_offset => wfb_offset,
        seq_offset => seq_offset,
        sequencer_control => sequencer_control,
        ------------------------------------------------------------------
        pll_status => (others => '0'),
        phase_a_count => (others => '0'),
        phase_b_count => (others => '0'),
        zero_out => open,
        trigger_word => open ,
        trigger_interval => open
    );
    
    WFA: entity work.WF_BRAM
    port map (
        clka => wfA_clk,
        rsta => wfA_rst,
        ena => wfA_en,
        wea => wfA_we,
        addra => wfA_addr(14 downto 4),
        dina => wfA_din,
        douta => wfA_dout,
        clkb => SYS_CLK,
        web => (others => '0'),
        addrb => WFA_addrb,
        dinb => (others => '0'),
        doutb => WFA_doutb
    );

    WFB: entity work.WF_BRAM
    port map (
        clka => wfB_clk,
        rsta => wfB_rst,
        ena => wfB_en,
        wea => wfB_we,
        addra => wfB_addr(14 downto 4),
        dina => wfB_din,
        douta => wfB_dout,
        clkb => SYS_CLK,
        web => (others => '0'),
        addrb => WFB_addrb,
        dinb  => (others => '0'),
        doutb => WFB_doutb
    );

    SEQ: entity work.SEQ_BRAM
    port map (
        clka  => SEQ_clk,
        rsta  => SEQ_rst,
        ena   => SEQ_en,
        wea   => SEQ_we,
        addra => SEQ_addr(14 downto 4),
        dina  => SEQ_din,
        douta => SEQ_dout,
        clkb  => SYS_CLK,
        web   => (others => '0'),
        addrb => SEQ_addrb,
        dinb  => (others => '0'),
        doutb => SEQ_doutb
    );

end Behavioral;

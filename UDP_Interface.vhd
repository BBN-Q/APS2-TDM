
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UDP_Interface is
  Port ( 
    MAC_CLK : in std_logic;
    RST : in std_logic;
    --real MAC signals to/from the TRIMAC
    MAC_RXD_trimac : in std_logic_vector (7 downto 0);
    MAC_RX_VALID_trimac : in std_logic;
    MAC_RX_EOP_trimac : in std_logic;
    MAC_BAD_FCS_trimac : in std_logic;
    MAC_TXD_trimac : out std_logic_vector (7 downto 0);
    MAC_TX_RDY_trimac : in std_logic;
    MAC_TX_VALID_trimac : out std_logic;
    MAC_TX_EOP_trimac : out std_logic;

    --fake MAC signals to/from the APSMsgProc
    MAC_RXD_msgproc : buffer std_logic_vector (7 downto 0);
    MAC_RX_VALID_msgproc : buffer std_logic;
    MAC_RX_EOP_msgproc : buffer std_logic;
    MAC_BAD_FCS_msgproc : out std_logic;
    MAC_TXD_msgproc : in std_logic_vector (7 downto 0);
    MAC_TX_RDY_msgproc : out std_logic;
    MAC_TX_VALID_msgproc : in std_logic;
    MAC_TX_EOP_msgproc : in std_logic;

    mac_addr : in std_logic_vector(47 downto 0);
    ip_addr : in std_logic_vector(31 downto 0)
  );

end UDP_Interface;

architecture Behavioral of UDP_Interface is

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
ATTRIBUTE SYN_BLACK_BOX : BOOLEAN;
ATTRIBUTE SYN_BLACK_BOX OF UDPOutputBufferFIFO : COMPONENT IS TRUE;
ATTRIBUTE BLACK_BOX_PAD_PIN : STRING;
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


--internal routing signals
signal udp_tx_start : std_logic;
signal udp_txi : udp_tx_type;
signal udp_tx_result : std_logic_vector(1 downto 0) ;
signal udp_tx_data_out_ready : std_logic;

signal udp_rx_start : std_logic;
signal udp_rxo : udp_rx_type;

signal ip_rx_hdr : ipv4_rx_header_type;

signal control : udp_control_type;

signal arp_pkt_count, ip_pkt_count : std_logic_vector(7 downto 0) ;

--signals from buffering FIFO into UDP TX
signal m_axis_tvalid, m_axis_tlast : std_logic := '0';
signal m_axis_tdata : std_logic_vector(7 downto 0) ;
signal packetSize : unsigned(11 downto 0);


signal mac_tx_tdata : std_logic_vector(7 downto 0) := (others => '0');
signal mac_tx_tvalid, mac_tx_tready, mac_tx_tfirst, mac_tx_tlast : std_logic := '0';

constant APS_PORT : std_logic_vector(15 downto 0) := x"bb4e";
signal BBNPacketForUS : boolean := false;

--Sequence number control
signal expectedSeqNum, packetSeqNum : unsigned(15 downto 0) := (others => '0');
signal badSeqNum : boolean := false;


begin

MAC_BAD_FCS_msgproc <= '1' when (MAC_BAD_FCS_trimac = '1' or badSeqNum) else '0';

--Clear the ARP cache on reset
control.ip_controls.arp_controls.clear_cache <= RST;

--We have a BBN UDP packet for us when the headers are valid and the ports match the APS_PORT
BBNPacketForUS  <= (udp_rxo.hdr.is_valid = '1') and (udp_rxo.hdr.src_port = APS_PORT) and (udp_rxo.hdr.dst_port = APS_PORT) and (ip_rx_hdr.is_valid = '1');

--Send good BBN UDP packets on to the msgproc
MAC_RX_VALID_msgproc <= udp_rxo.data.data_in_valid when BBNPacketForUS else '0';
MAC_RX_EOP_msgproc <= udp_rxo.data.data_in_last when BBNPacketForUS else '0';
MAC_RXD_msgproc <= udp_rxo.data.data_in when BBNPacketForUS else (others => '0');

latchDstIP : process( MAC_CLK )
begin
    if rising_edge(MAC_CLK) then
        if RST = '1' then 
            udp_txi.hdr.dst_ip_addr <= (others => '0');
        else
            --Send packets back to source of received good packets
            --Latch on a good BBNPacketForUS
            if BBNPacketForUS then
                udp_txi.hdr.dst_ip_addr <= udp_rxo.hdr.src_ip_addr;
            end if;
        end if;
    end if;
end process ; -- latchDstIP

catchSeqNum : process( MAC_CLK )

variable byteCount : natural range 0 to 31 := 0;

begin
    if rising_edge(MAC_CLK) then
        if RST = '1' then
            packetSeqNum <= (others => '0');
            byteCount := 0;
        elsif MAC_RX_VALID_msgproc = '1' then
            if MAC_RX_EOP_msgproc = '1' then
                byteCount := 0;
            elsif byteCount < 17 then
                    byteCount := byteCount + 1;
            end if;
            case( byteCount ) is
                
                when 15 =>
                    packetSeqNum(15 downto 8) <= unsigned(MAC_RXD_msgproc);

                when 16 => 
                    packetSeqNum(7 downto 0) <= unsigned(MAC_RXD_msgproc);

                when others =>
                    null;
            end case ;
        end if ;
    end if ;
end process ; -- catchSeqNum

checkSeqNum : process( MAC_CLK )
begin
    if rising_edge(MAC_CLK) then
        if RST= '1' or (packetSeqNum = x"0000") then
            expectedSeqNum <= x"0001";
        elsif MAC_RX_EOP_msgproc = '1' then
            expectedSeqNum <= expectedSeqNum + 1;
        end if;
    end if ;
end process ; -- checkSeqNum

badSeqNum <= false when (packetSeqNum = expectedSeqNum) or (packetSeqNum = x"0000") else true;

--Set the BBN ports for the outgoing udp packets
udp_txi.hdr.dst_port <= APS_PORT;
udp_txi.hdr.src_port <= APS_PORT;

--TODO: calculate checksum
udp_txi.hdr.checksum <= x"0000";

udp_txi.data.data_out_valid <= m_axis_tvalid;
udp_txi.data.data_out_last <= m_axis_tlast;
udp_txi.data.data_out <= m_axis_tdata;

--buffer from to take outgoing packets and count their size
outputBuffer : UDPOutputBufferFIFO
  port map (
    s_aclk => MAC_CLK,
    s_aresetn => "not"(RST),
    s_axis_tvalid => MAC_TX_VALID_msgproc,
    s_axis_tready => MAC_TX_RDY_msgproc,
    s_axis_tdata => MAC_TXD_msgproc,
    s_axis_tlast => MAC_TX_EOP_msgproc,
    m_axis_tvalid => m_axis_tvalid,
    m_axis_tready => udp_tx_data_out_ready,
    m_axis_tdata => m_axis_tdata,
    m_axis_tlast => m_axis_tlast,
    unsigned(axis_data_count) => packetSize
  );


--buffer to handle new ready behaviour from MAC
outputBuffer2 : UDPOutputBufferFIFO2
  port map (
    s_aclk => MAC_CLK,
    s_aresetn => "not"(RST),
    s_axis_tvalid => mac_tx_tvalid,
    s_axis_tready => mac_tx_tready,
    s_axis_tdata => mac_tx_tdata,
    s_axis_tlast => mac_tx_tlast,
    m_axis_tvalid => MAC_TX_VALID_trimac,
    m_axis_tready => MAC_TX_RDY_trimac,
    m_axis_tdata => MAC_TXD_trimac,
    m_axis_tlast => MAC_TX_EOP_trimac
  );


--Little SM to handle FIFO 
BufferManager : process( MAC_CLK )
type STATE_TYPE is (loading, latchCount, playBack);
variable curState : STATE_TYPE := loading; 
begin
	if rising_edge(MAC_CLK) then
		if RST = '1' then
			curState := loading;
		else
			case( curState ) is
			
				when loading =>
					--hold up data until end of packet
					udp_tx_start <= '0';
					if m_axis_tvalid = '1' then
						curState := latchCount;
					end if;

				when latchCount =>
					udp_txi.hdr.data_length <= "0000" & std_logic_vector(packetSize);
					curState := playBack;
					udp_tx_start <= '1';

				when playBack =>
					--play (as long as UDP_nomac can take it) into until end of packet
					udp_tx_start <= '0';
					if m_axis_tvalid = '0' then
						curState := loading;
					end if;

				when others =>
			
			end case ;
		end if ;
	end if ;
end process ; -- BufferManager



--Instantiate the complete UDP nomac
udp_nomac: entity work.UDP_Complete_nomac
	generic map( CLOCK_FREQ	=> 125000000,	-- freq of data_in_clk -- needed to timout cntr
			ARP_TIMEOUT => 60,				-- ARP response timeout (s)
			ARP_MAX_PKT_TMO	=> 5,			-- # wrong nwk pkts received before set error
			MAX_ARP_ENTRIES => 15)
	port map(
			-- UDP TX signals
			udp_tx_start => udp_tx_start,	--  in std_logic;-- indicates req to tx UDP
			udp_txi => udp_txi, 		--  in udp_tx_type;	-- UDP tx cxns
			udp_tx_result => udp_tx_result,  -- 	: out std_logic_vector (1 downto 0);-- tx status (changes during transmission)
			udp_tx_data_out_ready => udp_tx_data_out_ready, -- : out std_logic;	-- indicates udp_tx is ready to take data
			-- UDP RX signals
			udp_rx_start => udp_rx_start, --  out std_logic;-- indicates receipt of udp header
			udp_rxo => udp_rxo,		--	: out udp_rx_type;
			-- IP RX signals
			ip_rx_hdr => ip_rx_hdr,		--: out ipv4_rx_header_type;
			-- system signals
			rx_clk => MAC_CLK,
			tx_clk => MAC_CLK,
			reset => RST,
			our_ip_address => ip_addr,		-- : in STD_LOGIC_VECTOR (31 downto 0);
			our_mac_address => mac_addr, -- 	: in std_logic_vector (47 downto 0);
			control	=> control, --				: in udp_control_type;

			-- status signals
			arp_pkt_count => arp_pkt_count,	-- 			: out STD_LOGIC_VECTOR(7 downto 0);			-- count of arp pkts received
			ip_pkt_count => ip_pkt_count,	-- 			: out STD_LOGIC_VECTOR(7 downto 0);			-- number of IP pkts received for us
			
			-- MAC Transmitter
			mac_tx_tdata => mac_tx_tdata,	--         : out  std_logic_vector(7 downto 0);	-- data byte to tx
			mac_tx_tvalid => mac_tx_tvalid,	--   : out  std_logic;	-- tdata is valid
			mac_tx_tready => mac_tx_tready,	--  : in std_logic;			-- mac is ready to accept data -- buffer FIFO can always take some
			mac_tx_tfirst => open,	--      : out  std_logic;				-- indicates first byte of frame
			mac_tx_tlast => mac_tx_tlast,	--  : out  std_logic;		-- indicates last byte of frame
			-- MAC Receiver
			mac_rx_tdata => MAC_RXD_trimac,	--         : in std_logic_vector(7 downto 0);	-- data byte received
			mac_rx_tvalid => MAC_RX_VALID_trimac, --   : in std_logic;					-- indicates tdata is valid
			mac_rx_tready => open,	--        : out  std_logic;			-- tells mac that we are ready to take data
			mac_rx_tlast => MAC_RX_EOP_trimac	--        : in std_logic	-- indicates last byte of the trame
		);





end Behavioral;

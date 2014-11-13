--- Package for handling APS ethernet frames

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package EthernetFrame is

type MACAddr_t is array(0 to 5) of std_logic_vector(7 downto 0);

type APSCommand_t is record
	ack : std_logic;
	seq : std_logic;
	sel : std_logic;
	rw : std_logic;
	cmd : std_logic_vector(3 downto 0);
	mode : std_logic_vector(7 downto 0);
	cnt : std_logic_vector(15 downto 0);
end record;

type APSEthernetFrameHeader_t is record
	destMAC : MACAddr_t;
	srcMAC : MACAddr_t;
	seqNum : unsigned(15 downto 0);
	command : APSCommand_t;
	addr : std_logic_vector(31 downto 0);	
end record;

type APSPayload_t is array(integer range <>) of std_logic_vector(7 downto 0);

procedure write_MAC_addr(macAddr : in MACAddr_t; signal mac_rx : out std_logic_vector(7 downto 0); signal clk : in std_logic);

procedure write_ethernet_frame_header(destMAC : in MACAddr_t; srcMAC : in MACAddr_t; frameType : in std_logic_vector(15 downto 0); signal mac_rx : out std_logic_vector(7 downto 0); signal clk : in std_logic);

procedure write_APS_command(cmd : in APSCommand_t; signal mac_rx : out std_logic_vector(7 downto 0); signal clk : in std_logic); 

procedure write_APSEthernet_frame(frame : in APSEthernetFrameHeader_t; payload : in APSPayload_t; signal mac_rx : out std_logic_vector(7 downto 0); 
	signal clk : in std_logic; signal rx_valid : out std_logic; signal rx_eop : out std_logic; seqNum : in natural := 0; badFCS : in boolean := false; signal mac_fcs : out std_logic ); 

end EthernetFrame;

package body EthernetFrame is


procedure write_MAC_addr(macAddr : in MACAddr_t; signal mac_rx : out std_logic_vector(7 downto 0); signal clk : in std_logic) is
begin
	for ct in 0 to 5 loop
		mac_rx <= macAddr(ct); wait until rising_edge(clk);
	end loop;
end procedure write_MAC_addr;

procedure write_ethernet_frame_header(destMAC : in MACAddr_t; srcMAC : in MACAddr_t; frameType : in std_logic_vector(15 downto 0); signal mac_rx : out std_logic_vector(7 downto 0); signal clk : in std_logic) is
begin
	write_MAC_addr(destMAC, mac_rx, clk);
	write_MAC_addr(srcMAC, mac_rx, clk);
	mac_rx <= frameType(15 downto 8); wait until rising_edge(clk);
	mac_rx <= frameType(7 downto 0); wait until rising_edge(clk);
end procedure write_ethernet_frame_header;

procedure write_APS_command(cmd : in APSCommand_t; signal mac_rx : out std_logic_vector(7 downto 0); signal clk : in std_logic) is
begin
	mac_rx <= cmd.ack & cmd.seq & cmd.sel & cmd.rw & cmd.cmd; wait until rising_edge(clk);
	mac_rx <= cmd.mode; wait until rising_edge(clk);
	mac_rx <= cmd.cnt(15 downto 8); wait until rising_edge(clk);
	mac_rx <= cmd.cnt(7 downto 0); wait until rising_edge(clk);
end procedure write_APS_command;


procedure write_APSEthernet_frame(frame : in APSEthernetFrameHeader_t; payload : in APSPayload_t; signal mac_rx : out std_logic_vector(7 downto 0); 
	signal clk : in std_logic; signal rx_valid : out std_logic; signal rx_eop : out std_logic; seqNum : in natural := 0; badFCS : in boolean := false; signal mac_fcs : out std_logic  ) is

variable seqNum_u : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(seqNum, 16));
begin

	rx_valid <= '1';
	
	write_ethernet_frame_header(frame.destMAC, frame.srcMAC, x"BB4E", mac_rx, clk);

	--seq. num.
	mac_rx <= seqNum_u(15 downto 8); wait until rising_edge(clk);
	mac_rx <= seqNum_u(7 downto 0); wait until rising_edge(clk);

	--command
	write_APS_command(frame.command, mac_rx, clk);

	--address
	for ct in 4 downto 1 loop
		if (payload'length = 0) and (ct = 1) then
			rx_valid <= '0';
		end if;
		mac_rx <= frame.addr(ct*8-1 downto (ct-1)*8); wait until rising_edge(clk);
		--if there is no payload then the packet ends here
	end loop;

	-- clock in the payload
	for ct in payload'range loop
		--deassert valid for last byte until frame check is finished
		if ct = payload'right then
			rx_valid <= '0';
		end if;
		mac_rx <= payload(ct); wait until rising_edge(clk);
	end loop;

	--Frame check sequence
	rx_valid <= '0';
	for ct in 1 to 4 loop
		wait until rising_edge(clk);
	end loop;

	--Signal end of packet
	rx_valid <= '1';
	rx_eop <= '1';
	if badFCS then
		mac_fcs <= '1';
	end if;
	wait until rising_edge(clk);
	rx_valid <= '0'; 
	rx_eop <= '0';
	mac_fcs <= '0';
	wait until rising_edge(clk);

	--Interframe gap of four beats
	for ct in 1 to 4 loop
		wait until rising_edge(clk);
	end loop;
	

end procedure write_APSEthernet_frame;

end package body;
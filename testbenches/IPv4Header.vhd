--- Package for handling IPv4 Headers

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package IPv4Header is

type IPv4Addr_t is array(0 to 3) of std_logic_vector(7 downto 0);

type IPv4Header_t is record
	srcIP : IPv4Addr_t;
	destIP : IPv4Addr_t;
	totalLength : natural;
	protocol : std_logic_vector(7 downto 0) ;
end record;

type UDPHeader_t is record
	srcPort : natural;
	destPort : natural;
	totalLength : natural;
end record;


procedure write_IPv4_addr(ipAddr : in IPv4Addr_t; signal mac_rx : out std_logic_vector(7 downto 0); signal clk : in std_logic);
procedure write_IPv4Header(header : in IPv4Header_t; signal mac_rx : out std_logic_vector(7 downto 0); signal clk : in std_logic); 
procedure write_UDPHeader(header : in UDPHeader_t; signal mac_rx : out std_logic_vector(7 downto 0); signal clk : in std_logic);

end IPv4Header;

package body IPv4Header is

procedure write_IPv4_addr(ipAddr : in IPv4Addr_t; signal mac_rx : out std_logic_vector(7 downto 0); signal clk : in std_logic) is
begin
	for ct in 0 to 3 loop
		mac_rx <= ipAddr(ct); wait until rising_edge(clk);
	end loop;
end procedure write_IPv4_addr;

procedure write_IPv4Header(header : in IPv4Header_t; signal mac_rx : out std_logic_vector(7 downto 0); signal clk : in std_logic) is
variable totalLength : std_logic_vector(15 downto 0);
begin
	totalLength := std_logic_vector(to_unsigned(header.totalLength, 16));

	-- ver & HL / service type
	mac_rx <= x"45"; wait until rising_edge(clk);	
	mac_rx <= x"00"; wait until rising_edge(clk);
	-- total len
	mac_rx <= totalLength(15 downto 8); wait until rising_edge(clk);
	mac_rx <= totalLength(7 downto 0); wait until rising_edge(clk);
	-- ID
	mac_rx <= x"00"; wait until rising_edge(clk);
	mac_rx <= x"7a"; wait until rising_edge(clk);
	-- flags & frag
	mac_rx <= x"00"; wait until rising_edge(clk);
	mac_rx <= x"00"; wait until rising_edge(clk);
	-- TTL
	mac_rx <= x"80"; wait until rising_edge(clk);
	-- Protocol x"11" = UDP
	mac_rx <= header.protocol; wait until rising_edge(clk);
	-- Header CKS
	mac_rx <= x"00"; wait until rising_edge(clk);
	mac_rx <= x"00"; wait until rising_edge(clk);
	-- SRC IP
	write_IPv4_addr(header.srcIP, mac_rx, clk);
	-- DST IP
	write_IPv4_addr(header.destIP, mac_rx, clk);
	
end procedure write_IPv4Header;

procedure write_UDPHeader(header : in UDPHeader_t; signal mac_rx : out std_logic_vector(7 downto 0); signal clk : in std_logic) is
variable srcPort, destPort, totalLength : std_logic_vector(15 downto 0);
begin
	srcPort := std_logic_vector(to_unsigned(header.srcPort, 16));
	destPort := std_logic_vector(to_unsigned(header.destPort, 16));
	totalLength := std_logic_vector(to_unsigned(header.totalLength, 16));
	
	-- SRC port
	mac_rx <= srcPort(15 downto 8); wait until rising_edge(clk);
	mac_rx <= srcPort(7 downto 0); wait until rising_edge(clk);
	-- DST port
	mac_rx <= destPort(15 downto 8); wait until rising_edge(clk);
	mac_rx <= destPort(7 downto 0); wait until rising_edge(clk);
	-- length
	mac_rx <= totalLength(15 downto 8); wait until rising_edge(clk);
	mac_rx <= totalLength(7 downto 0); wait until rising_edge(clk);
	-- cks
	mac_rx <= x"00"; wait until rising_edge(clk);
	mac_rx <= x"00"; wait until rising_edge(clk);

end procedure write_UDPHeader;

end package body;
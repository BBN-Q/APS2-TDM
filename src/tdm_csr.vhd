-- AXI memory mapped CSR registers
--
-- Original authors: Colm Ryan, Brian Donovan
-- Copyright 2015-2016, Raytheon BBN Technologies


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TDM_CSR is
port (
	--CSR control ports
	resets             : out std_logic_vector(31 downto 0);
	control            : out std_logic_vector(31 downto 0);
	trigger_interval   : out std_logic_vector(31 downto 0);

	-- CSR status ports
	trigger_word       : in std_logic_vector(31 downto 0);
	SATA_status        : in std_logic_vector(31 downto 0);
	uptime_seconds     : in std_logic_vector(31 downto 0);
	uptime_nanoseconds : in std_logic_vector(31 downto 0);
	tdm_version        : in std_logic_vector(31 downto 0);
	temperature        : in std_logic_vector(31 downto 0);
	git_sha1           : in std_logic_vector(31 downto 0);
	build_timestamp    : in std_logic_vector(31 downto 0);

	-- slave AXI bus
	s_axi_aclk    : in std_logic;
	s_axi_aresetn : in std_logic;
	s_axi_awaddr  : in std_logic_vector(6 downto 0);
	s_axi_awprot  : in std_logic_vector(2 downto 0);
	s_axi_awvalid : in std_logic;
	s_axi_awready : out std_logic;
	s_axi_wdata   : in std_logic_vector(31 downto 0);
	s_axi_wstrb   : in std_logic_vector(3 downto 0);
	s_axi_wvalid  : in std_logic;
	s_axi_wready  : out std_logic;
	s_axi_bresp   : out std_logic_vector(1 downto 0);
	s_axi_bvalid  : out std_logic;
	s_axi_bready  : in std_logic;
	s_axi_araddr  : in std_logic_vector(6 downto 0);
	s_axi_arprot  : in std_logic_vector(2 downto 0);
	s_axi_arvalid : in std_logic;
	s_axi_arready : out std_logic;
	s_axi_rdata   : out std_logic_vector(31 downto 0);
	s_axi_rresp   : out std_logic_vector(1 downto 0);
	s_axi_rvalid  : out std_logic;
	s_axi_rready  : in std_logic
	);
end entity;

architecture arch of TDM_CSR is

	-- array of registers
	constant NUM_REGS : natural := 32;
	type REG_ARRAY_t is array(natural range <>) of std_logic_vector(31 downto 0) ;
	signal regs : REG_ARRAY_t(0 to NUM_REGS-1) := (others => (others => '0'));
	signal write_reg_addr : integer range 0 to NUM_REGS-1;
	signal read_reg_addr  : integer range 0 to NUM_REGS-1;

	-- internal AXI signals
	signal axi_awready : std_logic;
	signal axi_wready  : std_logic;
	signal axi_wdata   : std_logic_vector(31 downto 0);
	signal axi_wstrb   : std_logic_vector(3 downto 0);
	signal axi_bvalid  : std_logic;
	signal axi_arready : std_logic;
	signal axi_rvalid  : std_logic;

begin

	-- wire control/status ports to internal registers
	resets             <= regs(0);
	control            <= regs(1);
	trigger_interval   <= regs(12);
	read_regs_register_pro: process (s_axi_aclk)
	begin
		if rising_edge(s_axi_aclk) then
			regs(11) <= trigger_word;
			regs(18) <= SATA_status;
			regs(20) <= uptime_seconds;
			regs(21) <= uptime_nanoseconds;
			regs(22) <= tdm_version;
			regs(23) <= temperature;
			regs(24) <= git_sha1;
			regs(25) <= build_timestamp;
		end if;
	end process;

	-- connect internal AXI signals
	s_axi_awready <= axi_awready;
	s_axi_wready  <= axi_wready;
	s_axi_bvalid  <= axi_bvalid;
	s_axi_arready <= axi_arready;
	s_axi_rvalid  <= axi_rvalid;


	-- simplistic response to write requests that only handles one write at a time
	-- 1. hold awready and wready low
	-- 2. wait until both awvalid and wvalid are asserted
	-- 3. assert awready and wready high; latch write address and data
	-- 4. update control register
	-- 5. always respond with OK
	s_axi_bresp <= "00";

	write_ready_pro : process (s_axi_aclk)
	begin
		if rising_edge(s_axi_aclk) then
			if s_axi_aresetn = '0' then
				axi_awready <= '0';
				axi_wready <= '0';
				axi_bvalid <= '0';
			else
				if (axi_awready = '0' and axi_wready = '0' and s_axi_awvalid = '1' and s_axi_wvalid = '1') then
					axi_awready <= '1';
					axi_wready  <= '1';
				else
					axi_awready <= '0';
					axi_wready  <= '0';
				end if;

				-- once writing set response valid high until accepted
				if axi_wready = '1' then
					axi_bvalid <= '1';
				elsif axi_bvalid = '1' and s_axi_bready = '1' then
					axi_bvalid <= '0';
				end if;
			end if;
		end if;
	end process;

	-- update control / internal registers
	update_write_regs_pro : process (s_axi_aclk)
	begin
		if rising_edge(s_axi_aclk) then
			-- decode register address
			write_reg_addr <= to_integer(unsigned(s_axi_awaddr(s_axi_awaddr'high downto 2)));
			-- register data and byte enables
			axi_wdata <= s_axi_wdata;
			axi_wstrb <= s_axi_wstrb;

			if s_axi_aresetn = '0' then
				regs(0) <= x"00000000"; -- resets
				regs(1) <= x"00000000"; -- control
				regs(12) <= x"000186a0"; -- trigger_interval

			else
				for ct in 0 to 3 loop
					if axi_wstrb(ct) = '1' and axi_wready = '1' then
						-- resets
						if write_reg_addr = 0 then
							regs(0)(ct*8+7 downto ct*8) <= axi_wdata(ct*8+7 downto ct*8);
						end if;
						-- control
						if write_reg_addr = 1 then
							regs(1)(ct*8+7 downto ct*8) <= axi_wdata(ct*8+7 downto ct*8);
						end if;
						-- trigger_interval
						if write_reg_addr = 12 then
							regs(12)(ct*8+7 downto ct*8) <= axi_wdata(ct*8+7 downto ct*8);
						end if;
					end if;
				end loop;
			end if;
		end if;
	end process;

	-- read response
	-- respond with data one clock later
	s_axi_rresp <= "00"; -- always OK

	read_response_pro : process (s_axi_aclk)
	begin
		if rising_edge(s_axi_aclk) then

			if s_axi_aresetn = '0' then
				axi_arready <= '0';
				read_reg_addr <= 0;
				s_axi_rdata <= (others => '0');
				axi_rvalid <= '0';
			else
				-- acknowledge and latch address when no outstanding read responses
				if axi_arready = '0' and s_axi_arvalid = '1' then
					axi_arready <= '1';
					-- latch register address
					read_reg_addr <= to_integer(unsigned(s_axi_araddr(s_axi_araddr'high downto 2)));
				else
					axi_arready <= '0';
				end if;

				-- hold data valid high after latching address and until response
				if axi_arready = '1' then
					axi_rvalid <= '1';
				elsif axi_rvalid = '1' and s_axi_rready = '1' then
					axi_rvalid <= '0';
				end if;

				-- register out data
				s_axi_rdata <= regs(read_reg_addr);

			end if;

		end if;
	end process;

end architecture;
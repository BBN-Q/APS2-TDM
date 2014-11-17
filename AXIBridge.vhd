library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

--This module translates from APS USER commands from APSMsgProc to AXI read/write commands
--It assumes the user FIFO's from the APSMsgProc are clocked on the same clock as the AXI domain

entity AXIBridge is
	Port ( 
		RST : in STD_LOGIC;

		-- User Logic Connections
		USER_CLK       : in std_logic;                       -- Clock for User side of FIFO interface
		USER_RST       : in std_logic;                       -- User Logic global reset, synchronous to USER_CLK

		USER_DIF       : in std_logic_vector(31 downto 0);   -- User Data Input FIFO output
		USER_DIF_RD    : out std_logic;                      -- User Data Onput FIFO Read Enable

		USER_CIF_EMPTY : in std_logic;                       -- Low when there is data available
		USER_CIF_RD    : out std_logic;                      -- Command Input FIFO Read Enable
		USER_CIF_RW    : in std_logic;                       -- High for read, low for write
		USER_CIF_MODE  : in std_logic_vector(7 downto 0) ;   -- MODE field from current User I/O command
		USER_CIF_CNT   : in std_logic_vector(15 downto 0);   -- CNT field from current User I/O command
		USER_CIF_ADDR  : in std_logic_vector(31 downto 0);   -- Address for the current command

		USER_DOF       : out std_logic_vector(31 downto 0);  -- User Data Onput FIFO input
		USER_DOF_WR    : out std_logic;                      -- User Data Onput FIFO Write Enable

		USER_COF_STAT  : out std_logic_vector(7 downto 0);  -- STAT value to return for current User I/O command
		USER_COF_CNT   : out std_logic_vector(15 downto 0);  -- Number of words written to DOF for current User I/O command
		USER_COF_AFULL : in std_logic;                       -- User Control Output FIFO Almost Full
		USER_COF_WR    : out std_logic;                       -- User Control Onput FIFO Write Enable

		MM2S_STS_tdata : in STD_LOGIC_VECTOR ( 7 downto 0 );
		MM2S_STS_tkeep : in STD_LOGIC_VECTOR ( 0 to 0 );
		MM2S_STS_tlast : in STD_LOGIC;
		MM2S_STS_tready : out STD_LOGIC;
		MM2S_STS_tvalid : in STD_LOGIC;

		MM2S_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
		MM2S_tkeep : in STD_LOGIC_VECTOR ( 3 downto 0 );
		MM2S_tlast : in STD_LOGIC;
		MM2S_tready : out STD_LOGIC;
		MM2S_tvalid : in STD_LOGIC;

		S2MM_STS_tdata : in STD_LOGIC_VECTOR ( 7 downto 0 );
		S2MM_STS_tkeep : in STD_LOGIC_VECTOR ( 0 to 0 );
		S2MM_STS_tlast : in STD_LOGIC;
		S2MM_STS_tready : out STD_LOGIC;
		S2MM_STS_tvalid : in STD_LOGIC;

		MM2S_CMD_tdata : out STD_LOGIC_VECTOR ( 71 downto 0 );
		MM2S_CMD_tready : in STD_LOGIC;
		MM2S_CMD_tvalid : out STD_LOGIC;

		S2MM_CMD_tdata : out STD_LOGIC_VECTOR ( 71 downto 0 );
		S2MM_CMD_tready : in STD_LOGIC;
		S2MM_CMD_tvalid : out STD_LOGIC;

		S2MM_tdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
		S2MM_tkeep : out STD_LOGIC_VECTOR ( 3 downto 0 );
		S2MM_tlast : out STD_LOGIC;
		S2MM_tready : in STD_LOGIC;
		S2MM_tvalid : out STD_LOGIC

		   );
end AXIBridge;

architecture Behavioral of AXIBridge is


type IOState_t is (IDLE, WRITE_AXI_CMD, READ_AXI_CMD, WRITE_SINGLE, WRITE_DATA, WAIT_AXI_WRITE_ACK, READ_DATA, WAIT_AXI_READ_ACK, FINISHED );
signal ioState : IOState_t := IDLE;

signal wordCt : unsigned(15 downto 0) := (others => '0'); -- words left to read/write on this command
signal writing : boolean := false;

type DataMoverCmd_t is record
	rsvd : std_logic_vector(3 downto 0) ;
	tag : std_logic_vector(3 downto 0) ;
	addr : std_logic_vector(31 downto 0) ;
	drr : std_logic;
	eof : std_logic;
	dsa : std_logic_vector(5 downto 0) ; 
	axiType : std_logic;
	btt : std_logic_vector(22 downto 0) ;
end record;

signal moverCmd : DataMoverCmd_t := (rsvd => (others => '0'), tag => (others => '0'), addr => (others => '0'), drr => '0', eof => '1', dsa => (others => '0'), axiType => '1', btt => (others => '0'));

function movercmd2slv(cmd : DataMoverCmd_t) return std_logic_vector is
variable slvOut : std_logic_vector(71 downto 0) ;
begin
	slvOut := cmd.rsvd & cmd.tag & cmd.addr & cmd.drr & cmd.eof & cmd.dsa & cmd.axiType & cmd.btt;
	return slvOut;
end movercmd2slv;

begin

--We can always take from the AXI DataMover
MM2S_STS_tready <= '1';
S2MM_STS_tready <= '1';
MM2S_tready <= '1';

--Connect msg_proc data to AXI data busses
S2MM_tdata <= USER_DIF;
USER_DOF <= MM2S_tdata;
USER_DOF_WR <= MM2S_tvalid;

--Pull the next data when we are writing and when the data mover can take it
USER_DIF_RD <= '1' when writing and S2MM_tready = '1' else '0';

--Assume 4 byte boundaries for now
S2MM_tkeep <= "1111";

--We only have one source of mover commands so wire both directions to the same command
S2MM_CMD_tdata <=  movercmd2slv(moverCmd);
MM2S_CMD_tdata <= movercmd2slv(moverCmd);

mainProc : process( USER_CLK )

begin

	if rising_edge(USER_CLK) then
		if USER_RST = '1' then
			wordCt <= (others => '0');
			ioState <= IDLE;
			writing <= false;
			USER_CIF_RD <= '0';
			USER_COF_WR <= '0';
			USER_COF_CNT <= (others => '0');
			USER_COF_STAT <= (others => '0');
			MM2S_CMD_tvalid <= '0';
			S2MM_CMD_tvalid <= '0';
			S2MM_tlast <= '0';
			S2MM_tvalid <= '0';

		else
		  --defaults
			MM2S_CMD_tvalid <= '0';
			S2MM_CMD_tvalid <= '0';
			S2MM_tlast <= '0';
			S2MM_tvalid <= '0';

			USER_COF_WR <= '0';
			USER_CIF_RD <= '0';
			writing <= false;

		  case ( ioState ) is

			when IDLE =>
				--Load up the starting address and word counts
				moverCmd.addr <= USER_CIF_ADDR;
				wordCt <= unsigned(USER_CIF_CNT)-1;
				--bytes to transfer is 4x the number of words
				moverCmd.btt <= b"00000" & USER_CIF_CNT & b"00";
				--tag the command with the lower nibble of the mode/stat
				moverCmd.tag <= USER_CIF_MODE(3 downto 0);

				USER_COF_CNT <= (others => '0');
				USER_COF_STAT <= (others => '0');

				--Wait until there is a command to process
				--should probably also check whether COF is full before proceeding
				if USER_CIF_EMPTY = '0' then
					if USER_CIF_RW = '1' then
						ioState <= READ_AXI_CMD;
						--For reading we will return the requested number of words
						USER_COF_CNT <= USER_CIF_CNT;
					else
						ioState <= WRITE_AXI_CMD;
					end if; 
				end if ;

			when WRITE_AXI_CMD =>
				S2MM_CMD_tvalid <= '1';

				--wait until data mover has taken command
				if S2MM_CMD_tready = '1' then
					ioState <= WRITE_DATA;
					--load next command
					USER_CIF_RD <= '1';
				end if;

			when WRITE_DATA =>
				S2MM_tvalid <= '1';
				writing <= true;
				if wordCt = 0 then
					S2MM_tlast <= '1';
				end if;
				--Count down data and signal end with tlast
				--In future this should be handled elsewhere on the AXI stream
				if S2MM_tready = '1' then
					wordCt <= wordCt - 1;
					--If this is the last word then move on to waiting for acknowledge
					if wordCt = 0 then
						ioState <= WAIT_AXI_WRITE_ACK;
					end if;
				end if;
	
			when WAIT_AXI_WRITE_ACK =>
				if S2MM_STS_tvalid = '1' then
					USER_COF_STAT <= S2MM_STS_tdata;
					ioState <= FINISHED;
				end if;
				
			when READ_AXI_CMD =>
				MM2S_CMD_tvalid <= '1';
				if MM2S_CMD_tready = '1' then
					ioState <= READ_DATA;
					--load next command
					USER_CIF_RD <= '1';
				end if;

			when READ_DATA =>
				--Pass data over to output FIFO until finished
				--Should really check status too
				if MM2S_STS_tvalid = '1' then
					ioState <= FINISHED;
					USER_COF_STAT <= MM2S_STS_tdata;
			  end if;

			when FINISHED =>
				--Put the acknowledge out on the COF
				USER_COF_WR <= '1';
				ioState <= IDLE;

			when others =>
			  null;
		  
			end case ;

		end if;
	end if;

end process ; -- mainProc

end Behavioral;

-- TriggerInLogic.vhd
--
-- Deserializes triggers and passes them to the User Logic through a FIFO based interface.
-- The FIFO allows the trigger receive logic and the User Logic clock to have independent clocks.
--
-- REVISIONS
--
-- 3/6/2014  CRJ
--   Created
--
-- 7/31/2014 CRJ
--   Modified to allow use of I/O buffer for loopback
--
-- 8/5/2014 CRJ
--   Unmodified
--
-- 8/28/2014 CRJ
--   Changed back to 0xF0 clock, since now bit slipping in logic versus the input cell
--
-- END REVISIONS
--


library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity TriggerInLogic is
port
(
  USER_CLK   : in  std_logic;  -- Clock for the output side of the FIFO
  CLK_200MHZ : in  std_logic;  -- Delay calibration clock
  RESET      : in  std_logic;  -- Asynchronous reset for the trigger logic and FIFO

  TRIG_CLKP  : in  std_logic;  -- 100MHz Serial Clock, clocks input side of FIFO
  TRIG_CLKN  : in  std_logic;
  TRIG_DATP  : in  std_logic;  -- 800 Mbps Serial Data
  TRIG_DATN  : in  std_logic;

  TRIG_NEXT  : in  std_logic;  -- Advance the FIFO output to the next trigger, must be synchronous to USER_CLK

  TRIG_LOCKED : out std_logic; -- Set when locked and aligned to the received trigger clock, synchronous to USER_CLK
  TRIG_ERR   : out std_logic;  -- Set if unaligned clock received after clock locked and aligned, synchronous to USER_CLK
  TRIG_RX    : out std_logic_vector(7 downto 0);  -- Current trigger value, synchronous to USER_CLK
  TRIG_OVFL  : out std_logic;  -- Set if trigger FIFO overflows, cleared by RESET, synchronous to USER_CLK
  TRIG_READY : out std_logic   -- FIFO output valid flag, set when TRIG_RX is valid, synchronous to USER_CLK
);
end TriggerInLogic;


architecture behavior of TriggerInLogic is

component TRIG_MMCM
port
(
  -- Clock in ports
  CLK_100MHZ_IN           : in     std_logic;

  -- Clock out ports
  TRIG_100MHZ          : out    std_logic;
  TRIG_400MHZ          : out    std_logic;

  -- Status and control signals
  RESET             : in     std_logic;
  LOCKED            : out    std_logic
);
end component;


COMPONENT TRIG_FIFO
PORT
(
  rst : IN STD_LOGIC;
  wr_clk : IN STD_LOGIC;
  rd_clk : IN STD_LOGIC;
  din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
  wr_en : IN STD_LOGIC;
  rd_en : IN STD_LOGIC;
  dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
  full : OUT STD_LOGIC;
  empty : OUT STD_LOGIC;
  prog_full : OUT STD_LOGIC  
);
END COMPONENT;

COMPONENT TIO_FIFO
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    prog_full : OUT STD_LOGIC
  );
END COMPONENT;

ATTRIBUTE SYN_BLACK_BOX : BOOLEAN;
ATTRIBUTE SYN_BLACK_BOX OF TRIG_MMCM : COMPONENT IS TRUE;
ATTRIBUTE SYN_BLACK_BOX OF TRIG_FIFO : COMPONENT IS TRUE;
ATTRIBUTE SYN_BLACK_BOX OF TIO_FIFO : COMPONENT IS TRUE;

ATTRIBUTE BLACK_BOX_PAD_PIN : STRING;
ATTRIBUTE BLACK_BOX_PAD_PIN OF TRIG_MMCM : COMPONENT IS "CLK_100MHZ_IN,TRIG_100MHZ,TRIG_400MHZ,RESET,LOCKED";
ATTRIBUTE BLACK_BOX_PAD_PIN OF TRIG_FIFO : COMPONENT IS "rst,wr_clk,rd_clk,din[7:0],wr_en,rd_en,dout[7:0],full,empty,prog_full";
ATTRIBUTE BLACK_BOX_PAD_PIN OF TIO_FIFO : COMPONENT IS "rst,wr_clk,rd_clk,din[7:0],wr_en,rd_en,dout[7:0],full,empty,prog_full";


type TRIG_STATE is (TRIG_START, TRIG_CHK_STABLE, TRIG_NEXT_DLY, TRIG_CHK_DLY, TRIG_RESTART, TRIG_SET_DLY, TRIG_ALIGN, TRIG_DONE);
signal TrigState : TRIG_STATE;

signal TRIG_100MHZ    : std_logic;
signal TRIG_200MHZ    : std_logic;
signal TRIG_400MHZ    : std_logic;

signal TRGCLK_IN     : std_logic;
signal TRGCLK_IN_DLY : std_logic;
signal TRGCLK_IN_O   : std_logic;
signal TRGDAT_IN     : std_logic;
signal TRGDAT_IN_DLY : std_logic;
signal SerClk       : std_logic_vector(7 downto 0);
signal PrevClk      : std_logic_vector(7 downto 0);
signal FirstClk     : std_logic_vector(7 downto 0);
signal SerDat       : std_logic_vector(7 downto 0);
signal TrigDat      : std_logic_vector(7 downto 0);
signal TrigLocked   : std_logic;
signal sTrigLocked   : std_logic;
signal DelayReady   : std_logic;
signal FirstFound   : std_logic;
signal DlyVal       : std_logic_vector(5 downto 0);
signal DlyDiff      : std_logic_vector(5 downto 0);
signal DlySum       : std_logic_vector(5 downto 0);
signal FirstDly     : std_logic_vector(5 downto 0);
signal CurDly       : std_logic_vector(4 downto 0);
signal StableCnt    : std_logic_vector(4 downto 0);
signal DbgTrigState : std_logic_vector(2 downto 0);
signal TrigRst      : std_logic;
signal BitSlip      : std_logic;
signal TrigErr      : std_logic;
signal sTrigErr     : std_logic;
signal TrigFull     : std_logic;
signal TrigValid    : std_logic;
signal TrigDone     : std_logic;
signal TrigEmpty    : std_logic;
signal sTrigDone    : std_logic;
signal sTRIG_OVFL   : std_logic;
signal TrigOvfl     : std_logic;
signal SlipCnt      : std_logic_vector(3 downto 0);

signal DataA : std_logic_vector(7 downto 0);
signal DataB : std_logic_vector(7 downto 0);
signal ClkA  : std_logic_vector(7 downto 0);
signal ClkB  : std_logic_vector(7 downto 0);
signal SlipData : std_logic_vector(7 downto 0);
signal SlipClk : std_logic_vector(7 downto 0);

attribute MARK_DEBUG : string;
attribute MARK_DEBUG of SerClk : signal is "true";
attribute MARK_DEBUG of CurDly : signal is "true";
attribute MARK_DEBUG of TrigLocked : signal is "true";
attribute MARK_DEBUG of DlyVal : signal is "true";
attribute MARK_DEBUG of DbgTrigState : signal is "true";
attribute MARK_DEBUG of SerDat : signal is "true";

begin

  DbgTrigState <= "000" when TrigState = TRIG_START
             else "001" when TrigState = TRIG_CHK_STABLE
             else "010" when TrigState = TRIG_NEXT_DLY
             else "011" when TrigState = TRIG_CHK_DLY
             else "100" when TrigState = TRIG_RESTART
             else "101" when TrigState = TRIG_SET_DLY
             else "110" when TrigState = TRIG_ALIGN
             else "111" when TrigState = TRIG_DONE
             else "000";


  -- Locked and alined when you are in the done state
  process(USER_CLK, RESET)
  begin
    if RESET = '1' then
      sTrigDone <= '0';
      TRIG_LOCKED <= '0';
      sTrigErr <= '0';
      TRIG_ERR <= '0';
      TRIG_OVFL <= '0';
      sTRIG_OVFL <= '0';
    elsif rising_edgE(USER_CLK) then
      -- Double synchronized lock state, set when the receiver is ready to receive triggesrs
      sTrigDone <= TrigDone;
      TRIG_LOCKED <= sTrigDone;

      -- Double synchronized error state, set when invlaid clock pattern received after initial lock
      sTrigErr <= TrigErr;
      TRIG_ERR <= sTrigErr;

      -- Double synchronized overflow flag, set when trigger receive FIFO overflows because not read fast enough by user
      sTRIG_OVFL <= TrigOvfl;
      TRIG_OVFL <= sTRIG_OVFL;
    end if;

  end process;

  -- Trigger 1 Received Clock
  BTC1 : IBUFDS
  generic map
  (
    DIFF_TERM => TRUE, -- Differential Termination
    IBUF_LOW_PWR => FALSE -- Low power (TRUE) vs. performance (FALSE) setting for refernced I/O standards
  )
  port map
  (
    O  => TRGCLK_IN,  -- Buffer output
    I  => TRIG_CLKP, -- Diff_p buffer input (connect directly to top-level port)
    IB => TRIG_CLKN  -- Diff_n buffer input (connect directly to top-level port)
  );

  -- Trigger 1 Received Data
  BTD1 : IBUFDS
  generic map
  (
    DIFF_TERM => TRUE, -- Differential Termination
    IBUF_LOW_PWR => FALSE -- Low power (TRUE) vs. performance (FALSE) setting for refernced I/O standards
  )
  port map
  (
    O  => TRGDAT_IN,  -- Buffer output
    I  => TRIG_DATP, -- Diff_p buffer input (connect directly to top-level port)
    IB => TRIG_DATN  -- Diff_n buffer input (connect directly to top-level port)
  );

  -- Generate data receive clocks from the external 100 MHz trigger clock.
  CK1 : TRIG_MMCM
  port map
  (
    CLK_100MHZ_IN  => TRGCLK_IN_O,  -- From undelayed output of Trigger Clock ISERDES

    -- Clock out ports
    TRIG_100MHZ    => TRIG_100MHZ,  -- Parallel trigger clock
    TRIG_400MHZ    => TRIG_400MHZ,  -- DDR Data output clock

    -- Status and control signals
    RESET          => not DelayReady,  -- Ignore external clock until input delay is calibrated.  IDELAYCTRL reset by RESET
    LOCKED         => TrigLocked
  );

  -- Define input delay related logic
  IDC1 : IDELAYCTRL
  port map
  (
    RDY => DelayReady,
    REFCLK => CLK_200MHZ, -- 1-bit input: Reference clock input
    RST => RESET -- 1-bit input: Active high reset input
  );

  -- Delay for serial clock input
  ID1 : IDELAYE2
  generic map
  (
    CINVCTRL_SEL          => "FALSE",   -- Enable dynamic clock inversion (FALSE, TRUE)
    DELAY_SRC             => "IDATAIN", -- Delay input (IDATAIN, DATAIN)
    HIGH_PERFORMANCE_MODE => "TRUE",    -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
    IDELAY_TYPE           => "VAR_LOAD",-- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
    IDELAY_VALUE          => 0,         -- Input delay tap setting (0-31)
    PIPE_SEL              => "FALSE",   -- Select pipelined mode, FALSE, TRUE
    REFCLK_FREQUENCY      => 200.0,     -- IDELAYCTRL clock input frequency in MHz (190.0-210.0).
    SIGNAL_PATTERN        => "DATA"     -- DATA, CLOCK input signal
  )
  port map
  (
    CNTVALUEOUT   => CurDly,        -- 5-bit output: Counter value output
    DATAOUT       => TRGCLK_IN_DLY, -- 1-bit output: Delayed data output
    C             => TRIG_100MHZ,   -- Must be same as CLKDIV
    CE            => '0',           -- 1-bit input: Active high enable increment/decrement input
    CINVCTRL      => '0',           -- 1-bit input: Dynamic clock inversion input
    CNTVALUEIN    => DlyVal(4 downto 0), -- 5-bit input: Counter value input
    DATAIN        => '0',           -- 1-bit input: Internal delay data input
    IDATAIN       => TRGCLK_IN,     -- 1-bit input: Data input from the I/O
    INC           => '0',           -- 1-bit input: Increment / Decrement tap delay input
    LD            => '1',           -- 1-bit input: Load IDELAY_VALUE input
    LDPIPEEN      => '0',           -- 1-bit input: Enable PIPELINE register to load data input
    REGRST        => not TrigLocked
  );

  -- Delay for serial data input
  ID2 : IDELAYE2
  generic map
  (
    CINVCTRL_SEL          => "FALSE",   -- Enable dynamic clock inversion (FALSE, TRUE)
    DELAY_SRC             => "IDATAIN", -- Delay input (IDATAIN, DATAIN)
    HIGH_PERFORMANCE_MODE => "TRUE",    -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
    IDELAY_TYPE           => "VAR_LOAD",-- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
    IDELAY_VALUE          => 0,         -- Input delay tap setting (0-31)
    PIPE_SEL              => "FALSE",   -- Select pipelined mode, FALSE, TRUE
    REFCLK_FREQUENCY      => 200.0,     -- IDELAYCTRL clock input frequency in MHz (190.0-210.0).
    SIGNAL_PATTERN        => "DATA"     -- DATA, CLOCK input signal
  )
  port map
  (
    CNTVALUEOUT   => open ,         -- 5-bit output: Counter value output
    DATAOUT       => TRGDAT_IN_DLY, -- 1-bit output: Delayed data output
    C             => TRIG_100MHZ,   -- Must be same as CLKDIV
    CE            => '0',        -- 1-bit input: Active high enable increment/decrement input
    CINVCTRL      => '0',           -- 1-bit input: Dynamic clock inversion input
    CNTVALUEIN    => DlyVal(4 downto 0), -- 5-bit input: Counter value input
    DATAIN        => '0',           -- 1-bit input: Internal delay data input
    IDATAIN       => TRGDAT_IN,     -- 1-bit input: Data input from the I/O
    INC           => '0',           -- 1-bit input: Increment / Decrement tap delay input
    LD            => '1',           -- 1-bit input: Load IDELAY_VALUE input
    LDPIPEEN      => '0',           -- 1-bit input: Enable PIPELINE register to load data input
    REGRST        => not TrigLocked
  );

  -- Deserialize received clock
  SIN1 : ISERDESE2
  generic map
  (
    DATA_RATE         => "DDR",        -- DDR, SDR
    DYN_CLKDIV_INV_EN => "FALSE",      -- Enable DYNCLKDIVINVSEL inversion (FALSE, TRUE)
    DYN_CLK_INV_EN    => "FALSE",      -- Enable DYNCLKINVSEL inversion (FALSE, TRUE)
    INIT_Q1           => '0',          -- INIT_Q1 - INIT_Q4: Initial value on the Q outputs (0/1)
    INIT_Q2           => '0',
    INIT_Q3           => '0',
    INIT_Q4           => '0',
    INTERFACE_TYPE    => "NETWORKING", -- MEMORY, MEMORY_DDR3, MEMORY_QDR, NETWORKING, OVERSAMPLE
    IOBDELAY          => "IFD",       -- NONE, BOTH, IBUF, IFD
    NUM_CE            => 1,            -- Number of clock enables (1,2)
    OFB_USED          => "FALSE",      -- Select OFB path (FALSE, TRUE)
    SERDES_MODE       => "MASTER",     -- MASTER, SLAVE
    SRVAL_Q1 => '0',                   -- SRVAL_Q1 - SRVAL_Q4: Q output values when SR is used (0/1)
    SRVAL_Q2 => '0',
    SRVAL_Q3 => '0',
    SRVAL_Q4 => '0'
  )
  port map
  (
    O            => TRGCLK_IN_O, -- Udelayed clock to MMCM
    Q1           => SerClk(0),
    Q2           => SerClk(1),
    Q3           => SerClk(2),
    Q4           => SerClk(3),
    Q5           => SerClk(4),
    Q6           => SerClk(5),
    Q7           => SerClk(6),
    Q8           => SerClk(7),
    SHIFTOUT1    => open ,
    SHIFTOUT2    => open ,
    BITSLIP      => '0', -- Not used since it does not function as expected
    CE1          => '1',
    CE2          => '1',
    CLKDIVP      => '0' ,
    CLK          => TRIG_400MHZ, -- DDR clock
    CLKB         => not TRIG_400MHZ,
    CLKDIV       => TRIG_100MHZ, -- Parallel Data Clock
    OCLK         => '0' ,
    DYNCLKDIVSEL => '0',
    DYNCLKSEL    => '0',
    D            => TRGCLK_IN,  -- Direct Data input
    DDLY         => TRGCLK_IN_DLY , -- Data from input delay
    OFB          => '0' ,
    OCLKB        => '0' ,
    RST          => not TrigLocked,
    SHIFTIN1     => '0' ,
    SHIFTIN2     => '0'
  );

  -- Deserialize received data
  SIN2 : ISERDESE2
  generic map
  (
    DATA_RATE         => "DDR",        -- DDR, SDR
    DYN_CLKDIV_INV_EN => "FALSE",      -- Enable DYNCLKDIVINVSEL inversion (FALSE, TRUE)
    DYN_CLK_INV_EN    => "FALSE",      -- Enable DYNCLKINVSEL inversion (FALSE, TRUE)
    INIT_Q1           => '0',          -- INIT_Q1 - INIT_Q4: Initial value on the Q outputs (0/1)
    INIT_Q2           => '0',
    INIT_Q3           => '0',
    INIT_Q4           => '0',
    INTERFACE_TYPE    => "NETWORKING", -- MEMORY, MEMORY_DDR3, MEMORY_QDR, NETWORKING, OVERSAMPLE
    IOBDELAY          => "IFD",        -- NONE, BOTH, IBUF, IFD
    NUM_CE            => 1,            -- Number of clock enables (1,2)
    OFB_USED          => "FALSE",      -- Select OFB path (FALSE, TRUE)
    SERDES_MODE       => "MASTER",     -- MASTER, SLAVE
    SRVAL_Q1 => '0',                   -- SRVAL_Q1 - SRVAL_Q4: Q output values when SR is used (0/1)
    SRVAL_Q2 => '0',
    SRVAL_Q3 => '0',
    SRVAL_Q4 => '0'
  )
  port map
  (
    O            => open,  -- 1-bit output: Combinatorial output
    Q1           => SerDat(0),
    Q2           => SerDat(1),
    Q3           => SerDat(2),
    Q4           => SerDat(3),
    Q5           => SerDat(4),
    Q6           => SerDat(5),
    Q7           => SerDat(6),
    Q8           => SerDat(7),
    SHIFTOUT1    => open ,
    SHIFTOUT2    => open ,
    BITSLIP      => '0', -- Not used since it does not function as expected
    CE1          => '1',
    CE2          => '1',
    CLKDIVP      => '0' ,
    CLK          => TRIG_400MHZ, -- DDR clock
    CLKB         => not TRIG_400MHZ,
    CLKDIV       => TRIG_100MHZ, -- Parallel Data Clock
    OCLK         => '0' ,
    DYNCLKDIVSEL => '0',
    DYNCLKSEL    => '0',
    D            => TRGDAT_IN,  -- Direct Data input
    DDLY         => TRGDAT_IN_DLY , -- Data from input delay
    OFB          => '0' ,
    OCLKB        => '0' ,
    RST          => not TrigLocked,
    SHIFTIN1     => '0' ,
    SHIFTIN2     => '0'
  );


  -- Sync the reset before using it to reset the trigger state machine
  process(TRIG_100MHZ)
  begin
    if rising_edge(TRIG_100MHZ) then
      TrigRst <= RESET or (not TrigLocked);
    end if;
  end process;

  -- Clock alignment state machine
  process(TRIG_100MHZ, TrigRst)
  begin
    if TrigRst = '1' then
      DlyVal <= "000000";
      DlyDiff <= "000000";
      DlySum <= "000000";
      TrigState <= TRIG_START;
      StableCnt <= "00000";
      PrevClk <= (others => '0');
      FirstFound <= '0';
      FirstDly <= "000000";
      FirstClk <= "00000000";
      BitSlip <= '0';
      TrigErr <= '0';
      TrigOvfl <= '0';
      TrigValid <= '0';
      TrigDat <= "00000000";
      TrigDone <= '0';
      SlipCnt <= "0000";
      DataA <= x"00";
      DataB <= x"00";
      ClkA <= x"00";
      ClkB <= x"00";
      SlipData <= x"00";
      SlipClk <= x"00";
    elsif rising_edge(TRIG_100MHZ) then
      -- Increment stable counter by default
      StableCnt <= StableCnt + 1;

      if BitSlip = '1' then
        SlipCnt <= SlipCnt + 1;
      end if;

      -- ISERDES2 Bitslip doesn't seem to work for DDR 8:1, so do the slip in logic
      DataA <= SerDat;
      DataB <= DataA;

      case SlipCnt(2 downto 0) is
        when "000" => SlipData <= DataB(7 downto 0);
        when "001" => SlipData <= DataB(6 downto 0) & DataA(7);          
        when "010" => SlipData <= DataB(5 downto 0) & DataA(7 downto 6); 
        when "011" => SlipData <= DataB(4 downto 0) & DataA(7 downto 5); 
        when "100" => SlipData <= DataB(3 downto 0) & DataA(7 downto 4); 
        when "101" => SlipData <= DataB(2 downto 0) & DataA(7 downto 3); 
        when "110" => SlipData <= DataB(1 downto 0) & DataA(7 downto 2); 
        when "111" => SlipData <= DataB(0)          & DataA(7 downto 1); 
      end case;
      
      ClkA <= SerClk;
      ClkB <= ClkA;
  
      case SlipCnt(2 downto 0) is
        when "000" => SlipClk <= ClkB(7 downto 0);                    
        when "001" => SlipClk <= ClkB(6 downto 0) & ClkA(7);         
        when "010" => SlipClk <= ClkB(5 downto 0) & ClkA(7 downto 6);
        when "011" => SlipClk <= ClkB(4 downto 0) & ClkA(7 downto 5);
        when "100" => SlipClk <= ClkB(3 downto 0) & ClkA(7 downto 4);
        when "101" => SlipClk <= ClkB(2 downto 0) & ClkA(7 downto 3);
        when "110" => SlipClk <= ClkB(1 downto 0) & ClkA(7 downto 2);
        when "111" => SlipClk <= ClkB(0)          & ClkA(7 downto 1);
      end case;

      -- Calculate difference between current tap setting and start of stable region
      DlyDiff <= DlyVal - FirstDly;

      -- Calculate sum of current tap setting and start of stable region to allow finding mid point
      DlySum <= DlyVal + FirstDly;

      case TrigState is
        when TRIG_START =>
          -- Cleared in case of restart for debugging
          TrigErr <= '0';
          TrigDone <= '0';
          TrigOvfl <= '0';
          TrigValid <= '0';

          -- Wait for 16 counts before proceeding
          if StableCnt(4) = '1' then
            StableCnt(4) <= '0';
            PrevClk <= SerClk;  -- Remember starting value for stability test
            TrigState <= TRIG_CHK_STABLE;
          end if;


        when TRIG_CHK_STABLE =>
          -- You may get a difference before the StableCnt reaches 16, but since the required setup and hold
          -- times are so short, it is likely that you will always get stable values for all delay settings.
          if PrevClk /= SerClk then
            if FirstFound = '1' then
              -- At the end of a stable section, check to see if you have found a wide stable set of taps
              TrigState <= TRIG_CHK_DLY;
            else
              -- Haven't found a stable delay so advance the delay and try again
              TrigState <= TRIG_NEXT_DLY;
            end if;
          else
            -- 16 clocks with the same SerClk value, so remember the start of the stable region
            -- Note that this ignores the PrevClk comparison on the last pass of the loop.
            -- Leave StableCnt(4) set to indicate stable delay found for TRIG_CHK_DLY
            if StableCnt(4) = '1' then
              if FirstFound = '0' then
                -- Save the first stable delay tap value and received clock value
                FirstDly <= DlyVal;
                FirstClk <= SerClk;
                FirstFound <= '1';
                TrigState <= TRIG_NEXT_DLY;  -- Check for more consecutive stable delays
              else
                if SerClk = FirstClk then
                  -- Still in the same initial stable portion, so keep advancing
                  TrigState <= TRIG_NEXT_DLY;
                else
                  -- If you have a new stable value, check to see if you have found a wide stable set of taps
                  TrigState <= TRIG_CHK_DLY;
                end if;
              end if;
            end if;
          end if;


        when TRIG_NEXT_DLY =>
          -- Increment the tap and wait 16 clocks before testing stability again
          DlyVal(4 downto 0) <= DlyVal(4 downto 0) + 1;
          StableCnt <= "00000";  -- 16 clocks for the delay and DDR regiters to update
          TrigState <= TRIG_START;


        when TRIG_CHK_DLY =>
          -- This state is entered either when a non-stable tap is found after finding a stable tap,
          -- or when a stable value that is different than the first stable value is found.
          -- Check if the difference between the first stable tap and the current tap is at least 14
          -- and then use the middle of the tap as the delay setting if it is.
          -- If StableCnt(4) is set, then you had a new astable value, otherwise, you found an unstable value
          -- This state is only entered if FirstFound is true.

          if DlyDiff(4 downto 0) > 13 then
            -- If you find a stable stretch 14 or longer, then set the delay in the middle of it
            TrigState <= TRIG_SET_DLY;
          else
            if StableCnt(4) = '1' then
              -- A short stable section was found, so restart at the current position, which is the start of a new stable section
              TrigState <= TRIG_RESTART;
            else
              -- Start looking for a new starting stable point, since now unstable and previous stable was not 14 or more wide
              FirstFound <= '0';
              TrigState <= TRIG_NEXT_DLY;
            end if;
          end if;


        when TRIG_RESTART =>
          -- Change the starting point to the current clock and delay vlaue
          -- Note that FirstFound remains set, only the starting point changes
          -- Go through TRIG_START to reset the PrevClk to the current clock value
          FirstDly <= DlyVal;
          FirstClk <= SerClk;
          TrigState <= TRIG_START;


        when TRIG_SET_DLY =>
          -- Set the delay to the average of the fisrt stable and current unstable delays
          DlyVal(4 downto 0) <= DlySum(5 downto 1);
          StableCnt <= (others => '0');
          TrigState <= TRIG_ALIGN;


        when TRIG_ALIGN =>
          -- Keep shifting the bits by one clock until the clock is 0xF0 in order to align the data
          BitSlip <= '0';

          if StableCnt(4) = '1' then
            StableCnt(4) <= '0';

            if SlipClk /= x"F0" then
              BitSlip <= '1';
            else
              TrigDone <= '1';         -- Single bit to sync for the TRIG_LOCKED output
              TrigState <= TRIG_DONE;
            end if;

            -- Retry if no alignment after 8 slips            
            if SlipCnt(3) = '1' then
              SlipCnt(3) <= '0';
              FirstFound <= '0';
              BitSlip <= '0';
              TrigState <= TRIG_START;
            end if;
          end if;


        when TRIG_DONE =>
          -- Set an error flag if you ever receive anything other than an aligned clock on the clock input
          -- This is an indication of noise and/or poor alignment on the serial clock input.
          if SlipClk /= x"F0" then
            TrigErr <= '1';
          end if;

          TrigDat <= SlipData;  -- Save data for possible FIFO write

          -- Write non-zero value to the trigger receive FIFO
          if SlipData /= 0 then
            if TrigFull = '0' then
              TrigValid <= '1';   -- Enable write in next cycle
            else
              TrigValid <= '0';   -- No write since FIFO Full
              TrigOvfl <= '1';
            end if;
          else
            TrigValid <= '0';   -- No write since zero value received
          end if;
      end case;

    end if;
  end process;


  TFFI : TIO_FIFO
  port map
  (
    rst         => not TrigDone,  -- Only enable FIFO once you have locked onto the incoming clock
    wr_clk      => TRIG_100MHZ,
    rd_clk      => USER_CLK,
    din         => TrigDat,
    wr_en       => TrigValid,
    rd_en       => TRIG_NEXT,
    dout        => TRIG_RX,
    full        => TrigFull ,
    empty       => TrigEmpty,
    prog_full   => open
  );

  TRIG_READY <= not TrigEmpty;

end behavior;




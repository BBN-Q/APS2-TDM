library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PWMA8 is
port
(
   CLK : in std_logic;
   RESET : in std_logic;
   DIN : in std_logic_vector (7 downto 0) := "00000000";
   PWM_OUT : out std_logic
);
end PWMA8;

architecture behavior of PWMA8 is

signal  PWM_Accumulator : std_logic_vector(8 downto 0);

begin

  process(CLK, RESET)
  begin
    if RESET = '1' then
      PWM_Accumulator <= (others => '0');
    elsif rising_edge(CLK) then
      PWM_Accumulator  <=  ("0" & PWM_Accumulator(7 downto 0)) + ("0" & DIN);
    end if;
  end process;

  PWM_OUT <= PWM_Accumulator(8);

end behavior;

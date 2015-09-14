----
-- Original authors: Blake Johnson and Colm Ryan
-- Copyright 2015, Raytheon BBN Technologies
--
-- InternalTrig module
--
-- Produce trigger signal on a counter or from a command.
----

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

entity InternalTrig is
	port (
		--Resets
		RESET : in std_logic;

		--Clocks
		CLK : in std_logic;

		--trigger params
		triggerInterval : in std_logic_vector(31 downto 0);
		triggerSource : in std_logic;
		softTrigToggle : in std_logic;

		--ouput
		trigger : out std_logic
	);

end entity ; -- InternalTrig

architecture arch of InternalTrig is

signal loadInternalTrigger : std_logic := '0';
signal internalTrig, softwareTrig: std_logic := '0';

signal softTrigToggle_d : std_logic := '0';

begin

-- INTERNAL TRIGGER --

--Downcounter for internal trigger
triggerCounter : process( CLK )
	variable c : unsigned(32 downto 0); -- one extra bit to catch underflow
begin
	if rising_edge(CLK) then
		internalTrig <= '0';
		if RESET = '1' then
			c := resize(unsigned(triggerInterval), c'length) - 2;
		else
			if c(c'high) = '1' then
				internalTrig <= '1';
				c := resize(unsigned(triggerInterval), c'length) - 2;
			else
				c := c - 1;
			end if;
		end if ;		
	end if ;
end process ; -- triggerCounter

-- SOFTWARE TRIGGER --

--The user toggles the trigger line so simple edge detection
catchSoftwareTrigger : process( CLK )
begin
	if rising_edge(CLK) then
		softTrigToggle_d <= softTrigToggle;
		if ((softTrigToggle xor softTrigToggle_d)  = '1') then
			softwareTrig <= '1';
		else
			softwareTrig <= '0';
		end if;
	end if ;
end process ; -- catchSoftwareTrigger

-- Mux INTERNAL / EXTERNAL / SOFTWARE triggers --
with triggerSource select trigger <=
	internalTrig when '0',
	softwareTrig when '1',
	'0' when others;

end architecture ; -- arch

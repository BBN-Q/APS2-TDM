--APS2 Constants

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;


package ATMConstants is

	-----------------------------------------------------
	--Sort out whether we are in simulation or synthesis and switch constant values appropriately.
	-----------------------------------------------------
	constant in_simulation : boolean := false
	--pragma synthesis_off
	                                    or true
	--pragma synthesis_on
	;
	constant in_synthesis : boolean := not in_simulation;	

	---------------------------------------------------------------- 
    -- Function to select one or the other based on a boolean
    -- Analogous to the C statement x = Cond ? a : b 
    -- Modified from https://groups.google.com/forum/#!topic/comp.lang.vhdl/9I5CO5eaCbE
    ---------------------------------------------------------------- 
    function sel(cond : boolean; ifTrue : integer; ifFalse: integer) return integer; 

    ------------------------------------------------------
    -- Firmware version reported to user
    ------------------------------------------------------

	constant USER_VERSION : std_logic_vector(31 downto 0) := x"00000009";

    --CSR register read / write directions
    type CSR_ARRAY_t is array(natural range <>) of natural;

    constant CSR_READ_REGS : CSR_ARRAY_t(0 to 1) := (1, 5);
    constant CSR_WRITE_REGS : CSR_ARRAY_t(0 to 3) := (0, 2, 3, 4);
    type CSR_ARRAY_INIT_t is array(natural range <>) of std_logic_vector(31 downto 0);
    constant CSR_WRITE_REGS_INIT : CSR_ARRAY_INIT_t(0 to 3) := (0 => x"00000001", others => x"00000000");

end ATMConstants;


package body ATMConstants is

    function sel(cond : boolean; ifTrue : integer; ifFalse: integer) return integer is 
    begin 
        if cond then 
            return(ifTrue); 
        else 
            return(ifFalse); 
        end if; 
    end function sel; 


end ATMConstants;
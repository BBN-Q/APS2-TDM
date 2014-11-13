library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use std.textio.all;
use IEEE.std_logic_textio.all;

package FileIO is

	type DataArray_t is array(integer range <>) of std_logic_vector(31 downto 0);
	type SeqArray_t is array(integer range <>) of std_logic_vector(63 downto 0);

	impure function read_wf_file(fileName : string ) return DataArray_t;
	impure function read_seq_file(fileName : string ) return DataArray_t;
	impure function read_seq_file(fileName : string ) return SeqArray_t;
	impure function num_lines(fileName : string) return natural;

end FileIO;

package body FileIO is 

impure function read_wf_file(fileName : string ) return DataArray_t is
	--Read a waveform file into an array  
	--Expects a single signed 16 bit integer on each line
	--Will pack into an array of 32 bit words
	variable numLines : natural := num_lines(fileName);
	variable dataArray : DataArray_t(0 to numLines/2-1);
	file FID : text;
	variable ln : line;
	variable a,b : integer;
	variable ct : natural := 0;
	variable upperWord, lowerWord : std_logic_vector(15 downto 0) ;
	begin

		file_open(FID, fileName, read_mode);

		lineReading : while not endfile(FID) loop
			readline(FID, ln);
			read(ln, a);
			readline(FID, ln);
			read(ln, b);
			dataArray(ct) := std_logic_vector(to_signed(b, 16)) & std_logic_vector(to_signed(a, 16));
			ct := ct + 1;
		end loop lineReading;
		file_close(FID);
		return dataArray;
end read_wf_file;

impure function read_seq_file(fileName : string) return DataArray_t is
	--Read a sequence file into an array.
	--Expects 1 64bit entry per line as a hex string
	--Will parse it into 2 32bit entries and pad a zero word at the top word

	variable numLines : natural := num_lines(fileName);
	variable dataArray : DataArray_t(0 to 2*numLines-1);
	file FID : text;
	variable ln : line;
	variable seqWord : std_logic_vector(63 downto 0) ;
	variable ct : natural := 0;
	begin
		file_open(FID, fileName, read_mode);

		lineReading : while not endfile(FID) loop
			readline(FID, ln);
			hread(ln, seqWord);
			for wordct in 1 to 2 loop
				dataArray(ct) := seqWord(wordct*32-1 downto (wordct-1)*32);
				ct := ct + 1;
			end loop;
		end loop lineReading;
		file_close(FID);
		return dataArray;
end read_seq_file;

impure function read_seq_file(fileName : string) return SeqArray_t is
	--Read a sequence file into an array.
	--Expects 1 64bit entry per line as a hex string

	variable numLines : natural := num_lines(fileName);
	variable dataArray : SeqArray_t(0 to numLines-1);
	file FID : text;
	variable ln : line;
	variable seqWord : std_logic_vector(63 downto 0) ;
	variable ct : natural := 0;
	begin
		file_open(FID, fileName, read_mode);

		lineReading : while not endfile(FID) loop
			readline(FID, ln);
			hread(ln, dataArray(ct));
			ct := ct + 1;
		end loop lineReading;
		file_close(FID);
		return dataArray;
end read_seq_file;

impure function num_lines(fileName : string) return natural is
	--Helper function to count the number of lines in a file
	variable linect : natural := 0;
	file FID : text;
    variable ln : line;

	begin
		file_open(FID, fileName, read_mode);
		lineReading : while not endfile(FID) loop
		    readline(FID, ln);
			linect := linect + 1;
		end loop lineReading;
		file_close(FID);
	return linect;
end num_lines;


end package body; -- FileIO 
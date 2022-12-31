library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library uart_lib;
  use uart_lib.uart_pkg.all;

entity commonCathodSevenSeg is
  port (
  	binNumIn           : in  std_logic_vector(3 downto 0);
  	sevenSegDisplayOut : out std_logic_vector(6 downto 0));
end entity commonCathodSevenSeg;

architecture behave of commonCathodSevenSeg is 
  signal sevenSeg : std_logic_vector(6 downto 0);
begin

 sevenSegDisplayOut <= sevenSeg;

  process (binNumIn)
  begin
    case  binNumIn is
      when X"0" =>
       sevenSeg <= "1000000";
      when X"1" =>
        sevenSeg <= "1111001";
      when X"2" =>
        sevenSeg <= "0100100";
      when X"3" =>
        sevenSeg <= "0110000";
      when X"4" =>
        sevenSeg <= "0011001";
      when X"5" =>
        sevenSeg <= "0010010";
      when X"6" =>
        sevenSeg <= "0000010";
      when X"7" =>
        sevenSeg <= "1111000";
      when X"8" =>
        sevenSeg <= "0000000";
      when X"9" =>
        sevenSeg <= "0010000";
      when others =>
        sevenSeg <= "0111111";
       NULL;
        NULL;
    end case;
  end process;

end architecture behave;
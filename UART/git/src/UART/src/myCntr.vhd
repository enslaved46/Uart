library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library uart_lib;
  use uart_lib.uart_pkg.all;
entity mYCntr is
  generic (
    FREQUENCY_REQ   : integer;
    CLK_FREQ        : real;
    SAMPLING_RATE   : positive);
  port (
    sysClkIn         : in   std_logic;
    sysRstIn         : in   std_logic;
    enCntrIn         : in   std_logic;
    cntrDnePulseOut  : out  std_logic);

end entity mYCntr;

architecture rtl of mYCntr is
  constant MAX_CNTR      : integer := integer(CLK_FREQ)/(FREQUENCY_REQ * SAMPLING_RATE);
  signal   cntrValR      : unsigned (log2Fn(MAX_CNTR) -1 downto 0 );
  signal   cntrDnePulseR : std_logic;
  
begin
  cntrDnePulseOut <= cntrDnePulseR;

  pulseGenProc : process (sysClkIn)
  begin
    if(rising_edge(sysClkIn)) then
      if(sysRstIn /= '1') then
        cntrValR <= (others => '0');
        cntrDnePulseR <= '0';
      elsif (enCntrIn = '1') then
        cntrDnePulseR <= '0';
        if(cntrValR = MAX_CNTR -1 ) then
          cntrDnePulseR <= '1';
          cntrValR <= (others => '0');
        else
          cntrValR <= cntrValR +1;
        end if;
      else 
        cntrValR <= (others => '0');
      end if;
    end if;
  end process pulseGenProc;
end architecture rtl;
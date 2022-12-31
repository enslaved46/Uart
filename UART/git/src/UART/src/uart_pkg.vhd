library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

package uart_pkg is
  constant UART_PKT_SIZE             : positive  := 11;
  constant START_BIT                 : std_logic := '0';
  constant STOP_BIT                  : std_logic := '1';
  constant UART_RX_OVR_SAMPLING_RATE : positive  := 16;
  CONSTANT SYS_CLK_FREQ              : real      := 100.0e6;
  CONSTANT BAUD_RATE                 : positive  := 115200;
  
  function log2Fn (x : positive) return natural;
  function chkParity (dataIn : std_logic_vector) return std_logic;
  function createUartTxPkt (dataIn : std_logic_vector; parityBit : std_logic) return std_logic_vector;
end package uart_pkg ;

package body uart_pkg is
  function log2Fn (x : positive) return natural is
    variable i : natural;
   begin
      i := 0;  
      while (2**i < x) and i < 31 loop
         i := i + 1;
      end loop;
      return i;
   end function;

  function chkParity (dataIn : std_logic_vector) return std_logic is
    variable parityVar : std_logic := '0';
   begin
     for i in 0 to dataIn'length-1 loop
       parityVar := parityVar xor dataIn(i);
     end loop;
     return parityVar;
   end function;

   function createUartTxPkt (dataIn : std_logic_vector;
                             parityBit : std_logic) return std_logic_vector  is
     variable txPacketVar     : std_logic_vector( 0 to UART_PKT_SIZE -1 ) := (others => '0');
     variable changeEndianVar : std_logic_vector( 0 to 7) := (others => '0');
   begin
     for i in dataIn'range loop
       changeEndianVar(i) := dataIn(i);
     end loop;
     txPacketVar := START_BIT & changeEndianVar & parityBit & STOP_BIT;
     -- txPacketVar := changeEndianVar & parityBit;
     return txPacketVar;
   end function;

end package body;
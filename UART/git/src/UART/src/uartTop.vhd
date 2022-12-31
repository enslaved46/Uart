-- Designer : Enslaved FortySixx
-- Entity : uartTop.vhd

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library uart_lib;
  use uart_lib.uart_pkg.all;

entity uartTop is
generic (
  BAUD_RATE     : integer  := BAUD_RATE;
  CLK_FREQ      : real     := SYS_CLK_FREQ);    
  port (
    sysClkIn      : in   std_logic;
    sysRstIn      : in   std_logic;
    txDataIn      : in   std_logic_vector(7 downto 0);  -- Data from FPGA Switch
    txDataRdyIn   : in   std_logic;                     -- Data RDY sig from FPGA Switch
    rxDataIn      : in   std_logic;                     -- Received Data on Receiver wire 
    txOut         : out  std_logic;                     -- TX out signal that feeds back to FPGA from USB CABLE
    pModTxOut     : out  std_logic;                     -- TX Out on a PMOD, 3.3 V
    pModTestOut   : out  std_logic;                     -- Tx Bit Period, Test Pin 
    anodeOut      : out  std_logic_vector(7 downto 0);  -- CNTRL which Segment to turn at a time
    sevnSegOut    : out  std_logic_vector(6 downto 0);  -- SEvn Seg CNtrl sig
    ledOut        : out  std_logic_vector(3 downto 0)); -- Test LED
end entity uartTop;

architecture rtl of uartTop  is
signal txSevnSegDislpayByte : std_logic_vector(7 downto 0);
signal rxSevnSegDislpayByte : std_logic_vector(7 downto 0);
signal txPushBtFilteredSig  : std_logic;
begin 
--------------------------------------------------------------------------------------------------
-- TX INST
--------------------------------------------------------------------------------------------------
  uartTxInst : entity uart_lib.uartTx(rtl)
    generic map (
      BAUD_RATE          => BAUD_RATE,
      CLK_FREQ           => CLK_FREQ,
      OVER_SAMPLING_RATE => 1)          -- NO oversampling
    port map (
      sysClkIn    => sysClkIn,
      sysRstIn    => sysRstIn,
      dataIn      => txDataIn,
      dataRdyIn   => txPushBtFilteredSig,
      txOut       => txOUt,
      txByteOut   => txSevnSegDislpayByte,
      pModTxOut   => pModTxOut,
      pModTestOut => pModTestOut,
      ledOut      => ledOut);
--------------------------------------------------------------------------------------------------
-- RX INST
--------------------------------------------------------------------------------------------------
  uartRxInst : entity uart_lib.uartRx(rtl)
    generic map (
     BAUD_RATE           => BAUD_RATE,
      CLK_FREQ           => CLK_FREQ,
      OVER_SAMPLING_RATE => UART_RX_OVR_SAMPLING_RATE)
    port map (
      sysClkIn    => sysClkIn,
      sysRstIn    => sysRstIn,
      rxDataIn    => rxDataIn,
      rxByteOut   => rxSevnSegDislpayByte);
--------------------------------------------------------------------------------------------------
-- Sevn Seg Cntrl Inst
--------------------------------------------------------------------------------------------------
  sevnSegSCntrlInst : entity uart_lib.sevenSegCntrl(rtl)
    generic map(
      REFRESH_RATE_HZ    => 1000,
      CLK_FREQ           => 100.0e6)
    port map (
      sysClkIn           => sysClkIn,
      sysRstIn           => sysRstIn,
      txTransmitedDataIn => txSevnSegDislpayByte,
      rxReceivedDataIn   => rxSevnSegDislpayByte,
      anodeOut           => anodeOut,
      sevnSegOut         => sevnSegOut);
--------------------------------------------------------------------------------------------------
-- Debounce Push Btn
--------------------------------------------------------------------------------------------------
    debouncerInst  : entity uart_lib.debouncer(rtl)
    generic map (
      HOLD_FREQUNCY      => 1.0/(10.0e-3),   -- Filter TIme is 10 ms
      CLK_FREQ           => CLK_FREQ)
    port map(
      sysClkIn           => sysClkIn,
      sysRstIn           => sysRstIn,
      pushBtnIn          => txDataRdyIn,
      filteredSignalOut  => txPushBtFilteredSig);

    
end architecture rtl;

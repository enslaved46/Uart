-- Designer : Enslaved FortySixx
-- Entity   : uartTx.Vhd
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library uart_lib;
  use uart_lib.uart_pkg.all;

entity uartTx is
  generic (
    BAUD_RATE          : integer  := 9600;
    CLK_FREQ           : real     := 100.0e6;
    OVER_SAMPLING_RATE : positive := 16);
  port (
    sysClkIn      : in   std_logic;
    sysRstIn      : in   std_logic;
    dataIn        : in   std_logic_vector(7 downto 0);
    dataRdyIn     : in   std_logic;
    txOut         : out  std_logic;
    pModTxOut     : out  std_logic;
    pModTestOut   : out  std_logic;
    txByteOut     : out  std_logic_vector(7 downto 0);
    ledOut        : out  std_logic_vector(3 downto 0));
    
end entity uartTx;

architecture rtl of uartTx is
  type TX_STATE is ( IDLE, START, TRANSMIT, STOP);
  signal txStateR          : TX_STATE;
  signal txPacketR         : std_logic_vector (7 downto 0 );
  signal enTxBaudRateR     : std_logic;
  signal txBaudRatePulseR  : std_logic;
  signal txPktSentCntr     : unsigned (log2Fn(UART_PKT_SIZE) -1 downto 0 );
  -- signal txBitPeriodCntrR  : unsigned (log2Fn(OVER_SAMPLING_RATE) -1 downto 0 );
  signal txDataR           : std_logic;
  signal txDataSentDneR    : std_logic;
  signal rstPktCntr        : std_logic;
  signal txBitPeriodR      : std_logic;
  signal ledR              : std_logic_vector (3 downto 0);
  
begin
--------------------------------------------------------------------------------------------------
-- Output Proc, Display to Sevn Seg and FPGA PIN OUT
--------------------------------------------------------------------------------------------------
  txOut       <= START_BIT when (txStateR = START) else
                 txDataR   when (txStateR = TRANSMIT) else
                 STOP_BIT;
  pModTxOut   <= START_BIT when (txStateR = START) else
                 txDataR   when (txStateR = TRANSMIT) else
                 STOP_BIT;
  pModTestOut <= txBitPeriodR; 
  ledOut      <= ledR;
  txByteOut   <= txPacketR;
  
--------------------------------------------------------------------------------------------------
-- Tx Baud Rate Generator
--------------------------------------------------------------------------------------------------  
  txBaudRateGenInst : entity uart_lib.mYCntr(rtl) 
    generic map (
      FREQUENCY_REQ   => BAUD_RATE,
      CLK_FREQ        => CLK_FREQ,
      SAMPLING_RATE   => OVER_SAMPLING_RATE)
    port map (
      sysClkIn        => sysClkIn,
      sysRstIn        => sysRstIn,
      enCntrIn        => enTxBaudRateR,
      cntrDnePulseOut => txBaudRatePulseR);

--------------------------------------------------------------------------------------------------
-- Tx Sampling Period
--------------------------------------------------------------------------------------------------
  holdTxSampleProc : process (sysClkIn)
  begin
    if(rising_edge(sysClkIn)) then
      if(sysRstIn /= '1') then
      --  txBitPeriodCntrR <= (others => '0');
        txBitPeriodR <= '0';
      elsif (txBaudRatePulseR = '1') then 
       -- if (txBitPeriodCntrR = X"F") then
       --   txBitPeriodCntrR <= (others => '0');
          txBitPeriodR <= '1';
       -- else
       --   txBitPeriodCntrR <= txBitPeriodCntrR + 1;
      --  end if;
      else 
        txBitPeriodR <= '0';
      end if;
    end if;
  end process holdTxSampleProc;
 
--------------------------------------------------------------------------------------------------
-- Send Out 
-------------------------------------------------------------------------------------------------- 
  sendPacketsProc : process (sysClkIn)
  begin
  if(rising_edge(sysClkIn)) then
    if(sysRstIn /= '1') then
      txPktSentCntr <=  (others => '0');
      txDataSentDneR <= '0';
      txDataR <= '1';
    else
      txDataSentDneR <= '0';                 -- default
      if (txStateR = TRANSMIT) then 
        if (txBitPeriodR = '1') then
          if (txPktSentCntr = X"7") then      -- end of byte
            txPktSentCntr <= (others => '0');
            txDataSentDneR <= '1';
          else
            txPktSentCntr <= txPktSentCntr + 1;
          end if;
        end if;
        txDataR <= txPacketR(to_integer(txPktSentCntr));
      end if;
    end if;
  end if;
  end process sendPacketsProc;
--------------------------------------------------------------------------------------------------
-- Tx Cntrl State Machine
--------------------------------------------------------------------------------------------------
 uartTxCntrlProc : process (sysClkIn)
  begin
    if(rising_edge(sysClkIn)) then
      if(sysRstIn /= '1') then
        enTxBaudRateR <= '0';
        txPacketR <= (others => '0');
        txStateR <= IDLE;
        ledR <= "1111";
      else
        case txStateR is
          when IDLE =>
            ledR <= "0001";
            if (dataRdyIn = '1') then
              enTxBaudRateR <= '1';
              ledR <= "0010";
            end if;
            if (txBitPeriodR  = '1') then
              txStateR <= START;
            end if;

          when START =>
            ledR <= "0011";
            txPacketR <=  dataIn;
            if (txBitPeriodR  = '1') then
              txStateR <= TRANSMIT;
            end if;

          when TRANSMIT =>
            ledR <= "0111";
            if (txDataSentDneR = '1') then
              txStateR <= STOP;
            end if;

          when STOP =>
            ledR <= "1000";
            if (txBitPeriodR  = '1') then
              txStateR <= IDLE;
              enTxBaudRateR <= '0';
            end if;

          when others =>
            ledR <= "1001";
            NULL;
        end case;
      end if;
    end if;
  end process;
end architecture rtl;
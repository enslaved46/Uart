-- Designer : Enslaved FortySixx
-- Entity  : uartRx.vhd

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library uart_lib;
  use uart_lib.uart_pkg.all;

entity uartRx is
  generic (
    BAUD_RATE          : integer  := 9600;
    CLK_FREQ           : real     := 100.0e6;
    OVER_SAMPLING_RATE : positive := 16);
  port (
    sysClkIn      : in   std_logic;
    sysRstIn      : in   std_logic;
    rxDataIn      : in   std_logic;
    rxByteOut     : out  std_logic_vector(7 downto 0)
  );
end entity uartRx;

architecture rtl of uartRx is
 -- constant OVER_SAMPLING_HALF_BIT_RATE   : integer := integer(OVER_SAMPLING_RATE/2);
 -- constant MAX_CNTR_BIT_FOR_HALF_PERIOD   : natural := log2Fn(OVER_SAMPLING_HALF_BIT_RATE);
  
  type RX_STATE_TYE is ( IDLE, DETECT_START, RECEIVE, STOP, RX_ERROR);
  signal rxStateR  : RX_STATE_TYE;

  -- signal rxHalfBitPeriodCntrR : unsigned (log2Fn(OVER_SAMPLING_HALF_BIT_RATE) -1 downto 0 );
  signal enRxBaudRateR           : std_logic;
  signal rx16xClkEnPulse         : std_logic;
  signal rxOne16thBitPeriodCntrR : unsigned (log2Fn(OVER_SAMPLING_RATE) -1 downto 0 );
  signal rxBitPeriodR            : std_logic; 
  signal rxMidBitPeriodR         : std_logic; 
  signal rxReceivedByteR         : std_logic_vector (7 downto 0 );
  signal rxReceivedBitCntR       : unsigned(2 downto 0);
  signal rxDataSync1R            : std_logic;
  signal rxDataSync2R            : std_logic;
  signal captureRxFallingEdge    : std_logic;
  
begin
--------------------------------------------------------------------------------------------------
-- Output Proc, Display this to Sevn Seg
--------------------------------------------------------------------------------------------------
  rxByteOut <= rxReceivedByteR;

--------------------------------------------------------------------------------------------------
-- Baud Rate Generator Cntr Inst
--------------------------------------------------------------------------------------------------
  rxBaudRateGenInst : entity uart_lib.mYCntr(rtl) 
    generic map (
      FREQUENCY_REQ   => BAUD_RATE,
      CLK_FREQ        => CLK_FREQ,
      SAMPLING_RATE   => OVER_SAMPLING_RATE)
    port map (
      sysClkIn        => sysClkIn,
      sysRstIn        => sysRstIn,
      enCntrIn        => enRxBaudRateR,
      cntrDnePulseOut => rx16xClkEnPulse);

--------------------------------------------------------------------------------------------------
-- Create BitPeriod And MidBit Period to sample incomming Rx Sample
--------------------------------------------------------------------------------------------------
  holdRxSampleProc : process (sysClkIn)
  begin
    if(rising_edge(sysClkIn)) then
      if(enRxBaudRateR /= '1') then
        rxOne16thBitPeriodCntrR <= (others => '0');
        rxBitPeriodR <= '0';
      else
        if (rx16xClkEnPulse = '1') then 
          if (rxOne16thBitPeriodCntrR = X"F" ) then -- to_unsigned(OVER_SAMPLING_RATE, OVER_SAMPLING_RATE)
            rxOne16thBitPeriodCntrR <= (others => '0');
            rxBitPeriodR <= '1';
          else
            rxOne16thBitPeriodCntrR <= rxOne16thBitPeriodCntrR + 1;
          end if;
          if (rxOne16thBitPeriodCntrR = X"7") then
            rxMidBitPeriodR <= '1';
          end if;
        else
          rxMidBitPeriodR <= '0';
          rxBitPeriodR    <= '0';
        end if;
      end if;
    end if;
  end process holdRxSampleProc;

--------------------------------------------------------------------------------------------------
-- Use this to find out that Start Bit is captured
--------------------------------------------------------------------------------------------------
  captureRxFallingEdge <= (not rxDataIn) and rxDataSync2R;
--------------------------------------------------------------------------------------------------
-- Sync Rx signal to clk Domain
-- Xtra Flops might be required
--------------------------------------------------------------------------------------------------
  syncRxSigToClkDomainProc : process (sysClkIn)
  begin
   if(rising_edge(sysClkIn)) then
     if(sysRstIn /= '1') then
       rxDataSync1R <= '0';
       rxDataSync2R <= '0';
     else
       rxDataSync1R <= rxDataIn;
       rxDataSync2R <= rxDataSync1R;
     end if;
   end if;
  end process syncRxSigToClkDomainProc;
--------------------------------------------------------------------------------------------------
-- TX CNTRL STATE MACHINE
--------------------------------------------------------------------------------------------------
  uartRxCntrlProc : process (sysClkIn)
  begin
    if(rising_edge(sysClkIn)) then
      if(sysRstIn /= '1') then
        enRxBaudRateR <= '0';
        rxStateR <= IDLE;
        rxReceivedByteR    <= (others => '0');
        rxReceivedBitCntR  <= (others => '0');
      else
        case rxStateR is
          when IDLE =>
            if (captureRxFallingEdge = '1') then
              enRxBaudRateR <= '1';
              rxStateR <= DETECT_START;
            end if;

          when DETECT_START =>
            if (rxMidBitPeriodR = '1') then
              if (rxDataSync2R  = '0') then
                rxStateR <= RECEIVE; 
                enRxBaudRateR <= '0';           -- rst the cntr
              else
                rxStateR <= IDLE; 
              end if;
            end if;

          when RECEIVE =>
            enRxBaudRateR <= '1';
            if (rxBitPeriodR = '1') then
              if (rxReceivedBitCntR = X"7") then
                rxReceivedBitCntR  <= (others => '0');
                rxStateR <= STOP; 
              else
                rxReceivedByteR(to_integer(rxReceivedBitCntR)) <= rxDataSync2R;
                rxReceivedBitCntR  <= rxReceivedBitCntR + 1;
              end if;
            end if;

          when STOP =>
            if (rxBitPeriodR = '1') then
              enRxBaudRateR <= '0';
              if (rxDataSync2R  ='1') then
                rxStateR <= IDLE;
              else 
                rxStateR <= RX_ERROR;
              end if;
            end if;
          when RX_ERROR =>
            rxStateR <= IDLE;
          end case;
      end if;
    end if;
  end process uartRxCntrlProc;
   
end architecture rtl;
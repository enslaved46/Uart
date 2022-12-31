library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library uart_lib;
  use uart_lib.uart_pkg.all;

entity sevenSegCntrl is
  generic (
    REFRESH_RATE_HZ    : positive  := 9600;
    CLK_FREQ           : real      := 100.0e6
  );
  port (
    sysClkIn           : in   std_logic;
    sysRstIn           : in   std_logic;
    txTransmitedDataIn : in   std_logic_vector(7 downto 0); -- Byte that is transmitted out of the FPGA
    rxReceivedDataIn   : in   std_logic_vector(7 downto 0); -- Received Byte in the FPGA
    anodeOut           : out  std_logic_vector(7 downto 0); -- Enable signal for SegnSeg Anode
    sevnSegOut         : out  std_logic_vector(6 downto 0)  -- Sevn Seg Driver
  );
end entity sevenSegCntrl;

architecture rtl of sevenSegCntrl is
  signal sevnSegDisplayEnR    : std_logic;                     -- enable sevn seg
  signal sevnSegDisplayDataR : std_logic_vector (3 downto 0 ); -- Dislpay data on 7 seg
  signal svnSegRefreshCntrR  : unsigned(2 downto 0);           -- Refresh sevn seg, only one is on at a time (persistence of vision)
  signal anodeCntrlR         : std_logic_vector (3 downto 0);  -- Cnt Anode, which sevn seg to enable, where to display data
  signal rfrshSvenSegPulse   : std_logic;                      -- Refresh pulse
  alias  txAnodeCntrlR     is anodeCntrlR (1 downto 0);        -- Alias Tx Anode Cntrl
  alias  rxAnodeCntrlR     is anodeCntrlR (3 downto 2);        -- Alias Rx Anode Cntrl
begin
--------------------------------------------------------------------------------------------------
-- OutPut Proc
--------------------------------------------------------------------------------------------------
  anodeOut    <=  rxAnodeCntrlR & "1111" & txAnodeCntrlR;
  
-- ------------------------------------------------------------------------------------------------
-- Get Sevn seg Refresh  Pulse
-- ------------------------------------------------------------------------------------------------
  sevenSegRefeshRateInt : entity uart_lib.mYCntr(rtl) 
    generic map (
      FREQUENCY_REQ   => 1000,
      CLK_FREQ        => CLK_FREQ,
      SAMPLING_RATE   => 1)
    port map (
      sysClkIn        => sysClkIn,
      sysRstIn        => sysRstIn,
      enCntrIn        => sevnSegDisplayEnR,
      cntrDnePulseOut => rfrshSvenSegPulse);

--------------------------------------------------------------------------------------------------
-- BCD TO 7 Seg Driver
--------------------------------------------------------------------------------------------------
  sevenSegInst  : entity uart_lib.commonCathodSevenSeg(behave)
    port map(
      binNumIn => (sevnSegDisplayDataR),
      sevenSegDisplayOut => sevnSegOut(6 downto 0));
      
--------------------------------------------------------------------------------------------------
-- Cntrl What to display on Seven seg
-- Enable one Segment at time
-- Due to Persistence Of vision, all of are seen to be lightened
--------------------------------------------------------------------------------------------------
  displayCntrlProc : process(sysClkIn)
  begin
    if(rising_edge(sysClkIn)) then
      if (sysRstIn /= '1') then
        sevnSegDisplayDataR  <= (others => '0');
        anodeCntrlR <= (others => '1');          -- turn all the anodes off
        svnSegRefreshCntrR <= (others => '0');
        sevnSegDisplayEnR  <= '1';
      elsif (rfrshSvenSegPulse = '1') then
        anodeCntrlR <= (others => '1');         --  default
        svnSegRefreshCntrR <= svnSegRefreshCntrR + 1;
        case svnSegRefreshCntrR is
          when "000" =>
            NULL;
          when "001" =>                 -- indx 1 svn seg
            sevnSegDisplayDataR <= txTransmitedDataIn(3 downto 0); 
            txAnodeCntrlR  <= "10";
          when "010" =>
            txAnodeCntrlR   <= "01";
            sevnSegDisplayDataR <= txTransmitedDataIn(7 downto 4);
          when "011" =>
            NULL;
          when "100" =>
            NULL;
          when "101" =>
            NULL;
          when "110" =>
           sevnSegDisplayDataR <= rxReceivedDataIn(3 downto 0);
           rxAnodeCntrlR <= "10";
          when "111" =>
           sevnSegDisplayDataR <= rxReceivedDataIn(7 downto 4);
           rxAnodeCntrlR <= "01";
           svnSegRefreshCntrR <= (others => '0');
          when others =>
            NULL;
        end case;
      end if;
    end if;
  end process displayCntrlProc;
end architecture rtl;
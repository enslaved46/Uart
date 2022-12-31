-- Designer : Enslaved FortySixx
-- Entity   : debouncer.vhd
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library uart_lib;
  use uart_lib.uart_pkg.all;

entity debouncer is
  generic (
    HOLD_FREQUNCY      : real :=  10.0;
    CLK_FREQ           : real := 100.0e6);
  port (
    sysClkIn           : in   std_logic;
    sysRstIn           : in   std_logic;
    pushBtnIn          : in   std_logic;
    filteredSignalOut  : out  std_logic);
end entity debouncer;

architecture rtl of debouncer is
  signal   pushBtnSync1R      : std_logic;
  signal   pushBtnSync2R      : std_logic;
  signal   enDebouncerCntr    : std_logic;
  signal   filterdSignalR     : std_logic;
  signal   cntrDonePulse      : std_logic;
  signal   captureRisingEdge  : std_logic;
  signal   captureFallingEdge : std_logic;
  signal   enDebouncerCntrR   : std_logic;
  signal   latchedStateR      : std_logic;
begin
--------------------------------------------------------------------------------------------------
-- OutPut Proc
--------------------------------------------------------------------------------------------------
  filteredSignalOut <= filterdSignalR;
--------------------------------------------------------------------------------------------------
-- Edge Capture
--------------------------------------------------------------------------------------------------
  captureRisingEdge  <= (not pushBtnSync2R) and pushBtnIn;
  captureFallingEdge <= (not pushBtnIn) and pushBtnSync2R;
--------------------------------------------------------------------------------------------------
-- Sync the button to the sys Clk domain
-- May need few more flops
-- Latch when Button is released
--------------------------------------------------------------------------------------------------
  syncBtnToClkDomainProc : process (sysClkIn)
  begin
    if(rising_edge(sysClkIn)) then
      if(sysRstIn /= '1') then
        pushBtnSync1R <= '0';
        pushBtnSync2R <= '0';
      else
        pushBtnSync1R <= pushBtnIn;
        pushBtnSync2R <= pushBtnSync1R;
        if(captureFallingEdge = '1') then
          latchedStateR  <= pushBtnSync2R;
        end if;
      end if;
    end if;
  end process syncBtnToClkDomainProc;

-- figure outwhy I can t make this work
  enDebouncerCntr <= pushBtnSync2R xor pushBtnIn; -- Verify it is still the same
--------------------------------------------------------------------------------------------------
-- Enable/Diable Debouncer Cntr
-- Filter Debounced Signal when Cntr Expires
--------------------------------------------------------------------------------------------------
  enableDebounceCntrProc : process (sysClkIn)
  begin
    if(rising_edge(sysClkIn)) then
      if(sysRstIn /= '1') then
        enDebouncerCntrR <= '0';
        filterdSignalR <= '0';
      else
        filterdSignalR <= '0';
        if(captureFallingEdge = '1') then
          enDebouncerCntrR <= '1';
        elsif (cntrDonePulse = '1') then
          enDebouncerCntrR <= '0';
          filterdSignalR <= latchedStateR;
        end if;
      end if;
    end if;
  end process enableDebounceCntrProc;
--------------------------------------------------------------------------------------------------
-- Debouncer Cntr Setup
--------------------------------------------------------------------------------------------------
  deBouncerHoldTime : entity uart_lib.mYCntr(rtl) 
    generic map (
    FREQUENCY_REQ   => integer(HOLD_FREQUNCY),
    CLK_FREQ        => CLK_FREQ,
    SAMPLING_RATE   => 1)
    port map (
    sysClkIn        => sysClkIn,
    sysRstIn        => sysRstIn,
    enCntrIn        => enDebouncerCntrR,
    cntrDnePulseOut => cntrDonePulse);
    
end architecture rtl;
-------------------------------------------------------------------------------
--
-- Super Serial Card
--
-- (c)2025 Gyorgy Szombathelyi
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ssc is
  port (
    CLK_14M        : in  std_logic;
    CLK_2M         : in  std_logic;
    PHASE_ZERO     : in  std_logic;
    IO_SELECT      : in  std_logic;             -- e.g., C700 - C7FF ROM
    IO_STROBE      : in  std_logic;             -- e.g., C800 - CFFF I/O locations
    DEVICE_SELECT  : in  std_logic;
    RESET          : in  std_logic;
    A              : in  unsigned(15 downto 0);
    D_IN           : in  unsigned( 7 downto 0); -- From 6502
    D_OUT          : out unsigned( 7 downto 0); -- To 6502
    RNW            : in  std_logic;
    OE             : out std_logic;
    IRQ_N          : out std_logic;

    SW1            : in  std_logic_vector(6 downto 1);
    SW2            : in  std_logic_vector(5 downto 1);

    -- UART
    UART_RX        : in  std_logic;
    UART_TX        : out std_logic;
    UART_CTS       : in  std_logic;
    UART_RTS       : out std_logic;
    UART_DCD       : in  std_logic;
    UART_DSR       : in  std_logic;
    UART_DTR       : out std_logic;

    clk_sys                   : in  std_logic;
    wifimodem                 : in  std_logic;

    serial_data_out_available : out std_logic_vector( 7 downto 0);  -- bytes available
    serial_data_in_free       : out std_logic_vector( 7 downto 0);  -- free buffer available
    serial_strobe_out         : in  std_logic;
    serial_data_out           : out std_logic_vector( 7 downto 0);
    serial_status_out         : out std_logic_vector(31 downto 0);
    -- serial rs223 connection from io controller
    serial_strobe_in          : in  std_logic;
    serial_data_in            : in std_logic_vector( 7 downto 0)
    );
end ssc;

architecture rtl of ssc is

  signal rom_a : unsigned(10 downto 0);
  signal rom_dout : unsigned(7 downto 0);
  signal rom_active : std_logic;
  signal uart_dout : std_logic_vector(7 downto 0);
  signal uart_clk_en : std_logic;
  signal uart_cs : std_logic;
  signal sw1_cs, sw2_cs : std_logic;
  signal uart_dout_wifi : std_logic_vector(7 downto 0);
  signal uart_dout_std  : std_logic_vector(7 downto 0);
  signal wifi_cs : std_logic_vector(1 downto 0);
  signal nullmdm1,nullmdm2 : std_logic;

begin

  process(CLK_14M) begin
    if rising_edge(CLK_14M) then
      if RESET = '1' then
        rom_active <= '0';
      else
        if IO_STROBE = '1' and A(11 downto 8) = x"F" then
          rom_active <= '0';
        elsif IO_SELECT = '1' then
          rom_active <= '1';
        end if;
      end if;
    end if;
  end process;

  uart_cs <= DEVICE_SELECT and A(3) and not A(2);
  sw1_cs  <= DEVICE_SELECT and not A(3) and not A(1);
  sw2_cs  <= DEVICE_SELECT and not A(3) and not A(0);

--  Bit-> B7  B6  B5  B4  B3  B2  B1  B0
-- DIPSW1 S1  S2  S3  S4  Z   Z   S5  S6   8'b11101100:
-- 1110 9600 baud
-- '1' fix
-- '1' fix
-- 00 firmware mode 

-- DIPSW2 S1  Z   S2  Z   S3  S4  S5  CTS  {7'b0101000, UART_CTS}:
-- rs232 CTS signal
-- irq
-- (5) add linefeed
-- (4) no parity
-- (3) no parity
-- (2) 8bit dataformat
-- '1' fix
-- (1) 1bit stopbit
  D_OUT <= SW1(1) & SW1(2) & SW1(3) & SW1(4) &   '1'  &  '1'   & SW1(5) &   SW1(6) when sw1_cs = '1' else
           SW2(1) &  '1'   & SW2(2) &   '1'  & SW2(3) & SW2(4) & SW2(5) & UART_CTS when sw2_cs = '1' else
           unsigned(uart_dout) when uart_cs = '1' else
           rom_dout;
  OE <= (IO_STROBE and rom_active) or IO_SELECT or DEVICE_SELECT;

  cegen : entity work.CEGen port map (
    CLK    => CLK_14M,
    RST_N  => not RESET,

    IN_CLK => 14000000,
    OUT_CLK=>  1843200,

    CE     => uart_clk_en
  );

  wifi_cs <= '0' & uart_cs;
  uart_dout <= uart_dout_wifi when wifimodem = '1' else uart_dout_std;

uart : entity work.gen_uart_mos_6551 port map (
    reset  => RESET,
    clk    => CLK_14M,
    clk_en => uart_clk_en,
    din    => std_logic_vector(D_IN),
    dout   => uart_dout_std,
    rnw    => RNW,
    cs     => uart_cs,
    rs     => std_logic_vector( A(1 downto 0) ),
    irq_n  => IRQ_N,
    cts_n  => UART_CTS,
    dcd_n  => UART_DCD,
    dsr_n  => UART_DSR,
    dtr_n  => UART_DTR,
    rts_n  => UART_RTS,
    rx     => UART_RX,
    tx     => UART_TX
  );

uart_wifi : entity work.glb6551 port map (
  RESET_N     => not RESET,
  CLK         => CLK_14M,
  RX_CLK      => open,
  RX_CLK_IN   => uart_clk_en,
  XTAL_CLK_IN => uart_clk_en,
  PH_2        => wifi_cs(0),
  DI          => D_IN,
  DO          => uart_dout_wifi,
  IRQ         => open, -- IRQ_N,
  CS          => wifi_cs,
  RW_N        => RNW,
  RS          => A(1 downto 0),
  TXDATA_OUT  => open,
  RXDATA_IN   => '1',
  RTS         => nullmdm1,
  CTS         => nullmdm1,
  DCD         => nullmdm2,
  DTR         => nullmdm2,
  DSR         => nullmdm2,
  -- serial/rs232 interface io-controller<-> UART
  clk_sys             => clk_sys,
  serial_status_out   => serial_status_out,
  serial_data_out_available => serial_data_out_available,
  serial_strobe_out   => serial_strobe_out,
  serial_data_out     => serial_data_out,

  serial_data_in_free => serial_data_in_free,
  serial_strobe_in    =>  serial_strobe_in,
  serial_data_in      => serial_data_in
  );

  -- ROM
  rom_a <= "111" & A(7 downto 0) when IO_SELECT = '1' else A(10 downto 0);
  rom : entity work.ssc_rom port map (
    addr => rom_a,
    clk  => CLK_14M,
    data => rom_dout);

end rtl;

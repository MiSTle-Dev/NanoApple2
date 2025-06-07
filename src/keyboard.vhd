-------------------------------------------------------------------------------
--
-- USB Keyboard interface for the Apple //e
--
-- Based on
-- PS/2 Keyboard interface for the Apple ][
--
-- Stephen A. Edwards, sedwards@cs.columbia.edu
-- After an original by Alex Freed
--
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keyboard is

  port (
    CLK_14M  : in std_logic;
    usb_key  : in std_logic_vector(7 downto 0);
    kbd_strobe : in std_logic;
    reads    : in std_logic;            -- Read strobe
    reset    : in std_logic;
    akd      : buffer std_logic;        -- Any key down
    K        : out unsigned(7 downto 0); -- Latched, decoded keyboard data
    open_apple:    out std_logic;
    closed_apple:  out std_logic;
    soft_reset:    out std_logic := '0';
  	video_toggle:  out std_logic := '0';	  -- signal to control change of video modes
    palette_toggle:out std_logic := '0'	  -- signal to control change of paleetes
	);
end keyboard;

architecture rtl of keyboard is

  signal PS2_Key            : std_logic_vector(10 downto 0);
  signal rom_addr           : std_logic_vector(10 downto 0);
  signal rom_out            : unsigned(7 downto 0);
  signal junction_code      : std_logic_vector(7 downto 0);
  signal code, latched_code : unsigned(7 downto 0);
  signal latched_ext, ext   : std_logic;

  signal key_pressed        : std_logic;  -- Key pressed & not read
  signal ctrl,shift,caplock : std_logic;
  signal old_stb            : std_logic;
  signal rep_timer          : unsigned(22 downto 0);
  signal kbd_strobeD1, kbd_strobeD : std_logic;

  -- Special PS/2 keyboard codes
  constant LEFT_SHIFT       : unsigned(7 downto 0) := X"69"; -- X
  constant RIGHT_SHIFT      : unsigned(7 downto 0) := X"6D"; -- X
  constant LEFT_CTRL        : unsigned(7 downto 0) := X"68"; -- X
  constant CAPS_LOCK        : unsigned(7 downto 0) := X"39"; -- X
  constant WINDOWS          : unsigned(7 downto 0) := X"6B"; -- X
  constant ALT              : unsigned(7 downto 0) := X"6A"; -- X
  
  constant F2               : unsigned(7 downto 0) := X"3B"; -- X
  constant F8               : unsigned(7 downto 0) := X"41"; -- X
  constant F9               : unsigned(7 downto 0) := X"42"; -- X
	
  type states is (IDLE,
                  HAVE_CODE,
                  DECODE,
                  GOT_KEY_UP_CODE,
                  GOT_KEY_UP2,
                  KEY_UP,
                  NORMAL_KEY,
                  KEY_READY1,
                  KEY_READY
                  );

  signal state, next_state : states;

begin

keyboard_rom : entity work.Gowin_pROM_key
    port map (
        unsigned(dout) => rom_out,
        clk => CLK_14M,
        oce => '1',
        ce => '1',
        reset => '0',
        ad => std_logic_vector(rom_addr)
    );

--  keyboard_rom : work.spram
--  generic map (11,8,"rtl/roms/keyboard.mif")
--  port map (
--   address => std_logic_vector(rom_addr),
--   clock => CLK_14M,
--   data => (others=>'0'),
--   wren => '0',
--   unsigned(q) => rom_out);

  K <= key_pressed & rom_out(6 downto 0);

  caplock_ctrl : process (CLK_14M, reset)
  begin
    if reset = '1' then
      caplock <= '0';
    elsif rising_edge(CLK_14M) then
      if state = KEY_UP and code = CAPS_LOCK then
        caplock <= not caplock;
      end if;
    end if;
  end process;

  shift_ctrl : process (CLK_14M, reset)
  begin
    if reset = '1' then
      shift <= '0';
      ctrl <= '0';
      --open_apple<='0';
      --closed_apple<='0';
		soft_reset<='0';
		video_toggle<='0';
		palette_toggle<='0';
    elsif rising_edge(CLK_14M) then
     if state = HAVE_CODE then
        if code = LEFT_SHIFT or code = RIGHT_SHIFT then
          shift <= '1';
        elsif code = LEFT_CTRL then
          ctrl <= '1';
        elsif code = WINDOWS then
          open_apple <= '1';
        elsif code = ALT then
          closed_apple <= '1';
        elsif code = F2 then
		    soft_reset <= '1';
          --reset_key <= '1';
	    elsif code = F8 then
			palette_toggle <= '1';
		elsif code = F9 then
			video_toggle <= '1';
        end if;
      elsif state = KEY_UP then
        if code = LEFT_SHIFT or code = RIGHT_SHIFT then
          shift <= '0';
        elsif code = LEFT_CTRL then
          ctrl <= '0';
        elsif code = WINDOWS then
          open_apple <= '0';
        elsif code = ALT then
          closed_apple <= '0';
        elsif code = F2 then
          --reset_key <= '0';
			 soft_reset <= '0';
		elsif code = F8 then
			palette_toggle <= '0';
		elsif code = F9 then
			video_toggle <= '0';
        end if;
      end if;
    end if;
  end process shift_ctrl;

  code <= unsigned('0' & usb_key(6 downto 0));
-- PS2 [9] - pressed, 
-- PS2 [10] - toggles with every press/release
-- pressed  = (ps2_key_raw[15:8] != 8'hf0);
-- ps2_key <= {~ps2_key[10], pressed, extended, ps2_key_raw[7:0]};

 PS2_Key(9) <= not usb_key(7);
 PS2_Key(10) <= not kbd_strobeD1;

  fsm : process (CLK_14M, reset)
  begin
    if reset = '1' then
      state <= IDLE;
      latched_code <= (others => '0');
      latched_ext <= '0';
      key_pressed <= '0';
    elsif rising_edge(CLK_14M) then
      kbd_strobeD <= kbd_strobe;
      kbd_strobeD1 <= kbd_strobeD;

      state <= next_state;
      if reads = '1' then key_pressed <= '0'; end if;
      if state = HAVE_CODE then
        old_stb <= ps2_key(10);
      end if;
      if state = GOT_KEY_UP_CODE then
        akd <= '0';
      end if;
      if state = NORMAL_KEY then
        -- set up keyboard ROM read address
        latched_code <= code ;
        latched_ext <= ext;
      end if;
      if state = KEY_READY and junction_code /= x"FF" then
        -- key code ready from ROM
         akd <= '1';
         key_pressed <= '1';
         rep_timer <= to_unsigned(7000000, 23); -- 0.5s
      end if;
      if akd = '1' then
         rep_timer <= rep_timer - 1;
         if rep_timer = 0 then
            rep_timer <= to_unsigned(933333, 23); -- 1/15s
            key_pressed <= '1';
         end if;
      end if;
    end if;
  end process fsm;

  fsm_next_state : process (code, old_stb, ps2_key, state)
  begin
    next_state <= state;
    case state is
      when IDLE =>
        if old_stb /= ps2_key(10) then next_state <= HAVE_CODE; end if;

      when HAVE_CODE =>
        next_state <= DECODE;

      when DECODE =>
        if ps2_key(9) = '0' then
          next_state <= GOT_KEY_UP_CODE;
        elsif code = LEFT_SHIFT or code = RIGHT_SHIFT or code = LEFT_CTRL or code = CAPS_LOCK then
          next_state <= IDLE;
        else
          next_state <= NORMAL_KEY;
        end if;

      when GOT_KEY_UP_CODE =>
        next_state <= GOT_KEY_UP2;

      when GOT_KEY_UP2 =>
        next_state <= KEY_UP;

      when KEY_UP =>
        next_state <= IDLE;

      when NORMAL_KEY =>
        next_state <= KEY_READY1;

      when KEY_READY1 =>
        next_state <= KEY_READY;

      when KEY_READY =>
        next_state <= IDLE;
    end case;
  end process fsm_next_state;

  -- PS/2 scancode to Keyboard ROM address translation
  rom_addr <= '0' & caplock & junction_code(6 downto 0) & not ctrl & not shift;

  -- the following junction codes correspond to the locations in the Apple II keybpard matrix
  -- see "Keyboard Matrix A2e", drawing number 699-00760C;  decimal values converted to hex (e.g. CR -> 66 -> 0x42)
  with latched_code(6 downto 0) select
    junction_code <=
     X"00" when 7X"29", -- Escape ("esc" key)
     X"01" when 7X"1E", -- 1x
     X"02" when 7X"1F", -- 2x
     X"03" when 7X"20", -- 3x
     X"04" when 7X"21", -- 4x
     X"05" when 7X"23", -- 6x
     X"06" when 7X"22", -- 5x
     X"07" when 7X"24", -- 7x
     X"08" when 7X"25", -- 8x
     X"09" when 7X"26", -- 9x

     X"0A" when 7X"2B", -- Horizontal Tab
     X"0B" when 7X"14", -- Q
     X"0C" when 7X"1A", -- W
     X"0D" when 7X"08", -- E
     X"0E" when 7X"15", -- R
     X"0F" when 7X"1C", -- Y
     X"10" when 7X"17", -- T
     X"11" when 7X"18", -- U
     X"12" when 7X"0C", -- I
     X"13" when 7X"12", -- O

     X"14" when 7X"04", -- A
     X"15" when 7X"07", -- D
     X"16" when 7X"16", -- S
     X"17" when 7X"0B", -- H
     X"18" when 7X"09", -- F
     X"19" when 7X"0A", -- G
     X"1A" when 7X"0D", -- J
     X"1B" when 7X"0E", -- K
     X"1C" when 7X"33", -- ;
     X"1D" when 7X"0F", -- L

     X"1E" when 7X"1D", -- Z
     X"1F" when 7X"1B", -- X
     X"20" when 7X"06", -- C
     X"21" when 7X"19", -- V
     X"22" when 7X"05", -- B
     X"23" when 7X"11", -- N
     X"24" when 7X"10", -- M
     X"25" when 7X"36", -- ,
     X"26" when 7X"37", -- .
     X"27" when 7X"38", -- /

     x"28" when 7x"54", -- KP /
--   X"29" when 7x"6b", -- KP Left
     X"2A" when 7x"62", -- KP 0
     X"2B" when 7x"59", -- KP 1
     X"2C" when 7x"5A", -- KP 2
     X"2D" when 7x"5B", -- KP 3
     X"2E" when 7X"31", -- \
     X"2F" when 7X"2E", -- =
     X"30" when 7X"27", -- 0
     X"31" when 7X"2D", -- -

--   x"32" when 7x"",   -- KP )
--   X"33" when 7X"76", -- KP Escape ("esc" key)
     X"34" when 7x"5C", -- KP 4
     X"35" when 7x"5D", -- KP 5
     X"36" when 7x"5E", -- KP 6
     X"37" when 7x"5F", -- KP 7
     X"38" when 7X"35", -- `
     X"39" when 7X"13", -- P
     X"3A" when 7X"2F", -- [
     X"3B" when 7X"30", -- ]

     X"3C" when 7X"55", -- KP *
--   X"3D" when 7X"74", -- KP Right
     X"3E" when 7X"60", -- KP 8
     X"3F" when 7X"61", -- KP 9
     X"40" when 7X"63", -- KP .
     X"41" when 7X"57", -- KP +
     X"42" when 7X"58", -- Carriage return ("enter" key)
     X"43" when 7X"52", -- (up arrow)
     X"44" when 7X"2C", -- Space
     X"45" when 7X"34", -- '

--   X"46" when 7X"4a", -- ?
--   X"47" when 7X"29", -- KP Space
--   X"48" when 7x"",   -- KP (
     X"49" when 7X"56", -- KP -
     X"4A" when 7X"28", -- KP return
--   X"4B" when 7X"",   -- KP ,
     X"4C" when 7X"4C", -- Del key - mapped to character 127 ("rub" / "delete" - shows as a square cursor characters)
     X"4E" when 7X"2A", -- KP del (backspace - mapped to left)
     X"4D" when 7X"51", -- down arrow
     X"4E" when 7X"50", -- left arrow
     X"4F" when 7X"4F", -- right arrow

     X"FF" when others;

end rtl;

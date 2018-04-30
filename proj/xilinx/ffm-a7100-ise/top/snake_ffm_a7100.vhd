----------------------------
-- ULX3S Top level for SNAKE
-- http://github.com/emard
----------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.ALL;
use IEEE.numeric_std.all;

-- vendor specific library for ddr and differential video out
library unisim;
use unisim.vcomponents.all;

entity snake_ffm_a7100 is
generic
(
  C_dummy: boolean := false -- unused parameter
);
port
(
  clk_100mhz_n, clk_100mhz_p: in std_logic;
  fio0: in std_logic_vector(7 downto 0);
  vid_d_p, vid_d_n: out std_logic_vector(3 downto 0)
);
end;

architecture struct of snake_ffm_a7100 is
        signal reset_n: std_logic := '1';

	alias ps2_clk : std_logic is fio0(0);
	alias ps2_dat : std_logic is fio0(1);

	signal clk_100MHz, clk_fb: std_logic;
	signal clk_pixel, clk_pixel_shift, clkn_pixel_shift: std_logic;

	signal S_vga_r, S_vga_g, S_vga_b: std_logic_vector(2 downto 0);
	signal S_vga_vsync, S_vga_hsync: std_logic;
	signal S_vga_vblank, S_vga_blank: std_logic;
	signal ddr_d: std_logic_vector(3 downto 0);
	signal dvid_crgb: std_logic_vector(7 downto 0); -- clock, red, green, blue
begin
  -- fio0(7 downto 2) <= (others => 'Z');
  -- reset_n <= fio0(2); -- this makes design unroutable
  reset_n <= '1';

  clkin_ibufgds: ibufgds
  port map (I => clk_100MHz_P, IB => clk_100MHz_N, O => clk_100MHz);

  clk_main: mmcme2_base
  generic map
  (
    clkin1_period    => 10.0,
    clkfbout_mult_f  => 10.0,		-- 1000 MHz x10 common multiply
    clkout0_divide_f => 4.0,		--  250 MHz /8 divide
    clkout1_divide   => 8,		--  125 MHz /4 divide
    clkout2_divide   => 40,		--   25 MHz /40 divide
    bandwidth        => "LOW"
  )
  port map
  (
    pwrdwn   => '0',
    rst      => '0',
    clkin1   => clk_100MHz,
    clkfbin  => clk_fb,
    clkfbout => clk_fb,
    clkout0  => open,
    clkout1  => clk_pixel_shift,
    clkout2  => clk_pixel,
    locked   => open
  );

  snake_module: entity work.snake
  port map
  (
    VGA_clk    => clk_pixel,
    start      => reset_n,
    KB_clk     => ps2_clk,
    KB_data    => ps2_dat,
    VGA_R      => S_vga_r,
    VGA_G      => S_vga_g,
    VGA_B      => S_vga_b,
    VGA_hSync  => S_vga_hsync,
    VGA_vSync  => S_vga_vsync,
    VGA_Blank  => S_vga_blank
  );

  vga2dvi_converter: entity work.vga2dvid
  generic map
  (
      C_ddr     => true,
      C_depth   => 3 -- 3bpp (3 bit per pixel)
  )
  port map
  (
      clk_pixel => clk_pixel, -- 25 MHz
      clk_shift => clk_pixel_shift, -- 5*25 MHz

      in_red   => S_vga_r,
      in_green => S_vga_g,
      in_blue  => S_vga_b,

      in_hsync => S_vga_hsync,
      in_vsync => S_vga_vsync,
      in_blank => S_vga_blank,

      -- single-ended output ready for differential buffers
      out_clock => dvid_crgb(7 downto 6),
      out_red   => dvid_crgb(5 downto 4),
      out_green => dvid_crgb(3 downto 2),
      out_blue  => dvid_crgb(1 downto 0)
  );

  -- vendor specific DDR and differential modules
  gpdi_ddr_diff: for i in 0 to 3 generate
    gpdi_ddr:   oddr generic map (DDR_CLK_EDGE => "SAME_EDGE", INIT => '0', SRTYPE => "SYNC") port map (D1=>dvid_crgb(2*i+0), D2=>dvid_crgb(2*i+1), Q=>ddr_d(i), C=>clk_pixel_shift, CE=>'1', R=>'0', S=>'0');
    gpdi_diff:  obufds port map(i => ddr_d(i), o => vid_d_p(i), ob => vid_d_n(i));
  end generate;
end struct;

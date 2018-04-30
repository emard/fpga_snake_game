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

entity snake_scarab is
generic
(
  C_dummy: boolean := false -- unused parameter
);
port
(
  clk_50mhz: in std_logic;
  porta: in std_logic_vector(6 downto 0);
  sw: in std_logic_vector(4 downto 1);
  AUDIO_L, AUDIO_R: out std_logic;

  -- warning TMDS_in is used as output
  tmds_in_rgb_p, tmds_in_rgb_n: out std_logic_vector(2 downto 0);
  tmds_in_clk_p, tmds_in_clk_n: out std_logic;
  -- FPGA_SDA, FPGA_SCL: inout std_logic; -- i2c on TMDS_in
  tmds_out_rgb_p, tmds_out_rgb_n: out std_logic_vector(2 downto 0);
  tmds_out_clk_p, tmds_out_clk_n: out std_logic;

  leds      : out std_logic_vector(7 downto 0)
);
end;

architecture struct of snake_scarab is
        signal reset_n: std_logic;

	alias ps2_clk : std_logic is porta(0);
	alias ps2_dat : std_logic is porta(1);

	signal clk_pixel, clk_pixel_shift, clkn_pixel_shift: std_logic;

	signal S_vga_r, S_vga_g, S_vga_b: std_logic_vector(2 downto 0);
	signal S_vga_vsync, S_vga_hsync: std_logic;
	signal S_vga_vblank, S_vga_blank: std_logic;
	signal ddr_d0, ddr_d1: std_logic_vector(2 downto 0);
	signal ddr_clk0, ddr_clk1: std_logic;
	signal dvid_red, dvid_green, dvid_blue, dvid_clock: std_logic_vector(1 downto 0);
begin
  leds <= (others => '0'); -- 0: all leds OFF
  audio_l <= '0';
  audio_r <= '0';

  clkgen: entity work.clk_50M_100M_125Mp_125Mn_25M
  port map
  (
      CLK_50M_IN => clk_50MHz,       --  50 MHz input from board
      CLK_100M => open,
      CLK_125MP => clk_pixel_shift,  -- 125 MHz
      CLK_125MN => clkn_pixel_shift, -- 125 MHz inverted
      CLK_25M => clk_pixel,          --  25 MHz
      RESET => '0',
      LOCKED => reset_n
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
      out_red   => dvid_red,
      out_green => dvid_green,
      out_blue  => dvid_blue,
      out_clock => dvid_clock
  );

  -- vendor specific DDR modules
  -- convert SDR 2-bit input to DDR clocked 1-bit output (single-ended)
  ddr_red0:   ODDR2 generic map (DDR_ALIGNMENT => "C0", INIT => '0', SRTYPE => "ASYNC") port map (D0=>dvid_red(0),   D1=>dvid_red(1),   Q=>ddr_d0(2), C0=>clk_pixel_shift, C1=>clkn_pixel_shift, CE=>'1', R=>'0', S=>'0');
  ddr_green0: ODDR2 generic map (DDR_ALIGNMENT => "C0", INIT => '0', SRTYPE => "ASYNC") port map (D0=>dvid_green(0), D1=>dvid_green(1), Q=>ddr_d0(1), C0=>clk_pixel_shift, C1=>clkn_pixel_shift, CE=>'1', R=>'0', S=>'0');
  ddr_blue0:  ODDR2 generic map (DDR_ALIGNMENT => "C0", INIT => '0', SRTYPE => "ASYNC") port map (D0=>dvid_blue(0),  D1=>dvid_blue(1),  Q=>ddr_d0(0), C0=>clk_pixel_shift, C1=>clkn_pixel_shift, CE=>'1', R=>'0', S=>'0');
  ddr_clock0: ODDR2 generic map (DDR_ALIGNMENT => "C0", INIT => '0', SRTYPE => "ASYNC") port map (D0=>dvid_clock(0), D1=>dvid_clock(1), Q=>ddr_clk0,  C0=>clk_pixel_shift, C1=>clkn_pixel_shift, CE=>'1', R=>'0', S=>'0');
  -- same for the second port
  ddr_red1:   ODDR2 generic map (DDR_ALIGNMENT => "C0", INIT => '0', SRTYPE => "ASYNC") port map (D0=>dvid_red(0),   D1=>dvid_red(1),   Q=>ddr_d1(2), C0=>clk_pixel_shift, C1=>clkn_pixel_shift, CE=>'1', R=>'0', S=>'0');
  ddr_green1: ODDR2 generic map (DDR_ALIGNMENT => "C0", INIT => '0', SRTYPE => "ASYNC") port map (D0=>dvid_green(0), D1=>dvid_green(1), Q=>ddr_d1(1), C0=>clk_pixel_shift, C1=>clkn_pixel_shift, CE=>'1', R=>'0', S=>'0');
  ddr_blue1:  ODDR2 generic map (DDR_ALIGNMENT => "C0", INIT => '0', SRTYPE => "ASYNC") port map (D0=>dvid_blue(0),  D1=>dvid_blue(1),  Q=>ddr_d1(0), C0=>clk_pixel_shift, C1=>clkn_pixel_shift, CE=>'1', R=>'0', S=>'0');
  ddr_clock1: ODDR2 generic map (DDR_ALIGNMENT => "C0", INIT => '0', SRTYPE => "ASYNC") port map (D0=>dvid_clock(0), D1=>dvid_clock(1), Q=>ddr_clk1,  C0=>clk_pixel_shift, C1=>clkn_pixel_shift, CE=>'1', R=>'0', S=>'0');
  -- vendor specific modules for differential output
  gpdi_differential_data: for i in 0 to 2 generate
    gpdi_diff_data0: obufds port map(i => ddr_d0(i), o => tmds_out_rgb_p(i), ob => tmds_out_rgb_n(i));
    gpdi_diff_data1: obufds port map(i => ddr_d1(i), o => tmds_in_rgb_p(i),  ob => tmds_in_rgb_n(i));
  end generate;
  gpdi_diff_clock0: obufds port map(i => ddr_clk0, o => tmds_out_clk_p, ob => tmds_out_clk_n);
  gpdi_diff_clock1: obufds port map(i => ddr_clk1, o => tmds_in_clk_p,  ob => tmds_in_clk_n);
end struct;

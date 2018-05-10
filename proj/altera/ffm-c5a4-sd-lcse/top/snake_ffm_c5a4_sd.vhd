----------------------------
-- ULX3S Top level for SNAKE
-- http://github.com/emard
----------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.ALL;
use IEEE.numeric_std.all;

-- vendor specific library for ddr and differential video out
LIBRARY altera_mf;
USE altera_mf.all;

entity snake_ffm_c5a4_sd is
generic
(
  C_dvid_ddr: boolean := false -- true:use vendor-specific DDR-differential output buffeers
);
port
(
  clock_50a: in std_logic;
  fio: in std_logic_vector(23 downto 0);
  vid_d_p, vid_d_n: out std_logic_vector(3 downto 0)
);
end;

architecture struct of snake_ffm_c5a4_sd is
        signal reset_n: std_logic := '1';

	alias ps2_clk : std_logic is fio(6);
	alias ps2_dat : std_logic is fio(4);

	signal clk_pixel, clk_pixel_shift, clkn_pixel_shift: std_logic;

	signal S_vga_r, S_vga_g, S_vga_b: std_logic_vector(2 downto 0);
	signal S_vga_vsync, S_vga_hsync: std_logic;
	signal S_vga_vblank, S_vga_blank: std_logic;
	signal ddr_d: std_logic_vector(3 downto 0);
	signal dvid_crgb: std_logic_vector(7 downto 0); -- clock, red, green, blue
	signal pll_locked: std_logic;

  component altera_pll is
  generic
  (
    fractional_vco_multiplier: string;
    reference_clock_frequency: string;
    operation_mode: string;
    number_of_clocks: integer;
    output_clock_frequency0: string;
    phase_shift0: string;
    duty_cycle0: integer;
    output_clock_frequency1: string;
    phase_shift1: string;
    duty_cycle1: integer;
    --output_clock_frequency2: string;
    --phase_shift2: string;
    --duty_cycle2: integer;
    --output_clock_frequency3: string;
    --phase_shift3: string;
    --duty_cycle3: integer;
    --output_clock_frequency4: string;
    --phase_shift4: string;
    --duty_cycle4: integer;
    --output_clock_frequency5: string;
    --phase_shift5: string;
    --duty_cycle5: integer;
    -- up to output_clock_frequency17
    pll_type: string;
    pll_subtype: string
  );
  port
  (
    refclk: in std_logic; -- input clock
    rst: in std_logic;
    outclk: out std_logic_vector(17 downto 0);
    fboutclk: out std_logic;
    fbclk: in std_logic;
    locked: out std_logic
  );
  end component;
begin
  -- fio0(7 downto 2) <= (others => 'Z');
  -- reset_n <= fio0(2); -- this makes design unroutable
  reset_n <= pll_locked;

  clk_pll: altera_pll
  generic map
  (
    fractional_vco_multiplier => "false",
    reference_clock_frequency => "50.0 MHz",
    operation_mode => "direct",
    number_of_clocks => 6,
    output_clock_frequency0 => "25.000 MHz",
    phase_shift0 => "0 ps",
    duty_cycle0 => 50,
    output_clock_frequency1 => "250.000 MHz",
    phase_shift1 => "0 ps",
    duty_cycle1 => 50,
    pll_type => "General",
    pll_subtype => "General"
  )
  port map
  (
    refclk => clock_50a, --  50 MHz input
    rst	=> '0',
    outclk(0) => clk_pixel,
    outclk(1) => clk_pixel_shift,
    fboutclk  => open,
    fbclk     => '0',
    locked    => pll_locked
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
      C_ddr     => C_dvid_ddr,
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

  -- vendor independent video modules
  gpdi_sdr_se: for i in 0 to 3 generate
    vid_d_p(i) <= dvid_crgb(2*i);
    vid_d_n(i) <= not dvid_crgb(2*i);
  end generate;

  -- vendor specific DDR and differential modules
  --gpdi_ddr_diff: for i in 0 to 3 generate
  --  gpdi_ddr:   oddr generic map (DDR_CLK_EDGE => "SAME_EDGE", INIT => '0', SRTYPE => "SYNC") port map (D1=>dvid_crgb(2*i+0), D2=>dvid_crgb(2*i+1), Q=>ddr_d(i), C=>clk_pixel_shift, CE=>'1', R=>'0', S=>'0');
  --  gpdi_diff:  obufds port map(i => ddr_d(i), o => vid_d_p(i), ob => vid_d_n(i));
  --end generate;
end struct;

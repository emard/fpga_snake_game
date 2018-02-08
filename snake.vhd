--
-- AUTHOR=EMARD
-- LICENSE=BSD
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

-- vhdl wrapper for verilog module snake_v.v

entity snake is
  port
  (
    VGA_clk, KB_clk, KB_data, start: in std_logic;
    VGA_R, VGA_G, VGA_B: out std_logic_vector(2 downto 0);
    VGA_hSync, VGA_vSync, VGA_Blank: out std_logic
  );
end;

architecture syn of snake is
  component snake_v
    port (
      start, VGA_clk, KB_clk, KB_data: in std_logic;
      VGA_R, VGA_G, VGA_B: out std_logic_vector(2 downto 0);
      VGA_hSync, VGA_vSync, VGA_Blank: out std_logic
    );
  end component;

begin
  snake_inst: snake_v
  port map
  (
      VGA_clk => VGA_clk, KB_clk => KB_clk, KB_data => KB_data, start => start,
      VGA_R => VGA_R, VGA_G => VGA_G, VGA_B => VGA_B,
      VGA_hSync => VGA_hSync, VGA_vSync => VGA_vSync, VGA_Blank => VGA_Blank
  );
end syn;

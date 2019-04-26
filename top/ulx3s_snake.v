module ulx3s_snake
(
  input clk_25mhz,
  input [6:0] btn,
  output [7:0] led,
  input usb_fpga_dp, usb_fpga_dn,
  output [3:0] gpdi_dp, gpdi_dn,
  output wifi_gpio0
);
    parameter C_ddr = 1'b1; // 0:SDR 1:DDR

    // wifi_gpio0=1 keeps board from rebooting
    // hold btn0 to let ESP32 take control over the board
    assign wifi_gpio0 = btn[0];

    // clock generator
    wire [2:0] clkout;
    wire clk_250MHz, clk_125MHz, clk_25MHz, clk_locked;
    clk_25_250_125_25
    clock_instance
    (
      .clkin(clk_25mhz),
      .clkout(clkout),
      .locked(clk_locked)
    );
    
    // shift clock choice SDR/DDR
    wire clk_pixel, clk_shift;
    assign clk_pixel = clkout[2]; // 25MHz
    generate
      if(C_ddr == 1'b1)
        assign clk_shift = clkout[1]; // 125MHz;
      else
        assign clk_shift = clkout[0]; // 250MHz;
    endgenerate

    // VGA snake
    wire [2:0] vga_r, vga_g, vga_b;
    wire vga_hsync, vga_vsync, vga_blank;
    snake_v
    snake_v_instance
    (
      .start(btn[1]),
      .VGA_clk(clk_pixel),
      .KB_clk(usb_fpga_dp),
      .KB_data(usb_fpga_dn),
      .VGA_R(vga_r),
      .VGA_G(vga_g),
      .VGA_B(vga_b),
      .VGA_hSync(vga_hsync),
      .VGA_vSync(vga_vsync),
      .VGA_Blank(vga_blank)
    );

    // VGA to digital video converter
    wire [1:0] tmds[3:0];
    vga2dvid
    #(
      .C_ddr(C_ddr),
      .C_depth(3)
    )
    vga2dvid_instance
    (
      .clk_pixel(clk_pixel),
      .clk_shift(clk_shift),
      .in_red(vga_r),
      .in_green(vga_g),
      .in_blue(vga_b),
      .in_hsync(vga_hsync),
      .in_vsync(vga_vsync),
      .in_blank(vga_blank),
      .out_clock(tmds[3]),
      .out_red(tmds[2]),
      .out_green(tmds[1]),
      .out_blue(tmds[0])
    );

    // output TMDS SDR/DDR data to fake differential lanes
    fake_differential
    #(
      .C_ddr(C_ddr)
    )
    fake_differential_instance
    (
      .clk_shift(clk_shift),
      .in_clock(tmds[3]),
      .in_red(tmds[2]),
      .in_green(tmds[1]),
      .in_blue(tmds[0]),
      .out_p(gpdi_dp),
      .out_n(gpdi_dn)
    );
endmodule

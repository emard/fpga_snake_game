project = miniSpartan6-plus
vendor = xilinx
family = spartan6
MODEL ?= xc6slx25
part = ${MODEL}-ftg256-3 # last number -3 is speed grade
flashsize = 8192 # KB (kilobytes) - SPI flash device is M25P40
top_module = snake_scarab
isedir = /opt/Xilinx/ISE/14.7/ISE_DS
xil_env = . $(isedir)/settings64.sh
SHELL = /bin/bash
# openocd_interface = interface/altera-usb-blaster.cfg
# openocd_interface = ../include/ft2232-fpu1.ocd
openocd_interface = programmer/ft2232-generic.ocd
xc3sprog_interface = ftdi

include ../include/xilinx.mk

vfiles = \
../../../snake_v.v

vhdfiles = \
top/snake_scarab.vhd \
clocks/clk_50M_100M_125Mp_125Mn_25M.vhd \
../../../snake.vhd \
../../../rtl_emard/generic/bram_true2p_1clk.vhd \
../../../rtl_emard/vga/hdmi/vga2dvid.vhd \
../../../rtl_emard/vga/hdmi/tmds_encoder.vhd \

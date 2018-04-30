project = FFM-A7100-V3r0_and_FFC-CA7-V2r0
vendor = xilinx
family = artix7
MODEL ?= xc7a100t
part = ${MODEL}-fgg484-2 # last number -3 is speed grade
flashsize = 8192 # KB (kilobytes) - SPI flash device is M25P40
top_module = snake_ffm_a7100
isedir = /opt/Xilinx/ISE/14.7/ISE_DS
xil_env = . $(isedir)/settings64.sh
SHELL = /bin/bash
# openocd_interface = interface/altera-usb-blaster.cfg
# openocd_interface = ../include/ft2232-fpu1.ocd
openocd_interface = programmer/ft2232-generic.ocd
xc3sprog_interface = ft4232h_fast

include ../include/xilinx.mk

vfiles = \
../../../snake_v.v

vhdfiles = \
top/snake_ffm_a7100.vhd \
../../../snake.vhd \
../../../rtl_emard/generic/bram_true2p_1clk.vhd \
../../../rtl_emard/vga/hdmi/vga2dvid.vhd \
../../../rtl_emard/vga/hdmi/tmds_encoder.vhd \

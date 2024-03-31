set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

## Clock signal
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports i_clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports i_clk]; # 100 MHz clock signal

## Switches
set_property -dict { PACKAGE_PIN A8    IOSTANDARD LVCMOS33 } [get_ports { i_rst }]; #IO_L12N_T1_MRCC_16 Sch=sw[0]

## Buttons
set_property -dict { PACKAGE_PIN D9    IOSTANDARD LVCMOS33 } [get_ports { i_btn }]; #IO_L6N_T0_VREF_16 Sch=btn[0]

## USB-UART Interface
set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports { o_ser_data }]; #IO_L19N_T3_VREF_16 Sch=uart_rxd_out
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS33} [get_ports i_ser_data]



set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

## Clock signal
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports i_clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports i_clk]; # 100 MHz clock signal

## Switches
set_property -dict { PACKAGE_PIN A8    IOSTANDARD LVCMOS33 } [get_ports { i_rst }]; #IO_L12N_T1_MRCC_16 Sch=sw[0]

## USB-UART Interface
set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports { o_ser_data }]; #IO_L19N_T3_VREF_16 Sch=uart_rxd_out
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS33} [get_ports i_ser_data]


## Pmod Header JA
set_property -dict { PACKAGE_PIN G13   IOSTANDARD LVCMOS33 } [get_ports { o_ssd_seg_A }]; #IO_0_15 Sch=ja[1]
set_property -dict { PACKAGE_PIN B11   IOSTANDARD LVCMOS33 } [get_ports { o_ssd_seg_B }]; #IO_L4P_T0_15 Sch=ja[2]
set_property -dict { PACKAGE_PIN A11   IOSTANDARD LVCMOS33 } [get_ports { o_ssd_seg_C }]; #IO_L4N_T0_15 Sch=ja[3]
set_property -dict { PACKAGE_PIN D12   IOSTANDARD LVCMOS33 } [get_ports { o_ssd_seg_D }]; #IO_L6P_T0_15 Sch=ja[4]

# Pmod Header JB
set_property -dict { PACKAGE_PIN E15   IOSTANDARD LVCMOS33 } [get_ports { o_ssd_seg_E }]; #IO_L11P_T1_SRCC_15 Sch=jb_p[1]
set_property -dict { PACKAGE_PIN E16   IOSTANDARD LVCMOS33 } [get_ports { o_ssd_seg_F }]; #IO_L11N_T1_SRCC_15 Sch=jb_n[1]
set_property -dict { PACKAGE_PIN D15   IOSTANDARD LVCMOS33 } [get_ports { o_ssd_seg_G }]; #IO_L12P_T1_MRCC_15 Sch=jb_p[2]
set_property -dict { PACKAGE_PIN C15   IOSTANDARD LVCMOS33 } [get_ports { o_ssd_digit_sel }]; #IO_L12N_T1_MRCC_15 Sch=jb_n[2]



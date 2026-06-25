## ============================================================
## File: Two_Digit_Counter.xdc
## Board: Nexys A7-100T
## Function: Two-digit decimal counter 00-99 on 7-segment display
## START_STOP = SW0, CLEAR = BTNC
## ============================================================

## Clock signal: 100 MHz system clock
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports {CLK100MHZ}]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {CLK100MHZ}]

## Start/Stop input: SW0
set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS33 } [get_ports {START_STOP}]

## Clear input: BTNC
set_property -dict { PACKAGE_PIN N17 IOSTANDARD LVCMOS33 } [get_ports {CLEAR}]

## 7-segment cathodes, active-low
set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports {CA}]
set_property -dict { PACKAGE_PIN R10 IOSTANDARD LVCMOS33 } [get_ports {CB}]
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports {CC}]
set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS33 } [get_ports {CD}]
set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports {CE}]
set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports {CF}]
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports {CG}]
set_property -dict { PACKAGE_PIN H15 IOSTANDARD LVCMOS33 } [get_ports {DP}]

## 7-segment anodes, active-low
## AN0 = units digit, AN1 = tens digit. AN2-AN7 are kept OFF by the VHDL code.
set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports {AN[0]}]
set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports {AN[1]}]
set_property -dict { PACKAGE_PIN T9  IOSTANDARD LVCMOS33 } [get_ports {AN[2]}]
set_property -dict { PACKAGE_PIN J14 IOSTANDARD LVCMOS33 } [get_ports {AN[3]}]
set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports {AN[4]}]
set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS33 } [get_ports {AN[5]}]
set_property -dict { PACKAGE_PIN K2  IOSTANDARD LVCMOS33 } [get_ports {AN[6]}]
set_property -dict { PACKAGE_PIN U13 IOSTANDARD LVCMOS33 } [get_ports {AN[7]}]

## Recommended configuration voltage settings for Nexys A7
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

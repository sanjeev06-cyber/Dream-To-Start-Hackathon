## CLOCK
set_property PACKAGE_PIN Y9 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk [get_ports clk]

## RESET
set_property PACKAGE_PIN T18 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

## DHT11
set_property PACKAGE_PIN AA4 [get_ports dht_data]
set_property IOSTANDARD LVCMOS33 [get_ports dht_data]

## UART TX
set_property PACKAGE_PIN Y11 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]

## LED LD0
set_property PACKAGE_PIN T22 [get_ports data_valid]
set_property IOSTANDARD LVCMOS33 [get_ports data_valid]

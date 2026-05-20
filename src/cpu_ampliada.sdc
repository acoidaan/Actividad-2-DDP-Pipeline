create_clock -name mi_clk -period 20 [get_ports CLOCK_50] 
#Update -period with clock period (in nanoseconds) of the clock driving the fpga 
#Setting LED outputs as false path, since no timing requirement 
derive_pll_clocks
set_false_path -from * -to [get_ports LEDR[*]] 
set_false_path -from * -to [get_ports HEX0[*]] 
set_false_path -from * -to [get_ports HEX1[*]] 
set_false_path -from * -to [get_ports HEX2[*]] 
set_false_path -from [get_ports KEY[*]] -to *

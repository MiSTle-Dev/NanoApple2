create_clock -name clkin -period 20 -waveform {0 10} [get_ports {clk_in}]
create_clock -name clk28 -period 34.921 -waveform {0 17} [get_nets {clk_sys}]
create_clock -name clk_pixel_x5 -period 6.984 -waveform {0 3.5} [get_nets {clk_pixel_x5}] -add

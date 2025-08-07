//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.03 (64-bit) 
//Created Time: 2025-08-07 13:29:32
create_clock -name clkin -period 20 -waveform {0 10} [get_ports {clk_in}]
create_clock -name clk_i2s -period 500 -waveform {0 250} [get_nets {video_inst/i2s_clk}]
create_clock -name clk28 -period 34.921 -waveform {0 17} [get_nets {clk_sys}]
create_clock -name ds_clk -period 8000 -waveform {0 5} [get_nets {gamepad_p1/clk_spi}]
create_clock -name ds2_clk -period 8000 -waveform {0 5} [get_nets {gamepad_p2/clk_spi}]
create_clock -name clk_pixel_x5 -period 6.984 -waveform {0 3.5} [get_nets {clk_pixel_x5}] -add
create_clock -name m0sclk -period 50 -waveform {0 25} [get_ports {spi_sclk}] -add
create_clock -name clk_audio -period 20833 -waveform {0 10000} [get_nets {video_inst/clk_audio}] -add
set_clock_groups -asynchronous -group [get_clocks {ds2_clk}] -group [get_clocks {ds_clk}] -group [get_clocks {m0sclk}] -group [get_clocks {clk_audio}] -group [get_clocks {clk28}] -group [get_clocks {clk_pixel_x5}]
report_timing -hold -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
report_timing -setup -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1

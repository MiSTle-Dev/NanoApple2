create_clock -name clkin -period 37.037 -waveform {0 18} [get_ports {clk_in}]
create_clock -name clk14 -period 69.842 -waveform {0 34} [get_nets {clk_core}]
create_clock -name clk28 -period 34.921 -waveform {0 17} [get_nets {clk_sys}]
create_clock -name clk_pixel_x5 -period 6.984 -waveform {0 3.5} [get_nets {clk_pixel_x5}] -add
create_clock -name clk_audio -period 20833 -waveform {0 10000} [get_nets {video_inst/clk_audio}] -add
create_clock -name ds_clk -period 8000 -waveform {0 5} [get_nets {gamepad_p1/clk_spi}]
create_clock -name ds2_clk -period 8000 -waveform {0 5} [get_nets {gamepad_p2/clk_spi}]
report_timing -hold -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1
report_timing -setup -from_clock [get_clocks {clk*}] -to_clock [get_clocks {clk*}] -max_paths 25 -max_common_paths 1

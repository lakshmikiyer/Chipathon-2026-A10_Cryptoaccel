###############################################################################
# Created by write_sdc
###############################################################################
current_design A10_A
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name clk_IN -period 62.5000 [get_ports {clk_IN}]
set_clock_transition 0.1500 [get_clocks {clk_IN}]
set_clock_uncertainty 0.5000 clk_IN
set_propagated_clock [get_clocks {clk_IN}]
create_clock -name sclk_IN -period 2000.0000 [get_ports {sclk_IN}]
set_clock_transition 0.1500 [get_clocks {sclk_IN}]
set_clock_uncertainty 0.5000 sclk_IN
set_propagated_clock [get_clocks {sclk_IN}]
set_input_delay 0.5000 -clock [get_clocks {sclk_IN}] -clock_fall -min -add_delay [get_ports {cs_n_IN}]
set_input_delay 1.5000 -clock [get_clocks {sclk_IN}] -clock_fall -max -add_delay [get_ports {cs_n_IN}]
set_input_delay 0.5000 -clock [get_clocks {sclk_IN}] -clock_fall -min -add_delay [get_ports {mosi_IN}]
set_input_delay 1.5000 -clock [get_clocks {sclk_IN}] -clock_fall -max -add_delay [get_ports {mosi_IN}]
set_output_delay 0.5000 -clock [get_clocks {sclk_IN}] -min -add_delay [get_ports {miso_OUT}]
set_output_delay 1.5000 -clock [get_clocks {sclk_IN}] -max -add_delay [get_ports {miso_OUT}]
set_false_path\
    -from [get_ports {rst_n_IN}]
###############################################################################
# Environment
###############################################################################
set_load -pin_load 0.0729 [get_ports {miso_OUT}]
set_driving_cell -lib_cell gf180mcu_fd_sc_mcu7t5v0__inv_1 -pin {ZN} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {cs_n_IN}]
set_driving_cell -lib_cell gf180mcu_fd_sc_mcu7t5v0__inv_1 -pin {ZN} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {mosi_IN}]
set_driving_cell -lib_cell gf180mcu_fd_sc_mcu7t5v0__inv_1 -pin {ZN} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {rst_n_IN}]
###############################################################################
# Design Rules
###############################################################################
set_max_transition 6.0000 [current_design]

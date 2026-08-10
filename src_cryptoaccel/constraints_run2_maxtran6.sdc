# ASCON 128a Accelerator Full design  Constraints SDC
 
set_units -time 1.0ns
set_units -capacitance 1.0pF

# 1. Clock Definition
if { [info exists ::env(CLOCK_PORT)] } {
    set EXTCLK1 $::env(CLOCK_PORT)
} else {
    set EXTCLK1 "clk"
}

if { [info exists ::env(CLOCK_PERIOD)] } {
    set EXTCLK1_PERIOD $::env(CLOCK_PERIOD)
} else {
    set EXTCLK1_PERIOD 62.5
}

create_clock -name "$EXTCLK1" -period "$EXTCLK1_PERIOD" -waveform "0 [expr $EXTCLK1_PERIOD/2]" [get_ports $EXTCLK1]



set EXTCLK2 "sclk" ;


if { [info exists ::env(SCLK_PERIOD)] } {
    set EXTCLK2_PERIOD $::env(SCLK_PERIOD)
} else {
    set EXTCLK2_PERIOD [expr {$EXTCLK1_PERIOD * 32}]
}
create_clock -name "$EXTCLK2" -period "$EXTCLK2_PERIOD" -waveform "0 [expr $EXTCLK2_PERIOD/2]" [get_ports $EXTCLK2]

# CDC: the two domains are unrelated (toggle + 2FF synchronizers in the RTL).
#set_false_path -from [get_clocks $EXTCLK1] -to [get_clocks $EXTCLK2]
#set_false_path -from [get_clocks $EXTCLK2] -to [get_clocks $EXTCLK1]






set_false_path -from [get_ports rst_n]


# 2. Clock Uncertainty and Transition
set SETUP_UNCERTAINTY 0.5
set HOLD_UNCERTAINTY 0.5     
set_clock_uncertainty -setup $SETUP_UNCERTAINTY [get_clocks $EXTCLK1]
set_clock_uncertainty -hold $HOLD_UNCERTAINTY [get_clocks $EXTCLK1]
set_clock_uncertainty -setup $SETUP_UNCERTAINTY [get_clocks $EXTCLK2]
set_clock_uncertainty -hold $HOLD_UNCERTAINTY [get_clocks $EXTCLK2]


if { [info exists ::env(CLOCK_TRANSITION_CONSTRAINT)] } {
    set_clock_transition $::env(CLOCK_TRANSITION_CONSTRAINT) [get_clocks $EXTCLK1]
} else {
    set_clock_transition 0.15 [get_clocks $EXTCLK1]
}

if { [info exists ::env(CLOCK_TRANSITION_CONSTRAINT)] } {
    set_clock_transition $::env(CLOCK_TRANSITION_CONSTRAINT) [get_clocks $EXTCLK2]
} else {
    set_clock_transition 0.15 [get_clocks $EXTCLK2]
}

# 3. Input / Output Delays
#
# Split into -max (setup) and -min (hold). Previously a single value was given
# with neither switch, which makes OpenSTA apply it to BOTH, so hold analysis on
# the SPI pins was using the max numbers.
set MAX_IN_DELAY  1.50
set MIN_IN_DELAY  0.50
set MAX_OUT_DELAY 1.50
set MIN_OUT_DELAY 0.50

# mosi / cs_n are sampled on the sclk FALLING edge (spi_slave.v: always @(negedge
# sclk)), so the input delay is referenced to the falling edge via -clock_fall.
set_input_delay -clock [get_clocks $EXTCLK2] -clock_fall -max $MAX_IN_DELAY -add_delay [get_ports {mosi cs_n}]
set_input_delay -clock [get_clocks $EXTCLK2] -clock_fall -min $MIN_IN_DELAY -add_delay [get_ports {mosi cs_n}]

# miso is driven on the sclk RISING edge (SPI mode 1: CPOL=0, CPHA=1).
set_output_delay -clock [get_clocks $EXTCLK2] -max $MAX_OUT_DELAY -add_delay [get_ports {miso}]
set_output_delay -clock [get_clocks $EXTCLK2] -min $MIN_OUT_DELAY -add_delay [get_ports {miso}]

# 4. Driving Cell / Load Modeling


if { [info exists ::env(SYNTH_DRIVING_CELL)] } {
    set IN_DRV $::env(SYNTH_DRIVING_CELL)
} else {
    set IN_DRV "gf180mcu_fd_sc_mcu7t5v0__inv_1/ZN"
}
set_driving_cell -lib_cell [lindex [split $IN_DRV "/"] 0] \
                 -pin      [lindex [split $IN_DRV "/"] 1] \
                 [get_ports {rst_n mosi cs_n}]

# Output load. The PDK value is OUTPUT_CAP_LOAD = 72.91fF; units here are pF.
if { [info exists ::env(OUTPUT_CAP_LOAD)] } {
    set_load [expr {$::env(OUTPUT_CAP_LOAD) / 1000.0}] [all_outputs]
} else {
    set_load 0.0729 [all_outputs]
}

# 5. Global DRC Constraints
#


if { [info exists ::env(MAX_TRANSITION_CONSTRAINT)] } {
    set MAXTRANS $::env(MAX_TRANSITION_CONSTRAINT)
} else {
    set MAXTRANS 6.0
}

set_max_transition $MAXTRANS [current_design]






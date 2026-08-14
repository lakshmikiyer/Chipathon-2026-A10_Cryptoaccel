# ============================================================================
# chip_top.sdc  -  Chipathon 2026 padring top level
#
# This is the TEMPLATE base SDC (env-var driven) plus a Team A10 section at the
# end. The base file only creates ONE clock ("Multi-clock files are not
# currently supported"), but the Ascon accelerator has TWO asynchronous input
# clocks - clk and sclk - so sclk must be added here or its whole domain goes
# unconstrained.
#
# Pad mapping (keep in sync with src/pad_map.svh):
#   bidir_PAD[12]=clk  [13]=rst_n  [14]=sclk  [15]=mosi  [16]=cs_n  [17]=miso
#
# Set in config: CLOCK_PORT: "bidir_PAD[12]"
# ============================================================================

current_design $::env(DESIGN_NAME)

set_units -time ns

set clock_port __VIRTUAL_CLK__
if { [info exists ::env(CLOCK_PORT)] } {
    set port_count [llength $::env(CLOCK_PORT)]
    if { $port_count == "0" } {
        puts "\[WARNING] No CLOCK_PORT found. A dummy clock will be used."
    } elseif { $port_count != "1" } {
        puts "\[WARNING] Multi-clock files are not currently supported by the base SDC file. Only the first clock will be constrained."
    }
    if { $port_count > "0" } {
        set ::clock_port [lindex $::env(CLOCK_PORT) 0]
    }
}

if { $::env(CLOCK_PORT) == $::env(CLOCK_NET) } {
    set port_args [get_ports $clock_port]
} else {
    set port_args [get_pins [lindex $::env(CLOCK_NET) 0]]
}

puts "\[INFO] Using clock $clock_port..."
create_clock {*}$port_args -name $clock_port -period $::env(CLOCK_PERIOD)

set input_delay_value  [expr $::env(CLOCK_PERIOD) * $::env(IO_DELAY_CONSTRAINT) / 100]
set output_delay_value [expr $::env(CLOCK_PERIOD) * $::env(IO_DELAY_CONSTRAINT) / 100]
puts "\[INFO] Setting output delay to: $output_delay_value"
puts "\[INFO] Setting input delay to: $input_delay_value"

set_max_fanout $::env(MAX_FANOUT_CONSTRAINT) [current_design]

if { [info exists ::env(MAX_TRANSITION_CONSTRAINT)] } {
    set_max_transition $::env(MAX_TRANSITION_CONSTRAINT) [current_design]
}
if { [info exists ::env(MAX_CAPACITANCE_CONSTRAINT)] } {
    set_max_capacitance $::env(MAX_CAPACITANCE_CONSTRAINT) [current_design]
}

set clocks [get_clocks $clock_port]

# ---------------------------------------------------------------------------
# [A10 EDIT] Pads owned by the Ascon block are constrained in the A10 section
# below, against their own clock. Exclude them here so the base file does not
# also reference them to clk (delays would accumulate with -add_delay, and the
# SPI pins belong to the sclk domain, not clk).
# ---------------------------------------------------------------------------
set a10_spi_pads [get_ports { bidir_PAD[14] bidir_PAD[15] bidir_PAD[16] bidir_PAD[17] }]
set a10_clk_pads [get_ports { bidir_PAD[12] bidir_PAD[13] }]


set clk_core_inout_ports [get_ports {
    bidir_PAD[0]  bidir_PAD[1]  bidir_PAD[2]  bidir_PAD[3]
    bidir_PAD[4]  bidir_PAD[5]  bidir_PAD[6]  bidir_PAD[7]
    bidir_PAD[8]  bidir_PAD[9]  bidir_PAD[10] bidir_PAD[11]
    bidir_PAD[18] bidir_PAD[19]
}]

set_input_delay  -min 0                   -clock $clocks $clk_core_inout_ports
set_input_delay  -max $input_delay_value  -clock $clocks $clk_core_inout_ports
set_output_delay      $output_delay_value -clock $clocks $clk_core_inout_ports

# Input-only pads
set clk_core_input_ports [get_ports {
    rst_n_PAD
    input_PAD[*]
}]
set_input_delay -min 0                  -clock $clocks $clk_core_input_ports
set_input_delay -max $input_delay_value -clock $clocks $clk_core_input_ports

# Output load
set cap_load [expr $::env(OUTPUT_CAP_LOAD) / 1000.0]
puts "\[INFO] Setting load to: $cap_load"
set_load $cap_load [all_outputs]

puts "\[INFO] Setting clock uncertainty to: $::env(CLOCK_UNCERTAINTY_CONSTRAINT)"
set_clock_uncertainty $::env(CLOCK_UNCERTAINTY_CONSTRAINT) $clocks

puts "\[INFO] Setting clock transition to: $::env(CLOCK_TRANSITION_CONSTRAINT)"
set_clock_transition $::env(CLOCK_TRANSITION_CONSTRAINT) $clocks

puts "\[INFO] Setting timing derate to: $::env(TIME_DERATING_CONSTRAINT)%"
set_timing_derate -early [expr 1-[expr $::env(TIME_DERATING_CONSTRAINT) / 100]]
set_timing_derate -late  [expr 1+[expr $::env(TIME_DERATING_CONSTRAINT) / 100]]

# ===========================================================================
# ===============  TEAM A10 ADDITIONS - Ascon-AEAD128 block  ================
# ===========================================================================

# ---- 1. Second clock: sclk (SPI bit clock, asynchronous to clk) ------------
if { [info exists ::env(SCLK_PERIOD)] } {
    set A10_SCLK_PERIOD $::env(SCLK_PERIOD)
} else {
    set A10_SCLK_PERIOD [expr {$::env(CLOCK_PERIOD) * 32}]
}
puts "\[INFO] \[A10] Creating sclk on bidir_PAD\[14] with period $A10_SCLK_PERIOD"
create_clock -name sclk -period $A10_SCLK_PERIOD [get_ports { bidir_PAD[14] }]

set a10_sclk [get_clocks sclk]

# ---- 2. CDC: clk and sclk cross only through 2FF synchronizers -------------
#set_clock_groups -asynchronous -group $clocks -group $a10_sclk
#set_false_path -from $clocks   -to $a10_sclk
#set_false_path -from $a10_sclk -to $clocks

# ---- 3. Asynchronous reset -------------------------------------------------
set_false_path -from [get_ports { bidir_PAD[13] }]

# ---- 4. sclk uncertainty / transition --------------------------------------
set_clock_uncertainty $::env(CLOCK_UNCERTAINTY_CONSTRAINT) $a10_sclk
set_clock_transition  $::env(CLOCK_TRANSITION_CONSTRAINT)  $a10_sclk

# ---- 5. SPI I/O delays, referenced to sclk ---------------------------------
# mosi / cs_n are sampled on the sclk FALLING edge (spi_slave: @(negedge sclk))
# miso is driven on the sclk RISING edge (SPI mode 1: CPOL=0, CPHA=1)
set A10_MAX_IN  1.50
set A10_MIN_IN  0.50
set A10_MAX_OUT 1.50
set A10_MIN_OUT 0.50

set_input_delay -clock $a10_sclk -clock_fall -max $A10_MAX_IN -add_delay \
    [get_ports { bidir_PAD[15] bidir_PAD[16] }]
set_input_delay -clock $a10_sclk -clock_fall -min $A10_MIN_IN -add_delay \
    [get_ports { bidir_PAD[15] bidir_PAD[16] }]

set_output_delay -clock $a10_sclk -max $A10_MAX_OUT -add_delay [get_ports { bidir_PAD[17] }]
set_output_delay -clock $a10_sclk -min $A10_MIN_OUT -add_delay [get_ports { bidir_PAD[17] }]

# ===========================================================================
# ===================  END TEAM A10 ADDITIONS  ==============================
# ===========================================================================

if { [info exists ::env(OPENLANE_SDC_IDEAL_CLOCKS)] && $::env(OPENLANE_SDC_IDEAL_CLOCKS) } {
    unset_propagated_clock [all_clocks]
} else {
    set_propagated_clock [all_clocks]
}

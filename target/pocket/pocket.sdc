#
# APF constraints
# Do not edit this file.
#
# Add your own constraints in the \core_constraints.sdc in the core directory, which will also be loaded.

create_clock -name clk_74a -period 13.468 [get_ports clk_74a]
create_clock -name clk_74b -period 13.468 [get_ports clk_74b]
create_clock -name bridge_spiclk -period 13.468 [get_ports bridge_spiclk]

# autogenerate PLL clock names for use down below
derive_pll_clocks
derive_clock_uncertainty

# This is tDS in the data sheet, setup time, spec is 1.5ns
set_output_delay -clock dram_clk -max 1.5 \
    [get_ports {dram_a[*] dram_ba[*] dram_cke dram_dqm[*] \
                dram_dq[*] dram_ras_n dram_cas_n dram_we_n}]

# this is tdh in the data sheet, hold time, spec is 0.8ns
set_output_delay -clock  dram_clk -min -0.8 \
    [get_ports {dram_a[*] dram_ba[*] dram_cke dram_dqm[*] \
                dram_dq[*] dram_ras_n dram_cas_n dram_we_n}]


# load in user constraints 
# read_sdc "core/core_constraints.sdc"

# JTFRAME specific:

set_false_path -to [get_keepers {*|jtframe_sync:*|synchronizer[*].s[0]}]

set_false_path -from [get_keepers {io_pad_controller:ipm|cont1_key[*]}] -to [get_keepers {jtframe_pocket_top:ic|jtframe_pocket:u_frame|jtframe_board:u_board|jtframe_inputs:u_inputs|joy1_sync[*]}]

set_false_path -from [get_keepers {io_pad_controller:ipm|cont2_key[*]}] -to [get_keepers {jtframe_pocket_top:ic|jtframe_pocket:u_frame|jtframe_board:u_board|jtframe_inputs:u_inputs|joy2_sync[*]}]

set_false_path -from [get_keepers {io_pad_controller:ipm|cont3_key[*]}] -to [get_keepers {jtframe_pocket_top:ic|jtframe_pocket:u_frame|jtframe_board:u_board|jtframe_inputs:u_inputs|joy3_sync[*]}]

set_false_path -from [get_keepers {io_pad_controller:ipm|cont4_key[*]}] -to [get_keepers {jtframe_pocket_top:ic|jtframe_pocket:u_frame|jtframe_board:u_board|jtframe_inputs:u_inputs|joy4_sync[*]}]

set_false_path -from [get_keepers {io_pad_controller:ipm|cont1_key[*]}] -to [get_keepers {jtframe_pocket_top:ic|jtframe_pocket:u_frame|jtframe_board:u_board|jtframe_inputs:u_inputs|game_start[*]}]

set_false_path -from [get_keepers {io_pad_controller:ipm|cont1_key[*]}] -to [get_keepers {jtframe_pocket_top:ic|jtframe_pocket:u_frame|jtframe_board:u_board|jtframe_inputs:u_inputs|game_coin[*]}]

set_false_path -from [get_keepers {io_pad_controller:ipm|cont2_key[*]}] -to [get_keepers {jtframe_pocket_top:ic|jtframe_pocket:u_frame|jtframe_board:u_board|jtframe_inputs:u_inputs|game_start[*]}]

set_false_path -from [get_keepers {io_pad_controller:ipm|cont2_key[*]}] -to [get_keepers {jtframe_pocket_top:ic|jtframe_pocket:u_frame|jtframe_board:u_board|jtframe_inputs:u_inputs|game_coin[*]}]

set_false_path -from [get_keepers {io_pad_controller:ipm|cont3_key[*]}] -to [get_keepers {jtframe_pocket_top:ic|jtframe_pocket:u_frame|jtframe_board:u_board|jtframe_inputs:u_inputs|game_start[*]}]

set_false_path -from [get_keepers {io_pad_controller:ipm|cont3_key[*]}] -to [get_keepers {jtframe_pocket_top:ic|jtframe_pocket:u_frame|jtframe_board:u_board|jtframe_inputs:u_inputs|game_coin[*]}]

set_false_path -from [get_keepers {io_pad_controller:ipm|cont4_key[*]}] -to [get_keepers {jtframe_pocket_top:ic|jtframe_pocket:u_frame|jtframe_board:u_board|jtframe_inputs:u_inputs|game_start[*]}]

set_false_path -from [get_keepers {io_pad_controller:ipm|cont4_key[*]}] -to [get_keepers {jtframe_pocket_top:ic|jtframe_pocket:u_frame|jtframe_board:u_board|jtframe_inputs:u_inputs|game_coin[*]}]

set_false_path -from [get_keepers {jtframe_pocket_top:ic|jtframe_pocket:u_frame|jtframe_pocket_base:u_base|core_bridge_cmd:u_bridge|reset_n}] -to [get_keepers {jtframe_pocket_top:ic|jtframe_pocket:u_frame|jtframe_board:u_board|jtframe_reset:u_reset|rst_req_sync[0]}]





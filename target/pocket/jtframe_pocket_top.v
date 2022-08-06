/*  This file is part of JTFRAME.
    JTFRAME program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTFRAME program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTFRAME.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 6-8-2022 */

// This is the Pocket top level, based on the official
// core template from Analogue

module jtframe_pocket_top(
    ///////////////////////////////////////////////////
    // clock inputs 74.25mhz. not phase aligned, so treat these domains as asynchronous

    input             clk_74a, // mainclk1
    input             clk_74b, // mainclk1

    ///////////////////////////////////////////////////
    // cartridge interface
    // switches between 3.3v and 5v mechanically
    // output enable for multibit translators controlled by pic32

    // GBA AD[15:8]
    inout     [7:0]   cart_tran_bank2,
    output            cart_tran_bank2_dir,

    // GBA AD[7:0]
    inout     [7:0]   cart_tran_bank3,
    output            cart_tran_bank3_dir,

    // GBA A[23:16]
    inout     [7:0]   cart_tran_bank1,
    output            cart_tran_bank1_dir,

    // GBA [7] PHI#
    // GBA [6] WR#
    // GBA [5] RD#
    // GBA [4] CS1#/CS#
    //     [3:0] unwired
    inout     [7:4]   cart_tran_bank0,
    output            cart_tran_bank0_dir,

    // GBA CS2#/RES#
    inout             cart_tran_pin30,
    output            cart_tran_pin30_dir,
    // when GBC cart is inserted, this signal when low or weak will pull GBC /RES low with a special circuit
    // the goal is that when unconfigured, the FPGA weak pullups won't interfere.
    // thus, if GBC cart is inserted, FPGA must drive this high in order to let the level translators
    // and general IO drive this pin.
    output            cart_pin30_pwroff_reset,

    // GBA IRQ/DRQ
    inout             cart_tran_pin31,
    output            cart_tran_pin31_dir,

    // infrared
    input             port_ir_rx,
    output            port_ir_tx,
    output            port_ir_rx_disable,

    // GBA link port
    inout             port_tran_si,
    output            port_tran_si_dir,
    inout             port_tran_so,
    output            port_tran_so_dir,
    inout             port_tran_sck,
    output            port_tran_sck_dir,
    inout             port_tran_sd,
    output            port_tran_sd_dir,

    ///////////////////////////////////////////////////
    // cellular psram 0 and 1, two chips (64Mbit x2 dual die per chip)

    output    [21:16] cram0_a,
    inout     [15:0]  cram0_dq,
    input             cram0_wait,
    output            cram0_clk,
    output            cram0_adv_n,
    output            cram0_cre,
    output            cram0_ce0_n,
    output            cram0_ce1_n,
    output            cram0_oe_n,
    output            cram0_we_n,
    output            cram0_ub_n,
    output            cram0_lb_n,

    output    [21:16] cram1_a,
    inout     [15:0]  cram1_dq,
    input             cram1_wait,
    output            cram1_clk,
    output            cram1_adv_n,
    output            cram1_cre,
    output            cram1_ce0_n,
    output            cram1_ce1_n,
    output            cram1_oe_n,
    output            cram1_we_n,
    output            cram1_ub_n,
    output            cram1_lb_n,

    ///////////////////////////////////////////////////
    // sdram, 512 Mbit 16bit (64 MBytes)

    output    [12:0]  dram_a,
    output    [1:0]   dram_ba,
    inout     [15:0]  dram_dq,
    output    [1:0]   dram_dqm,
    output            dram_clk,
    output            dram_cke,
    output            dram_ras_n,
    output            dram_cas_n,
    output            dram_we_n,

    ///////////////////////////////////////////////////
    // sram, 1 Mbit 16bit

    output    [16:0]  sram_a,
    inout     [15:0]  sram_dq,
    output            sram_oe_n,
    output            sram_we_n,
    output            sram_ub_n,
    output            sram_lb_n,

    ///////////////////////////////////////////////////
    // vblank driven by dock for sync in a certain mode

    input             vblank,

    ///////////////////////////////////////////////////
    // i/o to 6515D breakout usb uart

    output            dbg_tx,
    input             dbg_rx,

    ///////////////////////////////////////////////////
    // i/o pads near jtag connector user can solder to

    output            user1,
    input             user2,

    ///////////////////////////////////////////////////
    // RFU internal i2c bus

    inout             aux_sda,
    output            aux_scl,

    ///////////////////////////////////////////////////
    // RFU, do not use
    output            vpll_feed,


    //
    // logical connections
    //

    // video, audio output to scaler
    output    [23:0]  video_rgb,
    output            video_rgb_clock,
    output            video_rgb_clock_90,
    output            video_de,
    output            video_skip,
    output            video_vs,
    output            video_hs,

    output            audio_mclk,
    input             audio_adc,
    output            audio_dac,
    output            audio_lrck,
    // bridge bus connection
    // synchronous to clk_74a
    output            bridge_endian_little,
    input     [31:0]  bridge_addr,
    input             bridge_rd,
    output    [31:0]  bridge_rd_data,
    input             bridge_wr,
    input     [31:0]  bridge_wr_data,

    // controller data
    input     [15:0]  cont1_key,
    input     [15:0]  cont2_key,
    input     [15:0]  cont3_key,
    input     [15:0]  cont4_key,
    input     [31:0]  cont1_joy,
    input     [31:0]  cont2_joy,
    input     [31:0]  cont3_joy,
    input     [31:0]  cont4_joy,
    input     [15:0]  cont1_trig,
    input     [15:0]  cont2_trig,
    input     [15:0]  cont3_trig,
    input     [15:0]  cont4_trig
);

// not using the IR port, so turn off both the LED, and
// disable the receive circuit to save power
assign port_ir_tx         = 0;
assign port_ir_rx_disable = 1;

// bridge endianness
assign bridge_endian_little = 0;

// cart is unused, so set all level translators accordingly
// directions are 0:IN, 1:OUT
assign cart_tran_bank3         = 8'hzz;
assign cart_tran_bank3_dir     = 1'b0;
assign cart_tran_bank2         = 8'hzz;
assign cart_tran_bank2_dir     = 1'b0;
assign cart_tran_bank1         = 8'hzz;
assign cart_tran_bank1_dir     = 1'b0;
assign cart_tran_bank0         = 4'hf;
assign cart_tran_bank0_dir     = 1'b1;
assign cart_tran_pin30         = 1'b0;      // reset or cs2, we let the hw control it by itself
assign cart_tran_pin30_dir     = 1'bz;
assign cart_pin30_pwroff_reset = 1'b0;  // hardware can control this
assign cart_tran_pin31         = 1'bz;      // input
assign cart_tran_pin31_dir     = 1'b0;  // input

// link port is input only
assign port_tran_so      = 1'bz;
assign port_tran_so_dir  = 1'b0;     // SO is output only
assign port_tran_si      = 1'bz;
assign port_tran_si_dir  = 1'b0;     // SI is input only
assign port_tran_sck     = 1'bz;
assign port_tran_sck_dir = 1'b0;    // clock direction can change
assign port_tran_sd      = 1'bz;
assign port_tran_sd_dir  = 1'b0;     // SD is input and not used

localparam GAME_BUTTONS=`JTFRAME_BUTTONS;

jtframe_pocket #(
    .SDRAMW       ( SDRAMW         ),
    .SIGNED_SND   ( `JTFRAME_SIGNED_SND    ),
    .BUTTONS      ( GAME_BUTTONS   ),
    .DIPBASE      ( DIPBASE        ),
    .COLORW       ( COLORW         )
    `ifdef JTFRAME_WIDTH
    ,.VIDEO_WIDTH ( `JTFRAME_WIDTH )
    `endif
    `ifdef JTFRAME_HEIGHT
    ,.VIDEO_HEIGHT(`JTFRAME_HEIGHT )
    `endif
)
u_frame(
    .clk_sys        ( clk_sys        ),
    .clk_rom        ( clk_rom        ),
    .clk_pico       ( clk_pico       ),
    .pll_locked     ( pll_locked     ),
    .status         ( status         ),
    // Base video
    .game_r         ( red            ),
    .game_g         ( green          ),
    .game_b         ( blue           ),
    .LHBL           ( LHBL           ),
    .LVBL           ( LVBL           ),
    .hs             ( hs             ),
    .vs             ( vs             ),
    .pxl_cen        ( pxl_cen        ),
    .pxl2_cen       ( pxl2_cen       ),
    // MiST VGA pins
    .pck_rgb        ( video_rgb      ),
    .pck_rgb_clk    ( video_rgb_clock),
    .pck_rgb_clk90  ( video_rgb_clock_90 ),
    .pck_de         ( video_de       ),
    .pck_skip       ( video_skip     ),
    .pck_vs         ( video_vs       ),
    .pck_hs         ( video_hs       ),
    // LED
    .game_led       ( game_led       ),
    // UART
`ifndef JTFRAME_UART
    .uart_rx        ( UART_RX        ),
    .uart_tx        ( UART_TX        ),
`else
    .uart_rx        ( 1'b1           ),
    .uart_tx        (                ),
`endif
    // SDRAM interface
    .SDRAM_DQ       ( SDRAM_DQ       ),
    .SDRAM_A        ( SDRAM_A        ),
    .SDRAM_DQML     ( SDRAM_DQML     ),
    .SDRAM_DQMH     ( SDRAM_DQMH     ),
    .SDRAM_nWE      ( SDRAM_nWE      ),
    .SDRAM_nCAS     ( SDRAM_nCAS     ),
    .SDRAM_nRAS     ( SDRAM_nRAS     ),
    .SDRAM_nCS      ( SDRAM_nCS      ),
    .SDRAM_BA       ( SDRAM_BA       ),
    .SDRAM_CKE      ( SDRAM_CKE      ),
    // SPI interface to arm io controller
    .SPI_DO         ( SPI_DO         ),
    .SPI_DI         ( SPI_DI         ),
    .SPI_SCK        ( SPI_SCK        ),
    .SPI_SS2        ( SPI_SS2        ),
    .SPI_SS3        ( SPI_SS3        ),
    .SPI_SS4        ( SPI_SS4        ),
    .CONF_DATA0     ( CONF_DATA0     ),

    // ROM access from game
    // Bank 0: allows R/W
    .ba0_addr   ( ba0_addr      ),
    .ba1_addr   ( ba1_addr      ),
    .ba2_addr   ( ba2_addr      ),
    .ba3_addr   ( ba3_addr      ),
    .ba_rd      ( ba_rd         ),
    .ba_wr      ({ 3'd0, ba_wr }),
    .ba_dst     ( ba_dst        ),
    .ba_dok     ( ba_dok        ),
    .ba_rdy     ( ba_rdy        ),
    .ba_ack     ( ba_ack        ),
    .ba0_din    ( ba0_din       ),
    .ba0_din_m  ( ba0_din_m     ),  // write mask

    // ROM-load interface
    .prog_addr  ( prog_addr     ),
    .prog_ba    ( prog_ba       ),
    .prog_rd    ( prog_rd       ),
    .prog_we    ( prog_we       ),
    .prog_data  ( prog_data     ),
    .prog_mask  ( prog_mask     ),
    .prog_ack   ( prog_ack      ),
    .prog_dst   ( prog_dst      ),
    .prog_dok   ( prog_dok      ),
    .prog_rdy   ( prog_rdy      ),

    // ROM load
    .ioctl_addr     ( ioctl_addr     ),
    .ioctl_dout     ( ioctl_dout     ),
    .ioctl_din      ( ioctl_din      ),
    .ioctl_wr       ( ioctl_wr       ),
    .ioctl_ram      ( ioctl_ram      ),

    .downloading    ( downloading    ),
    .dwnld_busy     ( dwnld_busy     ),

    .sdram_dout     ( sdram_dout     ),
//////////// board
    .rst            ( rst            ),
    .rst_n          ( rst_n          ), // unused
    .game_rst       ( game_rst       ),
    .game_rst_n     (                ),
    // reset forcing signals:
    .rst_req        ( rst_req        ),
    // Sound from game
    .snd_left       ( snd_left       ),
    .snd_right      ( snd_right      ),
    .snd_sample     ( sample         ),
    // Sound to Pcket
    .audio_mclk     ( audio_mclk     ),
    .audio_adc      ( audio_adc      ),
    .audio_dac      ( audio_dac      ),
    .audio_lrck     ( audio_lrck     ),    // joystick
    .game_joystick1 ( game_joy1      ),
    .game_joystick2 ( game_joy2      ),
    .game_joystick3 ( game_joy3      ),
    .game_joystick4 ( game_joy4      ),
    .game_coin      ( game_coin      ),
    .game_start     ( game_start     ),
    .game_service   ( game_service   ),
    .joyana_l1      ( joyana_l1      ),
    .joyana_l2      ( joyana_l2      ),
    .joyana_l3      ( joyana_l3      ),
    .joyana_l4      ( joyana_l4      ),
    .joyana_r1      ( joyana_r1      ),
    .joyana_r2      ( joyana_r2      ),
    .joyana_r3      ( joyana_r3      ),
    .joyana_r4      ( joyana_r4      ),
    // Paddle inputs
    .paddle_0       ( paddle_0       ),
    .paddle_1       ( paddle_1       ),
    .paddle_2       ( paddle_2       ),
    .paddle_3       ( paddle_3       ),
    // Mouse inputs
    .mouse_1p       ( mouse_1p       ),
    .mouse_2p       ( mouse_2p       ),
    .LED            ( LED            ),
    // Unused in MiST
    .BUTTON_n       ( 4'hf           ),
    .ps2_clk        (                ),
    .ps2_dout       (                ),
    .joy1_bus       (                ),
    .joy2_bus       (                ),
    .JOY_SELECT     (                ),
    // DIP and OSD settings
    .enable_fm      ( enable_fm      ),
    .enable_psg     ( enable_psg     ),
    .dip_test       ( dip_test       ),
    .dip_pause      ( dip_pause      ),
    .dip_flip       ( dip_flip       ),
    .dip_fxlevel    ( dip_fxlevel    ),
    // status
    .st_addr        ( st_addr        ),
    .st_dout        ( st_dout        ),
    // Debug
    .gfx_en         ( gfx_en         ),
    .debug_bus      ( debug_bus      ),
    .debug_view     ( debug_view     )
);

`GAMETOP
u_game(
    .rst         ( game_rst       ),
    // The main clock is always the same one as the SDRAM
    .clk         ( clk_rom        ),
`ifdef JTFRAME_CLK96
    .clk96       ( clk96          ),
    .rst96       ( rst96          ),
`endif
`ifdef JTFRAME_CLK48
    .clk48       ( clk48          ),
    .rst48       ( rst48          ),
`endif
`ifdef JTFRAME_CLK24
    .clk24       ( clk24          ),
    .rst24       ( rst24          ),
`endif
`ifdef JTFRAME_CLK6
    .clk6        ( clk6           ),
    .rst6        ( rst6           ),
`endif
    // Video
    .pxl2_cen    ( pxl2_cen       ),
    .pxl_cen     ( pxl_cen        ),
    .red         ( red            ),
    .green       ( green          ),
    .blue        ( blue           ),
    .LHBL        ( LHBL           ),
    .LVBL        ( LVBL           ),
    .HS          ( hs             ),
    .VS          ( vs             ),
    // LED
    .game_led    ( game_led[0]    ),

    .start_button( game_start[STARTW-1:0] ),
    .coin_input  ( game_coin[STARTW-1:0]  ),
    // Joysticks
    .joystick1    ( game_joy1[GAME_BUTTONS+3:0]   ),
    .joystick2    ( game_joy2[GAME_BUTTONS+3:0]   ),
    `ifdef JTFRAME_4PLAYERS
    .joystick3    ( game_joy3[GAME_BUTTONS+3:0]   ),
    .joystick4    ( game_joy4[GAME_BUTTONS+3:0]   ),
    `endif
`ifdef JTFRAME_PADDLE
    .paddle_0     ( paddle_0         ),
    .paddle_1     ( paddle_1         ),
    .paddle_2     ( paddle_2         ),
    .paddle_3     ( paddle_3         ),
`endif
`ifdef JTFRAME_MOUSE
    .mouse_1p     ( mouse_1p         ),
    .mouse_2p     ( mouse_2p         ),
`endif
`ifdef JTFRAME_ANALOG
    .joyana_l1    ( joyana_l1        ),
    .joyana_l2    ( joyana_l2        ),
    `ifdef JTFRAME_ANALOG_DUAL
        .joyana_r1    ( joyana_r1        ),
        .joyana_r2    ( joyana_r2        ),
    `endif
    `ifdef JTFRAME_4PLAYERS
        .joyana_l3( joyana_l3        ),
        .joyana_l4( joyana_l4        ),
        `ifdef JTFRAME_ANALOG_DUAL
            .joyana_r3( joyana_r3        ),
            .joyana_r4( joyana_r4        ),
        `endif
    `endif
`endif

    // Sound control
    .enable_fm   ( enable_fm      ),
    .enable_psg  ( enable_psg     ),
    // PROM programming
    .ioctl_addr  ( ioctl_addr     ),
    .ioctl_dout  ( ioctl_dout     ),
    .ioctl_wr    ( ioctl_wr       ),
`ifdef JTFRAME_IOCTL_RD
    .ioctl_ram   ( ioctl_ram      ),
    .ioctl_din   ( ioctl_din      ),
`endif
    // ROM load
    .downloading ( downloading    ),
    .dwnld_busy  ( dwnld_busy     ),
    .data_read   ( sdram_dout     ),

`ifdef JTFRAME_SDRAM_BANKS
    // Bank 0: allows R/W
    .ba0_addr   ( ba0_addr      ),
    .ba1_addr   ( ba1_addr      ),
    .ba2_addr   ( ba2_addr      ),
    .ba3_addr   ( ba3_addr      ),
    .ba_rd      ( ba_rd         ),
    .ba_wr      ( ba_wr         ),
    .ba_dst     ( ba_dst        ),
    .ba_dok     ( ba_dok        ),
    .ba_rdy     ( ba_rdy        ),
    .ba_ack     ( ba_ack        ),
    .ba0_din    ( ba0_din       ),
    .ba0_din_m  ( ba0_din_m     ),  // write mask

    .prog_ba    ( prog_ba       ),
    .prog_rdy   ( prog_rdy      ),
    .prog_ack   ( prog_ack      ),
    .prog_dok   ( prog_dok      ),
    .prog_dst   ( prog_dst      ),
    .prog_data  ( prog_data     ),
`else
    .sdram_req  ( ba_rd[0]      ),
    .sdram_addr ( ba0_addr      ),
    .data_dst   ( ba_dst[0] | prog_dst ),
    .data_rdy   ( ba_rdy[0] | prog_rdy ),
    .sdram_ack  ( ba_ack[0] | prog_ack ),

    .prog_data  ( prog_data8    ),
`endif

    // common ROM-load interface
    .prog_addr  ( prog_addr     ),
    .prog_rd    ( prog_rd       ),
    .prog_we    ( prog_we       ),
    .prog_mask  ( prog_mask     ),

    // DIP switches
    .status      ( status[31:0]   ),
    .dip_pause   ( dip_pause      ),
    .dip_flip    ( dip_flip       ),
    .dip_test    ( dip_test       ),
    .dip_fxlevel ( dip_fxlevel    ),
    .service     ( game_service   ),
    .dipsw       ( dipsw          ),

`ifdef JTFRAME_GAME_UART
    .uart_tx     ( UART_TX        ),
    .uart_rx     ( UART_RX        ),
`endif

    // sound
`ifndef JTFRAME_STEREO
    .snd         ( snd_left       ),
`else
    .snd_left    ( snd_left       ),
    .snd_right   ( snd_right      ),
    `endif
    .sample      ( sample         ),
    // Debug
`ifdef JTFRAME_STATUS
    .st_addr     ( st_addr        ),
    .st_dout     ( st_dout        ),
`endif
    .gfx_en      ( gfx_en         )
`ifdef JTFRAME_DEBUG
   ,.debug_bus   ( debug_bus      )
   ,.debug_view  ( debug_view     )
`endif
);
    
endmodule

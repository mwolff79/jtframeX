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

`ifdef JTFRAME_SDRAM_LARGE
    localparam SDRAMW=23; // 64 MB
`else
    localparam SDRAMW=22; // 32 MB
`endif

wire          rst, rst_n, clk_sys, clk_rom, clk6, clk24, clk48, clk96;
wire [63:0]   status;
wire [31:0]   joystick1, joystick2;
wire [24:0]   ioctl_addr;
wire [ 7:0]   ioctl_dout, ioctl_din;
wire          ioctl_wr;
wire          ioctl_ram;

wire [15:0] joyana_l1, joyana_l2, joyana_l3, joyana_l4,
            joyana_r1, joyana_r2, joyana_r3, joyana_r4;

// ROM download
wire          downloading, dwnld_busy;

wire [SDRAMW-1:0] prog_addr;
wire [15:0]   prog_data;
`ifndef JTFRAME_SDRAM_BANKS
wire [ 7:0]   prog_data8;
`endif
wire [ 1:0]   prog_mask, prog_ba;
wire          prog_we, prog_rd, prog_rdy, prog_ack, prog_dst, prog_dok;

// ROM access from game
wire [SDRAMW-1:0] ba0_addr, ba1_addr, ba2_addr, ba3_addr;
wire [ 3:0] ba_rd, ba_rdy, ba_ack, ba_dst, ba_dok;
wire        ba_wr;
wire [15:0] ba0_din;
wire [ 1:0] ba0_din_m;
wire [15:0] sdram_dout;

`ifndef JTFRAME_COLORW
`define JTFRAME_COLORW 4
`endif

localparam COLORW=`JTFRAME_COLORW;

wire [COLORW-1:0] red;
wire [COLORW-1:0] green;
wire [COLORW-1:0] blue;

wire LHBL, LVBL, hs, vs;
wire [15:0] snd_left, snd_right;
wire        sample;

wire [9:0] game_joy1, game_joy2, game_joy3, game_joy4;
wire [3:0] game_coin, game_start;
wire       game_rst, game_service;
wire       rst96, rst48, rst24, rst6;
wire [3:0] gfx_en;
// SDRAM
wire data_rdy, sdram_ack;

// PLL's
wire pll_locked, clk_pico;


`ifndef JTFRAME_STEREO
assign snd_right = snd_left;
`endif

`ifndef JTFRAME_SDRAM_BANKS
    assign prog_data = {2{prog_data8}};
    assign ba_rd[3:1] = 0;
    assign ba_wr      = 0;
    assign prog_ba    = 0;
    // tie down unused bank signals
    assign ba1_addr   = 0;
    assign ba2_addr   = 0;
    assign ba3_addr   = 0;
    assign ba0_din    = 0;
    assign ba0_din_m  = 3;
`endif

jtframe_mist_clocks u_clocks(
    .clk_ext    ( clk_74b        ), // 74.25 MHz

    // PLL outputs
    .clk96      ( clk96          ),
    .clk48      ( clk48          ),
    .clk24      ( clk24          ),
    .clk6       ( clk6           ),
    .pll_locked ( pll_locked     ),

    // System clocks
    .clk_sys    ( clk_sys        ),
    .clk_rom    ( clk_rom        ),
    .SDRAM_CLK  ( dram_clk      ),

    // reset signals
    .game_rst   ( game_rst       ),
    .rst96      ( rst96          ),
    .rst48      ( rst48          ),
    .rst24      ( rst24          ),
    .rst6       ( rst6           )
);

assign clk_pico = clk48;

wire [ 7:0] debug_bus, debug_view;
wire [ 1:0] dip_fxlevel, game_led;
wire        enable_fm, enable_psg;
wire        dip_pause, dip_flip, dip_test;
wire        pxl_cen, pxl2_cen;
wire [ 7:0] st_addr, st_dout;
wire [ 7:0] paddle_0, paddle_1, paddle_2, paddle_3;
wire [15:0] mouse_1p, mouse_2p;

`ifdef SIMULATION
assign sim_pxl_clk    = clk_sys;
assign sim_pxl_cen    = pxl_cen;
assign sim_vb         = ~LVBL;
assign sim_hb         = ~LHBL;
assign sim_dwnld_busy = dwnld_busy;
`endif

`ifndef JTFRAME_SIGNED_SND
`define JTFRAME_SIGNED_SND 1'b1
`endif

`ifndef JTFRAME_BUTTONS
`define JTFRAME_BUTTONS 2
`endif

`ifdef JTFRAME_MIST_DIPBASE
localparam DIPBASE=`JTFRAME_MIST_DIPBASE;
`else
localparam DIPBASE=16;
`endif

assign game_led[1] = 1'b0; // Let system LED info go through too

localparam GAME_BUTTONS=`JTFRAME_BUTTONS;

// Unused Pocket ports
assign port_ir_tx         = 0;
assign port_ir_rx_disable = 1;
assign cart_tran_bank3         = 8'hzz;
assign cart_tran_bank3_dir     = 0;
assign cart_tran_bank2         = 8'hzz;
assign cart_tran_bank2_dir     = 0;
assign cart_tran_bank1         = 8'hzz;
assign cart_tran_bank1_dir     = 0;
assign cart_tran_bank0         = 4'hf;
assign cart_tran_bank0_dir     = 1;
assign cart_tran_pin30         = 0;
assign cart_tran_pin30_dir     = 1'bz;
assign cart_pin30_pwroff_reset = 0;
assign cart_tran_pin31         = 1'bz;
assign cart_tran_pin31_dir     = 0;
assign port_tran_so            = 1'bz;
assign port_tran_so_dir        = 0;
assign port_tran_si            = 1'bz;
assign port_tran_si_dir        = 0;
assign port_tran_sck           = 1'bz;
assign port_tran_sck_dir       = 0;
assign port_tran_sd            = 1'bz;
assign port_tran_sd_dir        = 0;
assign sram_a                  = 0;
assign sram_dq                 = 0;
assign sram_oe_n               = 1;
assign sram_we_n               = 1;
assign sram_ub_n               = 1;
assign sram_lb_n               = 1;
assign cram1_a                 = 0;
assign cram1_dq                = 0;
assign cram1_clk               = 0;
assign cram1_adv_n             = 1;
assign cram1_cre               = 0;
assign cram1_ce0_n             = 1;
assign cram1_ce1_n             = 1;
assign cram1_oe_n              = 1;
assign cram1_we_n              = 1;
assign cram1_ub_n              = 1;
assign cram1_lb_n              = 1;

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
    .clk_74a        ( clk_74a        ),
    .clk_sys        ( clk_sys        ),
    .clk_rom        ( clk_rom        ),
    .clk_pico       ( clk_pico       ),
    .pll_locked     ( pll_locked     ),
    .status         ( status         ),
    // Bridge
    .bridge_addr    ( bridge_addr   ),
    .bridge_rd      ( bridge_rd     ),
    .bridge_rd_data ( bridge_rd_data),
    .bridge_wr      ( bridge_wr     ),
    .bridge_wr_data ( bridge_wr_data),
    .bridge_endian_little(bridge_endian_little),
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
    // Pocket video pins
    .pck_rgb        ( video_rgb      ),
    .pck_rgb_clk    ( video_rgb_clock),
    .pck_rgb_clkq   ( video_rgb_clock_90 ),
    .pck_de         ( video_de       ),
    .pck_vs         ( video_vs       ),
    .pck_hs         ( video_hs       ),
    .pck_skip       ( video_skip     ),
    // LED
    .game_led       ( game_led       ),
    // SDRAM interface
    .SDRAM_DQ       ( dram_dq        ),
    .SDRAM_A        ( dram_a         ),
    .SDRAM_DQML     ( dram_dqm[0]    ),
    .SDRAM_DQMH     ( dram_dqm[1]    ),
    .SDRAM_nWE      ( dram_we_n      ),
    .SDRAM_nCAS     ( dram_cas_n     ),
    .SDRAM_nRAS     ( dram_ras_n     ),
    .SDRAM_nCS      (                ),
    .SDRAM_BA       ( dram_ba        ),
    .SDRAM_CKE      ( dram_cke       ),
    // Controllers
    .cont1_trig     ( cont1_trig     ),
    .cont2_trig     ( cont2_trig     ),
    .cont3_trig     ( cont3_trig     ),
    .cont4_trig     ( cont4_trig     ),
    .cont1_joy      ( cont1_joy      ),
    .cont2_joy      ( cont2_joy      ),
    .cont3_joy      ( cont3_joy      ),
    .cont4_joy      ( cont4_joy      ),
    .cont1_key      ( cont1_key      ),
    .cont2_key      ( cont2_key      ),
    .cont3_key      ( cont3_key      ),
    .cont4_key      ( cont4_key      ),
    // ROM access from game
    // Bank 0: allows R/W
    .ba0_addr       ( ba0_addr       ),
    .ba1_addr       ( ba1_addr       ),
    .ba2_addr       ( ba2_addr       ),
    .ba3_addr       ( ba3_addr       ),
    .ba_rd          ( ba_rd          ),
    .ba_wr          ({ 3'd0, ba_wr } ),
    .ba_dst         ( ba_dst         ),
    .ba_dok         ( ba_dok         ),
    .ba_rdy         ( ba_rdy         ),
    .ba_ack         ( ba_ack         ),
    .ba0_din        ( ba0_din        ),
    .ba0_din_m      ( ba0_din_m      ),  // write mask

    // ROM-load interface
    .prog_addr      ( prog_addr      ),
    .prog_ba        ( prog_ba        ),
    .prog_rd        ( prog_rd        ),
    .prog_we        ( prog_we        ),
    .prog_data      ( prog_data      ),
    .prog_mask      ( prog_mask      ),
    .prog_ack       ( prog_ack       ),
    .prog_dst       ( prog_dst       ),
    .prog_dok       ( prog_dok       ),
    .prog_rdy       ( prog_rdy       ),

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

`ifdef JTFRAME_4PLAYERS
localparam STARTW=4;
`else
localparam STARTW=2;
`endif

// For simulation, either ~32'd0 or `JTFRAME_SIM_DIPS will be used for DIPs
`ifdef SIMULATION
`ifndef JTFRAME_SIM_DIPS
    `define JTFRAME_SIM_DIPS ~32'd0
`endif
`endif

`ifdef JTFRAME_SIM_DIPS
    wire [31:0] dipsw = `JTFRAME_SIM_DIPS;
`else
    wire [31:0] dipsw = status[31+DIPBASE:DIPBASE];
`endif

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
    .uart_tx     (                ),
    .uart_rx     ( 1'b0           ),
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

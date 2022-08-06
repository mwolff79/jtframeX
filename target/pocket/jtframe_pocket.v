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

module jtframe_pocket #(parameter
    SIGNED_SND             = 1'b0,
    BUTTONS                = 2,
    DIPBASE                = 16,
    GAME_INPUTS_ACTIVE_LOW = 1'b1,
    COLORW                 = 4,
    VIDEO_WIDTH            = 384,
    VIDEO_HEIGHT           = 224,
    SDRAMW                 = 23
)(
    input               clk_sys,
    input               clk_rom,
    input               clk_pico,
    input               pll_locked,
    // interface with microcontroller
    output      [63:0]  status,
    // Base video
    input  [COLORW-1:0] game_r,
    input  [COLORW-1:0] game_g,
    input  [COLORW-1:0] game_b,
    input               LHBL,
    input               LVBL,
    input               hs,
    input               vs,
    input               pxl_cen,
    input               pxl2_cen,
    // LED
    input         [1:0] game_led,
    // Bridge Connection
    output              bridge_endian_little,
    input      [31:0]   bridge_addr,
    input               bridge_rd,
    output     [31:0]   bridge_rd_data,
    input               bridge_wr,
    input      [31:0]   bridge_wr_data,
    // Pocket video output
    output     [23:0]   pocket_rgb,
    output              pocket_rgb_clk,
    output              pocket_rgb_clk_90,
    output              pocket_de,
    output              pocket_skip,
    output              pocket_vs,
    output              pocket_hs,
    // ROM programming
    input  [SDRAMW-1:0] prog_addr,
    input        [15:0] prog_data,
    input        [ 1:0] prog_mask,
    input        [ 1:0] prog_ba,
    input               prog_we,
    input               prog_rd,
    output              prog_dst,
    output              prog_dok,
    output              prog_rdy,
    output              prog_ack,
    // ROM access from game
    input  [SDRAMW-1:0] ba0_addr,
    input  [SDRAMW-1:0] ba1_addr,
    input  [SDRAMW-1:0] ba2_addr,
    input  [SDRAMW-1:0] ba3_addr,
    input         [3:0] ba_rd,
    input         [3:0] ba_wr,
    output        [3:0] ba_ack,
    output        [3:0] ba_rdy,
    output        [3:0] ba_dst,
    output        [3:0] ba_dok,
    input        [15:0] ba0_din,
    input        [ 1:0] ba0_din_m,  // write mask
    output       [15:0] sdram_dout,
    // UART
    input           uart_rx,
    output          uart_tx,
    // SDRAM interface
    inout    [15:0] SDRAM_DQ,       // SDRAM Data bus 16 Bits
    output   [12:0] SDRAM_A,        // SDRAM Address bus 13 Bits
    output          SDRAM_DQML,     // SDRAM Low-byte Data Mask
    output          SDRAM_DQMH,     // SDRAM High-byte Data Mask
    output          SDRAM_nWE,      // SDRAM Write Enable
    output          SDRAM_nCAS,     // SDRAM Column Address Strobe
    output          SDRAM_nRAS,     // SDRAM Row Address Strobe
    output          SDRAM_nCS,      // SDRAM Chip Select
    output    [1:0] SDRAM_BA,       // SDRAM Bank Address
    output          SDRAM_CKE,      // SDRAM Clock Enable
    // Pocket inputs
    input  [15:0]   cont1_key,
    input  [15:0]   cont2_key,
    input  [15:0]   cont3_key,
    input  [15:0]   cont4_key,
    input  [31:0]   cont1_joy,
    input  [31:0]   cont2_joy,
    input  [31:0]   cont3_joy,
    input  [31:0]   cont4_joy,
    input  [15:0]   cont1_trig,
    input  [15:0]   cont2_trig,
    input  [15:0]   cont3_trig,
    input  [15:0]   cont4_trig,
    // ROM load from SPI
    output   [24:0] ioctl_addr,
    output   [ 7:0] ioctl_dout,
    output          ioctl_wr,
    input    [ 7:0] ioctl_din,
    output          ioctl_ram,
    input           dwnld_busy,
    output          downloading,

//////////// board
    output          rst,      // synchronous reset
    output          rst_n,    // asynchronous reset
    output          game_rst,
    output          game_rst_n,
    // Sound
    input   [15:0]  snd_left,
    input   [15:0]  snd_right,
    input           snd_sample,

    input           audio_mclk,
    output          audio_dac,
    output          audio_lrck,
    // joystick
    output   [9:0]  game_joystick1,
    output   [9:0]  game_joystick2,
    output   [9:0]  game_joystick3,
    output   [9:0]  game_joystick4,
    output   [3:0]  game_coin,
    output   [3:0]  game_start,
    output          game_service,
    output  [15:0]  joyana_l1,
    output  [15:0]  joyana_r1,
    output  [15:0]  joyana_l2,
    output  [15:0]  joyana_r2,
    output  [15:0]  joyana_l3,
    output  [15:0]  joyana_r3,
    output  [15:0]  joyana_l4,
    output  [15:0]  joyana_r4,
    // Paddle
    output  [ 7:0]  paddle_0,
    output  [ 7:0]  paddle_1,
    output  [ 7:0]  paddle_2,
    output  [ 7:0]  paddle_3,

    // Mouse
    output  [15:0]  mouse_1p,
    output  [15:0]  mouse_2p,

    // DIP and OSD settings
    output          enable_fm,
    output          enable_psg,

    output          dip_test,
    // non standard:
    output          dip_pause,
    inout           dip_flip,     // A change in dip_flip implies a reset
    output  [ 1:0]  dip_fxlevel,
    // Debug
    output          LED,
    output   [ 7:0] st_addr,
    input    [ 7:0] st_dout,
    output   [3:0]  gfx_en,
    output   [7:0]  debug_bus,
    input    [7:0]  debug_view
);

wire          rst_req;

// control
wire [31:0]   joystick1, joystick2, joystick3, joystick4;
wire [63:0]   board_status;
wire          ps2_kbd_clk, ps2_kbd_data;
wire          osd_shown;

wire [ 7:0]   scan2x_r, scan2x_g, scan2x_b;
wire          scan2x_hs, scan2x_vs, scan2x_clk;
wire [ 6:0]   core_mod;
wire [ 3:0]   but_start, but_coin;

wire [ 1:0]   rotate;
wire          ioctl_cheat, sdram_init;

wire  [15:0]  board_left, board_right;

wire  [ 8:0]  bd_mouse_dx, bd_mouse_dy;
wire          bd_mouse_st, bd_mouse_idx;
wire  [ 7:0]  bd_mouse_f;


assign bridge_endian_little = 0;
assign board_status = { {64-DIPBASE{1'b0}}, status[DIPBASE-1:0] };
assign paddle_1 = 0;
assign paddle_2 = 0;
assign paddle_3 = 0;

jtframe_pocket_base #(
    .SIGNED_SND     ( SIGNED_SND    ),
    .COLORW         ( COLORW        )
) u_base(
    .rst            ( rst           ),
    .rst_req        ( rst_req       ),
    .sdram_init     ( sdram_init    ),
    .clk_sys        ( clk_sys       ),
    .clk_rom        ( clk_rom       ),
    .core_mod       ( core_mod      ),
    .osd_shown      ( osd_shown     ),
    // Base video
    .osd_rotate     ( rotate        ),
    .game_r         ( game_r        ),
    .game_g         ( game_g        ),
    .game_b         ( game_b        ),
    .LHBL           ( LHBL          ),
    .LVBL           ( LVBL          ),
    .hs             ( hs            ),
    .vs             ( vs            ),
    .pxl_cen        ( pxl_cen       ),
    .prog_rdy       ( prog_rdy      ),
    // Scan-doubler video
    .scan2x_r       ( scan2x_r[7:2] ),
    .scan2x_g       ( scan2x_g[7:2] ),
    .scan2x_b       ( scan2x_b[7:2] ),
    .scan2x_hs      ( scan2x_hs     ),
    .scan2x_vs      ( scan2x_vs     ),
    .scan2x_clk     ( scan2x_clk    ),
    // MiST VGA pins (includes OSD)
    .pck_rgb        ( pck_rgb       ),
    .pck_rgb_clk    ( pck_rgb_clk   ),
    .pck_rgb_clk90  ( pck_rgb_clk_90),
    .pck_de         ( pck_de        ),
    .pck_skip       ( pck_skip      ),
    .pck_vs         ( pck_vs        ),
    .pck_hs         ( pck_hs        ),
    // control
    .status         ( status        ),
    .joystick1      ( joystick1     ),
    .joystick2      ( joystick2     ),
    .joystick3      ( joystick3     ),
    .joystick4      ( joystick4     ),
    .but_start      ( but_start     ),
    .but_coin       ( but_coin      ),
    // Analog joystick
    .joyana_l1      ( joyana_l1     ),
    .joyana_r1      ( joyana_r1     ),
    .joyana_l2      ( joyana_l2     ),
    .joyana_r2      ( joyana_r2     ),
    .joyana_l3      ( joyana_l3     ),
    .joyana_r3      ( joyana_r3     ),
    .joyana_l4      ( joyana_l4     ),
    .joyana_r4      ( joyana_r4     ),
    // Pocket inputs
    .cont1_key      ( cont1_key     ),
    .cont2_key      ( cont2_key     ),
    .cont3_key      ( cont3_key     ),
    .cont4_key      ( cont4_key     ),
    .cont1_joy      ( cont1_joy     ),
    .cont2_joy      ( cont2_joy     ),
    .cont3_joy      ( cont3_joy     ),
    .cont4_joy      ( cont4_joy     ),
    .cont1_trig     ( cont1_trig    ),
    .cont2_trig     ( cont2_trig    ),
    .cont3_trig     ( cont3_trig    ),
    .cont4_trig     ( cont4_trig    ),
    // audio
    .clk_dac        ( clk_sys       ),
    .snd_left       ( board_left    ),
    .snd_right      ( board_right   ),
    .snd_pwm_left   ( AUDIO_L       ),
    .snd_pwm_right  ( AUDIO_R       ),
    // ROM load from SPI
    .ioctl_addr     ( ioctl_addr    ),
    .ioctl_dout     ( ioctl_dout    ),
    .ioctl_din      ( ioctl_din     ),
    .ioctl_wr       ( ioctl_wr      ),
    .ioctl_ram      ( ioctl_ram     ),
    .ioctl_cheat    ( ioctl_cheat   ),
    .downloading    ( downloading   )
);

jtframe_board #(
    .BUTTONS               ( BUTTONS               ),
    .GAME_INPUTS_ACTIVE_LOW( GAME_INPUTS_ACTIVE_LOW),
    .COLORW                ( COLORW                ),
    .VIDEO_WIDTH           ( VIDEO_WIDTH           ),
    .VIDEO_HEIGHT          ( VIDEO_HEIGHT          ),
    .SDRAMW                ( SDRAMW                ),
    .MISTER                ( 0                     )
) u_board(
    .rst            ( rst             ),
    .rst_n          ( rst_n           ),
    .game_rst       ( game_rst        ),
    .game_rst_n     ( game_rst_n      ),
    .rst_req        ( rst_req         ),
    .sdram_init     ( sdram_init      ),
    .pll_locked     ( pll_locked      ),
    .downloading    ( dwnld_busy      ), // use busy signal from game module

    .clk_sys        ( clk_sys         ),
    .clk_rom        ( clk_rom         ),
    .clk_pico       ( clk_pico        ),
    .core_mod       ( core_mod        ),
    // Sound
    .snd_lin        ( snd_left        ),
    .snd_rin        ( snd_right       ),
    .snd_lout       ( board_left      ),
    .snd_rout       ( board_right     ),
    .snd_sample     ( snd_sample      ),
    // joystick
    .ps2_kbd_clk    ( 1'd0            ),
    .ps2_kbd_data   ( 1'd0            ),
    .board_joystick1( joystick1[15:0] ),
    .board_joystick2( joystick2[15:0] ),
    .board_joystick3( joystick3[15:0] ),
    .board_joystick4( joystick4[15:0] ),
    .joyana_l1      ( joyana_l1       ),
    .joyana_r1      ( joyana_r1       ),
    .joyana_l2      ( joyana_l2       ),
    .joyana_r2      ( joyana_r2       ),
    .board_start    ( but_start       ),
    .board_coin     ( but_coin        ),
    .game_joystick1 ( game_joystick1  ),
    .game_joystick2 ( game_joystick2  ),
    .game_joystick3 ( game_joystick3  ),
    .game_joystick4 ( game_joystick4  ),
    .game_coin      ( game_coin       ),
    .game_start     ( game_start      ),
    .game_service   ( game_service    ),
    // Mouse & paddle
    .bd_mouse_dx    ( bd_mouse_dx     ),
    .bd_mouse_dy    ( bd_mouse_dy     ),
    .bd_mouse_st    ( bd_mouse_st     ),
    .bd_mouse_f     ( bd_mouse_f      ),
    .bd_mouse_idx   ( bd_mouse_idx    ),

    .paddle_0       ( paddle_0        ),
    .mouse_1p       ( mouse_1p        ),
    .mouse_2p       ( mouse_2p        ),
    // DIP and OSD settings
    .status         ( board_status    ),
    .enable_fm      ( enable_fm       ),
    .enable_psg     ( enable_psg      ),
    .dip_test       ( dip_test        ),
    .dip_pause      ( dip_pause       ),
    .dip_flip       ( dip_flip        ),
    .dip_fxlevel    ( dip_fxlevel     ),
    .timestamp      ( 32'd0           ), // MiST doesn't -normally- have a RTC
    // screen
    .rotate         ( rotate          ),
    // LED
    .osd_shown      ( osd_shown       ),
    .game_led       ( game_led        ),
    .led            ( LED             ),
    // UART
    .uart_rx        ( uart_rx         ),
    .uart_tx        ( uart_tx         ),
    // SDRAM interface
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

    // ROM-load interface
    .prog_addr  ( prog_addr     ),
    .prog_ba    ( prog_ba       ),
    .prog_rd    ( prog_rd       ),
    .prog_we    ( prog_we       ),
    .prog_data  ( prog_data     ),
    .prog_mask  ( prog_mask     ),
    .prog_rdy   ( prog_rdy      ),
    .prog_dst   ( prog_dst      ),
    .prog_dok   ( prog_dok      ),
    .prog_ack   ( prog_ack      ),
    // SDRAM interface
    .SDRAM_DQ   ( SDRAM_DQ      ),
    .SDRAM_A    ( SDRAM_A       ),
    .SDRAM_DQML ( SDRAM_DQML    ),
    .SDRAM_DQMH ( SDRAM_DQMH    ),
    .SDRAM_nWE  ( SDRAM_nWE     ),
    .SDRAM_nCAS ( SDRAM_nCAS    ),
    .SDRAM_nRAS ( SDRAM_nRAS    ),
    .SDRAM_nCS  ( SDRAM_nCS     ),
    .SDRAM_BA   ( SDRAM_BA      ),
    .SDRAM_CKE  ( SDRAM_CKE     ),

    // Common signals
    .sdram_dout ( sdram_dout    ),

    // Cheat!
    .cheat          ( status[63:32]   ),
    .prog_cheat     ( ioctl_cheat     ),
    .prog_lock      ( 1'b0            ),  // locking is not needed on MiST
    .ioctl_wr       ( ioctl_wr        ),
    .ioctl_dout     ( ioctl_dout      ),
    .ioctl_addr     ( ioctl_addr[7:0] ),
    .st_addr        ( st_addr         ),
    .st_dout        ( st_dout         ),

    // Base video
    .osd_rotate     ( rotate          ),
    .game_r         ( game_r          ),
    .game_g         ( game_g          ),
    .game_b         ( game_b          ),
    .LHBL           ( LHBL            ),
    .LVBL           ( LVBL            ),
    .hs             ( hs              ),
    .vs             ( vs              ),
    .pxl_cen        ( pxl_cen         ),
    .pxl2_cen       ( pxl2_cen        ),
    // Scan-doubler video
    .scan2x_r       ( scan2x_r        ),
    .scan2x_g       ( scan2x_g        ),
    .scan2x_b       ( scan2x_b        ),
    .scan2x_hs      ( scan2x_hs       ),
    .scan2x_vs      ( scan2x_vs       ),
    .scan2x_enb     ( 1'b1            ),    // no scan doubler
    .scan2x_clk     ( scan2x_clk      ),
    // Debug
    .gfx_en         ( gfx_en          ),
    .debug_bus      ( debug_bus       ),
    .debug_view     ( debug_view      ),
    // Unused ports (MiSTer)
    .gamma_bus      (                 ),
    .direct_video   ( 1'b0            ),
    .hdmi_arx       (                 ),
    .hdmi_ary       (                 ),
    .scan2x_cen     (                 ),
    .scan2x_de      (                 ),
    .scan2x_sl      (                 )
);

endmodule // jtframe
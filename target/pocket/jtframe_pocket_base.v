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
    along with JTFRAME. If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 27-10-2017 */

module jtframe_mist_base #(parameter
    SIGNED_SND      = 1'b0,
    COLORW          = 4
) (
    input           rst,
    input           clk_sys,
    input           clk_rom,
    input           sdram_init,
    output          osd_shown,
    output  [6:0]   core_mod,
    // Base video
    input   [1:0]   osd_rotate,
    input [COLORW-1:0] game_r,
    input [COLORW-1:0] game_g,
    input [COLORW-1:0] game_b,
    input           LHBL,
    input           LVBL,
    input           hs,
    input           vs,
    input           pxl_cen,
    // Scan-doubler video
    input   [5:0]   scan2x_r,
    input   [5:0]   scan2x_g,
    input   [5:0]   scan2x_b,
    input           scan2x_hs,
    input           scan2x_vs,
    output          scan2x_enb, // scan doubler enable bar = scan doubler disable.
    input           scan2x_clk,
    // Final video: VGA+OSD or base+OSD depending on configuration
    output  [5:0]   VIDEO_R,
    output  [5:0]   VIDEO_G,
    output  [5:0]   VIDEO_B,
    output          VIDEO_HS,
    output          VIDEO_VS,
    // SPI interface to arm io controller
    inout           SPI_DO,
    input           SPI_DI,
    input           SPI_SCK,
    input           SPI_SS2,
    input           SPI_SS3,    // OSD interface
    input           SPI_SS4,
    input           CONF_DATA0,
    // control
    output [63:0]   status,
    output [31:0]   joystick1,
    output [31:0]   joystick2,
    output [31:0]   joystick3,
    output [31:0]   joystick4,
    output [15:0]   joyana_l1,
    output [15:0]   joyana_r1,
    output [15:0]   joyana_l2,
    output [15:0]   joyana_r2,
    output [15:0]   joyana_l3,
    output [15:0]   joyana_r3,
    output [15:0]   joyana_l4,
    output [15:0]   joyana_r4,

    output [ 8:0]   mouse_dx,
    output [ 8:0]   mouse_dy,
    output [ 7:0]   mouse_f,
    output          mouse_st,
    output          mouse_idx,

    output [ 3:0]   but_coin,   // buttons, active high
    output [ 3:0]   but_start,
    // PS2 pins are outputs if NEPTUNO isn't defined
    inout           ps2_kbd_clk,
    inout           ps2_kbd_data,
    // Sound
    input           clk_dac,
    input   [15:0]  snd_left,
    input   [15:0]  snd_right,
    output          snd_pwm_left,
    output          snd_pwm_right,
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
    input  [15:0]   cont4_trig

    // ROM load from SPI
    output [24:0]   ioctl_addr,
    output [ 7:0]   ioctl_dout,
    input  [ 7:0]   ioctl_din,
    output          ioctl_wr,
    output          ioctl_ram,
    output          ioctl_cheat,
    output          downloading

);

localparam [7:0] IDX_CHEAT = 8'h10,
                 IDX_NVRAM = 8'hFF;

wire        ypbpr, no_csync;
wire [7:0]  ioctl_index;
wire        ioctl_download, ioctl_upload;

assign downloading = ioctl_download;
assign ioctl_ram   = (ioctl_index == IDX_NVRAM && ioctl_download) || ioctl_upload;
assign ioctl_cheat = ioctl_index == IDX_CHEAT && ioctl_download;

// Convert Pocket inputs to JTFRAME standard
function [31:0] joyconv( input [15:0] joy_in );
    joyconv[31:14] = 0;
    joyconv[13:4] = joy_in[13:4];
    joyconv[3:0] = { joy_in[0], joy_in[1], joy_in[2], joy_in[3] };
endfunction

assign joystick1 = joyconv( cont1_key );
assign joystick2 = joyconv( cont2_key );
assign joystick3 = joyconv( cont3_key );
assign joystick4 = joyconv( cont4_key );
assign { joyana_r1, joyana_l1 } = cont1_joy;
assign { joyana_r2, joyana_l2 } = cont2_joy;
assign { joyana_r3, joyana_l3 } = cont3_joy;
assign { joyana_r4, joyana_l4 } = cont4_joy;

//
// host/target command handler
//
wire            reset_n;                // driven by host commands, can be used as core-wide reset
wire    [31:0]  cmd_bridge_rd_data;

// bridge host commands
// synchronous to clk_74a
wire            status_boot_done = pll_core_locked;
wire            status_setup_done = pll_core_locked; // rising edge triggers a target command
wire            status_running = reset_n; // we are running as soon as reset_n goes high

wire            dataslot_requestread;
wire    [15:0]  dataslot_requestread_id;
wire            dataslot_requestread_ack = 1;
wire            dataslot_requestread_ok = 1;

wire            dataslot_requestwrite;
wire    [15:0]  dataslot_requestwrite_id;
wire            dataslot_requestwrite_ack = 1;
wire            dataslot_requestwrite_ok = 1;

wire            dataslot_allcomplete;

wire            savestate_supported;
wire    [31:0]  savestate_addr;
wire    [31:0]  savestate_size;
wire    [31:0]  savestate_maxloadsize;

wire            savestate_start;
wire            savestate_start_ack;
wire            savestate_start_busy;
wire            savestate_start_ok;
wire            savestate_start_err;

wire            savestate_load;
wire            savestate_load_ack;
wire            savestate_load_busy;
wire            savestate_load_ok;
wire            savestate_load_err;

// bridge target commands
// synchronous to clk_74a


// bridge data slot access

wire    [9:0]   datatable_addr;
wire            datatable_wren;
wire    [31:0]  datatable_data;
wire    [31:0]  datatable_q;

core_bridge_cmd u_bridge (
    .clk                ( clk_74a ),
    .reset_n            ( reset_n ),

    .bridge_endian_little   ( bridge_endian_little ),
    .bridge_addr            ( bridge_addr ),
    .bridge_rd              ( bridge_rd ),
    .bridge_rd_data         ( cmd_bridge_rd_data ),
    .bridge_wr              ( bridge_wr ),
    .bridge_wr_data         ( bridge_wr_data ),

    .status_boot_done       ( status_boot_done ),
    .status_setup_done      ( status_setup_done ),
    .status_running         ( status_running ),

    .dataslot_requestread       ( dataslot_requestread ),
    .dataslot_requestread_id    ( dataslot_requestread_id ),
    .dataslot_requestread_ack   ( dataslot_requestread_ack ),
    .dataslot_requestread_ok    ( dataslot_requestread_ok ),

    .dataslot_requestwrite      ( dataslot_requestwrite ),
    .dataslot_requestwrite_id   ( dataslot_requestwrite_id ),
    .dataslot_requestwrite_ack  ( dataslot_requestwrite_ack ),
    .dataslot_requestwrite_ok   ( dataslot_requestwrite_ok ),

    .dataslot_allcomplete   ( dataslot_allcomplete ),

    .savestate_supported    ( savestate_supported ),
    .savestate_addr         ( savestate_addr ),
    .savestate_size         ( savestate_size ),
    .savestate_maxloadsize  ( savestate_maxloadsize ),

    .savestate_start        ( savestate_start ),
    .savestate_start_ack    ( savestate_start_ack ),
    .savestate_start_busy   ( savestate_start_busy ),
    .savestate_start_ok     ( savestate_start_ok ),
    .savestate_start_err    ( savestate_start_err ),

    .savestate_load         ( savestate_load ),
    .savestate_load_ack     ( savestate_load_ack ),
    .savestate_load_busy    ( savestate_load_busy ),
    .savestate_load_ok      ( savestate_load_ok ),
    .savestate_load_err     ( savestate_load_err ),

    .datatable_addr         ( datatable_addr ),
    .datatable_wren         ( datatable_wren ),
    .datatable_data         ( datatable_data ),
    .datatable_q            ( datatable_q )
);

endmodule
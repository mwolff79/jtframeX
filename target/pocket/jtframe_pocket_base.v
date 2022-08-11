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
    Date: 6-8-2022 */

module jtframe_pocket_base #(parameter
    SIGNED_SND      = 1'b0,
    COLORW          = 4
) (
    input           rst,
    output          rst_req,
    input           clk_sys,
    input           clk_rom,
    input           clk_74a,
    input           pxl_cen,
    input           pxl2_cen,

    input           sdram_init,
    output          osd_shown,
    output reg [6:0] core_mod,

    input           prog_rdy,
    // Bridge Connection
    input  [31:0]   bridge_addr,
    input           bridge_rd,
    output [31:0]   bridge_rd_data,
    input           bridge_wr,
    input  [31:0]   bridge_wr_data,
    output          bridge_endian_little,
    // Scan-doubler video
    input [3*COLORW-1:0] base_rgb,
    input           base_LHBL,
    input           base_LVBL,
    input           base_hs,
    input           base_vs,
    // Final video
    output  [23:0]  pck_rgb,
    output          pck_rgb_clk,
    output          pck_rgb_clkq,
    output          pck_de,
    output          pck_skip,
    output          pck_vs,
    output          pck_hs,
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

    output [ 3:0]   but_coin,   // buttons, active high
    output [ 3:0]   but_start,
    // Sound
    input   [15:0]  snd_left,
    input   [15:0]  snd_right,
    input           snd_sample,

    input           audio_mclk,
    output          audio_dac,
    output          audio_lrck,
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
    output reg [24:0]   ioctl_addr,
    output     [ 7:0]   ioctl_dout,
    input      [ 7:0]   ioctl_din,
    output reg          ioctl_wr,
    output              ioctl_ram,
    output              ioctl_cheat,
    output reg          downloading

);

localparam [7:0] IDX_CHEAT = 8'h10,
                 IDX_NVRAM = 8'hFF;

wire [7:0]  ioctl_index;
wire        ioctl_download, ioctl_upload;

assign ioctl_ram   = 0;
assign ioctl_cheat = 0;
assign osd_shown   = 1;
assign status      = 0;
assign bridge_endian_little = 0;

// Convert Pocket inputs to JTFRAME standard
function [31:0] joyconv( input [15:0] joy_in );
    joyconv = { 18'd0,
        joy_in[13:4], joy_in[0], joy_in[1], joy_in[2], joy_in[3] };
endfunction

assign joystick1 = joyconv( cont1_key );
assign joystick2 = joyconv( cont2_key );
assign joystick3 = joyconv( cont3_key );
assign joystick4 = joyconv( cont4_key );
assign { joyana_r1, joyana_l1 } = cont1_joy;
assign { joyana_r2, joyana_l2 } = cont2_joy;
assign { joyana_r3, joyana_l3 } = cont3_joy;
assign { joyana_r4, joyana_l4 } = cont4_joy;
assign but_coin  = { cont4_key[14], cont3_key[14], cont2_key[14], cont1_key[14] };
assign but_start = { cont4_key[15], cont3_key[15], cont2_key[15], cont1_key[15] };

wire         rst_req_n;

// bridge host commands
// synchronous to clk_74a
wire         boot_done,  // controlled by the PLL lock signals
             setup_done; // controlled by SDRAM init signal
wire [15:0]  dataslot_requestread_id, dataslot_requestwrite_id;
wire         dataslot_requestread, dataslot_requestwrite, dataslot_done;

// bridge data slot access
wire    [9:0]   datatable_addr;
wire            datatable_wren;
wire    [31:0]  datatable_data;
wire    [31:0]  datatable_q;

assign rst_req = ~rst_req_n;

wire        wr_s, ds_done, ds_done_s;
wire [31:0] data_s, addr_s;
reg  [ 2:0] ioctl_byte;
reg  [31:0] ioctl_qword;
reg         prog_rdyl;

assign ioctl_dout = ioctl_qword[7:0];

jtframe_sync #(.LATCHIN(1),.W(2)) u_rstsync(
    .clk_in ( clk_rom           ),
    .clk_out( clk_74a           ),
    .raw    ( {~sdram_init, ~rst } ),
    .sync   ( {setup_done, boot_done }  )
);

always @(posedge clk_rom, posedge rst) begin
    if( rst ) begin
        core_mod <= 0;
    end else if( ioctl_wr && ioctl_index==1 ) begin
        core_mod <= ioctl_dout[6:0];
    end
end

jtframe_sync #( .W(8+2+32+32) )
u_sync(
    .clk_in     ( clk_74a           ),
    .clk_out    ( clk_rom           ),
    .raw        ( { dataslot_requestwrite_id[7:0], ds_done, bridge_wr, bridge_wr_data, bridge_addr } ),
    .sync       ( { ioctl_index, ds_done_s, wr_s, data_s, addr_s }  )
);

always @(posedge clk_rom) begin
    prog_rdyl <= prog_rdy;
    ioctl_wr  <= 0;
    if( ioctl_index==0 && addr_s[31:24]!=8'hf8 ) begin
        if( wr_s ) begin
            ioctl_byte  <= 3'd1;
            ioctl_wr    <= 1;
            ioctl_qword <= data_s;
            downloading <= 1;
            ioctl_addr  <= addr_s[24:0];
        end
        if( prog_rdyl ) begin
            ioctl_addr[1:0] <= ioctl_addr[1:0] + 1'd1;
            ioctl_byte      <= ioctl_byte  << 1;
            ioctl_qword     <= ioctl_qword >> 8;
            ioctl_wr        <= ioctl_byte!= 0;
        end
    end
    if( ds_done_s || ioctl_index!=0 ) begin
        downloading <= 0;
    end
end

core_bridge_cmd u_bridge (
    .clk                        ( clk_74a                   ),
    .reset_n                    ( rst_req_n                 ),

    .bridge_addr                ( bridge_addr               ),
    .bridge_rd                  ( bridge_rd                 ),
    .bridge_rd_data             ( bridge_rd_data            ),
    .bridge_wr                  ( bridge_wr                 ),
    .bridge_wr_data             ( bridge_wr_data            ),
    .bridge_endian_little       ( bridge_endian_little      ),

    .status_boot_done           ( boot_done                 ),
    .status_setup_done          ( setup_done                ),
    .status_running             ( setup_done                ),

    .dataslot_requestread       ( dataslot_requestread      ),
    .dataslot_requestread_id    ( dataslot_requestread_id   ),
    .dataslot_requestread_ack   ( 1'b1                      ),
    .dataslot_requestread_ok    ( 1'b1                      ),

    .dataslot_requestwrite      ( dataslot_requestwrite     ),
    .dataslot_requestwrite_id   ( dataslot_requestwrite_id  ),
    .dataslot_requestwrite_ack  ( 1'b1                      ),
    .dataslot_requestwrite_ok   ( 1'b1                      ),

    .dataslot_allcomplete       ( ds_done                   ),

    .savestate_supported        ( 1'b0                      ),
    .savestate_addr             ( 32'd0                     ),
    .savestate_size             ( 32'd0                     ),
    .savestate_maxloadsize      ( 32'd0                     ),

    .savestate_start            (                           ),
    .savestate_start_ack        ( 1'd0                      ),
    .savestate_start_busy       ( 1'd0                      ),
    .savestate_start_ok         ( 1'd0                      ),
    .savestate_start_err        ( 1'd0                      ),

    .savestate_load             (                           ),
    .savestate_load_ack         ( 1'd0                      ),
    .savestate_load_busy        ( 1'd0                      ),
    .savestate_load_ok          ( 1'd0                      ),
    .savestate_load_err         ( 1'd0                      )
);

wire [3*COLORW-1:0] logo_rgb;
wire logo_hs, logo_vs, logo_lhbl, logo_lvbl;

jtframe_logo #(.COLORW(COLORW)) u_logo(
    .clk        ( clk_sys   ),
    .pxl_cen    ( pxl_cen   ),
    .show_en    ( 1'b1      ),

    .rgb_in     ( base_rgb  ),
    .hs         ( base_hs   ),
    .vs         ( base_vs   ),
    .lhbl       ( base_LHBL ),
    .lvbl       ( base_LVBL ),

    // VGA signals going to video connector
    .rgb_out    ( logo_rgb  ),
    .hs_out     ( logo_hs   ),
    .vs_out     ( logo_vs   ),
    .lhbl_out   ( logo_lhbl ),
    .lvbl_out   ( logo_lvbl )
);

jtframe_pocket_video u_video(
    .clk            ( clk_sys       ),
    .pxl2_cen       ( pxl2_cen      ),
    // Scan-doubler video
    .base_rgb       ( logo_rgb      ),
    .base_hs        ( logo_hs       ),
    .base_vs        ( logo_vs       ),
    .base_lhbl      ( logo_lhbl     ),
    .base_lvbl      ( logo_lvbl     ),
    // Final video
    .pck_rgb        ( pck_rgb       ),
    .pck_rgb_clk    ( pck_rgb_clk   ),
    .pck_rgb_clkq   ( pck_rgb_clkq  ),
    .pck_de         ( pck_de        ),
    .pck_skip       ( pck_skip      ),
    .pck_vs         ( pck_vs        ),
    .pck_hs         ( pck_hs        )
);

assign audio_dac  = 0;
assign audio_lrck = 0;

endmodule
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
    Date: 11-8-2022 */

module jtframe_logo #(parameter
    COLORW = 4
) (
    input        clk,
    input        pxl_cen,
    input        show_en,

    // input  [1:0] rotate, //[0] - rotate [1] - left or right

    // VGA signals coming from core
    input  [3*COLORW-1:0] rgb_in,
    input        hs,
    input        vs,
    input        lhbl,
    input        lvbl,

    // VGA signals going to video connector
    output [3*COLORW-1:0] rgb_out,

    output reg       hs_out,
    output reg       vs_out,
    output reg       lhbl_out,
    output reg       lvbl_out
);

reg  [ 8:0] hcnt=0,vcnt=0, htot=9'd256, vtot=9'd256;
reg         hsl, vsl;
wire [10:0] addr;
reg  [ 7:0] char;
wire [ 7:0] rom;
wire        pxl;
wire [COLORW-1:0] r_in, g_in, b_in;
reg  [COLORW-1:0] r_out, g_out, b_out;


jtframe_prom #(.synhex("jtframe_logo.hex")) u_rom(
    .clk    ( clk    ),
    .cen    ( 1'b1   ),
    .data   ( 8'd0   ),
    .rd_addr( addr   ),
    .wr_addr( 11'd0  ),
    .we     ( 1'b0   ),
    .q      ( rom    )
);

assign addr = { vcnt[7:5], hcnt[7:0] };
assign pxl  = char[ vcnt[4:2] ];
assign {r_in,g_in,b_in} = rgb_in;
assign rgb_out = { r_out, g_out, b_out };

function [COLORW-1:0] filter( input [COLORW-1:0] a );
    filter = show_en ? {COLORW{pxl}} : a;
endfunction

always @(posedge clk) if( pxl_cen ) begin
    { hs_out, vs_out }   <= { hs, vs };
    { lhbl_out, lvbl_out } <= { lhbl, lvbl };
    r_out <= filter( r_in );
    g_out <= filter( g_in );
    b_out <= filter( b_in );
end

// screen counter
always @(posedge clk) if( pxl_cen ) begin
    hsl <= hs;
    vsl <= vs;
    hcnt <= hcnt + 9'd1;
    if( hs & ~hsl ) begin
        htot <= hcnt;
        hcnt <= 0;
        if( lvbl ) vcnt <= vcnt+9'd1;
    end
    if( vs && !vsl && vcnt!=0 ) begin
        vtot <= vcnt;
    end
end

always @(posedge clk) begin
    char <= rom[addr];
end

endmodule

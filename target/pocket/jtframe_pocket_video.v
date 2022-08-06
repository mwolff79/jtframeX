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

module jtframe_pocket_video(
    input             clk,
    input             pxl2_cen,
    // Scan-doubler video
    input      [ 7:0] scan2x_r,
    input      [ 7:0] scan2x_g,
    input      [ 7:0] scan2x_b,
    input             scan2x_hs,
    input             scan2x_vs,
    input             scan2x_de,
    // Final video
    output reg [23:0] pck_rgb,
    output reg        pck_rgb_clk,
    output reg        pck_rgb_clk_90,
    output reg        pck_de,
    output reg        pck_skip,
    output reg        pck_vs,
    output reg        pck_hs
);

reg  [3:0] pxl_cnt, pxl_90;
reg        hsl, vsl;

always @(posedge clk) begin
    pxl_cnt <= pxl2_cen ? 4'd0 : pxl_cnt+4'd1;
    if( pxl_cnt[3:1] == pxl_90[3:1] )
        pck_rgb_clk_90 <= pck_rgb_clk;
    if(pxl2_cen) begin
        pck_rgb_clk <= ~pck_rgb_clk;
        pxl_90      <= pxl_cnt;
        if( !pck_rgb_clk ) begin
            hsl     <= scan2x_hs;
            vsl     <= scan2x_vs;
            pck_hs  <= scan2x_hs & ~hsl;
            pck_vs  <= scan2x_vs & ~vsl;
            pck_de  <= !scan2x_vs && !scan2x_hs; //scan2x_de;
            pck_rgb <= { scan2x_r, scan2x_g, scan2x_b };
        end
    end
end

endmodule
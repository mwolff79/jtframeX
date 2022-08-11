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

module jtframe_pocket_video #(parameter
    COLORW = 4
) (
    input             clk,
    input             pxl2_cen,
    // Base video
    input [3*COLORW-1:0] base_rgb,
    input             base_LHBL,
    input             base_LVBL,
    input             base_hs,
    input             base_vs,
    // Final video
    output reg [23:0] pck_rgb,
    output reg        pck_rgb_clk,
    output reg        pck_rgb_clkq,
    output reg        pck_de,
    output            pck_skip,
    output reg        pck_vs,
    output reg        pck_hs
);

reg  [3:0] pxl_cnt, pxl_90;
reg        hsl, vsl;
wire [COLORW-1:0] br,bg,bb;

`ifdef SIMULATION
    // counts the active video size
    integer hcnt=0, vcnt=0, htotal=0, vtotal=0;

    always @(posedge pck_rgb_clk) begin
        if( pck_hs ) begin
            hcnt <= 0;
            if( base_LVBL ) vcnt <= vcnt+1;
            if( hcnt!=0 ) htotal <= hcnt;
        end
        if( pck_vs ) begin
            vcnt <= 0;
            vtotal <= vcnt;
            $display("Pocket video size %0dx%0d",htotal, vtotal==0 ? vcnt : vtotal );
        end
        if( pck_de ) hcnt <= hcnt+1;
    end
`endif

assign pck_skip = 0;
assign {br,bg,bb} = base_rgb;

initial begin
    pck_rgb_clk = 0;
    pck_rgb     = 0;
end

function [7:0] extend8;
    input [COLORW-1:0] a;
    case( COLORW )
        3: extend8 = { a, a, a[2:1] };
        4: extend8 = { a, a         };
        5: extend8 = { a, a[4:2]    };
        6: extend8 = { a, a[5:4]    };
        7: extend8 = { a, a[6]      };
        8: extend8 = a;
    endcase
endfunction

always @(posedge clk) begin
    pxl_cnt <= pxl2_cen ? 4'd0 : pxl_cnt+4'd1;
    if( pxl_cnt == {pxl_90[3:1],1'd0}-4'd1 )
        pck_rgb_clkq <= pck_rgb_clk;
    if(pxl2_cen) begin
        pck_rgb_clk <= ~pck_rgb_clk;
        pxl_90      <= pxl_cnt;
        if( !pck_rgb_clk ) begin
            hsl     <= base_hs;
            vsl     <= base_vs;
            pck_hs  <= base_hs & ~hsl;
            pck_vs  <= base_vs & ~vsl;
            pck_de  <= base_LHBL & base_LVBL;
            //pck_rgb <= { extend8(br), extend8(bg), extend8(bb) };
            pck_rgb <= pck_rgb+1'd1;
        end
    end
end

endmodule
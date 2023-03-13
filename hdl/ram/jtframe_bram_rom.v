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
    Date: 27-10-2017 */

// ROM implemented in BRAM
// DW can only be 8 or 16 bits
// The programming interface is always 8 bits
// This module is similar to jtframe_dual_nvram16
// but it limits writting to a single port

module jtframe_bram_rom #(parameter
            DW=8,
            AW=10,
`ifdef JTFRAME_SDRAM_LARGE
            PW=25,
`else       PW=24, `endif
            OFFSET=0
)(
    input               clk,

    // Read Port
    input      [AW-1:0] addr,
    output reg [DW-1:0] data,

    // Write Port - connect to the output of jtframe_dwnld
    // same signals that go to the SDRAM programming input
    input    [PW-1:0] prog_addr, // max 32MB
    input       [1:0] prog_mask,
    input       [7:0] prog_data,
    input             prog_we
);
/* verilator lint_off WIDTH */
localparam [PW-1:0] ADDR1=OFFSET[PW-1:0] + (25'h1<<( AW-1 )); /* verilator lint_on WIDTH */ /* verilator lint_off UNSIGNED */
wire in_range = prog_addr>=OFFSET[PW-1:0] && prog_addr<ADDR1; /* verilator lint_on UNSIGNED */
wire [PW-1:0] prog_aeff = prog_addr-OFFSET[PW-1:0];

generate
    if( DW==8 ) begin
        wire we = prog_we && in_range;
        jtframe_rpwp_ram #(.DW(DW),.AW(AW)) u_ram(
            .clk    ( clk                ),
            .rd_addr( addr               ),
            .dout   ( data               ),

            .wr_addr({prog_aeff[AW-2:0],prog_mask[0]}),
            .din    ( prog_data          ),
            .we     ( we                 )
        );
    end else if( DW==16 ) begin
        wire we_upper = !prog_mask[1] && prog_we && in_range;
        wire we_lower = !prog_mask[0] && prog_we && in_range;

        jtframe_rpwp_ram #(.DW(8),.AW(AW)) u_upper(
            .clk    ( clk          ),
            .rd_addr( addr         ),
            .dout   ( data[DW-1-:8]),

            .wr_addr(prog_aeff[AW-1:0]),
            .din    ( prog_data   ),
            .we     ( we_upper     )
        );

        jtframe_rpwp_ram #(.DW(8),.AW(AW)) u_lower(
            .clk    ( clk          ),
            .rd_addr( addr         ),
            .dout   ( data[0+:8]   ),

            .wr_addr(prog_aeff[AW-1:0]),
            .din    ( prog_data   ),
            .we     ( we_lower     )
        );
    end
endgenerate

endmodule

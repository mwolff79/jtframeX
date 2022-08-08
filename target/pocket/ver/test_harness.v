/*  This file is part of JT_FRAME.
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
    Date: 6-9-2021 */

/////////////////////////////////////////////
//  This module includes the SDRAM model
//  when used to simulate the core at the game level (instead of MiST(er) level)
//  this module also adds the SDRAM controller
//
//

`timescale 1ns/1ps

module test_harness(
    output  reg  clk_74a,
    output  reg  clk_74b,

    input        vblank,
    // video output to the scaler
    input [11:0] scal_vid,
    input        scal_clk,
    input        scal_de,
    input        scal_skip,
    input        scal_vs,
    input        scal_hs,

    output       scal_audadc,
    input        scal_audmclk,
    input        scal_auddac,
    input        scal_audlrck,

    inout        bridge_spimosi,
    inout        bridge_spimiso,
    inout        bridge_spiclk,
    output       bridge_spiss,
    inout        bridge_1wire,
    // SDRAM
    inout [15:0] sdram_dq,
    input [12:0] sdram_a,
    input [ 1:0] sdram_dqm,
    input        sdram_nwe,
    input        sdram_ncas,
    input        sdram_nras,
    input        sdram_ncs,
    input [1:0]  sdram_ba,
    input        sdram_clk,
    input        sdram_cke
);

wire [31:0] frame_cnt;
integer fincnt;

initial begin
    clk_74a = 0;
    forever #6.734 clk_74a = ~clk_74a;
end

initial begin
    clk_74b = 0;
    #1.734
    forever #6.734 clk_74b = ~clk_74b;
end


mt48lc16m16a2 u_sdram (
    .Dq         ( sdram_dq      ),
    .Addr       ( sdram_a       ),
    .Ba         ( sdram_ba      ),
    .Clk        ( sdram_clk     ),
    .Cke        ( sdram_cke     ),
    .Cs_n       ( 1'd0          ),
    .Ras_n      ( sdram_nras    ),
    .Cas_n      ( sdram_ncas    ),
    .We_n       ( sdram_nwe     ),
    .Dqm        ( sdram_dqm     ),
    .downloading( dwnld_busy    ),
    .VS         ( vblank        ),
    .frame_cnt  ( frame_cnt     )
);

initial begin
    $display("Simulate for %d ms",`SIM_MS);
    forever begin
        #(1000*1000); // ms
        fincnt = fincnt+1;
        $display("%d ms",fincnt+1);
        if( fincnt>=`SIM_MS ) $finish;
    end
end

initial #1000 $finish;

endmodule

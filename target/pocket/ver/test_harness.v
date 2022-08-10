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

    inout        brg_spimosi,
    inout        brg_spimiso,
    inout        brg_spiclk,
    output reg   brg_spiss=1,
    inout        brg_1wire,
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

reg [31:0] frame_cnt=0;
integer fincnt;

assign scal_audadc = 0;
assign bridge_spiss = 0;

initial begin
    clk_74a = 0;
    forever #6.734 clk_74a = ~clk_74a;
end

initial begin
    clk_74b = 0;
    #1.734
    forever #6.734 clk_74b = ~clk_74b;
end

always @(posedge scal_vs) begin
    frame_cnt <= frame_cnt+1;
end

pocket_dump u_dump(
    .scal_vs    ( scal_vs   ),
    .frame_cnt  ( frame_cnt )
);

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
    fincnt=0;
    $display("Simulate for %0d ms",`SIM_MS);
    forever begin
        #(1000*1000); // ms
        fincnt = fincnt+1;
        $display("%d ms",fincnt);
        if( fincnt>=`SIM_MS ) $finish;
    end
end

// Send SPI commands
reg [63:0] cmd[0:15];
reg        clk_spi;
reg        spi_idlel, spi_wr;
reg        wait_startup, brg_drive;
integer    spi_cnt=0;
reg  [2:0] spi_idx=0;
wire [7:0] spi_din;
wire [1:0] spi_data;
wire       spi_idle;

assign spi_din    = cmd[spi_cnt][ 31-spi_idx*8 -: 8 ];
assign brg_spiclk = brg_drive ?  ~clk_spi : 1'bz;
assign { brg_spimosi, brg_spimiso } = brg_drive ? spi_data[1:0] :  2'bzz;

initial begin
    wait_startup = 1;
    #10_000 wait_startup = 0;
end

initial begin
    clk_spi=0;
    forever #500 clk_spi=~clk_spi;
end

initial begin // last address bit sets write (1) or read (0)
    cmd[0] = { 32'hf800_0000, 32'h0 }; // request status
end

always @(negedge clk_spi) begin
    spi_idlel <= spi_idle ;
    spi_wr    <= 0;
    if( spi_idle  && spi_idlel ) begin
        spi_wr    <= 1;
        brg_spiss <= 0;
        brg_drive <= 1;
    end
    if( spi_idle  && !spi_idlel ) begin
        spi_idx   <= spi_idx+3'd1;
        brg_spiss <= spi_idx==3;
    end
    if( brg_spiss ) brg_drive <= 0;
end

pocket_spi u_spi(
    .clk        ( clk_spi   ),
    .wr         ( spi_wr    ),
    .din        ( spi_din   ),
    .dout       ( spi_data  ),
    .idle       ( spi_idle  )
);

endmodule

/////////////////////////////////////////////////////////

module pocket_spi(
    input         clk, // slow clock
    input   [7:0] din,
    input         wr,
    inout   [1:0] dout,
    output reg    idle=1
);

    reg       wrl=0;
    reg [7:0] data;
    reg [2:0] cnt=0;

    assign dout = data[1:0];

    always @(posedge clk) begin
        wrl <= wr;
        if( wr && !wrl ) begin
            idle <= 0;
            data <= din;
            cnt  <= 3'b111;
        end else begin
            if( cnt[0] ) begin
                data <= data>>2;
                cnt  <= cnt>>1;
            end else begin
                idle <= 1;
            end
        end
    end

endmodule
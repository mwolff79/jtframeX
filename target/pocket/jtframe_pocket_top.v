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

    ///////////////////////////////////////////////////
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
    output reg [31:0] bridge_rd_data,
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

// not using the IR port, so turn off both the LED, and
// disable the receive circuit to save power
assign port_ir_tx         = 0;
assign port_ir_rx_disable = 1;

// bridge endianness
assign bridge_endian_little = 0;

// cart is unused, so set all level translators accordingly
// directions are 0:IN, 1:OUT
assign cart_tran_bank3         = 8'hzz;
assign cart_tran_bank3_dir     = 1'b0;
assign cart_tran_bank2         = 8'hzz;
assign cart_tran_bank2_dir     = 1'b0;
assign cart_tran_bank1         = 8'hzz;
assign cart_tran_bank1_dir     = 1'b0;
assign cart_tran_bank0         = 4'hf;
assign cart_tran_bank0_dir     = 1'b1;
assign cart_tran_pin30         = 1'b0;      // reset or cs2, we let the hw control it by itself
assign cart_tran_pin30_dir     = 1'bz;
assign cart_pin30_pwroff_reset = 1'b0;  // hardware can control this
assign cart_tran_pin31         = 1'bz;      // input
assign cart_tran_pin31_dir     = 1'b0;  // input

// link port is input only
assign port_tran_so      = 1'bz;
assign port_tran_so_dir  = 1'b0;     // SO is output only
assign port_tran_si      = 1'bz;
assign port_tran_si_dir  = 1'b0;     // SI is input only
assign port_tran_sck     = 1'bz;
assign port_tran_sck_dir = 1'b0;    // clock direction can change
assign port_tran_sd      = 1'bz;
assign port_tran_sd_dir  = 1'b0;     // SD is input and not used


// for bridge write data, we just broadcast it to all bus devices
// for bridge read data, we have to mux it
// add your own devices here
always @(*) begin
    casex(bridge_addr)
    32'h10xxxxxx: begin
        // example
        // bridge_rd_data <= example_device_data;
    end
    32'hF8xxxxxx: begin
        bridge_rd_data <= cmd_bridge_rd_data;
    end
    endcase
end

    
endmodule

`timescale 1ns/1ps

module pocket_dump(
    input           VGA_VS,
    input           led,
    input   [31:0]  frame_cnt
);

`ifdef DUMP
    `ifdef DUMP_START
    always @(negedge VGA_VS) if( frame_cnt==`DUMP_START ) begin
    `else
    initial begin
    `endif
        $shm_open("test.shm");
        `ifdef DEEPDUMP
            $display("NC Verilog: will dump all signals");
            $shm_probe(test,"AS");
        `else
            $display("NC Verilog: will dump selected signals");
            $shm_probe(frame_cnt);
            $shm_probe(UUT.u_game,"A");
            $shm_probe(UUT.u_game.u_main,"A");
            $shm_probe(UUT.u_game.u_sdram,"A");
            $shm_probe(UUT.u_game.u_sdram.u_dwnld,"A");
            // $shm_probe(UUT.u_game.u_sound,"A");
            // $shm_probe(UUT.u_game.u_video,"A");
        `endif
    end
`endif

endmodule // pocket_dump
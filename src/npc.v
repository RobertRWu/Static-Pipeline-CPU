`timescale 1ns / 1ns

module npc(
    input [31:0] addr,
    input rst,
    output [31:0] r
    );

    assign r = rst ? addr : addr + 4;

endmodule
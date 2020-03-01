//////////////////////////////////////////////////////////////////////////////////
// Engineer: Robert Wu
// 
// Create Date: 11/01/2019
// Project Name: Static Pipeline CPU with 54 Instructions Based on MIPS Architecture
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ns

module extend_sign_18_32 (
    input [17:0] data_in,
    output [31:0] data_out
    );

    assign data_out = (data_in[17] == 0) ? {14'b0, data_in} : {14'b11111111111111, data_in};
    
endmodule
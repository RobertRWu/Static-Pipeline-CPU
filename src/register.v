//////////////////////////////////////////////////////////////////////////////////
// Engineer: Robert Wu
// 
// Create Date: 11/01/2019
// Project Name: Static Pipeline CPU with 54 Instructions Based on MIPS Architecture
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ns

module register(
    input clk, 
    input rst, 
    input wena, 
    input [31:0] data_in, 
    output [31:0] data_out 
    );

    reg [31:0] data;

    always @ (negedge clk or posedge rst)
    begin
        if(rst == 1) begin
            data <= 0;
        end

        else if(wena == 1) begin
            data <= data_in;
        end
    end
    
    assign data_out = data;

endmodule
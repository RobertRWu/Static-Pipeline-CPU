///////////////////////////////////////////////////////////////////////////////
// Author: Zirui Wu
// Type: Module
// Project: MIPS Pipeline CPU 54 Instructions
// Description: Instruction Decoder
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module pipe_id(
    input clk,
    input rst,
    input [31:0] pc4,  
    input [31:0] instruction,
    input [31:0] rf_wdata,    //data for writing in regfile
    input [31:0] hi_wdata,
    input [31:0] lo_wdata,
    input [4:0] rf_waddr,  // Regfile write address
    input rf_wena,        //writing enable for regfile
    input hi_wena,        //writing enable for hi register
    input lo_wena,        //writing enable for lo register

    // Data from EXE  
	input [4:0] exe_rf_waddr,  
    input exe_rf_wena,
    input exe_hi_wena,
    input exe_lo_wena,

	// Data from MEM
	input [4:0] mem_rf_waddr,  
    input mem_rf_wena,
    input mem_hi_wena,
    input mem_lo_wena,

    output [31:0] id_cp0_pc,  // Interrupt address
    output [31:0] id_r_pc,
    output [31:0] id_b_pc,  // Jump address
    output [31:0] id_j_pc,  // Beq and Bne address
    output [31:0] id_rs_data_out,  
    output [31:0] id_rt_data_out,
    output [31:0] id_imm,  // Immediate value
    output [31:0] id_shamt,  
    output [31:0] id_pc4,  
    output [31:0] id_cp0_out,    //output data of cp0
    output [31:0] id_hi_out,     //output data of hi register
    output [31:0] id_lo_out,     //output data of lo register
    output [4:0] id_rf_waddr,
    output [3:0] id_aluc,
    output id_mul_sign,
    output id_div_sign,
    output id_cutter_sign,
    output id_clz_ena,
    output id_mul_ena,
    output id_div_ena,
    output id_dmem_ena,
    output id_hi_wena,
    output id_lo_wena,
    output id_rf_wena,
    output id_dmem_wena,
    output [1:0] id_dmem_w_cs,
    output [1:0] id_dmem_r_cs,
    output id_cutter_mux_sel,
    output id_alu_mux1_sel, 
    output [1:0] id_alu_mux2_sel,
    output [1:0] id_hi_mux_sel,
    output [1:0] id_lo_mux_sel,
    output [2:0] id_cutter_sel,
    output [2:0] id_rf_mux_sel,
    output [2:0] id_pc_mux_sel,
    output stall,
    output is_branch,
    output [31:0] reg28,
    output [31:0] reg29
    );

    //Regfile
    wire [4:0] rs;
    wire [4:0] rt;
    wire [4:0] rd;  // Register Destinition
    wire [5:0] op;  // Operand
    wire [5:0] func;  // Function
    wire rf_rena1;  // Regfile read enable 1
    wire rf_rena2;

    wire [15:0] ext16_data_in;  // Input data of extend16
    wire [17:0] ext18_data_in;  // Input data of extend18 
    wire [31:0] ext16_data_out;  // Output data of extend16
    wire [31:0] ext18_data_out;  // Output data of extend18 
    wire ext16_sign;
    wire mfc0;
    wire mtc0;
    wire eret;
    
    // CP0 ports
    wire cp0_exception;
    wire [4:0] cp0_cause;
    wire [4:0] cp0_addr;
    wire [31:0] cp0_status;

    // Ext5
    wire ext5_mux_sel;
    wire [4:0] ext5_mux_out;
    
    assign op = instruction[31:26];
    assign rs = instruction[25:21];
    assign rt = instruction[20:16];
    assign func = instruction[5:0];
    assign ext16_data_in = instruction[15:0];
    assign ext18_data_in = {instruction[15:0], 2'b00};

    assign id_imm = ext16_data_out;
    assign id_j_pc = {pc4[31:28], instruction[25:0], 2'b00};
    assign id_r_pc = id_rs_data_out;
    assign id_pc4 = pc4;
    assign id_rf_waddr = rd;


    id_stall stall_controller(
        .clk(clk),
        .rst(rst),
        .op(op),  
        .func(func),
        .rs(rs),
        .rt(rt),
        .rf_rena1(rf_rena1),
        .rf_rena2(rf_rena2),

	    .exe_rf_waddr(exe_rf_waddr),  
        .exe_rf_wena(exe_rf_wena),
        .exe_hi_wena(exe_hi_wena),
        .exe_lo_wena(exe_lo_wena),

        .mem_rf_waddr(mem_rf_waddr),  
        .mem_rf_wena(mem_rf_wena),
        .mem_hi_wena(mem_hi_wena),
        .mem_lo_wena(mem_lo_wena),

        .stall(stall)
    );


    // MUX for extend5
    mux_2_5 extend5_mux(
        .C0(instruction[10:6]),
        .C1(id_rs_data_out[4:0]),
        .S0(ext5_mux_sel), 
        .oZ(ext5_mux_out)
    );

    // Adder for beq and bne
    adder_32 b_pc_adder(
        .a(pc4),
        .b(ext18_data_out),
        .result(id_b_pc)
    );

    // Extend5 for shamt(sll etc)
    extend_5_32 sa_ext(
        .a(ext5_mux_out),
        .b(id_shamt)
    );

    // Extend16 for immediate
    extend_16_32 imm_ext(
        .data_in(ext16_data_in),
        .sign(ext16_sign),
        .data_out(ext16_data_out)
    );

    // Extend18 for beq and bne
    extend_sign_18_32 ext18_b_pc(
        .data_in(ext18_data_in),
        .data_out(ext18_data_out)
    );

    regfile cpu_regfile(
        .clk(clk), 
        .rst(rst), 
        .wena(rf_wena),
        .raddr1(rs),
        .raddr2(rt),
        .rena1(rf_rena1),
        .rena2(rf_rena2),
        .waddr(rf_waddr),
        .wdata(rf_wdata),
        .rdata1(id_rs_data_out),
        .rdata2(id_rt_data_out),
        .reg28(reg28),
        .reg29(reg29)
    );

    cp0 cpu_cp0(
        .clk(clk), 
        .rst(rst), 
        .mfc0(mfc0),
        .mtc0(mtc0),
        .pc(pc4 - 4),         
        .addr(cp0_addr),
        .wdata(id_rt_data_out),
        .exception(cp0_exception),
        .eret(eret),
        .cause(cp0_cause),
        .rdata(id_cp0_out),
        .status(cp0_status),
        .exc_addr(id_cp0_pc)
    );

    // HI Register
    register hi_reg(
        .clk(clk),
        .rst(rst),
        .wena(hi_wena),
        .data_in(hi_wdata),
        .data_out(id_hi_out)
    );

    // LO Register
    register lo_reg(
        .clk(clk),
        .rst(rst),
        .wena(lo_wena),
        .data_in(lo_wdata),
        .data_out(id_lo_out)
    );

    // Branch prediction
    branch_compare compare(
        .clk(clk),
        .rst(rst),
        .data_in1(id_rs_data_out),
        .data_in2(id_rt_data_out),
        .op(op),
        .func(func),
        .exception(cp0_exception),
        .is_branch(is_branch)
    );

    control_unit control_unit( 
        .is_branch(is_branch),
        .instruction(instruction),
        .op(op),
        .func(func),
        .status(cp0_status),
        .rf_wena(id_rf_wena),
        .hi_wena(id_hi_wena),
        .lo_wena(id_lo_wena),
        .dmem_wena(id_dmem_wena),
        .rf_rena1(rf_rena1),
        .rf_rena2(rf_rena2),
        .clz_ena(id_clz_ena),
        .mul_ena(id_mul_ena),
        .div_ena(id_div_ena),
        .dmem_ena(id_dmem_ena),
        .dmem_w_cs(id_dmem_w_cs),
        .dmem_r_cs(id_dmem_r_cs),
        .ext16_sign(ext16_sign),
        .cutter_sign(id_cutter_sign),
        .mul_sign(id_mul_sign),
        .div_sign(id_div_sign),
        .aluc(id_aluc),
        .rd(rd),
        .mfc0(mfc0),
        .mtc0(mtc0),
        .eret(eret),
        .exception(cp0_exception),
        .cp0_addr(cp0_addr),
        .cause(cp0_cause),
        .ext5_mux_sel(ext5_mux_sel),
        .cutter_mux_sel(id_cutter_mux_sel),
        .alu_mux1_sel(id_alu_mux1_sel),
        .alu_mux2_sel(id_alu_mux2_sel),
        .hi_mux_sel(id_hi_mux_sel),
        .lo_mux_sel(id_lo_mux_sel),
        .cutter_sel(id_cutter_sel),
        .rf_mux_sel(id_rf_mux_sel),
        .pc_mux_sel(id_pc_mux_sel)
    );

endmodule
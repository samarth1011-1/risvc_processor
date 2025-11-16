`timescale 1ns/1ps

module top_module #(
    parameter IMEM_DEPTH = 12,
    parameter DMEM_DEPTH = 12,
    parameter IMEM_FILE  = "final_test.hex"
)(
    input wire clk,
    input wire rst,

    output wire [31:0] debug_pc,
    output wire [31:0] debug_instruction,
    output wire [31:0] debug_alu_result
);

// ========================= IF STAGE =========================

wire [31:0] pc;
wire pc_write;
wire [31:0] next_pc;

program_counter  PC (
    .clk(clk),
    .rst(rst),
    .pc_write(pc_write),
    .next_pc(next_pc),
    .pc_out(pc)
);

wire [31:0] if_instr;

instruction_memory #(
    .DEPTH(IMEM_DEPTH),
    .IN_FILE(IMEM_FILE)
) IMEM (
    .addr_i(pc),
    .enable(1'b1),
    .instr_o(if_instr)
);

// ========================= IF/ID ============================

wire [31:0] id_pc;
wire [31:0] id_instr;
wire if_id_write;
wire if_id_flush;

if_id_pipeline IF_ID (
    .clk(clk),
    .rst(rst),
    .enable(if_id_write),
    .flush(if_id_flush),
    .if_pc(pc),
    .if_instr(if_instr),
    .id_pc(id_pc),
    .id_instr(id_instr)
);

// ========================= ID STAGE =========================

wire [6:0] id_opcode;
wire [4:0] id_rs1;
wire [4:0] id_rs2;
wire [4:0] id_rd;
wire [2:0] id_funct3;
wire [6:0] id_funct7;
wire [31:0] id_imm;

decoder DEC (
    .instr_input(id_instr),
    .pc(id_pc),
    .opcode(id_opcode),
    .rs1(id_rs1),
    .rs2(id_rs2),
    .rd(id_rd),
    .funct3(id_funct3),
    .funct7(id_funct7),
    .imm(id_imm)
);

wire cu_MemWrite, cu_MemRead, cu_ALUsrc, cu_branch, cu_RegWrite;
wire [1:0] cu_ALUop;

control_unit CU (
    .opcode(id_opcode),
    .MemWrite(cu_MemWrite),
    .MemRead(cu_MemRead),
    .ALUsrc(cu_ALUsrc),
    .branch(cu_branch),
    .RegWrite(cu_RegWrite),
    .ALUop(cu_ALUop)
);

wire [31:0] rs1_data, rs2_data;

wire [31:0] wb_data;
wire [4:0] wb_rd;
wire wb_RegWrite;

register_file RF (
    .clk(clk),
    .write_enable(wb_RegWrite),
    .rst(rst),
    .rs1_addr(id_rs1),
    .rs2_addr(id_rs2),
    .rd_addr(wb_rd),
    .rd_data(wb_data),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data)
);

// ALU control
wire [3:0] alu_control;
wire is_muldiv;
wire [2:0] muldiv_op;

alu_control ALUCTRL (
    .ALUop(cu_ALUop),
    .funct3(id_funct3),
    .funct7(id_funct7),
    .ALU_control(alu_control),
    .is_muldiv(is_muldiv),
    .muldiv_op(muldiv_op)
);

// ========================= ID/EX ============================

wire id_ex_enable;
wire id_ex_flush;

wire [31:0] ex_pc, ex_rs1_val, ex_rs2_val, ex_imm;
wire [4:0] ex_rd, ex_rs1, ex_rs2;
wire ex_RW, ex_MR, ex_MW, ex_branch, ex_ALUsrc, ex_is_muldiv;
wire [3:0] ex_alu_sel;
wire [2:0] ex_muldiv_op;

id_ex_pipeline ID_EX (
    .clk(clk),
    .rst(rst),
    .enable(id_ex_enable),
    .flush(id_ex_flush),

    .id_pc(id_pc),
    .id_rs1_val(rs1_data),
    .id_rs2_val(rs2_data),
    .id_imm(id_imm),
    .id_rd(id_rd),
    .id_rs1(id_rs1),
    .id_rs2(id_rs2),
    .id_RW(cu_RegWrite),
    .id_MR(cu_MemRead),
    .id_MW(cu_MemWrite),
    .id_branch(cu_branch),
    .id_ALUsrc(cu_ALUsrc),
    .id_is_muldiv(is_muldiv),
    .id_alu_sel(alu_control),
    .id_muldiv_op(muldiv_op),

    .ex_pc(ex_pc),
    .ex_rs1_val(ex_rs1_val),
    .ex_rs2_val(ex_rs2_val),
    .ex_imm(ex_imm),
    .ex_rd(ex_rd),
    .ex_rs1(ex_rs1),
    .ex_rs2(ex_rs2),
    .ex_RW(ex_RW),
    .ex_MR(ex_MR),
    .ex_MW(ex_MW),
    .ex_branch(ex_branch),
    .ex_ALUsrc(ex_ALUsrc),
    .ex_is_muldiv(ex_is_muldiv),
    .ex_alu_sel(ex_alu_sel),
    .ex_muldiv_op(ex_muldiv_op)
);

// ========================= FORWARDING =========================

wire [1:0] fwdA, fwdB;

forwarding_unit FWD (
    .ex_rs1(ex_rs1),
    .ex_rs2(ex_rs2),
    .mem_rd(mem_rd),
    .wb_rd(wb_rd),
    .mem_regwrite(mem_RW),
    .wb_regwrite(wb_RegWrite),
    .forwardA(fwdA),
    .forwardB(fwdB)
);

// Forwarding muxes
wire [31:0] alu_in_A = (fwdA==2'b10) ? mem_alu_result :
                       (fwdA==2'b01) ? wb_data :
                       ex_rs1_val;

wire [31:0] alu_in_B_pre = (fwdB==2'b10) ? mem_alu_result :
                           (fwdB==2'b01) ? wb_data :
                           ex_rs2_val;

wire [31:0] alu_in_B = ex_ALUsrc ? ex_imm : alu_in_B_pre;

// ========================= EXECUTE ============================

wire [31:0] alu_result;
wire alu_Z;

ALU alu_unit (
    .A(alu_in_A),
    .B(alu_in_B),
    .opcode(ex_alu_sel),
    .result(alu_result),
    .Z(alu_Z)
);

// MUL/DIV
wire muldiv_busy, muldiv_ready;
wire [31:0] muldiv_result;
wire muldiv_start = ex_is_muldiv && !muldiv_busy;

mul_div MULDIV (
    .clk(clk),
    .rst(rst),
    .start(muldiv_start),
    .opcode(ex_muldiv_op),
    .rs1(ex_rs1_val),
    .rs2(ex_rs2_val),
    .busy(muldiv_busy),
    .ready(muldiv_ready),
    .result(muldiv_result)
);

wire [31:0] ex_final_result = ex_is_muldiv ? muldiv_result : alu_result;

// Branch calculation
wire [31:0] ex_branch_target = ex_pc + ex_imm;
wire ex_branch_taken = ex_branch && alu_Z;

// ========================= EX/MEM ============================

wire [31:0] mem_alu_result, mem_rs2_val;
wire [4:0] mem_rd;
wire mem_RW, mem_MR, mem_MW, mem_branch;
wire [31:0] mem_branch_target;
wire mem_branch_taken;

ex_mem_pipeline EX_MEM (
    .clk(clk),
    .rst(rst),
    .enable(1'b1),
    .flush(1'b0),
    .ex_alu_result(ex_final_result),
    .ex_rs2_val(ex_rs2_val),
    .ex_rd(ex_rd),
    .ex_RW(ex_RW),
    .ex_MR(ex_MR),
    .ex_MW(ex_MW),
    .ex_branch(ex_branch),
    .ex_branch_target(ex_branch_target),
    .ex_branch_taken(ex_branch_taken),

    .mem_alu_result(mem_alu_result),
    .mem_rs2_val(mem_rs2_val),
    .mem_rd(mem_rd),
    .mem_RW(mem_RW),
    .mem_MR(mem_MR),
    .mem_MW(mem_MW),
    .mem_branch(mem_branch),
    .mem_branch_target(mem_branch_target),
    .mem_branch_taken(mem_branch_taken)
);

// ========================= MEMORY ============================

wire [31:0] mem_read_data;

data_memory #(
    .DEPTH(DMEM_DEPTH)
) DMEM (
    .clk(clk),
    .rst(rst),
    .MemRead(mem_MR),
    .MemWrite(mem_MW),
    .addr_i(mem_alu_result),
    .write_data_i(mem_rs2_val),
    .read_data_o(mem_read_data)
);

// ========================= MEM/WB ============================

wire [31:0] wb_alu_result, wb_read_data;
wire wb_MR;

mem_wb_pipeline MEM_WB (
    .clk(clk),
    .rst(rst),
    .enable(1'b1),
    .flush(1'b0),
    .mem_alu_result(mem_alu_result),
    .mem_read_data(mem_read_data),
    .mem_rd(mem_rd),
    .mem_RW(mem_RW),
    .mem_MR(mem_MR),
    .wb_alu_result(wb_alu_result),
    .wb_read_data(wb_read_data),
    .wb_rd(wb_rd),
    .wb_RW(wb_RegWrite),
    .wb_MR(wb_MR)
);

assign wb_data = wb_MR ? wb_read_data : wb_alu_result;

// ========================= HAZARD UNIT ============================

wire stall, id_ex_flush_sig;

hazard_detection HAZ (
    .clk(clk),
    .rst(rst),
    .id_rs1(id_rs1),
    .id_rs2(id_rs2),
    .ex_rd(ex_rd),
    .ex_memread(ex_MR),
    .id_is_muldiv(is_muldiv),
    .muldiv_busy(muldiv_busy),
    .stall(stall),
    .pc_write(pc_write),
    .if_id_write(if_id_write),
    .id_ex_flush(id_ex_flush_sig),
    .mem_stall()
);

assign id_ex_enable = ~stall;
assign id_ex_flush  = id_ex_flush_sig;
assign if_id_flush  = id_ex_flush_sig;
assign next_pc      = pc + 32'd4;

// ========================= DEBUG ==============================

assign debug_pc         = pc;
assign debug_instruction= id_instr;
assign debug_alu_result = mem_alu_result;

endmodule

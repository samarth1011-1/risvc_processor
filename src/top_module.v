`timescale 1ns/1ps

module top_module #(
    parameter IMEM_DEPTH = 256,
    parameter DMEM_DEPTH = 256,
    parameter IMEM_FILE  = "./programs/test_add.hex"
)(
    input  wire clk,
    input  wire rst,
    output wire [31:0] debug_pc,
    output wire [31:0] debug_instruction,
    output wire [31:0] debug_alu_result
);

    // ---------------------------------------------------------------------
    // IF stage
    // ---------------------------------------------------------------------
    wire [31:0] pc_value;
    wire [31:0] if_instr;

    wire        branch_resolved;
    wire [31:0] resolved_branch_target;

    // Stall infrastructure (currently used for mul/div long operations)
    wire muldiv_busy;
    wire muldiv_ready;
    reg  muldiv_active;
    wire stall_pipeline = muldiv_active && !muldiv_ready;

    wire hold_pc       = stall_pipeline & ~branch_resolved;
    wire pc_branch_evt = branch_resolved | hold_pc;
    wire [31:0] pc_branch_target = hold_pc ? pc_value : resolved_branch_target;

    program_counter pc_inst (
        .clk(clk),
        .rst(rst),
        .branch_target(pc_branch_target),
        .branch_taken(pc_branch_evt),
        .pc_out(pc_value)
    );

    instruction_memory #(
        .DEPTH(IMEM_DEPTH),
        .IN_FILE(IMEM_FILE)
    ) instr_mem (
        .addr_i(pc_value),
        .enable(1'b1),
        .instr_o(if_instr)
    );

    // ---------------------------------------------------------------------
    // IF/ID pipeline register
    // ---------------------------------------------------------------------
    wire [31:0] id_pc;
    wire [31:0] id_instr;

    wire flush_if_id = branch_resolved;
    wire pipe_enable = ~stall_pipeline;

    if_id_pipeline if_id_reg (
        .clk(clk),
        .rst(rst),
        .enable(pipe_enable),
        .flush(flush_if_id),
        .if_pc(pc_value),
        .if_instr(if_instr),
        .id_pc(id_pc),
        .id_instr(id_instr)
    );

    // ---------------------------------------------------------------------
    // Decode stage
    // ---------------------------------------------------------------------
    wire [6:0]  opcode;
    wire [4:0]  id_rs1;
    wire [4:0]  id_rs2;
    wire [4:0]  id_rd;
    wire [2:0]  funct3;
    wire [6:0]  funct7;
    wire [31:0] id_imm;

    decoder dec (
        .instr_input(id_instr),
        .pc(id_pc),
        .opcode(opcode),
        .rs1(id_rs1),
        .rs2(id_rs2),
        .rd(id_rd),
        .funct3(funct3),
        .funct7(funct7),
        .imm(id_imm)
    );

    wire MemWrite;
    wire MemRead;
    wire ALUsrc;
    wire branch;
    wire RegWrite;
    wire [1:0] ALUop;

    control_unit ctrl (
        .opcode(opcode),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .ALUsrc(ALUsrc),
        .branch(branch),
        .RegWrite(RegWrite),
        .ALUop(ALUop)
    );

    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    wire [31:0] wb_write_data;
    wire [4:0]  wb_rd;
    wire        wb_RegWrite;

    register_file regs (
        .clk(clk),
        .write_enable(wb_RegWrite),
        .rst(rst),
        .rs1_addr(id_rs1),
        .rs2_addr(id_rs2),
        .rd_addr(wb_rd),
        .rd_data(wb_write_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    wire [3:0] alu_sel;
    wire       id_is_muldiv;
    wire [2:0] id_muldiv_op;

    alu_control alu_ctrl (
        .ALUop(ALUop),
        .funct3(funct3),
        .funct7(funct7),
        .ALU_control(alu_sel),
        .is_muldiv(id_is_muldiv),
        .muldiv_op(id_muldiv_op)
    );

    // ---------------------------------------------------------------------
    // ID/EX pipeline register
    // ---------------------------------------------------------------------
    wire [31:0] ex_pc;
    wire [31:0] ex_rs1_val;
    wire [31:0] ex_rs2_val;
    wire [31:0] ex_imm;
    wire [4:0]  ex_rd;
    wire [4:0]  ex_rs1;
    wire [4:0]  ex_rs2;
    wire        ex_RW;
    wire        ex_MR;
    wire        ex_MW;
    wire        ex_branch;
    wire        ex_ALUsrc;
    wire        ex_is_muldiv;
    wire [3:0]  ex_alu_sel;
    wire [2:0]  ex_muldiv_op;

    id_ex_pipeline id_ex_reg (
        .clk(clk),
        .rst(rst),
        .enable(pipe_enable),
        .flush(branch_resolved),
        .id_pc(id_pc),
        .id_rs1_val(rs1_data),
        .id_rs2_val(rs2_data),
        .id_imm(id_imm),
        .id_rd(id_rd),
        .id_rs1(id_rs1),
        .id_rs2(id_rs2),
        .id_RW(RegWrite),
        .id_MR(MemRead),
        .id_MW(MemWrite),
        .id_branch(branch),
        .id_ALUsrc(ALUsrc),
        .id_is_muldiv(id_is_muldiv),
        .id_alu_sel(alu_sel),
        .id_muldiv_op(id_muldiv_op),
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

    // ---------------------------------------------------------------------
    // Execute stage
    // ---------------------------------------------------------------------
    wire [31:0] alu_operand_b = ex_ALUsrc ? ex_imm : ex_rs2_val;
    wire [31:0] alu_result;
    wire        alu_zero;

    ALU alu (
        .A(ex_rs1_val),
        .B(alu_operand_b),
        .opcode(ex_alu_sel),
        .result(alu_result),
        .Z(alu_zero)
    );

    wire [31:0] branch_target_ex = ex_pc + ex_imm;
    wire        ex_branch_taken  = ex_branch && alu_zero;

    wire [31:0] muldiv_result;

    wire muldiv_start = ex_is_muldiv && !muldiv_active;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            muldiv_active <= 1'b0;
        end else if (!ex_is_muldiv) begin
            muldiv_active <= 1'b0;
        end else if (muldiv_ready) begin
            muldiv_active <= 1'b0;
        end else if (muldiv_start) begin
            muldiv_active <= 1'b1;
        end
    end

    mul_div muldiv_unit (
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

    // ---------------------------------------------------------------------
    // EX/MEM pipeline register
    // ---------------------------------------------------------------------
    wire [31:0] mem_alu_result;
    wire [31:0] mem_rs2_val;
    wire [4:0]  mem_rd;
    wire        mem_RW;
    wire        mem_MR;
    wire        mem_MW;
    wire        mem_branch;
    wire [31:0] mem_branch_target;
    wire        mem_branch_taken;

    ex_mem_pipeline ex_mem_reg (
        .clk(clk),
        .rst(rst),
        .enable(pipe_enable),
        .flush(1'b0),
        .ex_alu_result(ex_final_result),
        .ex_rs2_val(ex_rs2_val),
        .ex_rd(ex_rd),
        .ex_RW(ex_RW),
        .ex_MR(ex_MR),
        .ex_MW(ex_MW),
        .ex_branch(ex_branch),
        .ex_branch_target(branch_target_ex),
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

    assign branch_resolved        = mem_branch && mem_branch_taken;
    assign resolved_branch_target = mem_branch_target;

    // ---------------------------------------------------------------------
    // Memory stage
    // ---------------------------------------------------------------------
    wire [31:0] mem_read_data;

    data_memory #(
        .DEPTH(DMEM_DEPTH)
    ) dmem (
        .clk(clk),
        .rst(rst),
        .MemRead(mem_MR),
        .MemWrite(mem_MW),
        .addr_i(mem_alu_result),
        .write_data_i(mem_rs2_val),
        .read_data_o(mem_read_data)
    );

    // ---------------------------------------------------------------------
    // MEM/WB pipeline register
    // ---------------------------------------------------------------------
    wire [31:0] wb_alu_result;
    wire [31:0] wb_read_data;
    wire        wb_MR;

    mem_wb_pipeline mem_wb_reg (
        .clk(clk),
        .rst(rst),
        .enable(pipe_enable),
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

    assign wb_write_data = wb_MR ? wb_read_data : wb_alu_result;

    // ---------------------------------------------------------------------
    // Debug outputs
    // ---------------------------------------------------------------------
    assign debug_pc           = pc_value;
    assign debug_instruction  = id_instr;
    assign debug_alu_result   = mem_alu_result;

endmodule

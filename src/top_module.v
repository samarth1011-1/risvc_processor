module riscv_core(
    input clk,
    input rst
);

wire [31:0] pc, next_pc, instr;
wire pc_write;

program_counter PC (
    .clk(clk),
    .rst(rst),
    .pc_write(pc_write),
    .next_pc(next_pc),
    .pc_out(pc)
);

instruction_memory IMEM (
    .addr_i(pc),
    .enable(1'b1),
    .instr_o(instr)
);

wire [31:0] id_pc, id_instr;
wire if_id_write, if_id_flush;

if_id_pipeline IF_ID (
    .clk(clk),
    .rst(rst),
    .enable(if_id_write),
    .flush(if_id_flush),
    .if_pc(pc),
    .if_instr(instr),
    .id_pc(id_pc),
    .id_instr(id_instr)
);

wire [6:0] opcode;
wire [4:0] rs1, rs2, rd;
wire [2:0] funct3;
wire [6:0] funct7;
wire [31:0] imm;

decoder DEC (
    .instr_input(id_instr),
    .pc(id_pc),
    .opcode(opcode),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .funct3(funct3),
    .funct7(funct7),
    .imm(imm)
);

// CONTROL UNIT
wire MemWrite, MemRead, ALUsrc, branch, RegWrite;
wire [1:0] ALUop;

control_unit CTRL (
    .opcode(opcode),
    .MemWrite(MemWrite),
    .MemRead(MemRead),
    .ALUsrc(ALUsrc),
    .branch(branch),
    .RegWrite(RegWrite),
    .ALUop(ALUop)
);

// ALU CONTROL
wire [3:0] alu_ctrl;
wire id_is_muldiv;
wire [2:0] id_muldiv_op;

alu_control ALUCTRL (
    .ALUop(ALUop),
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .ALU_control(alu_ctrl),
    .is_muldiv(id_is_muldiv),
    .muldiv_op(id_muldiv_op)
);

// REGISTER FILE
wire [31:0] rs1_data, rs2_data;
wire [31:0] wb_data;
wire wb_RW;
wire [4:0] wb_rd;

register_file REGFILE (
    .clk(clk),
    .write_enable(wb_RW),
    .rst(rst),
    .rs1_addr(rs1),
    .rs2_addr(rs2),
    .rd_addr(wb_rd),
    .rd_data(wb_data),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data)
);

wire ex_RW, ex_MR, ex_MW, ex_branch, ex_ALUsrc, ex_is_muldiv;
wire [31:0] ex_pc, ex_rs1_val, ex_rs2_val, ex_imm;
wire [4:0] ex_rs1, ex_rs2, ex_rd;
wire [3:0] ex_alu_sel;
wire [2:0] ex_muldiv_op;

wire id_ex_flush;

id_ex_pipeline ID_EX (
    .clk(clk),
    .rst(rst),
    .enable(1'b1),
    .flush(id_ex_flush),

    .id_pc(id_pc),
    .id_rs1_val(rs1_data),
    .id_rs2_val(rs2_data),
    .id_imm(imm),
    .id_rd(rd),
    .id_rs1(rs1),
    .id_rs2(rs2),

    .id_RW(RegWrite),
    .id_MR(MemRead),
    .id_MW(MemWrite),
    .id_branch(branch),
    .id_ALUsrc(ALUsrc),
    .id_is_muldiv(id_is_muldiv),
    .id_alu_sel(alu_ctrl),
    .id_muldiv_op(id_muldiv_op),
    .id_funct3(funct3),

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

wire [1:0] forwardA, forwardB;
wire mem_RW;
wire [4:0] mem_rd;

forwarding_unit FWD (
    .ex_rs1(ex_rs1),
    .ex_rs2(ex_rs2),
    .mem_rd(mem_rd),
    .wb_rd(wb_rd),
    .mem_regwrite(mem_RW),
    .wb_regwrite(wb_RW),
    .forwardA(forwardA),
    .forwardB(forwardB)
);

// FORWARD MUX
wire [31:0] alu_in1, alu_in2_raw, alu_in2;

assign alu_in1 =
    (forwardA == 2'b10) ? mem_alu_result :
    (forwardA == 2'b01) ? wb_data :
    ex_rs1_val;

assign alu_in2_raw =
    (forwardB == 2'b10) ? mem_alu_result :
    (forwardB == 2'b01) ? wb_data :
    ex_rs2_val;

assign alu_in2 = ex_ALUsrc ? ex_imm : alu_in2_raw;


// ALU
wire [31:0] alu_result;

ALU ALU (
    .A(alu_in1),
    .B(alu_in2),
    .opcode(ex_alu_sel),
    .result(alu_result)
);

// MUL/DIV
wire [31:0] muldiv_result;
wire muldiv_busy, muldiv_ready;

mul_div MULDIV (
    .clk(clk),
    .rst(rst),
    .start(ex_is_muldiv),
    .opcode(ex_muldiv_op),
    .rs1(alu_in1),
    .rs2(alu_in2),
    .busy(muldiv_busy),
    .ready(muldiv_ready),
    .result(muldiv_result)
);

wire [31:0] ex_result;

assign ex_result =
    (ex_is_muldiv && muldiv_ready) ? muldiv_result :
    (!ex_is_muldiv) ? alu_result :
    32'b0;

// BRANCH
wire branch_taken = ex_branch && (alu_in1 == alu_in2);
wire [31:0] branch_target = ex_pc + ex_imm;

wire mem_MR, mem_MW;
wire [31:0] mem_alu_result, mem_rs2_val;

ex_mem_pipeline EX_MEM (
    .clk(clk),
    .rst(rst),
    .enable(1'b1),
    .flush(1'b0),

    .ex_alu_result(ex_result),
    .ex_rs2_val(alu_in2_raw),
    .ex_rd(ex_rd),
    .ex_RW(ex_RW),
    .ex_MR(ex_MR),
    .ex_MW(ex_MW),
    .ex_branch(ex_branch),
    .ex_branch_target(branch_target),
    .ex_branch_taken(branch_taken),
    .ex_is_muldiv(ex_is_muldiv),

    .mem_alu_result(mem_alu_result),
    .mem_rs2_val(mem_rs2_val),
    .mem_rd(mem_rd),
    .mem_RW(mem_RW),
    .mem_MR(mem_MR),
    .mem_MW(mem_MW)
);

wire [31:0] mem_read_data;

data_memory DMEM (
    .clk(clk),
    .rst(rst),
    .MemRead(mem_MR),
    .MemWrite(mem_MW),
    .addr_i(mem_alu_result),
    .write_data_i(mem_rs2_val),
    .read_data_o(mem_read_data)
);

wire wb_MR;
wire [31:0] wb_alu_result, wb_read_data;

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
    .wb_RW(wb_RW),
    .wb_MR(wb_MR)
);

// WRITEBACK
assign wb_data = wb_MR ? wb_read_data : wb_alu_result;

assign next_pc = branch_taken ? branch_target : (pc + 4);

hazard_detection HZD (
    .id_rs1(rs1),
    .id_rs2(rs2),
    .ex_rd(ex_rd),
    .ex_memread(ex_MR),
    .id_is_muldiv(id_is_muldiv),
    .ex_is_muldiv(ex_is_muldiv),
    .muldiv_busy(muldiv_busy),
    .muldiv_ready(muldiv_ready),
    .stall(),
    .pc_write(pc_write),
    .if_id_write(if_id_write),
    .id_ex_flush(id_ex_flush),
    .mem_stall()
);

assign if_id_flush = branch_taken;

endmodule
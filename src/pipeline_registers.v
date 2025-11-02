/*
Creating pipeline registers between IF, ID, EX, MEM, WB stages
Each register latches values on the rising edge of clk.
They support:
  - rst  : synchronous reset
  - flush: clear outputs (used for branch mispredicts)
  - enable: hold outputs when low (used for pipeline stalls)
*/

// IF / ID
module if_id_pipeline(
    input clk,
    input rst,
    input enable,
    input flush,
    input [31:0] if_pc,
    input [31:0] if_instr,
    output reg [31:0] id_pc,
    output reg [31:0] id_instr
);
always @(posedge clk) begin
    if (rst || flush) begin
        id_pc    <= 32'b0;
        id_instr <= 32'h00000013;   // NOP = ADDI x0,x0,0
    end else if (enable) begin
        id_pc    <= if_pc;
        id_instr <= if_instr;
    end
end
endmodule

// ID / EX
module id_ex_pipeline(
    input clk,
    input rst,
    input enable,
    input flush,

    input  [31:0] id_pc,
    input  [31:0] id_rs1_val,
    input  [31:0] id_rs2_val,
    input  [31:0] id_imm,
    input  [4:0]  id_rd,
    input  [4:0]  id_rs1,
    input  [4:0]  id_rs2,
    input         id_RW,
    input         id_MR,
    input         id_MW,
    input         id_branch,
    input         id_ALUsrc,
    input         id_is_muldiv,
    input  [3:0]  id_alu_sel,
    input  [2:0]  id_muldiv_op,

    output reg [31:0] ex_pc,
    output reg [31:0] ex_rs1_val,
    output reg [31:0] ex_rs2_val,
    output reg [31:0] ex_imm,
    output reg [4:0]  ex_rd,
    output reg [4:0]  ex_rs1,
    output reg [4:0]  ex_rs2,
    output reg        ex_RW,
    output reg        ex_MR,
    output reg        ex_MW,
    output reg        ex_branch,
    output reg        ex_ALUsrc,
    output reg        ex_is_muldiv,
    output reg [3:0]  ex_alu_sel,
    output reg [2:0]  ex_muldiv_op
);
always @(posedge clk) begin
    if (rst || flush) begin
        ex_pc <= 0; ex_rs1_val <= 0; ex_rs2_val <= 0; ex_imm <= 0;
        ex_rd <= 0; ex_rs1 <= 0; ex_rs2 <= 0;
        ex_RW <= 0; ex_MR <= 0; ex_MW <= 0;
        ex_branch <= 0; ex_ALUsrc <= 0; ex_is_muldiv <= 0;
        ex_alu_sel <= 0; ex_muldiv_op <= 0;
    end else if (enable) begin
        ex_pc <= id_pc;
        ex_rs1_val <= id_rs1_val;
        ex_rs2_val <= id_rs2_val;
        ex_imm <= id_imm;
        ex_rd <= id_rd;
        ex_rs1 <= id_rs1;
        ex_rs2 <= id_rs2;
        ex_RW <= id_RW;
        ex_MR <= id_MR;
        ex_MW <= id_MW;
        ex_branch <= id_branch;
        ex_ALUsrc <= id_ALUsrc;
        ex_is_muldiv <= id_is_muldiv;
        ex_alu_sel <= id_alu_sel;
        ex_muldiv_op <= id_muldiv_op;
    end
end
endmodule

// EX / MEM
module ex_mem_pipeline(
    input clk,
    input rst,
    input enable,
    input flush,

    input  [31:0] ex_alu_result,
    input  [31:0] ex_rs2_val,
    input  [4:0]  ex_rd,
    input         ex_RW,
    input         ex_MR,
    input         ex_MW,
    input         ex_branch,
    input  [31:0] ex_branch_target,
    input         ex_branch_taken,

    output reg [31:0] mem_alu_result,
    output reg [31:0] mem_rs2_val,
    output reg [4:0]  mem_rd,
    output reg        mem_RW,
    output reg        mem_MR,
    output reg        mem_MW,
    output reg        mem_branch,
    output reg [31:0] mem_branch_target,
    output reg        mem_branch_taken
);
always @(posedge clk) begin
    if (rst || flush) begin
        mem_alu_result <= 0; mem_rs2_val <= 0; mem_rd <= 0;
        mem_RW <= 0; mem_MR <= 0; mem_MW <= 0; mem_branch <= 0;
        mem_branch_target <= 0; mem_branch_taken <= 0;
    end else if (enable) begin
        mem_alu_result <= ex_alu_result;
        mem_rs2_val <= ex_rs2_val;
        mem_rd <= ex_rd;
        mem_RW <= ex_RW;
        mem_MR <= ex_MR;
        mem_MW <= ex_MW;
        mem_branch <= ex_branch;
        mem_branch_target <= ex_branch_target;
        mem_branch_taken <= ex_branch_taken;
    end
end
endmodule

// MEM / WB
module mem_wb_pipeline(
    input clk,
    input rst,
    input enable,
    input flush,

    input  [31:0] mem_alu_result,
    input  [31:0] mem_read_data,
    input  [4:0]  mem_rd,
    input         mem_RW,
    input         mem_MR,

    output reg [31:0] wb_alu_result,
    output reg [31:0] wb_read_data,
    output reg [4:0]  wb_rd,
    output reg        wb_RW,
    output reg        wb_MR
);
always @(posedge clk) begin
    if (rst || flush) begin
        wb_alu_result <= 0; wb_read_data <= 0; wb_rd <= 0;
        wb_RW <= 0; wb_MR <= 0;
    end else if (enable) begin
        wb_alu_result <= mem_alu_result;
        wb_read_data <= mem_read_data;
        wb_rd <= mem_rd;
        wb_RW <= mem_RW;
        wb_MR <= mem_MR;
    end
end
endmodule

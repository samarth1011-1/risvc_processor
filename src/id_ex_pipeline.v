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
    input [2:0] id_funct3,

    output reg [2:0] ex_funct3,
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
        ex_alu_sel <= 0; ex_muldiv_op <= 0; ex_funct3 <= 0;
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
        ex_funct3 <= id_funct3;
    end
end
endmodule

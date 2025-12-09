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
    input         ex_is_muldiv,

    output reg    mem_is_muldiv,
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
        mem_branch_target <= 0; mem_branch_taken <= 0; mem_is_muldiv<=0;
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
        mem_is_muldiv <= ex_is_muldiv;
    end
end
endmodule
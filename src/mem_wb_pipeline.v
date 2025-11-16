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
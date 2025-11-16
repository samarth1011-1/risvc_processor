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
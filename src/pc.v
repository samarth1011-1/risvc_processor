module program_counter(
    input clk,
    input rst,
    input pc_write,
    input [31:0] next_pc,
    output reg [31:0] pc_out
);
always @(posedge clk) begin
    if (rst)
        pc_out <= 32'b0;
    else if (pc_write)
        pc_out <= next_pc;
end
endmodule

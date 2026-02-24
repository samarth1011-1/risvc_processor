module data_memory #(
    parameter DEPTH = 256
)(
    input clk,
    input rst,
    input MemRead,
    input MemWrite,
    input [31:0] addr_i,
    input [31:0] write_data_i,
    output reg [31:0] read_data_o
);

    reg [31:0] mem [0:DEPTH-1];
    wire [31:0] word_addr = addr_i >> 2;
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] <= 32'b0;
        end
        else if (MemWrite && (word_addr < DEPTH)) begin
            mem[word_addr] <= write_data_i;
        end
    end

    always @(*) begin
        if (MemRead && (word_addr < DEPTH))
            read_data_o = mem[word_addr];
        else
            read_data_o = 32'b0;
    end
endmodule

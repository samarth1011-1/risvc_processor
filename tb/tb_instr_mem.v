`timescale 1ns/1ps
module tb_instr_mem;
reg [31:0] addr_i;
reg enable;
wire [31:0] instr_o;

instruction_memory #(
    .DEPTH(256), // this depends on the size of the program we are going to run
    .IN_FILE("./programs/test_add.hex")
) DUT (
    .addr_i(addr_i),
    .enable(enable),
    .instr_o(instr_o)
);

initial begin
    addr_i = 32'b0;
    enable = 1'b0;
end

initial begin
    $dumpfile("vcd_files/tb_instr_mem.vcd");
    $dumpvars(0, tb_instr_mem);
    $monitor("Time = %0t, addr_i = %h, enable = %b, instr_o = %h", $time, addr_i, enable, instr_o);
    #10 addr_i = 32'b0; enable = 1'b1;
    #10 addr_i = 32'd4; enable = 1'b1;
    #10 addr_i = 32'd8; enable = 1'b1;
    #10 enable = 1'b0;
    #10 addr_i = 32'd12; enable = 1'b1;
    #10 $finish;
end
endmodule
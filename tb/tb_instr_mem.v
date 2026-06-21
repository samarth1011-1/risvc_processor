`timescale 1ns/1ps
module tb_instr_mem;
reg [31:0] addr_i;
reg enable;
wire [31:0] instr_o;

instruction_memory #(
    .DEPTH(19),
    .IN_FILE("./programs/core_basic_forward.hex")
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

    #10 addr_i = 32'b0; enable = 1'b1;
    #1 if (instr_o !== 32'h00500093) begin $display("FAIL IMEM addr 0 got=%h", instr_o); $finish; end
    #10 addr_i = 32'd4; enable = 1'b1;
    #1 if (instr_o !== 32'h00700113) begin $display("FAIL IMEM addr 4 got=%h", instr_o); $finish; end
    #10 addr_i = 32'd8; enable = 1'b1;
    #1 if (instr_o !== 32'h002081b3) begin $display("FAIL IMEM addr 8 got=%h", instr_o); $finish; end
    #10 enable = 1'b0;
    #1 if (instr_o !== 32'h00000013) begin $display("FAIL IMEM disabled got=%h", instr_o); $finish; end
    #10 addr_i = 32'd12; enable = 1'b1;
    #1 if (instr_o !== 32'h40118233) begin $display("FAIL IMEM addr 12 got=%h", instr_o); $finish; end

    $display("INSTRUCTION MEMORY TESTS PASSED");
    #10 $finish;
end
endmodule

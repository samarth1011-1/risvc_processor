`timescale 1ns/1ps

module tb_mul_div_unit;
reg clk, start, rst;
reg [2:0] opcode;
reg [31:0] rs1, rs2;
wire busy, ready;
wire [31:0] result;

// DUT instantiation
mul_div dut(
    .clk(clk),
    .rst(rst),
    .start(start),
    .opcode(opcode),
    .rs1(rs1),
    .rs2(rs2),
    .busy(busy),
    .ready(ready),
    .result(result)
);

// Clock generation (20 ns period)
initial clk = 0;
always #10 clk = ~clk;

initial begin
    // Dump file for GTKWave
    $dumpfile("vcd_files/muldiv.vcd");
    $dumpvars(0, tb_mul_div_unit);

    // Display key signals in console
    $monitor("t=%0t | Rst=%b | Start=%b | Opcode=%b | Busy=%b | Ready=%b | Result=%h",
             $time, rst, start, opcode, busy, ready, result);

    // -----------------------------------------
    // Initialization
    // -----------------------------------------
    rst = 1; start = 0; opcode = 3'b000; rs1 = 0; rs2 = 0;
    #20 rst = 0;

    // -----------------------------------------
    // MULTIPLICATION OPERATIONS (single-cycle)
    // -----------------------------------------
    rs1 = 32'd10; rs2 = 32'd10;

    #5  opcode = 3'b000; start = 1;   // MUL
    #20 start = 0;                    // pulse width 20 ns
    #20;                              // idle between ops

    #5  opcode = 3'b001; start = 1;   // MULH
    #20 start = 0;
    #20;

    #5  opcode = 3'b010; start = 1;   // MULHSU
    #20 start = 0;
    #20;

    #5  opcode = 3'b011; start = 1;   // MULHU
    #20 start = 0;
    #40;                              // longer idle before DIVs

    // -----------------------------------------
    // DIVISION / REMAINDER OPERATIONS (multi-cycle)
    // -----------------------------------------
    rs1 = 32'd100; rs2 = 32'd7;

    // DIV
    #5  opcode = 3'b100; start = 1;
    #20 start = 0;
    wait(ready);  #20;

    // DIVU
    #5  opcode = 3'b101; start = 1;
    #20 start = 0;
    wait(ready);  #20;

    // REM
    #5  opcode = 3'b110; start = 1;
    #20 start = 0;
    wait(ready);  #20;

    // REMU
    #5  opcode = 3'b111; start = 1;
    #20 start = 0;
    wait(ready);  #40;  // extra delay to observe final state

    // -----------------------------------------
    // End simulation
    // -----------------------------------------
    $display("Simulation complete at t=%0t", $time);
    #20 $finish;
end
endmodule

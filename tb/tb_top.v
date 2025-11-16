`timescale 1ns/1ps

module tb_top;

    reg clk;
    reg rst;

    wire [31:0] debug_pc;
    wire [31:0] debug_instruction;
    wire [31:0] debug_alu_result;

    // Instantiate your CPU
    top_module DUT (
        .clk(clk),
        .rst(rst),
        .debug_pc(debug_pc),
        .debug_instruction(debug_instruction),
        .debug_alu_result(debug_alu_result)
    );

    // Clock generation: 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Simulation routine
    initial begin
        // VCD dump
        $dumpfile("cpu_dump.vcd");
        $dumpvars(0, tb_top);

        $display("\n--- CPU Simulation Start ---\n");

        // Apply reset - FIXED TIMING
        rst = 1;
        repeat(3) @(posedge clk);  // ✅ Wait for clock edges
        rst = 0;

        // Run for N cycles
        repeat (100) begin
            @(posedge clk);
            #1;  // ✅ Wait for signals to settle
            $display("Cycle=%0d PC=%h INSTR=%h ALU=%h", 
                    $time/10, debug_pc, debug_instruction, debug_alu_result);
        end

        // ✅ Print final register state
        $display("\n--- Final Register Values ---");
        $display("x1  = %h (%0d)", DUT.RF.registers[1], DUT.RF.registers[1]);
        $display("x2  = %h (%0d)", DUT.RF.registers[2], DUT.RF.registers[2]);
        $display("x3  = %h (%0d)", DUT.RF.registers[3], DUT.RF.registers[3]);
        $display("x4  = %h (%0d)", DUT.RF.registers[4], DUT.RF.registers[4]);

        $display("\n--- CPU Simulation End ---\n");
        $finish;
    end

endmodule
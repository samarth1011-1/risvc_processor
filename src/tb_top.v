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

        // Apply reset
        rst = 1;
        #(20);   // hold reset for 2 clock cycles
        rst = 0;

        $display("\n--- CPU Simulation Start ---\n");

        // Run for N cycles
        repeat (100) begin
            @(posedge clk);
            $display("PC=%h   INSTR=%h   ALU=%h",
                    debug_pc, debug_instruction, debug_alu_result);
        end

        $display("\n--- CPU Simulation End ---\n");
        $finish;
    end

endmodule

`timescale 1ns/1ps

module tb_top;

    // ============================================================
    // 1. Signal Declaration
    // ============================================================
    reg clk;
    reg rst;
    
    // Wire signals to connect to the DUT (Device Under Test)
    // NOTE: Ensure these match the output ports of your top_module
    wire [31:0] debug_pc;
    wire [31:0] debug_instruction;
    wire [31:0] debug_alu_result;

    // ============================================================
    // 2. DUT Instantiation
    // ============================================================
    // Make sure 'top_module' matches the exact name of your processor module
    top_module cpu (
        .clk(clk),
        .rst(rst),
        // If your design does not have these debug ports, remove these lines:
        .debug_pc(debug_pc),
        .debug_instruction(debug_instruction),
        .debug_alu_result(debug_alu_result)
    );

    // ============================================================
    // 3. Clock Generation (100 MHz)
    // ============================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Toggle every 5ns = 10ns period
    end

    // ============================================================
    // 4. Test Stimulus
    // ============================================================
    initial begin
        // Optional: Vivado handles waveforms automatically, but this is fine to keep
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_top);
        
        $display("\n========================================");
        $display("    RISC-V CPU Testbench");
        $display("========================================\n");
        
        // --- Reset Sequence ---
        rst = 1;
        #20;         // Hold reset for 2 clock cycles
        rst = 0;
        
        $display("Time=%0t: Reset released", $time);
        $display("Starting execution...\n");
        
        // --- Run Simulation ---
        // Adjust this duration based on how long your program takes
        #1000; 
        
        // --- End of Simulation ---
        display_register_file(); // Call the task to print registers
        
        $display("\nSimulation Finished.");
        $finish;
    end
    
    // ============================================================
    // 5. Monitor Execution (PC Logging)
    // ============================================================
    always @(posedge clk) begin
        if (!rst) begin
            // Prints the PC and Instruction every cycle to the Tcl Console
            $display("Time=%0t | PC=0x%h | Instr=0x%h | ALU_Res=0x%h", 
                     $time, debug_pc, debug_instruction, debug_alu_result);
        end
    end

    // ============================================================
    // 6. Task: Display Register File
    // ============================================================
    // CRITICAL: Check your hierarchy!
    // If your register file instance is named 'rf' instead of 'RF', change it below.
    // If your memory array is named 'regs' instead of 'registers', change it below.
    task display_register_file;
        integer i;
        begin
            $display("\n========================================");
            $display("    Final Register Values (x0 - x31)");
            $display("========================================");
            
            // Note: Vivado might warn if it can't find this path. 
            // Ensure 'cpu' (instantiation name) -> 'RF' (sub-module name) -> 'registers' (array name) exists.
            
            for (i = 0; i < 32; i = i + 1) begin
                // Using $peek or direct hierarchical access
                $display("x%0d \t= 0x%h", i, cpu.RF.registers[i]);
            end
            
            $display("========================================\n");
        end
    endtask

endmodule
`timescale 1ns/1ps

module tb_top;

    // Parameters
    parameter IMEM_DEPTH = 128; // Increased depth for testing
    parameter DMEM_DEPTH = 128;
    parameter IMEM_FILE  = "multiply.hex"; // Ensure this file exists

    // Inputs
    reg clk;
    reg rst;

    // Outputs
    wire [31:0] debug_pc;
    wire [31:0] debug_instruction;
    wire [31:0] debug_alu_result;

    // Integer for loops
    integer i;

    // Instantiate the Unit Under Test (UUT)
    top_module #(
        .IMEM_DEPTH(IMEM_DEPTH),
        .DMEM_DEPTH(DMEM_DEPTH),
        .IMEM_FILE(IMEM_FILE)
    ) uut (
        .clk(clk), 
        .rst(rst), 
        .debug_pc(debug_pc), 
        .debug_instruction(debug_instruction), 
        .debug_alu_result(debug_alu_result)
    );

    // Clock Generation (10ns period -> 100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test Sequence
    initial begin
        // 1. Initialize and Reset
        $display("==================================================");
        $display("   RISC-V Pipelined Processor Testbench Start");
        $display("==================================================");
        
        // Dump waves for debugging (Optional)
        $dumpfile("cpu_wave.vcd");
        $dumpvars(0, tb_top);

        rst = 1;
        #20; // Hold reset for 2 cycles
        
        rst = 0;
        $display("Reset released. Processor running...");

        // 2. Run Simulation
        // Run enough cycles for instructions to pass through 
        // IF -> ID -> EX (Mul logic) -> MEM -> WB
        #200; 

        // 3. Print Register Values
        // Note: 'uut.RF.registers' assumes your internal register array 
        // inside register_file module is named 'registers'. 
        // If it is named 'registers' or 'rf', change it below.
        $display("\n==================================================");
        $display("   Final Register State (x1 - x5)");
        $display("==================================================");
        
        // Print x1 (Multiplier A)
        $display("x1: %0d (Expected: 5)", uut.RF.registers[1]);
        
        // Print x2 (Multiplier B)
        $display("x2: %0d (Expected: 10)", uut.RF.registers[2]);
        
        // Print x3 (Result)
        $display("x3: %0d (Expected: 50)", uut.RF.registers[3]);
        
        // Print x4 (Unused/Zero)
        $display("x4: %0d", uut.RF.registers[4]);
        
        // Print x5 (Unused/Zero)
        $display("x5: %0d", uut.RF.registers[5]);

        $display("==================================================");

        $finish;
    end

    // Optional: Monitor PC changes to see progress
    always @(posedge clk) begin
        if (!rst) begin
            //$display("Time: %0t | PC: %h | Instr: %h", $time, debug_pc, debug_instruction);
        end
    end

endmodule
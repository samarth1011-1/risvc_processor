`timescale 1ns/1ps

module tb_top;

    reg clk;
    reg rst;
    integer cycle;
    integer i;

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

    // Instruction decoder for display
    function [80*8:0] decode_instr;
        input [31:0] instr;
        reg [6:0] opcode;
        reg [2:0] funct3;
        reg [6:0] funct7;
        begin
            opcode = instr[6:0];
            funct3 = instr[14:12];
            funct7 = instr[31:25];
            
            if (instr == 32'h00000013)
                decode_instr = "NOP";
            else if (opcode == 7'b0110011 && funct7 == 7'b0000001) begin
                case (funct3)
                    3'b000: decode_instr = "MUL";
                    3'b001: decode_instr = "MULH";
                    3'b010: decode_instr = "MULHSU";
                    3'b011: decode_instr = "MULHU";
                    3'b100: decode_instr = "DIV";
                    3'b101: decode_instr = "DIVU";
                    3'b110: decode_instr = "REM";
                    3'b111: decode_instr = "REMU";
                    default: decode_instr = "UNKNOWN";
                endcase
            end
            else if (opcode == 7'b0010011)
                decode_instr = "ADDI";
            else if (opcode == 7'b1100011)
                decode_instr = "BRANCH";
            else if (opcode == 7'b0110011)
                decode_instr = "R-TYPE";
            else
                decode_instr = "OTHER";
        end
    endfunction

    // Simulation routine
    initial begin
        // VCD dump
        $dumpfile("cpu_dump.vcd");
        $dumpvars(0, tb_top);
        
        // Dump all registers for visibility
        for (i = 0; i < 32; i = i + 1) begin
            $dumpvars(1, DUT.RF.registers[i]);
        end

        $display("\n===============================================");
        $display("        CPU Simulation Start");
        $display("===============================================\n");
        $display("Expected Results:");
        $display("  x1 = 6 (0x00000006)");
        $display("  x2 = 4 (0x00000004)");
        $display("  x3 = 24 (0x00000018) <- MUL result");
        $display("-----------------------------------------------\n");

        // Apply reset
        rst = 1;
        repeat(3) @(posedge clk);
        rst = 0;
        
        $display("Reset released at time %0t\n", $time);

        // Initialize cycle counter
        cycle = 0;

        // Run for N cycles with detailed debug
        for (i = 0; i < 50; i = i + 1) begin
            @(posedge clk);
            #1;  // Wait for signals to settle
            cycle = cycle + 1;
            
            // Display pipeline stages
            $display("=== Cycle %0d (Time=%0t) ===", cycle, $time);
            $display("  IF : PC=%h INSTR=%h [%0s]", 
                     DUT.pc, DUT.if_instr, decode_instr(DUT.if_instr));
            $display("  ID : PC=%h INSTR=%h [%0s]", 
                     DUT.id_pc, DUT.id_instr, decode_instr(DUT.id_instr));
            $display("  EX : is_muldiv=%b alu_sel=%h", 
                     DUT.ex_is_muldiv, DUT.ex_alu_sel);
            
            // MULDIV Debug
            if (DUT.ex_is_muldiv) begin
                $display("  *** MULDIV ACTIVE ***");
                $display("      start=%b busy=%b ready=%b", 
                         DUT.muldiv_start, DUT.muldiv_busy, DUT.muldiv_ready);
                $display("      rs1=%h rs2=%h", DUT.alu_in_A, DUT.alu_in_B_pre);
                $display("      result=%h final_result=%h", 
                         DUT.muldiv_result, DUT.ex_final_result);
                $display("      held=%h valid=%b", 
                         DUT.muldiv_result_held, DUT.result_valid);
            end
            
            $display("  MEM: alu_result=%h rd=%d RW=%b", 
                     DUT.mem_alu_result, DUT.mem_rd, DUT.mem_RW);
            $display("  WB : data=%h rd=%d RW=%b", 
                     DUT.wb_data, DUT.wb_rd, DUT.wb_RegWrite);
            
            // Show register writes
            if (DUT.wb_RegWrite && DUT.wb_rd != 0) begin
                $display("  >>> WRITE: x%0d <= %h (%0d)", 
                         DUT.wb_rd, DUT.wb_data, DUT.wb_data);
            end
            
            // Hazard detection
            if (DUT.stall) begin
                $display("  !!! STALL DETECTED !!!");
            end
            
            $display("");
            
            // Stop after MUL completes and writes back
            if (cycle > 15 && DUT.RF.registers[3] == 32'h00000018) begin
                $display("*** MUL result detected in x3! ***\n");
                repeat(3) @(posedge clk);  // Wait a few more cycles
            end
            
            // Safety break for infinite loop
            if (cycle >= 40) begin
                $display("*** Stopping after 40 cycles ***\n");
            end
        end

        // Print final register state
        $display("\n===============================================");
        $display("       Final Register Values");
        $display("===============================================");
        $display("x0  = %h (%0d) [zero]", DUT.RF.registers[0], DUT.RF.registers[0]);
        $display("x1  = %h (%0d) %s", 
                 DUT.RF.registers[1], $signed(DUT.RF.registers[1]),
                 (DUT.RF.registers[1] == 32'd6) ? "✓ CORRECT" : "✗ WRONG");
        $display("x2  = %h (%0d) %s", 
                 DUT.RF.registers[2], $signed(DUT.RF.registers[2]),
                 (DUT.RF.registers[2] == 32'd4) ? "✓ CORRECT" : "✗ WRONG");
        $display("x3  = %h (%0d) %s", 
                 DUT.RF.registers[3], $signed(DUT.RF.registers[3]),
                 (DUT.RF.registers[3] == 32'd24) ? "✓ CORRECT (6*4=24)" : "✗ WRONG (Expected 24)");
        $display("x4  = %h (%0d)", DUT.RF.registers[4], DUT.RF.registers[4]);
        $display("x5  = %h (%0d)", DUT.RF.registers[5], DUT.RF.registers[5]);
        
        $display("\n===============================================");
        if (DUT.RF.registers[3] == 32'd24) begin
            $display("       ✓✓✓ TEST PASSED ✓✓✓");
        end else begin
            $display("       ✗✗✗ TEST FAILED ✗✗✗");
        end
        $display("===============================================\n");

        $finish;
    end

    // Watchdog timer
    initial begin
        #10000;  // 10000ns = 1000 cycles
        $display("\n!!! TIMEOUT - Simulation ran too long !!!\n");
        $finish;
    end

endmodule
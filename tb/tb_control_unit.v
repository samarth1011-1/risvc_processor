`timescale 1ns/1ps

module tb_control_unit;

    reg [6:0] opcode;

    wire MemWrite, MemRead, ALUsrc, branch, RegWrite;
    wire [1:0] ALUop;

    control_unit uut (
        .opcode(opcode),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .ALUsrc(ALUsrc),
        .branch(branch),
        .RegWrite(RegWrite),
        .ALUop(ALUop)
    );

    task check;
        input exp_MemWrite, exp_MemRead, exp_ALUsrc, exp_branch, exp_RegWrite;
        input [1:0] exp_ALUop;
        begin
            if (MemWrite !== exp_MemWrite ||
                MemRead  !== exp_MemRead  ||
                ALUsrc   !== exp_ALUsrc   ||
                branch   !== exp_branch   ||
                RegWrite !== exp_RegWrite ||
                ALUop    !== exp_ALUop) begin

                $display("FAIL @ %0t | opcode=%b", $time, opcode);
                $display("Got: MW=%b MR=%b AS=%b BR=%b RW=%b ALUop=%b",
                         MemWrite, MemRead, ALUsrc, branch, RegWrite, ALUop);
                $display("Exp: MW=%b MR=%b AS=%b BR=%b RW=%b ALUop=%b",
                         exp_MemWrite, exp_MemRead, exp_ALUsrc,
                         exp_branch, exp_RegWrite, exp_ALUop);
                $stop;
            end else begin
                $display("PASS @ %0t | opcode=%b", $time, opcode);
            end
        end
    endtask

    initial begin
        $dumpfile("control_unit.vcd");
        $dumpvars(0, tb_control_unit);

        // R-type
        opcode = 7'b0110011;
        #1;
        check(0,0,0,0,1,2'b10);

        // I-type (ALU)
        opcode = 7'b0010011;
        #1;
        check(0,0,1,0,1,2'b10);

        // Load
        opcode = 7'b0000011;
        #1;
        check(0,1,1,0,1,2'b00);

        // JALR
        opcode = 7'b1100111;
        #1;
        check(0,0,1,0,1,2'b00);

        // Store
        opcode = 7'b0100011;
        #1;
        check(1,0,1,0,0,2'b00);

        // Branch
        opcode = 7'b1100011;
        #1;
        check(0,0,0,1,0,2'b01);

        // LUI
        opcode = 7'b0110111;
        #1;
        check(0,0,1,0,1,2'b00);

        // AUIPC
        opcode = 7'b0010111;
        #1;
        check(0,0,1,0,1,2'b00);

        // JAL
        opcode = 7'b1101111;
        #1;
        check(0,0,1,0,1,2'b00);

        // Unknown
        opcode = 7'b1111111;
        #1;
        check(0,0,0,0,0,2'b00);

        $display("All tests passed.");
        $finish;
    end

endmodule

// yes i used ai for this tb
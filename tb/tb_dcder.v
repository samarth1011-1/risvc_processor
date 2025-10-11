`timescale 1ns/1ps
module tb_dcder;
reg [31:0] instr_input;
reg [31:0] pc;
wire [6:0] opcode;
wire [4:0] rs1;
wire [4:0] rs2;
wire [4:0] rd;
wire [2:0] funct3;
wire [6:0] funct7;
wire [31:0] imm;

initial pc = 32'd0;

decoder DUT(.instr_input(instr_input), .pc(pc), .opcode(opcode), .rs1(rs1), .rs2(rs2),
.rd(rd), .funct3(funct3), .funct7(funct7), .imm(imm));

initial begin
    $dumpfile("vcd_files/decoder.vcd");
    $dumpvars(0,tb_dcder);
    $monitor("Instr=%h | PC=%d | Opcode=%b | RS1=%d | RS2=%d | RD=%d | IMM=%d",instr_input, pc, opcode, rs1, rs2, rd, imm);
    instr_input = 32'b0;
    #10 instr_input = 32'h00500093;   // ADDI x1, x0, 5
    #10 instr_input = 32'h002081B3;   // ADD x3, x1, x2
    #10 instr_input = 32'h0020A023;   // SW x2, 8(x1)
    #10 instr_input = 32'h00208463;   // BEQ x1, x2, 16
    #10 instr_input = 32'h12345037;   // LUI x10, 0x12345
    #10 instr_input = 32'h020000EF;   // JAL x1, 32

    #20 $finish;
end

endmodule
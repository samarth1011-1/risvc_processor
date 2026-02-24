/*
a decoder takes the instruction(in binary format) and splits the instruction into
opcode(ADD,SUB,MUL)
rd (destination address)
rs1,rs2 ( source registers )
immediate value -> based on the type of OPCODE
func3,func7 which provides further context to the ALU for workings
*/
module decoder(
    input [31:0] instr_input,
    input [31:0] pc,
    output [6:0] opcode,
    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd,
    output [2:0] funct3,
    output [6:0] funct7,
    output reg [31:0] imm
);
    assign opcode = instr_input[6:0]; // OPCODE like ADD/SUB/MUL
    assign rd = instr_input[11:7]; // destination address
    assign funct3 = instr_input[14:12]; // funct3
    assign rs1 = instr_input[19:15]; // Source register 1
    assign rs2 = instr_input[24:20]; // Source register 2
    assign funct7 = instr_input[31:25]; // funct7
    always@(*)begin // building immediate value
        case(opcode)
            7'b0010011 : imm = {{20{instr_input[31]}}, instr_input[31:20]}; // I-type
            7'b0000011 : imm = {{20{instr_input[31]}}, instr_input[31:20]}; // I-type - load
            7'b1100111 : imm = {{20{instr_input[31]}}, instr_input[31:20]}; // I-type - jalr
            7'b0100011 : imm = {{20{instr_input[31]}},instr_input[31:25],instr_input[11:7]}; // S-type
            7'b1100011 : imm = {{19{instr_input[31]}},instr_input[31],instr_input[7],instr_input[30:25],instr_input[11:8],1'b0}; // B-type
            7'b1101111 : imm = {{11{instr_input[31]}},instr_input[31],instr_input[30:21],instr_input[20],instr_input[19:12],1'b0}; //J-type
            7'b0110111 : imm = {instr_input[31:12],12'b0}; // U-type
            7'b0010111 : imm = {instr_input[31:12],12'b0}; // U-type
            default : imm = 32'b0;
        endcase
    end 
endmodule

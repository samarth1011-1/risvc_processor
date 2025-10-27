/*
ALU control acts as a bridge between control unit and ALU
it takes the control unit output (ALUop) and assigns the ALU control 
this takes in funct3 and funct7 into consideration
funct3 and funct7 helps to differentiate if two instruction have same ALUop
*/
module alu_control(
    input [1:0] ALUop, // Control unit output
    input [2:0] funct3, // Adds context
    input [6:0] funct7, // Adds context
    output reg [3:0] ALU_control // This tells the actual ALU to perform specific operations based on the opcode
);

always@(*) begin
    ALU_control = 4'b0000;
    if(ALUop == 2'b00)ALU_control = 4'b0000; // ADD
    else if(ALUop == 2'b01)ALU_control = 4'b0001; // SUB
    /*
    Multiple instructions like ADD/SUB and SRL/SRA have same ALUop and funct3 
    and even funct7
    */
    else if(ALUop == 2'b10)begin 
        case(funct3) 
            3'b000 : begin ALU_control = (funct7 == 7'b0100000)?4'b0001:4'b0000; end
            3'b111 : begin ALU_control = 4'b0010; end
            3'b110 : begin ALU_control = 4'b0011; end
            3'b100 : begin ALU_control = 4'b0100; end
            3'b001 : begin ALU_control = 4'b0101; end
            3'b101 : begin ALU_control = (funct7 == 7'b0100000)?4'b0111:4'b0110; end
            3'b010 : begin ALU_control = 4'b1000; end
            3'b011 : begin ALU_control = 4'b1001; end
            default : ALU_control = 4'b0000;
        endcase
    end
    else ALU_control = 4'b0000; // safety ADD
end
endmodule
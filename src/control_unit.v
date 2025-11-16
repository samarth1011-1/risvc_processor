/*
control unit takes the input from the decoder (opcode)
and then decides which part of the processor must handle the respective instruction
the opcode is taken from the RV32I Instruction Set
*/

module control_unit(
    input [6:0] opcode,
    output reg MemWrite,MemRead,ALUsrc,branch,RegWrite,
    output reg [1:0] ALUop
);

always@(*) begin
    MemWrite=0; // Write to the memory
    MemRead=0;  // Read from the memory
    ALUsrc=0;  // 2nd input for ALU
    branch=0; // if branching is needed this is set to 1
    RegWrite=0; // Write into registers
    ALUop=2'b00; // this decides what operation ALU does
    
    case(opcode) 
     7'b0110011 :  begin RegWrite=1;MemWrite=0;MemRead=0;ALUsrc=0;branch=0;ALUop=2'b10;  end // R 
     7'b0010011 :  begin RegWrite=1;MemWrite=0;MemRead=0;ALUsrc=1;branch=0;ALUop=2'b10;  end // I
     7'b0000011 :  begin RegWrite=1;MemWrite=0;MemRead=1;ALUsrc=1;branch=0;ALUop=2'b00;  end // I
     7'b1100111 :  begin RegWrite=1;MemWrite=0;MemRead=0;ALUsrc=1;branch=0;ALUop=2'b00;  end // I
     7'b0100011 :  begin RegWrite=0;MemWrite=1;MemRead=0;ALUsrc=1;branch=0;ALUop=2'b00;  end // S
     7'b1100011 :  begin RegWrite=0;MemWrite=0;MemRead=0;ALUsrc=0;branch=1;ALUop=2'b01;  end // B
     7'b0110111 :  begin RegWrite=1;ALUsrc=1;MemRead=0;MemWrite=0;branch=0;ALUop=2'b00;  end // U
     7'b0010111 :  begin RegWrite=1;ALUsrc=1;MemRead=0;MemWrite=0;branch=0;ALUop=2'b00;  end // U
     7'b1101111 :  begin RegWrite=1;ALUsrc=1;MemRead=0;MemWrite=0;branch=0;ALUop=2'b00;  end // J 
     default: begin RegWrite=0;ALUsrc=0;MemRead=0;MemWrite=0;branch=0;ALUop=2'b00; end
    endcase
end
endmodule
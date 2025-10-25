module tb_control_unit;
reg [6:0] opcode;
wire MemWrite,MemRead,ALUsrc,branch,RegWrite;
wire [1:0] ALUop;

control_unit DUT(.opcode(opcode),.MemWrite(MemWrite),.ALUsrc(ALUsrc),
.branch(branch),.RegWrite(RegWrite),.ALUop(ALUop));

initial begin
    MemWrite=0;MemRead=0;ALUsrc=0;branch=0;RegWrite=0;
    opcode = 7'b0;
    ALUop=2'b0;
    $dumpfile("vcd_files/control_op.vcd");
    $dumpvars(0,tb_control_unit);
    $monitor("Opcode=%b | MemWrite=%b | MemRead=%b | ALUsrc=%b | branch=%b | RegWrite=%b | ALUop=%b",MemWrite,MemRead,ALUsrc,branch,RegWrite,ALUop);
    #10 opcode = 7'b0110011;
    #10 opcode = 7'b0010011;
    #10 opcode = 7'b0000011;
    #10 opcode = 7'b1100111;
    #10 opcode = 7'b0100011;
    #10 opcode = 7'b1100011;
    #10 opcode = 7'b0110111;
    #10 opcode = 7'b0010111;
    #10 opcode = 7'b1101111;
    #10 $finish;
end
endmodule
module ALU(
    input [31:0] A,B,
    input [3:0] opcode,
    output reg [31:0] result,
    output reg Z,OF,N,sign
);

always@(*) begin
Z=0;
OF=0;
N=0;
sign=0;
case(opcode)
    4'b0000 : begin result=A+B; end // ADD
    4'b0001 : begin result=A-B; end // SUB
    4'b0010 : begin result=A&B; end // AND
    4'b0011 : begin result=A|B; end // OR
    4'b0100 : begin result=A^B; end // XOR
    4'b0101 : begin result=A<<B[4:0]; end // SLL
    4'b0110 : begin result=A>>B[4:0]; end // SRL
    4'b0111 : begin result=$signed(A)>>>B[4:0]; end // SRA
    4'b1000 : begin result=($signed(A)<$signed(B))?1:0; end // SLT(signed)
    4'b1001 : begin result=(A<B)?1:0; end // SLTU(unsigned)
    4'b1010 : begin result=~A;end // NOT
    default : result=32'b0;
endcase
Z=(result==32'b0)?1:0;
sign=result[31];
N=(result<0)?1:0;

if(opcode==4'b0000)begin
    OF=(~A[31] & ~B[31] & result[31]) | (A[31] & B[31] & ~result[31]);
end
else if(opcode==4'b0001)begin
    OF=(~A[31] & B[31] & result[31]) | (A[31] & ~B[31] & ~result[31]);
end
end
endmodule
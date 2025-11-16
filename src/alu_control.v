module alu_control(
    input [1:0] ALUop,
    input [2:0] funct3,
    input [6:0] funct7,
    output reg [3:0] ALU_control,
    output reg is_muldiv,
    output reg [2:0] muldiv_op
);

always @(*) begin
    ALU_control = 4'b0000;
    is_muldiv = 0;
    muldiv_op = 3'b000;

    if (ALUop == 2'b00)
        ALU_control = 4'b0000;
    else if (ALUop == 2'b01)
        ALU_control = 4'b0001;
    else if (ALUop == 2'b10) begin
        if (funct7 == 7'b0000001) begin
            is_muldiv = 1;
            muldiv_op = funct3;
        end else begin
            case (funct3)
                3'b000: ALU_control = (funct7 == 7'b0100000) ? 4'b0001 : 4'b0000;
                3'b111: ALU_control = 4'b0010;
                3'b110: ALU_control = 4'b0011;
                3'b100: ALU_control = 4'b0100;
                3'b001: ALU_control = 4'b0101;
                3'b101: ALU_control = (funct7 == 7'b0100000) ? 4'b0111 : 4'b0110;
                3'b010: ALU_control = 4'b1000;
                3'b011: ALU_control = 4'b1001;
                default: ALU_control = 4'b0000;
            endcase
        end
    end
end

endmodule

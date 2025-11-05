module mul_div(
    input clk,
    input rst,
    input start,                // high to begin operation
    input [2:0] opcode,         // funct3 from alu_control
    input [31:0] rs1, rs2,      // operands
    output reg busy, ready,     
    output reg [31:0] result    // result (quotient or remainder or mul output)
);

reg [31:0] dividend, divisor;
reg [31:0] quotient, remainder;
reg [5:0]  count;              
reg signA, signB;             


localparam [2:0] IDLE = 3'b000,
                 INIT = 3'b001,
                 DIV  = 3'b010,
                 DONE = 3'b011;

reg [2:0] state;


always @(*) begin
    if (rst) begin
        result = 0;
        busy   = 0;
        ready  = 0;
    end
    else if (start && (opcode <= 3'b011)) begin
        case (opcode)
            3'b000: result = rs1 * rs2;                         // MUL
            3'b001: result = ($signed(rs1) * $signed(rs2)) >> 32; // MULH
            3'b010: result = ($signed(rs1) * $unsigned(rs2)) >> 32; // MULHSU
            3'b011: result = ($unsigned(rs1) * $unsigned(rs2)) >> 32; // MULHU
            default: result = 0;
        endcase
        busy  = 0;
        ready = 1;  
    end
end


always @(posedge clk) begin
    if (rst) begin
        state  <= IDLE;
        busy   <= 0;
        ready  <= 0;
        result <= 0;
    end
    else begin
        case (state)
            IDLE: begin
                ready <= 0;
                busy  <= 0;
                if (start && (opcode >= 3'b100)) begin
                    state <= INIT;
                    busy  <= 1;
                end
            end

            INIT: begin
                signA <= rs1[31];
                signB <= rs2[31];
                quotient  <= 0;
                remainder <= 0;
                count     <= 31;

                if (rs2 == 0) begin
                    if (opcode == 3'b100 || opcode == 3'b101) // DIV/DIVU
                        result <= 32'hFFFF_FFFF;
                    else // REM/REMU
                        result <= rs1;
                    state <= DONE;
                end
                // Overflow case: -2^31 / -1
                else if ((rs1 == 32'h80000000) && (rs2 == 32'hFFFFFFFF) && (opcode == 3'b100)) begin
                    result <= 32'h80000000;
                    state  <= DONE;
                end
                else begin
                    // Absolute values for signed division
                    dividend <= ((opcode == 3'b100) || (opcode == 3'b110)) && rs1[31] ? -rs1 : rs1;
                    divisor  <= ((opcode == 3'b100) || (opcode == 3'b110)) && rs2[31] ? -rs2 : rs2;
                    state <= DIV;
                end
            end
            DIV: begin
                remainder = {remainder[30:0], dividend[31]};
                dividend  = {dividend[30:0], 1'b0};

                if (remainder >= divisor) begin
                    remainder = remainder - divisor;
                    quotient  = {quotient[30:0], 1'b1};
                end
                else begin
                    quotient  = {quotient[30:0], 1'b0};
                end

                count <= count - 1;
                if (count == 0)
                    state <= DONE;
            end
            DONE: begin
                case (opcode)
                    3'b100: begin // DIV
                        if (signA ^ signB)
                            result <= -quotient;
                        else
                            result <= quotient;
                    end
                    3'b101: result <= quotient; // DIVU
                    3'b110: begin // REM
                        if (signA)
                            result <= -remainder;
                        else
                            result <= remainder;
                    end
                    3'b111: result <= remainder; // REMU
                endcase

                busy  <= 0;
                ready <= 1;
                state <= IDLE;
            end
        endcase
    end
end

endmodule

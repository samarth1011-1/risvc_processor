module mul_div(
    input clk,
    input rst,
    input start,
    input [2:0] opcode,
    input [31:0] rs1,
    input [31:0] rs2,
    output reg busy,
    output reg ready,
    output reg [31:0] result
);

localparam [2:0] IDLE = 3'b000,
                 INIT = 3'b001,
                 DIV  = 3'b010,
                 DONE = 3'b011;

reg [2:0] state;
reg [31:0] dividend, divisor, quotient, remainder;
reg [5:0] count;
reg signA, signB;
reg[31:0] mul_result;
reg signed [63:0] mulh_ss;
reg signed [63:0] mulh_su;
reg        [63:0] mulh_uu;

always @(*) begin
    mulh_ss = $signed(rs1) * $signed(rs2);
    mulh_su = $signed(rs1) * $signed({1'b0, rs2});
    mulh_uu = {1'b0, rs1}  * {1'b0, rs2};
    case (opcode)
        3'b000: mul_result = rs1 * rs2;
        3'b001: mul_result = mulh_ss[63:32];
        3'b010: mul_result = mulh_su[63:32];
        3'b011: mul_result = mulh_uu[63:32];
        default: mul_result = 0;
    endcase
end

always @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
        busy <= 0;
        ready <= 0;
        result <= 0;
        quotient <= 0;
        remainder <= 0;
    end else begin
        case (state)
            IDLE: begin
                ready <= 0;
                busy <= 0;
                if (start) begin
                    if (opcode <= 3'b011) begin
                        result <= mul_result;
                        ready <= 1;
                        busy <= 0;
                        state <= IDLE;
                    end else begin
                        busy <= 1;
                        state <= INIT;
                    end
                end
            end

            INIT: begin
                signA <= rs1[31];
                signB <= rs2[31];
                quotient <= 0;
                remainder <= 0;
                count <= 31;

                if (rs2 == 0) begin
                    result <= (opcode == 3'b100 || opcode == 3'b101) ? 32'hFFFFFFFF : rs1;
                    state <= DONE;
                end else if ((rs1 == 32'h80000000) && (rs2 == 32'hFFFFFFFF) && (opcode == 3'b100)) begin
                    result <= 32'h80000000;
                    state <= DONE;
                end else begin
                    dividend <= ((opcode == 3'b100 || opcode == 3'b110) && rs1[31]) ? -rs1 : rs1;
                    divisor <= ((opcode == 3'b100 || opcode == 3'b110) && rs2[31]) ? -rs2 : rs2;
                    state <= DIV;
                end
            end

            DIV: begin
                remainder = {remainder[30:0], dividend[31]};
                dividend  = {dividend[30:0], 1'b0};

                if (remainder >= divisor) begin
                    remainder = remainder - divisor;
                    quotient = {quotient[30:0], 1'b1};
                end else begin
                    quotient = {quotient[30:0], 1'b0};
                end

                count <= count - 1;
                if (count == 0)
                    state <= DONE;
            end

            DONE: begin
                case (opcode)
                    3'b100: result <= (signA ^ signB) ? -quotient : quotient;
                    3'b101: result <= quotient;
                    3'b110: result <= signA ? -remainder : remainder;
                    3'b111: result <= remainder;
                endcase
                busy <= 0;
                ready <= 1;
                state <= IDLE;
            end
        endcase
    end
end

endmodule

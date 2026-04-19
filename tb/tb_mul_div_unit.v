`timescale 1ns/1ps

module tb_div_debug;

    reg clk, rst, start;
    reg [2:0] opcode;
    reg [31:0] rs1, rs2;

    wire busy, ready;
    wire [31:0] result;

    mul_div uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .opcode(opcode),
        .rs1(rs1),
        .rs2(rs2),
        .busy(busy),
        .ready(ready),
        .result(result)
    );

    always #5 clk = ~clk;

    task wait_ready;
        begin
            while (!ready) #10;
        end
    endtask

    task run_and_check;
        input [2:0] op;
        input [31:0] a, b;
        input [31:0] expected;
        begin
            opcode = op;
            rs1 = a;
            rs2 = b;

            start = 1;
            #10;
            start = 0;

            wait_ready();

            if (result !== expected) begin
                $display("FAIL | op=%b | a=%0d | b=%0d | result=%0d (exp %0d)",
                         op, $signed(a), $signed(b), $signed(result), $signed(expected));
                $stop;
            end else begin
                $display("PASS | op=%b | a=%0d | b=%0d | result=%0d",
                         op, $signed(a), $signed(b), $signed(result));
            end
        end
    endtask

    initial begin
        $dumpfile("div_debug.vcd");
        $dumpvars(0, tb_div_debug);

        clk = 0;
        rst = 1;
        start = 0;

        #10 rst = 0;

        run_and_check(3'b100, 20, 4, 5);
        run_and_check(3'b100, 7, 3, 2);

        run_and_check(3'b100, -20, 4, -5);
        run_and_check(3'b100, 20, -4, -5);
        run_and_check(3'b100, -20, -4, 5);

        run_and_check(3'b100, 32'h80000000, 32'hFFFFFFFF, 32'h80000000);

        run_and_check(3'b101, 20, 4, 5);
        run_and_check(3'b101, 7, 3, 2);

        run_and_check(3'b110, 22, 5, 2);
        run_and_check(3'b110, -22, 5, -2);

        run_and_check(3'b111, 22, 5, 2);
        run_and_check(3'b111, 16, 5, 1);

        run_and_check(3'b100, 10, 0, 32'hFFFFFFFF);
        run_and_check(3'b110, 10, 0, 10);

        $display("ALL TESTS PASSED");
        $finish;
    end

endmodule
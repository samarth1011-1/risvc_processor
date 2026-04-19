`timescale 1ns/1ps

module tb_program_counter;

    reg clk;
    reg rst;
    reg pc_write;
    reg [31:0] next_pc;
    wire [31:0] pc_out;

    program_counter uut (
        .clk(clk),
        .rst(rst),
        .pc_write(pc_write),
        .next_pc(next_pc),
        .pc_out(pc_out)
    );

    always #5 clk = ~clk;

    task check;
        input [31:0] expected;
        begin
            if (pc_out !== expected) begin
                $display("FAIL at time %0t: Expected = %h, Got = %h", $time, expected, pc_out);
                $stop;
            end else begin
                $display("PASS at time %0t: pc_out = %h", $time, pc_out);
            end
        end
    endtask

    initial begin
        $dumpfile("program_counter.vcd");
        $dumpvars(0, tb_program_counter);

        clk = 0;
        rst = 1;
        pc_write = 0;
        next_pc = 0;

        #10;
        check(32'h00000000);

        rst = 0;

        pc_write = 1;
        next_pc = 32'h00000004;
        #10;
        check(32'h00000004);

        pc_write = 0;
        next_pc = 32'h00000008;
        #10;
        check(32'h00000004);

        pc_write = 1;
        next_pc = 32'h0000000C;
        #10;
        check(32'h0000000C);

        rst = 1;
        pc_write = 1;
        next_pc = 32'hFFFFFFFF;
        #10;
        check(32'h00000000);

        rst = 0;
        pc_write = 1;
        next_pc = 32'h00000010;
        #10;
        check(32'h00000010);

        $display("All tests passed.");
        $finish;
    end

endmodule
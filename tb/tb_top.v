`timescale 1ns/1ps

module tb_riscv_core;

reg clk;
reg rst;

riscv_core dut (
    .clk(clk),
    .rst(rst)
);

always #5 clk = ~clk;

integer i;

initial begin
    $dumpfile("core.vcd");
    $dumpvars(0, tb_riscv_core);

    clk = 0;
    rst = 1;

    #20;
    rst = 0;

    #300;

    $display("\nREGISTER FILE DUMP");

    for (i = 0; i < 32; i = i + 1) begin
        $display("x%0d = %0d", i, dut.REGFILE.registers[i]);
    end

    $display("END REGISTER DUMP\n");

    $finish;
end

endmodule
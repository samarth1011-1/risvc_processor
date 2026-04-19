`timescale 1ns/1ps

module tb_register_file;

    reg clk;
    reg rst;
    reg write_enable;
    reg [4:0] rs1_addr, rs2_addr, rd_addr;
    reg [31:0] rd_data;

    wire [31:0] rs1_data, rs2_data;

    register_file uut (
        .clk(clk),
        .write_enable(write_enable),
        .rst(rst),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    always #5 clk = ~clk;

    task check;
        input [31:0] exp1, exp2;
        begin
            if (rs1_data !== exp1 || rs2_data !== exp2) begin
                $display("FAIL @ %0t | rs1=%h (exp %h), rs2=%h (exp %h)",
                         $time, rs1_data, exp1, rs2_data, exp2);
                $stop;
            end else begin
                $display("PASS @ %0t", $time);
            end
        end
    endtask

    initial begin
        $dumpfile("reg_file.vcd");
        $dumpvars(0, tb_register_file);

        clk = 0;
        rst = 1;
        write_enable = 0;
        rs1_addr = 0;
        rs2_addr = 0;
        rd_addr = 0;
        rd_data = 0;

        #10;
        check(0,0);

        rst = 0;

        write_enable = 1;
        rd_addr = 5'd1;
        rd_data = 32'hA5A5A5A5;
        #10;

        rs1_addr = 5'd1;
        rs2_addr = 5'd0;
        #1;
        check(32'hA5A5A5A5, 0);

        write_enable = 1;
        rd_addr = 5'd0;
        rd_data = 32'hFFFFFFFF;
        #10;

        rs1_addr = 5'd0;
        #1;
        check(0,0);

        write_enable = 0;
        rd_addr = 5'd2;
        rd_data = 32'h12345678;
        #10;

        rs1_addr = 5'd2;
        #1;
        check(0,0);

        write_enable = 1;
        rd_addr = 5'd3;
        rd_data = 32'hDEADBEEF;
        rs1_addr = 5'd3;
        rs2_addr = 5'd3;
        #1;
        check(32'hDEADBEEF, 32'hDEADBEEF);

        #10;
        check(32'hDEADBEEF, 32'hDEADBEEF);

        $display("All tests passed.");
        $finish;
    end

endmodule
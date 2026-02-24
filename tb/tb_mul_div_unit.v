`timescale 1ns/1ps

module mul_div_tb;

    // ----------------------------------------------------------------
    // DUT signals
    // ----------------------------------------------------------------
    reg         clk, rst, start;
    reg  [2:0]  opcode;
    reg  [31:0] rs1, rs2;
    wire        busy, ready;
    wire [31:0] result;

    // ----------------------------------------------------------------
    // Instantiate DUT
    // ----------------------------------------------------------------
    mul_div dut (
        .clk    (clk),
        .rst    (rst),
        .start  (start),
        .opcode (opcode),
        .rs1    (rs1),
        .rs2    (rs2),
        .busy   (busy),
        .ready  (ready),
        .result (result)
    );

    // ----------------------------------------------------------------
    // Clock – 10 ns period
    // ----------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // ----------------------------------------------------------------
    // Helper task: apply one operation and wait for ready
    // ----------------------------------------------------------------
    integer test_num;

    task run_op;
        input [2:0]  op;
        input [31:0] a, b;
        input [63:0] expected;   // 64-bit so we can pass large hex easily
        input [127:0] op_name;   // text label (up to 16 chars)
        begin
            @(negedge clk);
            opcode = op;
            rs1    = a;
            rs2    = b;
            start  = 1;
            @(negedge clk);
            start  = 0;
            @(negedge clk);
            // Wait for ready (or timeout after 100 cycles)
            begin : wait_block
                integer timeout;
                timeout = 0;
                while (!ready && timeout < 100) begin
                    @(posedge clk);
                    timeout = timeout + 1;
                end
            end

            @(negedge clk); // settle

            test_num = test_num + 1;
            $write("Test %0d  %-8s  rs1=%0d  rs2=%0d  =>  result=0x%08X (%0d)",
                   test_num, op_name, $signed(a), $signed(b), result, $signed(result));

            if (result === expected[31:0])
                $display("   PASS");
            else
                $display("   FAIL  (expected 0x%08X / %0d)", expected[31:0], $signed(expected[31:0]));

            // One idle cycle between tests
            @(negedge clk);
        end
    endtask

    // ----------------------------------------------------------------
    // Stimulus
    // ----------------------------------------------------------------
    initial begin
        test_num = 0;
        rst   = 1;
        start = 0;
        opcode = 0; rs1 = 0; rs2 = 0;
        repeat(3) @(posedge clk);
        @(negedge clk);
        rst = 0;

        $display("============================================================");
        $display("              MUL/DIV Unit Testbench");
        $display("  opcode 000=MUL  001=MULH  010=MULHSU  011=MULHU");
        $display("         100=DIV  101=DIVU  110=REM     111=REMU");
        $display("============================================================");

        // ---- MUL (opcode 000) lower 32 bits ----
        run_op(3'b000, 32'd15,        32'd10,        64'd150,          "MUL     ");
        run_op(3'b000, -32'd7,        32'd3,         -32'd21,          "MUL     ");
        run_op(3'b000, 32'hFFFFFFFF,  32'hFFFFFFFF,  32'd1,            "MUL     "); // (-1)*(-1) low=1

        // ---- MULH (opcode 001) signed high 32 bits ----
        // 0x80000000 * 0x80000000 = 0x4000_0000_0000_0000 => high = 0x40000000
        run_op(3'b001, 32'h80000000, 32'h80000000, 64'h40000000,      "MULH    ");
        run_op(3'b001, -32'd1,       -32'd1,        32'd0,             "MULH    "); // 1 >> 32 = 0

        // ---- MULHSU (opcode 010) rs1 signed, rs2 unsigned ----
        run_op(3'b010, -32'd1,  32'd1, 32'hFFFFFFFF,                   "MULHSU  "); // -1 * 1 >> 32 = -1

        // ---- MULHU (opcode 011) unsigned high 32 bits ----
        run_op(3'b011, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFE,      "MULHU   "); // (2^32-1)^2 >> 32

        // ---- DIV (opcode 100) signed division ----
        run_op(3'b100, 32'd20,        32'd3,         32'd6,            "DIV     ");
        run_op(3'b100, -32'd20,       32'd3,         -32'd6,           "DIV     ");
        run_op(3'b100, -32'd20,       -32'd3,        32'd6,            "DIV     ");
        run_op(3'b100, 32'd7,         32'd0,         32'hFFFFFFFF,     "DIV/0   "); // divide by zero
        run_op(3'b100, 32'h80000000,  32'hFFFFFFFF,  32'h80000000,    "DIV ovfl"); // overflow corner

        // ---- DIVU (opcode 101) unsigned division ----
        run_op(3'b101, 32'd100,       32'd7,         32'd14,           "DIVU    ");
        run_op(3'b101, 32'hFFFFFFFE,  32'd2,         32'h7FFFFFFF,    "DIVU    ");
        run_op(3'b101, 32'd5,         32'd0,         32'hFFFFFFFF,    "DIVU/0  "); // divide by zero

        // ---- REM (opcode 110) signed remainder ----
        run_op(3'b110, 32'd20,        32'd3,         32'd2,            "REM     ");
        run_op(3'b110, -32'd20,       32'd3,         -32'd2,           "REM     ");
        run_op(3'b110, 32'd7,         32'd0,         32'd7,            "REM/0   "); // dividend returned

        // ---- REMU (opcode 111) unsigned remainder ----
        run_op(3'b111, 32'd20,        32'd3,         32'd2,            "REMU    ");
        run_op(3'b111, 32'hFFFFFFFF,  32'd10,        32'd5,            "REMU    "); // 4294967295 % 10 = 5
        run_op(3'b111, 32'd7,         32'd0,         32'd7,            "REMU/0  "); // dividend returned

        $display("============================================================");
        $display("All tests complete.");
        $finish;
    end

    // ----------------------------------------------------------------
    // Optional waveform dump
    // ----------------------------------------------------------------
    initial begin
        $dumpfile("mul_div_tb.vcd");
        $dumpvars(0, mul_div_tb);
    end

endmodule
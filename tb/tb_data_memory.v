`timescale 1ns/1ps

module tb_data_memory;
    reg clk, rst;
    reg MemRead, MemWrite;
    reg [31:0] addr_i;
    reg [31:0] write_data_i;
    wire [31:0] read_data_o;

    // Instantiate the Data Memory module
    data_memory uut (
        .clk(clk),
        .rst(rst),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .addr_i(addr_i),
        .write_data_i(write_data_i),
        .read_data_o(read_data_o)
    );

    // Clock generator (10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        MemRead = 0;
        MemWrite = 0;
        addr_i = 0;
        write_data_i = 0;

        // Reset the memory
        #10;
        rst = 0;
        $display("=== Memory Reset Done ===");

        // Write to address 8
        MemWrite = 1;
        addr_i = 8;
        write_data_i = 32'hAABBCCDD;
        #10; // wait for one clock

        MemWrite = 0; // stop writing
        $display("Wrote %h to address %d", write_data_i, addr_i);

        // Read from address 8
        MemRead = 1;
        addr_i = 8;
        #5; // small delay to allow read
        $display("Read %h from address %d", read_data_o, addr_i);

        // Write another value at address 12
        MemRead = 0;
        MemWrite = 1;
        addr_i = 12;
        write_data_i = 32'h12345678;
        #10;

        MemWrite = 0;
        MemRead = 1;
        addr_i = 12;
        #5;
        $display("Read %h from address %d", read_data_o, addr_i);

        // Try reading from an unwritten location
        addr_i = 20;
        #5;
        $display("Read (unwritten) %h from address %d", read_data_o, addr_i);

        // End simulation
        #20;
        $finish;
    end
endmodule

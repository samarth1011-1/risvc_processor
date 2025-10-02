module testbench_program_counter;
reg clk,rst,branch_taken;
reg [31:0] branch_target;
wire [31:0] pc_out;

program_counter pc(
    .clk(clk),
    .rst(rst),
    .branch_target(branch_target),
    .branch_taken(branch_taken),
    .pc_out(pc_out)
);

initial clk = 0;
always #5 clk=~clk; // generate the required clock cycle

initial begin
    $dumpfile("tb_pc.vcd");
    $dumpvars(0,testbench_program_counter);
    $monitor("clk=%b rst=%b branch_taken=%b branch_target=%d pc_out=%d",clk,rst,branch_taken,branch_target,pc_out);
    rst = 1; branch_taken = 0; branch_target = 32'd0; // reset the counter first
    #20 rst = 0; // pc begins counting by 4
    #50 branch_taken = 1; branch_target = 100; // branch updates to 100
    #10 branch_taken = 0;
    #40 rst=1;
    #20 rst =0;
    #50 $finish;
end

endmodule
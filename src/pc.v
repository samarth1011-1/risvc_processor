module program_counter(
    input clk,
    input rst,
    input [size-1:0] branch_target,
    input branch_taken,
    output reg [size-1:0] pc_out
    );
parameter size = 32;
always@(posedge clk) // synchronous reset used, ansynchronous reset can also be used
begin
    if(rst) pc_out <= {size{1'b0}};
    else if(branch_taken) pc_out <= branch_target; // if branch is taken, update pc to branch target
    else pc_out <= pc_out + 4;
end
endmodule

/* 
clk -> clock input
rst -> reset input
branch_target -> target address of a branch instruction
branch_taken -> signal indicating whether a branch is taken or not
pc_out -> current address of the program counter
*/
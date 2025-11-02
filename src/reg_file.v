/*
register file is a set of registers that can be read and written to.
it has 2 read ports and 1 write port.
the register file has 32 registers, each 32 bits wide.
read operation is combinational
write operation is done on postive edge of the clock
*/

// Ex: ADD x1(destination), x2(source1), x3(source2)
module register_file(
    input clk,
    input write_enable,   // write operation is done only if this is HIGH
    input rst,            // Resets all registers to 0 when HIGH
    input [4:0] rs1_addr, // address of the source1 register
    input [4:0] rs2_addr, // address of the source2 register
    input [4:0] rd_addr,  // address of the destination register
    input [31:0] rd_data, // data to be written to the destination register

    output reg [31:0] rs1_data, // data read from source1 register
    output reg [31:0] rs2_data  // data read from source2 register
);

reg [31:0] registers[0:31];
integer i;

always@(*)begin
    rs1_data = (rs1_addr ==0)?32'b0:registers[rs1_addr];
    rs2_data = (rs2_addr ==0)?32'b0:registers[rs2_addr];
end

always@(posedge clk)
begin
    if(rst)begin
        for(i=0;i<32;i=i+1) registers[i]<=32'b0;
    end
    else if(write_enable && (rd_addr != 5'b0)) registers[rd_addr] <= rd_data;
end
endmodule
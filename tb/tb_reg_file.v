`timescale 1ns/1ps
module tb_reg_file;
reg clk,rst,write_en;
reg [4:0] rs1_addr,rs2_addr,rd_addr;
reg [31:0] rd_data;
wire [31:0] rs1_data,rs2_data;

register_file DUT(
    .clk(clk),
    .rst(rst),
    .write_enable(write_en),
    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),
    .rd_addr(rd_addr),
    .rd_data(rd_data),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data)
);
always #5 clk=~clk;
initial begin
  clk = 0;
  rst = 1;
  write_en = 0;
  rs1_addr = 0;
  rs2_addr = 0;
  rd_addr  = 0;
  rd_data  = 0;
end
initial begin
    $dumpfile("tb_reg_file.vcd");
    $dumpvars(0,tb_reg_file);
    $monitor("clk=%b rst=%b write_en=%b rs1_addr=%d rs2_addr=%d rd_addr=%d rd_data=%d || rs1_data=%d rs2_data=%d",clk,rst,write_en,rs1_addr,rs2_addr,rd_addr,rd_data,rs1_data,rs2_data);
    #5 rst=1;
    #10 rst=0; rd_data = 32'd5; rd_addr = 5'd1; write_en=1; rs1_addr = 5'd0; rs2_addr = 5'd0;
    #10 rd_data = 32'd19; rd_addr = 5'd2; write_en=1; rs1_addr = 5'd1; rs2_addr = 5'd0;
    #10 rd_data = 32'd13; rd_addr = 5'd3; write_en=1; rs1_addr = 5'd1; rs2_addr = 5'd2;
    #10 $finish;
end
endmodule
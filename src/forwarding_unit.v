module forwarding_unit(
    input [4:0] ex_rs1,
    input [4:0] ex_rs2,
    input [4:0] mem_rd,
    input [4:0] wb_rd,
    input mem_regwrite,
    input wb_regwrite,
    output reg [1:0] forwardA,
    output reg [1:0] forwardB
);

always @(*) begin
    forwardA = 2'b00;
    forwardB = 2'b00;

    if (mem_regwrite && (mem_rd != 5'b0) && (mem_rd == ex_rs1))
        forwardA = 2'b10;
    else if (wb_regwrite && (wb_rd != 5'b0) && (wb_rd == ex_rs1))
        forwardA = 2'b01;

    if (mem_regwrite && (mem_rd != 5'b0) && (mem_rd == ex_rs2))
        forwardB = 2'b10;
    else if (wb_regwrite && (wb_rd != 5'b0) && (wb_rd == ex_rs2))
        forwardB = 2'b01;
end

endmodule

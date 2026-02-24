module hazard_detection(
    input clk,
    input rst,
    input [4:0] id_rs1,
    input [4:0] id_rs2,
    input [4:0] ex_rd,
    input ex_memread,
    input id_is_muldiv,
    input ex_is_muldiv,
    input muldiv_busy,
    input muldiv_ready,
    output reg stall,
    output reg pc_write,
    output reg if_id_write,
    output reg id_ex_flush,
    output reg mem_stall
);

always @(*) begin
    stall = 0;
    pc_write = 1;
    if_id_write = 1;
    id_ex_flush = 0;
    mem_stall = 0;

    if (ex_is_muldiv && !muldiv_ready) begin
        stall = 1;
        pc_write = 0;
        if_id_write = 0;
    end else if (ex_memread && (ex_rd != 5'b0) && ((ex_rd == id_rs1) || (ex_rd == id_rs2))) begin
        stall = 1;
        pc_write = 0;
        if_id_write = 0;
        id_ex_flush = 1;
    end else if (id_is_muldiv && muldiv_busy) begin
        stall = 1;
        pc_write = 0;
        if_id_write = 0;
        id_ex_flush = 0;
    end
end

endmodule

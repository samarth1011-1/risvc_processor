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

    // Load-use hazard: stall if EX stage has a load and ID needs that data
    if (ex_memread && (ex_rd != 5'b0) && ((ex_rd == id_rs1) || (ex_rd == id_rs2))) begin
        stall = 1;
        pc_write = 0;
        if_id_write = 0;
        id_ex_flush = 1;
    end

    // MULDIV in EX stage - stall pipeline until operation completes
    // Don't flush - keep the instruction in EX stage
    if (ex_is_muldiv && !muldiv_ready) begin
        stall = 1;
        pc_write = 0;
        if_id_write = 0;
        id_ex_flush = 0;  // Keep instruction in EX, don't flush it
    end

    // MULDIV in ID stage but unit is busy - stall and flush ID/EX
    if (id_is_muldiv && muldiv_busy) begin
        stall = 1;
        pc_write = 0;
        if_id_write = 0;
        id_ex_flush = 1;
    end
end

endmodule
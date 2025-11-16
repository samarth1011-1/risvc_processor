module branch_predictor #(
    parameter PC_WIDTH = 32,
    parameter INDEX_BITS = 10
)(
    input clk,
    input rst,
    input [PC_WIDTH-1:0] pc_fetch,
    output predict_taken,
    output [PC_WIDTH-1:0] predict_target,
    output [PC_WIDTH-1:0] predict_pc,
    input resolve_valid,
    input [PC_WIDTH-1:0] resolve_pc,
    input resolve_taken,
    input [PC_WIDTH-1:0] resolve_target,
    output mispredict,
    output [PC_WIDTH-1:0] redirect_pc
);

localparam ENTRIES = (1 << INDEX_BITS);
localparam IDX_LSB = 2;
localparam IDX_MSB = INDEX_BITS + 1;
localparam TAG_LSB = IDX_MSB + 1;
localparam TAG_MSB = PC_WIDTH - 1;
localparam TAG_WIDTH = (PC_WIDTH > (IDX_MSB + 1)) ? (PC_WIDTH - (IDX_MSB + 1)) : 1;

integer i;

reg [1:0] bht[0:ENTRIES-1];
reg [PC_WIDTH-1:0] btb_target[0:ENTRIES-1];
reg [TAG_WIDTH-1:0] btb_tag[0:ENTRIES-1];
reg valid_entry[0:ENTRIES-1];

wire [INDEX_BITS-1:0] fetch_index;
wire [TAG_WIDTH-1:0] fetch_tag;
assign fetch_index = pc_fetch[IDX_MSB:IDX_LSB];
assign fetch_tag = (TAG_WIDTH > 0) ? pc_fetch[PC_WIDTH-1:IDX_MSB+1] : {TAG_WIDTH{1'b0}};

wire [INDEX_BITS-1:0] res_index;
wire [TAG_WIDTH-1:0] res_tag;
assign res_index = resolve_pc[IDX_MSB:IDX_LSB];
assign res_tag = (TAG_WIDTH > 0) ? resolve_pc[PC_WIDTH-1:IDX_MSB+1] : {TAG_WIDTH{1'b0}};

wire [1:0] bht_fetch_val;
wire btb_hit_fetch;
assign bht_fetch_val = bht[fetch_index];
assign btb_hit_fetch = valid_entry[fetch_index] && (btb_tag[fetch_index] == fetch_tag);

assign predict_taken = btb_hit_fetch && (bht_fetch_val >= 2'b10);
assign predict_target = btb_target[fetch_index];
assign predict_pc = predict_taken ? btb_target[fetch_index] : (pc_fetch + 32'd4);

wire [1:0] bht_res_val;
wire btb_hit_res;
wire res_pred_taken;
wire [PC_WIDTH-1:0] res_pred_target;
assign bht_res_val = bht[res_index];
assign btb_hit_res = valid_entry[res_index] && (btb_tag[res_index] == res_tag);
assign res_pred_taken = btb_hit_res && (bht_res_val >= 2'b10);
assign res_pred_target = btb_target[res_index];

assign mispredict = resolve_valid && ((res_pred_taken != resolve_taken) || (res_pred_taken && (res_pred_target != resolve_target)));
assign redirect_pc = resolve_taken ? resolve_target : (resolve_pc + 32'd4);

always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < ENTRIES; i = i + 1) begin
            bht[i] <= 2'b01;
            btb_target[i] <= {PC_WIDTH{1'b0}};
            btb_tag[i] <= {TAG_WIDTH{1'b0}};
            valid_entry[i] <= 1'b0;
        end
    end else if (resolve_valid) begin
        case (bht[res_index])
            2'b00: bht[res_index] <= resolve_taken ? 2'b01 : 2'b00;
            2'b01: bht[res_index] <= resolve_taken ? 2'b10 : 2'b00;
            2'b10: bht[res_index] <= resolve_taken ? 2'b11 : 2'b01;
            2'b11: bht[res_index] <= resolve_taken ? 2'b11 : 2'b10;
            default: bht[res_index] <= 2'b01;
        endcase
        if (resolve_taken) begin
            btb_target[res_index] <= resolve_target;
            btb_tag[res_index] <= res_tag;
            valid_entry[res_index] <= 1'b1;
        end
    end
end

endmodule

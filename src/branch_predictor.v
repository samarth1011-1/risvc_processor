module branch_predictor #(
    parameter PC_WIDTH   = 32,
    parameter INDEX_BITS = 10
)(
    input  wire                  clk,
    input  wire                  rst,

    // Fetch port — inputs current PC, outputs prediction
    input  wire [PC_WIDTH-1:0]   pc_fetch,
    output wire                  predict_taken,
    output wire [PC_WIDTH-1:0]   predict_target,
    output wire [PC_WIDTH-1:0]   predict_pc,

    // Resolve port — EX stage tells us actual outcome
    input  wire                  resolve_valid,
    input  wire [PC_WIDTH-1:0]   resolve_pc,
    input  wire                  resolve_taken,
    input  wire [PC_WIDTH-1:0]   resolve_target,

    // Mispredict signal — tells pipeline to flush
    output wire                  mispredict,
    output wire [PC_WIDTH-1:0]   redirect_pc
);

    // Parameters
    localparam ENTRIES    = 1 << INDEX_BITS;   // 1024
    localparam IDX_LO     = 2;                 // skip [1:0], always 00
    localparam IDX_HI     = INDEX_BITS + 1;    // = 11
    localparam TAG_LO     = IDX_HI + 1;        // = 12
    localparam TAG_WIDTH  = PC_WIDTH - TAG_LO; // = 20

    // Storage
    reg [1:0]          bht         [0:ENTRIES-1]; // 2-bit saturating counters
    reg [PC_WIDTH-1:0] btb_target  [0:ENTRIES-1]; // predicted targets
    reg [TAG_WIDTH-1:0] btb_tag    [0:ENTRIES-1]; // tags for alias detection
    reg                btb_valid   [0:ENTRIES-1]; // valid bits

    integer i;

    // Index and tag extraction
    wire [INDEX_BITS-1:0] fetch_idx = pc_fetch[IDX_HI:IDX_LO];
    wire [TAG_WIDTH-1:0]  fetch_tag = pc_fetch[PC_WIDTH-1:TAG_LO];

    wire [INDEX_BITS-1:0] res_idx   = resolve_pc[IDX_HI:IDX_LO];
    wire [TAG_WIDTH-1:0]  res_tag   = resolve_pc[PC_WIDTH-1:TAG_LO];

    // Fetch side — predict
    wire btb_hit     = btb_valid[fetch_idx] && (btb_tag[fetch_idx] == fetch_tag);
    wire bht_taken   = (bht[fetch_idx] >= 2'b10); // Weakly or Strongly Taken

    assign predict_taken  = btb_hit && bht_taken;
    assign predict_target = btb_target[fetch_idx];
    assign predict_pc     = predict_taken ? predict_target : (pc_fetch + 32'd4);

    // Resolve side — was our prediction correct?
    wire res_btb_hit      = btb_valid[res_idx] && (btb_tag[res_idx] == res_tag);
    wire res_pred_taken   = res_btb_hit && (bht[res_idx] >= 2'b10);
    wire res_target_wrong = res_pred_taken && (btb_target[res_idx] != resolve_target);

    assign mispredict   = resolve_valid && ((res_pred_taken != resolve_taken) || res_target_wrong);
    assign redirect_pc  = resolve_taken ? resolve_target : (resolve_pc + 32'd4);

    // Update — BHT and BTB on resolve
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < ENTRIES; i = i + 1) begin
                bht[i]        <= 2'b01; // init to Weakly Not Taken
                btb_target[i] <= {PC_WIDTH{1'b0}};
                btb_tag[i]    <= {TAG_WIDTH{1'b0}};
                btb_valid[i]  <= 1'b0;
            end
        end else if (resolve_valid) begin

            // BHT: saturating counter update
            case (bht[res_idx])
                2'b00: bht[res_idx] <= resolve_taken ? 2'b01 : 2'b00;
                2'b01: bht[res_idx] <= resolve_taken ? 2'b10 : 2'b00;
                2'b10: bht[res_idx] <= resolve_taken ? 2'b11 : 2'b01;
                2'b11: bht[res_idx] <= resolve_taken ? 2'b11 : 2'b10;
                default: bht[res_idx] <= 2'b01;
            endcase

            // BTB: update only when branch is actually taken
            if (resolve_taken) begin
                btb_target[res_idx] <= resolve_target;
                btb_tag[res_idx]    <= res_tag;
                btb_valid[res_idx]  <= 1'b1;
            end
        end
    end

endmodule
//============================================================================
//
//  Williams core ROM pool: 292K as 128K + 64K + 32K + 4K (Blaster's exact 228K, 00000-38FFF) + 64K at 40000
//  (Joust 2's BG sound ROMs) of dual-port block RAM
//  Copyright (C) 2026 Rodimus
//
//  Port A: ioctl load, then the time-shared readers (rtl/williams_dispatcher.sv). Port B: the main bus.
//  39000-3FFFF and 50000 up read 0. q follows the address by one clock, as dpram_dc.
//
//============================================================================

module rom_pool
(
    input  logic        clk,

    input  logic [18:0] a_addr,
    input  logic  [7:0] a_din,
    input  logic        a_we,
    output logic  [7:0] a_q,

    input  logic [18:0] b_addr,
    output logic  [7:0] b_q
);

// block: 0 = 00000-1FFFF, 1 = 20000-2FFFF, 2 = 30000-37FFF, 3 = 38000-38FFF, 4 = 40000-4FFFF, 5 = none
function automatic [2:0] blk(input [18:0] a);
    if (a[18])                           blk = a[17:16] == 2'd0 ? 3'd4 : 3'd5;
    else if (!a[17])                     blk = 3'd0;
    else if (!a[16])                     blk = 3'd1;
    else if (!a[15])                     blk = 3'd2;
    else if (a[14:12] == 3'd0)           blk = 3'd3;
    else                                 blk = 3'd5;
endfunction

wire [2:0] ab = blk(a_addr), bb = blk(b_addr);
logic [2:0] ab_r, bb_r;
always_ff @(posedge clk) begin ab_r <= ab; bb_r <= bb; end

logic [7:0] qa0, qa1, qa2, qa3, qa4, qb0, qb1, qb2, qb3, qb4;

dpram_dc #(.widthad_a(17)) blk0
(
    .clock_a(clk), .address_a(a_addr[16:0]), .data_a(a_din), .wren_a(a_we && ab == 3'd0), .q_a(qa0),
    .clock_b(clk), .address_b(b_addr[16:0]), .q_b(qb0)
);
dpram_dc #(.widthad_a(16)) blk1
(
    .clock_a(clk), .address_a(a_addr[15:0]), .data_a(a_din), .wren_a(a_we && ab == 3'd1), .q_a(qa1),
    .clock_b(clk), .address_b(b_addr[15:0]), .q_b(qb1)
);
dpram_dc #(.widthad_a(15)) blk2
(
    .clock_a(clk), .address_a(a_addr[14:0]), .data_a(a_din), .wren_a(a_we && ab == 3'd2), .q_a(qa2),
    .clock_b(clk), .address_b(b_addr[14:0]), .q_b(qb2)
);
dpram_dc #(.widthad_a(12)) blk3
(
    .clock_a(clk), .address_a(a_addr[11:0]), .data_a(a_din), .wren_a(a_we && ab == 3'd3), .q_a(qa3),
    .clock_b(clk), .address_b(b_addr[11:0]), .q_b(qb3)
);
dpram_dc #(.widthad_a(16)) blk4
(
    .clock_a(clk), .address_a(a_addr[15:0]), .data_a(a_din), .wren_a(a_we && ab == 3'd4), .q_a(qa4),
    .clock_b(clk), .address_b(b_addr[15:0]), .q_b(qb4)
);

always_comb begin
    case (ab_r)
        3'd0: a_q = qa0;  3'd1: a_q = qa1;  3'd2: a_q = qa2;  3'd3: a_q = qa3;  3'd4: a_q = qa4;  default: a_q = 8'h00;
    endcase
    case (bb_r)
        3'd0: b_q = qb0;  3'd1: b_q = qb1;  3'd2: b_q = qb2;  3'd3: b_q = qb3;  3'd4: b_q = qb4;  default: b_q = 8'h00;
    endcase
end

endmodule

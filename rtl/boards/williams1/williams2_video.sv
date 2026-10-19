//============================================================================
//
//  Williams second-generation video additions (Inferno, Mystic Marathon, Turkey Shoot, Joust 2)
//  Copyright (C) 2026 Rodimus
//
//  From MAME williams/williams_v.cpp (williams2_state, mysticm_state):
//  - Background: 128 x 16 tiles of 24 x 16, scrolling in X only, tile RAM C000-C7FF (index = column * 16 + row,
//    D6-D0 tile, D7 flip X). Tile ROM: three 8K parts; pixel x of a row = part (x / 2) % 3, byte x / 6, high
//    nibble first, 4 bytes a row, 64 bytes a tile. A microsecond is 6 pixels, so a tile is 4 us.
//  - Scroll: CB40 / CB60 make a 12-bit value s; MAME scroll = (s & 7) + (s >> 3) * 6, dx 2.
//  - Foreground (the bitmap): pen = CB00 colour * 16 + pixel, pixel 0 shows the background.
//  - Background pen: Inferno / Turkey Shoot {CB20 D5-D3, row D3-D1, pixel}; Mystic Marathon: 74LS85 colour decode;
//    Joust 2 {CB20 D5-D0, pixel}, 256 tiles in 16K parts, never flipped (MAME joust2_state: mask 255).
//  - Palette RAM 8000-87FF (bank select page 3): 1024 x {even: G << 4 | R, odd: I << 4 | B}, through the
//    netlist-derived intensity table (williams2_lut.svh).
//  Timing (one pixel = 8 clk): clk 0 tile RAM, clk 1 tile ROM, clk 2 pen -> palette RAM, clk 3 colour out.
//
//============================================================================

module williams2_video
(
    input  logic        clk,
    input  logic  [2:0] pc,             // clock within the pixel (ph[2:0])
    input  logic        mysticm,
    input  logic        joust2,

    input  logic  [8:0] fx,             // screen x (after CRT Flip)
    input  logic  [7:0] fy,             // screen line (after CRT Flip)
    input  logic  [3:0] fg_pix,         // bitmap pixel

    input  logic  [5:0] fg_color,       // CB00
    input  logic  [7:0] bg_sel,         // CB20
    input  logic [11:0] xscroll,        // CB40 / CB60

    // MPU: tile RAM and palette RAM (byte address within each)
    input  logic [10:0] cpu_a,
    input  logic  [7:0] cpu_d,
    input  logic        tile_we,
    input  logic        pal_we,
    output logic  [7:0] tile_q,
    output logic  [7:0] pal_q,

    // tile ROM (three 8K parts at 0000 / 2000 / 4000; Joust 2 16K at 0000 / 4000 / 8000) in the board's pool:
    // address during clk 1, byte in clk 2
    output logic [15:0] rom_a,
    input  logic  [7:0] rom_q,

    output logic [23:0] rgb             // valid from clk 4 of the pixel
);

`include "williams2_lut.svh"

/////////////////////////////  Tile position  /////////////////////////////

// tilemap x = screen x + scroll - 2, worked in 6-pixel units so no divide by 24 is needed
wire [18:0] fx171 = {10'd0, fx} * 19'd171;
wire  [8:0] q6    = fx171[18:10];                              // fx / 6 for fx < 384
wire  [8:0] q6x6  = {q6[6:0], 2'b00} + {q6[7:0], 1'b0};
wire  [8:0] r6w   = fx - q6x6;
wire  [2:0] r6    = r6w[2:0];
wire signed [4:0] rem0 = $signed({2'b00, r6}) + $signed({2'b00, xscroll[2:0]}) - 5'sd2;   // -2 .. 10
logic [9:0] u;
logic [2:0] rem;
always_comb begin
    if (rem0 < 0)        begin u = {1'b0, q6} + {1'b0, xscroll[11:3]} - 10'd1; rem = rem0[2:0] + 3'd6; end
    else if (rem0 >= 6)  begin u = {1'b0, q6} + {1'b0, xscroll[11:3]} + 10'd1; rem = rem0[2:0] - 3'd6; end
    else                 begin u = {1'b0, q6} + {1'b0, xscroll[11:3]};         rem = rem0[2:0];        end
end

wire [6:0] col = u[8:2];
wire [3:0] row = fy[7:4];

/////////////////////////////  Tile RAM / ROM  /////////////////////////////

logic [7:0] tcode;
dpram_dc #(.widthad_a(11)) tile_ram
(
    .clock_a(clk), .address_a(cpu_a), .data_a(cpu_d), .wren_a(tile_we), .q_a(tile_q),
    .clock_b(clk), .address_b({col, row}), .q_b(tcode)
);

// held from clk 1 for the ROM and the pen
logic [1:0] byte_r;
logic [2:0] rem_r;
logic [3:0] row_r, line_r;
logic [7:0] code_r;
always_ff @(posedge clk) if (pc == 3'd0) begin byte_r <= u[1:0]; rem_r <= rem; row_r <= row; line_r <= fy[3:0]; end

wire       flip  = tcode[7] & ~joust2;
wire [1:0] tbyte = flip ? 2'd3 - byte_r : byte_r;
wire [2:0] trem  = flip ? 3'd5 - rem_r  : rem_r;
wire [1:0] part  = trem[2:1];

logic       nib_r;
assign rom_a = joust2 ? {part, tcode[7:0], line_r, tbyte} : {1'b0, part, tcode[6:0], line_r, tbyte};
always_ff @(posedge clk) if (pc == 3'd1) nib_r <= trem[0];

wire [3:0] bg_pix = nib_r ? rom_q[3:0] : rom_q[7:4];

/////////////////////////////  Pens / palette  /////////////////////////////

// Mystic Marathon IC79 74LS85: colour bit 0 = A > B or (A = B and not W11), A = {c0, c0, 0, 1}, B = {0, 0, W13, W12}
wire       w11 = row_r[1], w12 = row_r[2], w13 = row_r[3];
wire       my0 = bg_sel[0] | (!w13 && !w12) | (!w13 && w12 && !w11);
wire [5:0] bg_col = joust2 ? bg_sel[5:0] : mysticm ? {bg_sel[5:1], my0} : {bg_sel[5:3], row_r[3:1]};

wire [9:0] pen = (fg_pix != 4'd0) ? {fg_color, fg_pix} : {bg_col, bg_pix};

logic [7:0] pal_lo, pal_hi, pal_lo_c, pal_hi_c;
dpram_dc #(.widthad_a(10)) pal_ram_lo
(
    .clock_a(clk), .address_a(cpu_a[10:1]), .data_a(cpu_d), .wren_a(pal_we && !cpu_a[0]), .q_a(pal_lo_c),
    .clock_b(clk), .address_b(pen), .q_b(pal_lo)
);
dpram_dc #(.widthad_a(10)) pal_ram_hi
(
    .clock_a(clk), .address_a(cpu_a[10:1]), .data_a(cpu_d), .wren_a(pal_we &&  cpu_a[0]), .q_a(pal_hi_c),
    .clock_b(clk), .address_b(pen), .q_b(pal_hi)
);
assign pal_q = cpu_a[0] ? pal_hi_c : pal_lo_c;

wire [3:0] inten = pal_hi[7:4];
always_ff @(posedge clk)
    if (pc == 3'd3)
        rgb <= mysticm ? {w2_lv_mr({inten, pal_lo[3:0]}), w2_lv_mg({inten, pal_lo[7:4]}), w2_lv_mb({inten, pal_hi[3:0]})}
                       : {w2_lv   ({inten, pal_lo[3:0]}), w2_lv   ({inten, pal_lo[7:4]}), w2_lv   ({inten, pal_hi[3:0]})};

endmodule

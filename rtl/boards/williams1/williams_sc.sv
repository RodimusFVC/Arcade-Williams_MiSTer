//============================================================================
//
//  Williams Special Chip 1 / 2 (VTI VL2001 / VL2001A) block-transfer chip
//  Copyright (C) 2026 Rodimus
//
//  Behaviour from MAME williams/williamsblitter.cpp (Sean Riddle's measurements). Registers at CA00-CA07:
//    0 control (writing it starts the blit)   1 solid colour   2-3 source   4-5 destination   6 width   7 height
//  Control: 7 no even (D7-D4), 6 no odd (D3-D0), 5 shift right one pixel, 4 solid, 3 foreground only,
//           2 slow (one byte per 2 us), 1 destination stride 256, 0 source stride 256.
//  SC1 needs width / height XOR 4 (size_xor); SC2 does not. A size of 0 is 1.
//  While busy the chip halts the MPU and owns the bus: one byte per microsecond (fast), read source, read the
//  destination (always video RAM below C000), write it back. With the window enabled, video RAM writes at or
//  above clip_addr are dropped (Sinistar 7400, Blaster 9700); writes at C000 and up always go through.
//  Blaster: each source byte passes through the remap PROM (blaster.col, 128 tables of 16 nibbles, selected by
//  C940): byte = table[hi] << 4 | table[lo] (MAME williams_blitter_device::device_start).
//
//============================================================================

module williams_sc
(
    input  logic        clk,
    input  logic        rst,
    input  logic        run,            // one clk per microsecond: start a byte (frozen while paused)

    input  logic        reg_we,         // MPU register write
    input  logic  [2:0] reg_a,
    input  logic  [7:0] reg_d,

    input  logic  [2:0] size_xor,       // SC1: 4, SC2: 0
    input  logic [15:0] clip_addr,
    input  logic        window,

    input  logic        remap_en,
    input  logic  [6:0] remap_idx,
    input  logic [10:0] remap_wa,       // PROM load (ioctl)
    input  logic  [7:0] remap_wd,
    input  logic        remap_we,

    output logic        busy,
    output logic [15:0] a,              // bus master while busy
    output logic  [7:0] dout,
    output logic        we,
    input  logic  [7:0] din,            // bus read data (the MPU read path, at a)
    input  logic  [7:0] vram_q          // video RAM read data (at a)
);

logic [7:0] ctrl = 8'd0, solid = 8'd0, width = 8'd0, height = 8'd0;
logic [15:0] sstart = 16'd0, dstart = 16'd0;

wire no_even = ctrl[7], no_odd = ctrl[6], shift = ctrl[5], solid_m = ctrl[4], fg_only = ctrl[3];
wire slow = ctrl[2], dst256 = ctrl[1], src256 = ctrl[0];

logic [7:0]  w, x, h, y;
logic [15:0] src, dst, srow, drow;
logic [3:0]  pix = 4'd0;                // shift: the last source byte's odd pixel (carried across rows)
logic [7:0]  sdat;
logic [3:0]  st = 4'd0;
logic [7:0]  raw;
logic [7:0]  map_hi, map_lo;

dpram_dc #(.widthad_a(11)) remap_prom
(
    .clock_a(clk), .address_a(remap_we ? remap_wa : {remap_idx, raw[7:4]}), .data_a(remap_wd), .wren_a(remap_we),
    .q_a(map_hi),
    .clock_b(clk), .address_b({remap_idx, raw[3:0]}), .q_b(map_lo)
);
wire [7:0] rval = remap_en ? {map_hi[3:0], 4'd0} | map_lo : raw;
logic        half = 1'b0;               // slow mode: every other microsecond

wire [7:0] wsz = width  ^ {5'd0, size_xor};
wire [7:0] hsz = height ^ {5'd0, size_xor};

// which pixel of the byte is written: the even / odd inhibits, inverted for a zero pixel in foreground-only mode
wire wr_even = (fg_only && sdat[7:4] == 4'd0) ? no_even : ~no_even;
wire wr_odd  = (fg_only && sdat[3:0] == 4'd0) ? no_odd  : ~no_odd;
wire [7:0] keep = {{4{~wr_even}}, {4{~wr_odd}}};    // destination bits kept

always_ff @(posedge clk) begin
    we <= 1'b0;
    if (rst) begin
        busy <= 1'b0; st <= 4'd0;
        ctrl <= 8'd0; solid <= 8'd0; sstart <= 16'd0; dstart <= 16'd0; width <= 8'd0; height <= 8'd0;
    end else if (!busy) begin
        if (reg_we) begin
            case (reg_a)
                3'd0: begin
                    ctrl <= reg_d;
                    w    <= (wsz == 8'd0) ? 8'd1 : wsz;
                    h    <= (hsz == 8'd0) ? 8'd1 : hsz;
                    x    <= 8'd0; y <= 8'd0;
                    src  <= sstart; srow <= sstart;
                    dst  <= dstart; drow <= dstart;
                    pix  <= 4'd0;
                    half <= 1'b0;
                    st   <= 4'd0;
                    busy <= 1'b1;
                end
                3'd1: solid <= reg_d;
                3'd2: sstart[15:8] <= reg_d;
                3'd3: sstart[7:0]  <= reg_d;
                3'd4: dstart[15:8] <= reg_d;
                3'd5: dstart[7:0]  <= reg_d;
                3'd6: width  <= reg_d;
                3'd7: height <= reg_d;
            endcase
        end
    end else begin
        case (st)
            4'd0: if (run) begin
                      half <= ~half;
                      if (!slow || half) begin a <= src; st <= 4'd1; end
                  end
            4'd4: begin                                     // source byte
                      raw <= din;
                      st  <= 4'd5;
                  end
            4'd7: begin                                     // remapped (2 clocks for the PROM)
                      if (shift) begin
                          pix  <= rval[3:0];
                          sdat <= {pix, rval[7:4]};
                      end else
                          sdat <= rval;
                      a  <= dst;
                      st <= 4'd8;
                  end
            4'd11: begin                                    // destination byte, write back
                      dout <= ((dst < 16'hC000 ? vram_q : din) & keep) | ((solid_m ? solid : sdat) & ~keep);
                      we   <= !window || dst < clip_addr || dst >= 16'hC000;
                      st   <= 4'd12;
                  end
            4'd13: begin                                    // advance
                      if (x == w - 8'd1) begin
                          x <= 8'd0;
                          if (y == h - 8'd1)
                              busy <= 1'b0;
                          y <= y + 8'd1;
                          // the next row; with stride 256 the row step wraps in the low byte (PlayBall!)
                          if (dst256) begin drow <= {drow[15:8], drow[7:0] + 8'd1}; dst <= {drow[15:8], drow[7:0] + 8'd1}; end
                          else        begin drow <= drow + {8'd0, w}; dst <= drow + {8'd0, w}; end
                          if (src256) begin srow <= {srow[15:8], srow[7:0] + 8'd1}; src <= {srow[15:8], srow[7:0] + 8'd1}; end
                          else        begin srow <= srow + {8'd0, w}; src <= srow + {8'd0, w}; end
                      end else begin
                          x   <= x + 8'd1;
                          dst <= dst + (dst256 ? 16'h0100 : 16'h0001);
                          src <= src + (src256 ? 16'h0100 : 16'h0001);
                      end
                      st <= 4'd0;
                  end
            default: st <= st + 4'd1;
        endcase
    end
end

endmodule

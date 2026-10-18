//============================================================================
//
//  Williams first-generation CPU/video board + ROM board + interface board
//  Copyright (C) 2026 Rodimus
//
//  Sources: Defender theory of operation 16P-3001-301 (later system boards) and MAME williams.cpp.
//
//  Clocks (48 MHz = 4 x the 12 MHz crystal): ph counts one E cycle (1 us, 48 clocks).
//    6 MHz pixel = ph[2:0] == 7, 6 pixels per microsecond (3 RAM banks x 2 pixels).
//    E / Q: Q falls a quarter cycle before E; the video address counter steps with E (clocked reset CR).
//  Video address VA[13:0]: VA[5:0] = microsecond of the 64 us line, VA[13:6] = line. At the first 16383 the
//    upper stages preload to 16128, so lines 252-255 run twice: 260 lines a frame. Here vline 0..259 is
//    MAME's vpos, VA line = vline (0..255) or 252..255 for vline 256..259.
//  Pixel x (MAME screen x) = 6 * us + ph / 8; it reads the byte at (x / 2) * 256 + line, high nibble first.
//  COUNT 240 (VA10-13 all high) -> ROM PIA CA1, VA11 -> ROM PIA CB1 (4 ms), both IRQs -> 6809 IRQ.
//  HSYNC us 56-59 (VA3-5 high, VA2 low), VSYNC from line 248 to the counter wrap (12 lines).
//
//  Variant 0 (Defender): 0000-BFFF video RAM, C000-CFFF page selected by a write to D000-DFFF (D3-D0):
//    page 0 = I/O, pages 1-7 = banked ROM (stored at image 0000-6FFF), D000-FFFF ROM.
//  Page 0: C000-C3FF A4=0 colour RAM (A3-A0), A4=1 video control / watchdog (C3FC-C3FF, data 38 or 39),
//    C400-C7FF CMOS 256 x 4, C800-CBFF vertical count (VA13-8 on D7-D2), CC00 ROM board PIA, CC04 interface PIA.
//
//============================================================================

module williams1_main
(
    input  logic        clk,            // 48 MHz
    input  logic        reset,
    input  logic        pause,
    input  logic  [7:0] variant,

    // MC6809E (rtl/williams_board.sv)
    output logic        fall_e,
    output logic        fall_q,
    output logic        cpu_rst,
    output logic        irq_n,
    output logic  [7:0] cpu_di,
    input  logic [15:0] cpu_a,
    input  logic  [7:0] cpu_do,
    input  logic        cpu_rw,

    // program ROM image (64K)
    output logic [15:0] rom_a,
    input  logic  [7:0] rom_d,

    input  logic  [7:0] nv_addr,        // CMOS second port: MiSTer NVRAM load / save
    input  logic  [7:0] nv_din,
    input  logic        nv_we,
    output logic  [7:0] nv_dout,

    input  logic  [7:0] in0,            // interface PIA port A
    input  logic  [7:0] in1,            // interface PIA port B
    input  logic  [7:0] in2,            // ROM board PIA port A (coin door)
    output logic  [7:0] snd_cmd,        // to the sound board PIA port B

    input  logic        crt_flip,
    input  logic  [3:0] h_adj,
    input  logic  [3:0] v_adj,

    output logic        ce_pix,
    output logic  [7:0] video_r,
    output logic  [7:0] video_g,
    output logic  [7:0] video_b,
    output logic        video_hs,
    output logic        video_vs,
    output logic        video_hblank,
    output logic        video_vblank
);

/////////////////////////////  Clocks  /////////////////////////////

logic [5:0] ph = 6'd0;
always_ff @(posedge clk) ph <= (ph == 6'd47) ? 6'd0 : ph + 6'd1;

logic [1:0] pause_d = 2'b00;
always_ff @(posedge clk) pause_d <= {pause_d[0], pause};
wire pause_x = pause | (|pause_d);

// mc6809is only samples /RESET on a fallE tick, so E keeps running while the CPU is held in reset even when
// paused (the OSD is open, and pausing, during the MRA load). Otherwise it leaves the load in its power-up state.
assign fall_q = (ph == 6'd35) & (~pause_x | cpu_rst);
assign fall_e = (ph == 6'd47) & (~pause_x | cpu_rst);
assign ce_pix = (ph[2:0] == 3'd7);

/////////////////////////////  Video address generator  /////////////////////////////

logic [5:0] us = 6'd0;                  // VA5-VA0
logic [8:0] vline = 9'd0;               // 0..259
always_ff @(posedge clk) begin
    if (ph == 6'd47) begin
        us <= us + 6'd1;
        if (us == 6'd63) vline <= (vline == 9'd259) ? 9'd0 : vline + 9'd1;
    end
end

wire [7:0] va_line  = vline[8] ? {6'b111111, vline[1:0]} : vline[7:0];   // VA13-VA6
wire       count240 = &va_line[7:4];
wire       va11     = va_line[5];
wire [8:0] hpix     = {us, 3'd0} - {2'd0, us, 1'b0} + {6'd0, ph[5:3]};  // 6 * us + ph / 8

/////////////////////////////  Watchdog  /////////////////////////////

// Counts vertical scans; eight without a clear (data 38 / 39 to C3FC-C3FF, page 0) reset the MPU.
// Frozen while paused.
logic [3:0] wd_cnt = 4'd0;
logic       wd_kick;
always_ff @(posedge clk) begin
    if (reset || wd_kick || wd_cnt[3])
        wd_cnt <= 4'd0;
    else if (ph == 6'd47 && us == 6'd63 && vline == 9'd259 && !pause)
        wd_cnt <= wd_cnt + 4'd1;
end
assign cpu_rst = reset | wd_cnt[3];

/////////////////////////////  CPU decode  /////////////////////////////

wire defender = (variant == 8'd0);

logic [3:0] page = 4'd0;
wire  cs_vram = cpu_a < 16'hC000;
wire  cs_page = cpu_a[15:12] == 4'hC;
wire  cs_io   = cs_page && page == 4'd0;
wire  cs_prom = cs_page && page != 4'd0 && page < 4'd8;              // banked ROM pages 1-7
wire  cs_rom  = cpu_a[15:12] >= 4'hD;
wire  cs_col  = cs_io && cpu_a[11:10] == 2'd0 && !cpu_a[4];          // C000-C3FF, A4 = 0
wire  cs_vctl = cs_io && cpu_a[11:10] == 2'd0 &&  cpu_a[4];          // C010-C3FF, A4 = 1
wire  cs_cmos = cs_io && cpu_a[11:10] == 2'd1;                       // C400-C7FF
wire  cs_vcnt = cs_io && cpu_a[11:10] == 2'd2;                       // C800-CBFF
wire  cs_pia  = cs_io && cpu_a[11:10] == 2'd3 && cpu_a[4:3] == 2'd0; // CC00-CC07, A9-A5 not decoded
wire  cs_pia1 = cs_pia && !cpu_a[2];                                 // ROM board PIA
wire  cs_pia0 = cs_pia &&  cpu_a[2];                                 // interface board PIA

wire  wr = fall_e & ~cpu_rw & ~cpu_rst;

assign rom_a = cs_prom ? {page - 4'd1, cpu_a[11:0]} : cpu_a;

assign wd_kick = wr && cs_vctl && cpu_a[9:2] == 8'hFF && cpu_do[7:1] == 7'h1C;

always_ff @(posedge clk) begin
    if (cpu_rst)
        page <= 4'd0;
    else if (wr && cpu_a[15:12] == 4'hD)
        page <= cpu_do[3:0];
end

/////////////////////////////  Video RAM  /////////////////////////////

// CPU on port A, video on port B. 48K used of 64K.
logic [7:0] vram_cpu_q, vram_q;
logic [8:0] fx;
logic [7:0] fy;

dpram_dc #(.widthad_a(16)) vram
(
    .clock_a(clk), .address_a(cpu_a), .data_a(cpu_do), .wren_a(wr & cs_vram), .q_a(vram_cpu_q),
    .clock_b(clk), .address_b({fx[8:1], fy}), .q_b(vram_q)
);

/////////////////////////////  Colour RAM / CMOS  /////////////////////////////

logic [7:0] pal[16];
always_ff @(posedge clk)
    if (wr && cs_col) pal[cpu_a[3:0]] <= cpu_do;

// 5101 / 5114 CMOS, D3-D0 only. MAME stores data | F0 and reads the byte back.
logic [7:0] cmos_q;
dpram_dc #(.widthad_a(8)) cmos_ram
(
    .clock_a(clk), .address_a(cpu_a[7:0]), .data_a(cpu_do | 8'hF0), .wren_a(wr & cs_cmos), .q_a(cmos_q),
    .clock_b(clk), .address_b(nv_addr), .data_b(nv_din), .wren_b(nv_we), .q_b(nv_dout)
);

/////////////////////////////  PIAs  /////////////////////////////

logic [7:0] pia0_do, pia1_do, pia1_pb, pia1_pb_oe;
logic       pia1_irqa, pia1_irqb;

// IC1 interface board: player panel
pia6821 pia0
(
    .clk(clk), .rst(cpu_rst), .ce(fall_e), .cs(cs_pia0), .rw(cpu_rw), .rs(cpu_a[1:0]), .din(cpu_do), .dout(pia0_do),
    .irqa(), .irqb(),
    .pa_i(in0), .pa_o(), .pa_oe(), .ca1(1'b0), .ca2_i(1'b0), .ca2_o(), .ca2_oe(),
    .pb_i(in1), .pb_o(), .pb_oe(), .cb1(1'b0), .cb2_i(1'b0), .cb2_o(), .cb2_oe()
);

// IC22 ROM board: coin door in, sound select out, COUNT 240 on CA1, VA11 on CB1
pia6821 pia1
(
    .clk(clk), .rst(cpu_rst), .ce(fall_e), .cs(cs_pia1), .rw(cpu_rw), .rs(cpu_a[1:0]), .din(cpu_do), .dout(pia1_do),
    .irqa(pia1_irqa), .irqb(pia1_irqb),
    .pa_i(in2), .pa_o(), .pa_oe(), .ca1(count240), .ca2_i(1'b0), .ca2_o(), .ca2_oe(),
    .pb_i(8'hFF), .pb_o(pia1_pb), .pb_oe(pia1_pb_oe), .cb1(va11), .cb2_i(1'b0), .cb2_o(), .cb2_oe()
);

assign irq_n = ~(pia1_irqa | pia1_irqb);

// sound select lines are pulled up on the sound board; MAME: the top two are set externally
assign snd_cmd = (pia1_pb & pia1_pb_oe) | ~pia1_pb_oe | 8'hC0;

/////////////////////////////  CPU read mux  /////////////////////////////

always_comb begin
    if      (cs_vram) cpu_di = vram_cpu_q;
    else if (cs_rom)  cpu_di = rom_d;
    else if (cs_prom) cpu_di = rom_d;
    else if (cs_cmos) cpu_di = cmos_q;
    else if (cs_vcnt) cpu_di = {va_line[7:2], 2'b00};
    else if (cs_pia1) cpu_di = pia1_do;
    else if (cs_pia0) cpu_di = pia0_do;
    else              cpu_di = 8'h00;
end

/////////////////////////////  Video out  /////////////////////////////

// MAME visible area: Defender x 12-303, later boards x 6-297; lines 7-246
wire [8:0] x0 = defender ? 9'd12  : 9'd6;
wire [8:0] x1 = defender ? 9'd303 : 9'd297;

// CRT Flip: read the window back from the opposite corner (the cocktail PROMs do the same on the real board)
assign fx = crt_flip ? (x0 + x1 - hpix) : hpix;
assign fy = crt_flip ? (8'd253 - va_line) : va_line;

// palette levels: MAME compute_resistor_weights, R / G 1200 / 560 / 330, B 560 / 330
function automatic [7:0] lv_rg(input [2:0] v);
    case (v)
        3'd0: lv_rg = 8'd0;   3'd1: lv_rg = 8'd38;  3'd2: lv_rg = 8'd81;  3'd3: lv_rg = 8'd118;
        3'd4: lv_rg = 8'd137; 3'd5: lv_rg = 8'd174; 3'd6: lv_rg = 8'd217; 3'd7: lv_rg = 8'd255;
    endcase
endfunction
function automatic [7:0] lv_b(input [1:0] v);
    case (v)
        2'd0: lv_b = 8'd0;  2'd1: lv_b = 8'd95;  2'd2: lv_b = 8'd160;  2'd3: lv_b = 8'd255;
    endcase
endfunction

wire [3:0] nib = fx[0] ? vram_q[3:0] : vram_q[7:4];
wire [7:0] col = pal[nib];

wire [8:0] hs_beg = 9'd336 + {{5{h_adj[3]}}, h_adj};
wire [8:0] vs_beg = 9'd248 + {{5{v_adj[3]}}, v_adj};

always_ff @(posedge clk) begin
    if (ce_pix) begin
        video_r      <= lv_rg(col[2:0]);
        video_g      <= lv_rg(col[5:3]);
        video_b      <= lv_b(col[7:6]);
        video_hblank <= (hpix < x0) || (hpix > x1);
        video_vblank <= (vline < 9'd7) || (vline > 9'd246);
        video_hs     <= (hpix >= hs_beg) && (hpix < hs_beg + 9'd24);
        video_vs     <= (vline >= vs_beg) && (vline < vs_beg + 9'd12);
    end
end

endmodule

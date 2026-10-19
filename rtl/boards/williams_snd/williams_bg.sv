//============================================================================
//
//  Williams D-11298 "BG Music & Speech Board" (Joust 2): MC68B09E + YM2151 + HC-55516 + MC1408 DAC + MC6821
//  Copyright (C) 2026 Rodimus
//
//  MAME s11c_bg.cpp (s11_obg_device) / williams.cpp joust2: 6809E on 8 MHz / 4 (E = 2 MHz), map 0000-07FF RAM
//  (mirror to 1FFF), 2000-2001 YM2151 (mirror to 3FFF, 3.58 MHz), 4000-4003 PIA (mirror to 5FFF), 6000 CVSD clock
//  high, 6800 CVSD clock low + digit D0, 7800 bank, 8000-FFFF banked ROM. Bank D1-D0 select U4 / U19 / U20 (3 =
//  open bus, reads 0 as MAME's empty region); D3-D2 drive A15 / A16, unused by the 27256s (MAME reloads them).
//  PIA: PA -> DAC, PB <- main ROM-board PIA port B, CB1 <- main PIA CA2 (strobe), CB2 -> sound board PIA CB1,
//  CA1 <- YM2151 IRQ (inverted), CA2 -> YM2151 reset (on a rising edge, MAME reset_w), IRQA -> FIRQ, IRQB -> NMI.
//  resetq (sound board PIA CB2): a falling edge resets the CPU and the bank (MAME resetq_w / common_reset).
//  Mix (MAME s11_obg, x2 into the speaker): DAC, YM2151 left, right and the CVSD each 0.117.
//
//============================================================================

module williams_bg
(
    input  logic        clk,            // 48 MHz
    input  logic        reset,
    input  logic        pause,

    input  logic  [7:0] data,           // main ROM-board PIA port B pins
    input  logic        strobe,         // main ROM-board PIA CA2
    input  logic        resetq,         // sound board PIA CB2
    output logic        cb2,            // -> sound board PIA CB1

    output logic  [1:0] rom_sel,        // ROM U4 / U19 / U20 (3 = none) at 8000-FFFF, in the board's pool
    output logic [14:0] rom_a,
    input  logic  [7:0] rom_d,          // byte at rom_sel / rom_a, refreshed within 8 clocks of a change

    output logic        cvsd_clk,       // to the shared HC-55516 (rtl/williams_board.sv)
    output logic        cvsd_digit,

    output logic signed [15:0] audio    // DAC + YM2151 (the CVSD is mixed by the board)
);

/////////////////////////////  MC68B09E, E = 2 MHz  /////////////////////////////

logic [4:0] ph = 5'd0;
always_ff @(posedge clk) if (!pause) ph <= (ph == 5'd23) ? 5'd0 : ph + 5'd1;
wire fall_q = !pause && ph == 5'd17;
wire fall_e = !pause && ph == 5'd23;

// resetq: falling edge -> CPU and bank reset (a pulse long enough for the CPU to see a fallE)
logic rq_d = 1'b1;
logic [5:0] rq_cnt = 6'd0;
always_ff @(posedge clk) begin
    rq_d <= resetq;
    if (reset)                rq_cnt <= 6'd0;
    else if (rq_d && !resetq) rq_cnt <= 6'd48;
    else if (rq_cnt != 6'd0)  rq_cnt <= rq_cnt - 6'd1;
end
wire cpu_rst = reset || rq_cnt != 6'd0;

logic [15:0] a;
logic  [7:0] cpu_do, cpu_di;
logic        rnw;
logic        irqa, irqb;

mc6809is bg_cpu
(
    .CLK(clk), .fallE_en(fall_e), .fallQ_en(fall_q), .D(cpu_di), .DOut(cpu_do), .ADDR(a),
    .RnW(rnw), .BS(), .BA(), .nIRQ(1'b1), .nFIRQ(~irqa), .nNMI(~irqb), .AVMA(), .BUSY(),
    .LIC(), .nHALT(1'b1), .nRESET(~cpu_rst), .nDMABREQ(1'b1), .RegData()
);

wire wr     = fall_e & ~rnw & ~cpu_rst;
wire cs_ram = a[15:13] == 3'b000;
wire cs_ym  = a[15:13] == 3'b001;
wire cs_pia = a[15:13] == 3'b010;
wire cs_rom = a[15];

/////////////////////////////  RAM / bank / CVSD latches  /////////////////////////////

logic [7:0] ram_q;
dpram_dc #(.widthad_a(11)) ram
(
    .clock_a(clk), .address_a(a[10:0]), .data_a(cpu_do), .wren_a(wr & cs_ram), .q_a(ram_q),
    .clock_b(clk)
);

logic [1:0] bank = 2'd0;
always_ff @(posedge clk) begin
    if (cpu_rst) bank <= 2'd0;
    else if (wr && a[15:11] == 5'b01111) bank <= cpu_do[1:0];          // 7800
    if (reset) begin cvsd_clk <= 1'b0; cvsd_digit <= 1'b0; end
    else if (wr && a[15:11] == 5'b01100) cvsd_clk <= 1'b1;             // 6000
    else if (wr && a[15:11] == 5'b01101) begin cvsd_clk <= 1'b0; cvsd_digit <= cpu_do[0]; end   // 6800
end

assign rom_sel = bank;
assign rom_a   = a[14:0];

/////////////////////////////  MC6821  /////////////////////////////

logic [7:0] pia_do, pa_o, pa_oe;
logic       ca2_o, ca2_oe, cb2_o, ym_irq_n;

pia6821 pia
(
    .clk(clk), .rst(reset),
    .ce(fall_e & cs_pia & ~cpu_rst),
    .cs(cs_pia), .rw(rnw), .rs(a[1:0]), .din(cpu_do), .dout(pia_do),
    .irqa(irqa), .irqb(irqb),
    .pa_i(8'hFF), .pa_pins(1'b0), .pa_o(pa_o), .pa_oe(pa_oe),
    .ca1(ym_irq_n), .ca2_i(1'b1), .ca2_o(ca2_o), .ca2_oe(ca2_oe),
    .pb_i(data), .pb_o(), .pb_oe(), .cb1(strobe), .cb2_i(1'b1), .cb2_o(cb2_o), .cb2_oe()
);

assign cb2 = cb2_o;

/////////////////////////////  YM2151  /////////////////////////////

logic [7:0] ym_do;
logic signed [15:0] ym_l, ym_r;

// jt51 by Jose Tejada Gomez (jotego), rtl/sound/jt51 (GPL-3.0). Clock 3.579545 MHz; P1 (cen_p1) at half that.
logic [25:0] ym_acc = 26'd0;
logic        ym_cen = 1'b0, ym_p1 = 1'b0, ym_half = 1'b0;
always_ff @(posedge clk) begin
    ym_cen <= 1'b0; ym_p1 <= 1'b0;
    if (!pause) begin
        if (ym_acc >= 26'd48_000_000 - 26'd3_579_545) begin
            ym_acc  <= ym_acc + 26'd3_579_545 - 26'd48_000_000;
            ym_cen  <= 1'b1;
            ym_half <= ~ym_half;
            ym_p1   <= ym_half;
        end else
            ym_acc <= ym_acc + 26'd3_579_545;
    end
end

// a write is held until a P1 tick has passed (the busy flag and the register pipeline run on P1)
logic       ym_wr = 1'b0, ym_a0 = 1'b0, ym_seen = 1'b0;
logic [7:0] ym_din = 8'd0;
always_ff @(posedge clk) begin
    if (reset) ym_wr <= 1'b0;
    else if (wr & cs_ym) begin ym_wr <= 1'b1; ym_seen <= 1'b0; ym_a0 <= a[0]; ym_din <= cpu_do; end
    else if (ym_wr && ym_p1) ym_seen <= 1'b1;
    else if (ym_wr && ym_seen) ym_wr <= 1'b0;
end

// reset: PIA CA2 rising (MAME ym2151 reset_w), and board reset
wire        ca2_pin = ca2_oe ? ca2_o : 1'b1;
logic       ca2_d = 1'b1;
logic [5:0] ym_rcnt = 6'd0;
always_ff @(posedge clk) begin
    ca2_d <= ca2_pin;
    if (ca2_pin && !ca2_d) ym_rcnt <= 6'd63;
    else if (ym_rcnt != 6'd0) ym_rcnt <= ym_rcnt - 6'd1;
end

jt51 ym
(
    .rst(reset || ym_rcnt != 6'd0), .clk(clk), .cen(ym_cen), .cen_p1(ym_p1),
    .cs_n(!(ym_wr || (cs_ym && rnw))), .wr_n(!ym_wr), .a0(ym_wr ? ym_a0 : a[0]), .din(ym_din), .dout(ym_do),
    .ct1(), .ct2(), .irq_n(ym_irq_n), .sample(), .left(ym_l), .right(ym_r), .xleft(), .xright()
);

always_comb begin
    if      (cs_ram) cpu_di = ram_q;
    else if (cs_ym)  cpu_di = ym_do;
    else if (cs_pia) cpu_di = pia_do;
    else if (cs_rom) cpu_di = (bank == 2'd3) ? 8'h00 : rom_d;
    else             cpu_di = 8'hFF;
end

/////////////////////////////  Mix  /////////////////////////////

// MC1408 DAC on PA, unipolar about 0x80, AC-coupled (one-pole DC block as on the sound board)
wire [7:0] dac = (pa_o & pa_oe) | ~pa_oe;
wire signed [15:0] dac_s = $signed({{2{~dac[7]}}, dac[6:0], 7'd0});
logic signed [31:0] dc = 32'sd0;
always_ff @(posedge clk)
    if (fall_e) dc <= dc + (($signed({dac_s, 16'd0}) - dc) >>> 16);
wire signed [15:0] dc_hi = dc[31:16];

// MAME s11_obg x2: DAC 0.234 (its half-scale dac_s / 2), YM2151 left + right 0.234 each into the mono speaker
wire signed [17:0] dac_ac = $signed({{2{dac_s[15]}}, dac_s}) - $signed({{2{dc_hi[15]}}, dc_hi});
wire signed [21:0] ym_sum = ($signed({{6{ym_l[15]}}, ym_l}) + $signed({{6{ym_r[15]}}, ym_r})) * 22'sd15;   // x 15 / 64
wire signed [17:0] mix    = (dac_ac >>> 1) + $signed({{2{ym_sum[21]}}, ym_sum[21:6]});
assign audio = (mix > 18'sd32767) ? 16'sd32767 : (mix < -18'sd32768) ? -16'sd32768 : mix[15:0];

endmodule

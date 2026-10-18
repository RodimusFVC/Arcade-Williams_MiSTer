//============================================================================
//
//  Williams sound board D-8224 (Defender .. Joust): MC6808 + MC6821 + MC6810 + ROM + MC1408 DAC
//  Copyright (C) 2026 Rodimus
//
//  Schematic 16D-8224 (Defender drawing set, sheet 21): 3.58 MHz crystal into the 6808 (E = 894.886 kHz),
//  IC10 6821 at 0400-0403 (A15 not decoded), port A -> MC1408 DAC, port B <- sound select inputs J3
//  (pulled up, 4050 buffers), CB1 <- IC6 4068 (low only while all select inputs are high = command FF),
//  CA1 pulled high, IRQA / IRQB -> 6808 IRQ, diagnostic switch SW1 -> NMI (not wired here).
//  RAM 0000-00FF (MAME: 0000-007F on Defender, 0080-00FF MC6810 on later boards), ROM image 8000-FFFF.
//
//============================================================================

module williams_sndbd
(
    input  logic        clk,            // 48 MHz
    input  logic        reset,
    input  logic        pause,

    input  logic  [7:0] cmd,            // PIA port B pins (sound select inputs, idle FF)

    input  logic [14:0] rom_wa,         // ROM image 8000-FFFF (ioctl)
    input  logic  [7:0] rom_wd,
    input  logic        rom_we,

    output logic signed [15:0] audio
);

/////////////////////////////  Clock enable  /////////////////////////////

// jt680x takes the crystal rate and divides by 4 in its microcode (vault: Soft CPU internal clock divider)
logic [25:0] acc = 26'd0;
logic        tick = 1'b0;
always_ff @(posedge clk) begin
    tick <= acc >= 26'd48_000_000 - 26'd3_579_545;
    acc  <= (acc >= 26'd48_000_000 - 26'd3_579_545) ? acc + 26'd3_579_545 - 26'd48_000_000 : acc + 26'd3_579_545;
end
wire cen = tick & ~pause;

/////////////////////////////  MC6808  /////////////////////////////

logic [15:0] a;
logic  [7:0] cpu_do, cpu_di;
logic        cpu_wr;
logic        irq;

jt680x cpu
(
    .rst(reset), .clk(clk), .cen(cen), .wr(cpu_wr), .addr(a), .din(cpu_di), .dout(cpu_do),
    .ext_halt(1'b0), .ba(), .irq(irq), .nmi(1'b0),
    .irq_icf(1'b0), .irq_ocf(1'b0), .irq_tof(1'b0), .irq_sci(1'b0), .irq_cmf(1'b0), .irq2(1'b0)
);

// jt680x holds wr for a whole micro-cycle group: commit one write when it ends (Space Invaders sound pattern)
logic [15:0] wl_a = 16'd0, cmt_a = 16'd0;
logic  [7:0] wl_d = 8'd0,  cmt_d = 8'd0;
logic        wpend = 1'b0, cmt = 1'b0;
always_ff @(posedge clk) begin
    cmt <= 1'b0;
    if (reset)
        wpend <= 1'b0;
    else if (cen) begin
        if (wpend && (!cpu_wr || a != wl_a)) begin
            cmt_a <= wl_a;
            cmt_d <= wl_d;
            cmt   <= 1'b1;
            wpend <= 1'b0;
        end
        if (cpu_wr) begin
            wl_a  <= a;
            wl_d  <= cpu_do;
            wpend <= 1'b1;
        end
    end
end

wire rd_ram = a[15:8] == 8'h00;
wire rd_pia = a[14:2] == 13'h0100;          // 0400-0403, mirrored at 8400
wire rd_rom = a[15];
wire wr_ram = cmt & (cmt_a[15:8] == 8'h00);
wire wr_pia = cmt & (cmt_a[14:2] == 13'h0100);

/////////////////////////////  RAM / ROM  /////////////////////////////

logic [7:0] ram_q, rom_q;

dpram_dc #(.widthad_a(8)) ram
(
    .clock_a(clk), .address_a(wr_ram ? cmt_a[7:0] : a[7:0]), .data_a(cmt_d), .wren_a(wr_ram), .q_a(ram_q),
    .clock_b(clk)
);

dpram_dc #(.widthad_a(15)) rom
(
    .clock_a(clk), .address_a(rom_wa), .data_a(rom_wd), .wren_a(rom_we),
    .clock_b(clk), .address_b(a[14:0]), .q_b(rom_q)
);

/////////////////////////////  MC6821  /////////////////////////////

logic [7:0] pia_do, pa_o, pa_oe;
logic       irqa, irqb;

pia6821 pia
(
    .clk(clk), .rst(reset),
    .ce(wr_pia | (cen & ~cpu_wr & rd_pia)),
    .cs(wr_pia | rd_pia), .rw(~wr_pia), .rs(wr_pia ? cmt_a[1:0] : a[1:0]), .din(cmt_d), .dout(pia_do),
    .irqa(irqa), .irqb(irqb),
    .pa_i(8'hFF), .pa_o(pa_o), .pa_oe(pa_oe), .ca1(1'b1), .ca2_i(1'b1), .ca2_o(), .ca2_oe(),
    .pb_i(cmd), .pb_o(), .pb_oe(), .cb1(cmd != 8'hFF), .cb2_i(1'b1), .cb2_o(), .cb2_oe()
);

assign irq = irqa | irqb;

always_comb begin
    if      (rd_ram) cpu_di = ram_q;
    else if (rd_pia) cpu_di = pia_do;
    else if (rd_rom) cpu_di = rom_q;
    else             cpu_di = 8'hFF;
end

/////////////////////////////  MC1408 DAC  /////////////////////////////

wire [7:0] dac = (pa_o & pa_oe) | ~pa_oe;
wire signed [15:0] dac_s = $signed({{3{~dac[7]}}, dac[6:0], 6'd0});   // unipolar DAC centred on 0x80, quarter scale:
                                                                    // a full swing from the idle level still fits after the DC block

// The amplifier is AC-coupled: the idle DAC level (FF) must not reach the output. One-pole DC block,
// tau = 2^17 crystal clocks (37 ms, ~4 Hz).
logic signed [31:0] dc = 32'sd0;
always_ff @(posedge clk)
    if (tick) dc <= dc + (($signed({dac_s, 16'd0}) - dc) >>> 17);

wire signed [15:0] dc_hi = dc[31:16];                              // part-selects are unsigned: name it signed
wire signed [16:0] ac    = dac_s - dc_hi;
assign audio = (ac > 17'sd32767) ? 16'sd32767 : (ac < -17'sd32768) ? -16'sd32768 : ac[15:0];

endmodule

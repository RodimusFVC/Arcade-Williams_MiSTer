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
//  Variant 0 (Defender, also Colony 7), 7 (Mayday), 8 (Jin): 0000-BFFF video RAM, C000-CFFF page selected by a write to D000-DFFF (D3-D0):
//    page 0 = I/O, pages 1-7 = banked ROM (stored at image 0000-6FFF), D000-FFFF ROM.
//  Page 0: C000-C3FF A4=0 colour RAM (A3-A0), A4=1 video control / watchdog (C3FC-C3FF, data 38 or 39),
//    C400-C7FF CMOS 256 x 4, C800-CBFF vertical count (VA13-8 on D7-D2), CC00 ROM board PIA, CC04 interface PIA.
//  Mayday: its protection check result is read from A190 / A191; MAME returns A193 / A194 (the expected values).
//  Jin: MAME widens the visible area to x 0-315.
//
//  Variants 1-6 (Stargate and the Special Chip boards, MAME main_map): writes to 0000-BFFF always reach video RAM;
//    reads of 0000-8FFF come from ROM while C900 D0 is set. C000-C3FF colour RAM, C804 interface PIA,
//    C80C ROM board PIA (C800-C8FF, A3-A2), C900 D0 ROM select / D1 cocktail / D2 SC window (Sinistar),
//    CA00-CA07 Special Chip (mirror CAFF), CB00 vertical count, CBFF watchdog, CC00-CFFF CMOS 1K x 4, D000-FFFF ROM
//    (Sinistar: D000-DFFF RAM).
//    1 Stargate (no SC)   2 Robotron   3 Joust (muxed panel)   4 Bubbles (8-bit CMOS)   5 Splat (SC2, muxed)
//    6 Sinistar (SC window at 7400, D000 RAM, 49-way stick)   9 PlayBall! (sound select D7-D6 driven by the PIA,
//    lines 8-239)   10 Alien Arena (muxed panel, CBFF writes ignored as in MAME)
//    11 Blaster (MAME blaster_main_map): 0000-3FFF ROM = bank (C980 D3-D0) of 16K, 4000-8FFF fixed ROM, C900-C93F select,
//       C940 SC remap table, C980 bank, C9C0 video control (D0 per-line colour 0, D1 per-line erase behind), SC window
//       at 9700. Per line y: BB00+y = colour 0 (inverted palette byte, ORed onto pen 0), BC00+y = control (D0 latch
//       colour 0, D1 erase each byte after it is shown). Muxed panel: CB2 low = 49-way stick (PA) + buttons (PB).
//       Sound select goes to two boards: left D6-D0 | 80, right D7 on D6, D5-D0, | 80.
//    18 Blaster kit (MAME blastkit): as 11, but CB2 high selects the 49-way stick on PA (low: IN3), PB is not muxed,
//       one sound board with the usual select (| C0).
//
//  Variants 12 Inferno, 13 Mystic Marathon (MAME williams2_state common_map): 0000-7FFF ROM bank while C800 D1-D0
//    != 0 (bank = D2-D1, page 3: D2, 0), 8000-87FF palette RAM in page 3, C000-C7FF tile RAM, C800 bank, C880 SC2
//    (window CBA0 D0, clip 9000), C900 watchdog (D5-D0 = 14), C980 ROM board PIA, C984 interface PIA, CB00 fg colour,
//    CB20 bg select, CB40 / CB60 scroll, CBE0 vertical count (8 bits), CC00 CMOS, D000-DFFF RAM, E000-FFFF ROM.
//    Interface PIA CA1 = /ENDSCREEN (low from line 254 to 7), CB1 = VA11; ROM board PIA CA1 = VA11, port B = data bus
//    to the sound board PIA port A, CB2 -> sound CA1, CB1 <- sound CA2. IRQ = ROM board PIA (Mystic Marathon:
//    + interface IRQB, interface IRQA -> FIRQ). Inferno: interface CA2 selects player 2 (INP2) on port A.
//    Background and palette: williams2_video.sv. Visible x 8-283, lines 8-247.
//    15 Speed Ball: C800-C803 read trackballs AN0-AN3 (P1 Y, P1 X, P2 Y, P2 X), third PIA at C808 (PA IN3, PB IN4).
//    19 Lotto Fun: ticket dispenser on interface PIA PB7 (motor on while low); its status line toggles every 70 ms
//       while the motor runs (MAME ticket_dispenser_device) and is read on IN0 D7.
//    16 Conquest: dial D3-D2 on IN0 D3-D2, D1-D0 on IN1 D1-D0 (MAME dial0_r / dial1_r; PORT_REVERSE, 1 step per 4 counts).
//    Sinistar / Blaster: an analog stick off centre replaces the MRA's digital 49-way value (s49).
//    14 Turkey Shoot: D000-DFFF ROM, both PIAs on IRQ, interface CA2 selects INP2; INP1 D5-D0 = gun Y, INP2 D5-D0 =
//    gun X, Gray coded (MAME gun_r: v ^ v >> 1; GUNX is the stick's Y axis), D7-D6 from the MRA map (Fire on INP1 D7).
//    20 Joust 2: as 14 without the gun: interface CA2 (LS157) selects INP1 / INP2 into PA D3-D0; ROM-board PIA
//       CA2 is the BG sound board strobe and PB its data (rtl/boards/williams_snd/williams_bg.sv).
//  Muxed panel (Joust, Splat): interface PIA CB2 selects player 1 (in0 / in1) or player 2 (in3 / in4) on PA / PB.
//
//============================================================================

module williams1_main
(
    input  logic        clk,            // 48 MHz
    input  logic        reset,
    input  logic        pause,
    input  logic  [7:0] variant,
    input  logic        no_wd_flag,     // MRA flag (bootlegs that never clear the watchdog)

    // MC6809E (rtl/williams_board.sv)
    output logic        fall_e,
    output logic        fall_q,
    output logic        cpu_rst,
    output logic        irq_n,
    output logic        firq_n,
    output logic  [7:0] cpu_di,
    input  logic [15:0] cpu_a,
    input  logic  [7:0] cpu_do,
    input  logic        cpu_rw,

    // program ROM image (64K)
    output logic [18:0] rom_a,          // williams_board.sv: 00000-0FFFF image by CPU address, 10000+ Blaster banks
    input  logic  [7:0] rom_d,

    input  logic  [9:0] nv_addr,        // CMOS second port: MiSTer NVRAM load / save
    input  logic  [7:0] nv_din,
    input  logic        nv_we,
    output logic  [7:0] nv_dout,

    input  logic  [7:0] in0,            // interface PIA port A
    input  logic  [7:0] in1,            // interface PIA port B
    input  logic  [7:0] in2,            // ROM board PIA port A (coin door)
    input  logic  [7:0] in3,            // muxed panel: player 2 PA
    input  logic  [7:0] in4,            // muxed panel: player 2 PB
    input  logic  [5:0] gun_x,          // Turkey Shoot gun position
    input  logic  [5:0] gun_y,
    input  logic [31:0] an,             // trackball counters {P2 X, P2 Y, P1 X, P1 Y}
    input  logic  [8:0] s49,            // analog 49-way {valid, X nibble, Y nibble}
    output logic  [7:0] snd_cmd,        // to the sound board PIA port B
    output logic  [7:0] snd_cmd_r,      // Blaster: right channel sound board
    // ROMPOOL-2026-10-27: original ports below; the Blaster SC remap PROM is now rom_remap in rtl/williams_board.sv
    // input  logic [10:0] remap_wa,       // Blaster SC remap PROM load
    // input  logic  [7:0] remap_wd,
    // input  logic        remap_we,
    output logic [10:0] remap_a_a,      // remap PROM read ports (rom_remap, port A / B)
    input  logic  [7:0] remap_a_q,
    output logic [10:0] remap_b_a,
    input  logic  [7:0] remap_b_q,
    output logic  [2:0] pc,             // clock within the pixel: the board's ROM pool slots
    output logic [15:0] tile_a,         // gen2 tile ROM (pool slot clk 1)
    output logic        bg_strobe,      // Joust 2: ROM-board PIA CA2 -> BG sound board
    input  logic  [7:0] tile_d,
    output logic  [7:0] s2_bus,         // gen2 sound data bus pins
    input  logic  [7:0] s2_pa_o,        // gen2 sound PIA port A
    input  logic  [7:0] s2_pa_oe,
    input  logic        s2_ca2,         // gen2 sound PIA CA2 -> ROM board PIA CB1
    output logic        s2_cb2,         // gen2 ROM board PIA CB2 -> sound PIA CA1

    input  logic        crt_flip,
    input  logic  [3:0] h_adj,
    input  logic  [3:0] v_adj,

    // CHIPPOOL-2026-10-27: shared PIA pool (rtl/williams_board.sv); slot 0 = interface PIA (IC1), 1 = ROM board PIA
    // (IC22), 2 = Speed Ball's third PIA (the slot is shared with other boards' PIAs in the dispatcher)
    output chip_pool_pkg::pia6821p_i_t [2:0] pia_i,
    input  chip_pool_pkg::pia6821p_o_t [2:0] pia_o,

    // RAMPOOL-2026-10-27: shared RAM pool blocks 0-6 (rtl/williams_board.sv): 0 video RAM low 32K, 1 video RAM high 16K,
    // 2 D000 RAM 4K, 3 gen2 tile RAM, 4 CMOS (port B = NVRAM), 5 / 6 gen2 palette RAM
    output ram_pool_pkg::pram_i_t [6:0] pr_i,
    input  ram_pool_pkg::pram_o_t [6:0] pr_o,

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
// The Special Chip halts the MPU while it owns the bus: the MPU's E / Q stop, the PIAs keep theirs.
logic sc_busy;
wire  e_run = ~pause_x | cpu_rst;
assign fall_q = (ph == 6'd35) & e_run & ~sc_busy;
assign fall_e = (ph == 6'd47) & e_run & ~sc_busy;
wire   pia_e  = (ph == 6'd47) & e_run;
assign ce_pix = (ph[2:0] == 3'd7);
assign pc     = ph[2:0];

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
// Frozen while paused. Off for Mayday and Jin (not Williams boards; Jin clears it twice in 20 frames, MAME models none).
wire no_wd = no_wd_flag || variant == 8'd7 || variant == 8'd8 || variant == 8'd10;
wire [8:0] y0 = gen2 ? 9'd8 : variant == 8'd9 ? 9'd8 : 9'd7;      // first / last visible line
wire [8:0] y1 = gen2 ? 9'd247 : variant == 8'd9 ? 9'd239 : 9'd246;
logic [3:0] wd_cnt = 4'd0;
logic       wd_kick;
always_ff @(posedge clk) begin
    if (reset || wd_kick || wd_cnt[3])
        wd_cnt <= 4'd0;
    else if (ph == 6'd47 && us == 6'd63 && vline == 9'd259 && !pause && !no_wd)
        wd_cnt <= wd_cnt + 4'd1;
end
assign cpu_rst = reset | wd_cnt[3];

/////////////////////////////  CPU decode  /////////////////////////////

wire defender = (variant == 8'd0 || variant == 8'd7 || variant == 8'd8);
wire mayday   = (variant == 8'd7);
wire jin      = (variant == 8'd8);
wire has_sc   = (variant >= 8'd2 && variant <= 8'd6) || (variant >= 8'd9 && variant <= 8'd11) || (variant >= 8'd15 && variant <= 8'd19);
wire lottofun = (variant == 8'd19);
wire spdball  = (variant == 8'd15);
wire conquest = (variant == 8'd16);
wire blaster  = (variant == 8'd11 || variant == 8'd18);
wire blastkit = (variant == 8'd18);
wire playball = (variant == 8'd9);
wire sc2      = (variant == 8'd5 || blaster);
wire muxed    = (variant == 8'd3 || variant == 8'd5 || variant == 8'd10 || blaster);
wire cmos8    = (variant == 8'd4);
wire sinistar = (variant == 8'd6 || variant == 8'd17);   // 17: cockpit (second sound board, rtl/williams_board.sv)
wire inferno  = (variant == 8'd12);
wire mysticm  = (variant == 8'd13);
wire tshoot   = (variant == 8'd14);
wire joust2   = (variant == 8'd20);
wire gen2     = (variant >= 8'd12 && variant <= 8'd14) || joust2;

// bus: the MPU, or the Special Chip while it is busy
logic [15:0] sc_a;
logic  [7:0] sc_do;
logic        sc_we;
wire  [15:0] ba  = sc_busy ? sc_a  : cpu_a;
wire   [7:0] bdo = sc_busy ? sc_do : cpu_do;
wire         wr  = sc_busy ? sc_we : (fall_e & ~cpu_rw & ~cpu_rst);

logic [3:0] page = 4'd0;                // Defender ROM page
logic       rom_sel = 1'b0;             // later boards: C900 D0
logic       sc_window = 1'b0;           // Sinistar, Blaster: C900 D2
logic [3:0] bl_bank = 4'd0;             // Blaster C980
logic [6:0] bl_remap = 7'd0;            // Blaster C940
logic [7:0] bl_vctl = 8'd0;             // Blaster C9C0
logic [7:0] w_bank = 8'd0;              // gen2 C800
logic       w_window = 1'b0;            // gen2 CBA0
logic [5:0] w_fg = 6'd0;                // gen2 CB00
logic [7:0] w_bg = 8'd0;                // gen2 CB20
logic [11:0] w_xs = 12'd0;              // gen2 CB40 / CB60

// Defender
wire  d_page = defender && ba[15:12] == 4'hC;
wire  d_io   = d_page && page == 4'd0;
wire  d_prom = d_page && page != 4'd0 && page < 4'd8;                // banked ROM pages 1-7
wire  d_col  = d_io && ba[11:10] == 2'd0 && !ba[4];                  // C000-C3FF, A4 = 0
wire  d_vctl = d_io && ba[11:10] == 2'd0 &&  ba[4];                  // C010-C3FF, A4 = 1
wire  d_cmos = d_io && ba[11:10] == 2'd1;                            // C400-C7FF
wire  d_vcnt = d_io && ba[11:10] == 2'd2;                            // C800-CBFF
wire  d_pia  = d_io && ba[11:10] == 2'd3 && ba[4:3] == 2'd0;         // CC00-CC07, A9-A5 not decoded

// later boards
wire  g_io   = !defender && !gen2 && ba[15:12] == 4'hC;
wire  g_col  = g_io && ba[11:10] == 2'd0;                            // C000-C3FF
wire  g_pia  = g_io && ba[11:8] == 4'h8 && ba[2];                    // C804 / C80C
wire  g_an   = g_io && ba[11:8] == 4'h8 && ba[3:2] == 2'd0 && spdball; // Speed Ball C800-C803
wire  g_pia3 = g_io && ba[11:8] == 4'h8 && ba[3:2] == 2'd2 && spdball; // Speed Ball C808
wire  g_vsel = g_io && ba[11:8] == 4'h9 && (!blaster || ba[7:6] == 2'd0);
wire  g_c9   = g_io && ba[11:8] == 4'h9 && blaster;                  // C940 / C980 / C9C0 (ba[7:6])
wire  g_sc   = g_io && ba[11:8] == 4'hA && has_sc;
wire  g_vcnt = g_io && ba[11:8] == 4'hB;
wire  g_cmos = g_io && ba[11:10] == 2'd3;                            // CC00-CFFF
wire  g_dram = (sinistar | inferno | mysticm) && ba[15:12] == 4'hD;  // D000-DFFF RAM
wire  g_rlo  = !defender && !gen2 && rom_sel && ba < 16'h9000;       // ROM over video RAM (reads)

// gen2
wire  w_io   = gen2 && ba[15:12] == 4'hC;
wire  w_tile = w_io && !ba[11];                                      // C000-C7FF
wire  w_bsel = w_io && ba[11:7] == 5'b10000;                         // C800-C87F
wire  w_sc   = w_io && ba[11:7] == 5'b10001;                         // C880-C8FF
wire  w_wd   = w_io && ba[11:7] == 5'b10010;                         // C900-C97F
wire  w_pia  = w_io && ba[11:7] == 5'b10011 && !ba[3];               // C980 / C984
wire  w_cb   = w_io && ba[11:8] == 4'hB;                             // CB00-CBFF (ba[7:5])
wire  w_vcnt = w_cb && ba[7:4] == 4'hE;                              // CBE0-CBEF
wire  w_cmos = w_io && ba[11:10] == 2'd3;
wire  w_rlo  = gen2 && w_bank[1:0] != 2'd0 && !ba[15];               // ROM bank over 0000-7FFF (reads)
wire  w_palv = gen2 && w_bank[1:0] == 2'd3 && ba[15:11] == 5'b10000; // palette RAM 8000-87FF
wire  [1:0] w_entry = (w_bank[1:0] == 2'd3) ? {w_bank[2], 1'b0} : w_bank[2:1];

wire  cs_vram = ba < 16'hC000 && !w_palv;
wire  cs_rom  = ba[15:12] >= 4'hD && !g_dram;
wire  cs_col  = d_col | g_col;
wire  cs_cmos = d_cmos | g_cmos | w_cmos;
wire  cs_vcnt = d_vcnt | g_vcnt | w_vcnt;
wire  cs_pia1 = !sc_busy && (defender ? d_pia && !ba[2] : gen2 ? w_pia && !ba[2] : g_pia &&  ba[3]);   // ROM board PIA
wire  cs_pia0 = !sc_busy && (defender ? d_pia &&  ba[2] : gen2 ? w_pia &&  ba[2] : g_pia && !ba[3]);   // interface board PIA

assign rom_a = d_prom                        ? {3'd0, page - 4'd1, ba[11:0]} :
               (blaster && g_rlo && ba[15:14] == 2'd0) ? {{1'b0, bl_bank} + 5'd4, ba[13:0]} :
               w_rlo                                    ? {{2'b00, w_entry} + 4'd2, ba[14:0]} : {3'd0, ba};

assign wd_kick = wr && (gen2 ? w_wd && bdo[5:0] == 6'h14 :
                      (defender ? d_vctl && ba[9:2] == 8'hFF : ba == 16'hCBFF) && bdo[7:1] == 7'h1C);

always_ff @(posedge clk) begin
    if (cpu_rst) begin
        page <= 4'd0;
        rom_sel <= 1'b0;
        sc_window <= 1'b0;
        bl_bank <= 4'd0;
        bl_vctl <= 8'd0;
        w_bank <= 8'd0;
        w_window <= 1'b0;
    end else begin
        if (wr && w_bsel) w_bank <= bdo;
        if (wr && w_cb) begin
            case (ba[7:5])
                3'd0: w_fg <= bdo[5:0];
                3'd1: w_bg <= bdo;
                3'd2: w_xs[3:0]  <= {bdo[7], bdo[2:0]};
                3'd3: w_xs[11:4] <= bdo;
                3'd5: w_window <= bdo[0];
                default: ;
            endcase
        end
        if (wr && defender && ba[15:12] == 4'hD)
            page <= bdo[3:0];
        if (wr && g_vsel) begin
            rom_sel   <= bdo[0];
            sc_window <= bdo[2] & (sinistar | blaster);
        end
        if (wr && g_c9) begin
            if (ba[7:6] == 2'd1) bl_remap <= bdo[6:0];
            if (ba[7:6] == 2'd2) bl_bank  <= bdo[3:0];
            if (ba[7:6] == 2'd3) bl_vctl  <= bdo;
        end
    end
end

/////////////////////////////  Video RAM  /////////////////////////////

// CPU on port A, video on port B. 48K used of 64K.
wire may_prot = mayday && !sc_busy && cpu_rw && ba[15:1] == 15'h50C8;  // A190-A191 reads
logic [7:0] vram_cpu_q, vram_q;
logic [8:0] fx;
logic [7:0] fy;
logic [15:0] vid_a;
logic        vid_we;
logic  [7:0] w2_pal_q, w2_tile_q;     // gen2 (williams2_video)
logic [23:0] w2_rgb;

// 48K as 32K (0000-7FFF) + 16K (8000-BFFF)
wire  [15:0] va_cpu = may_prot ? ba + 16'd3 : ba;
logic        vsel_a, vsel_b;
logic  [7:0] vlo_a, vhi_a, vlo_b, vhi_b;
always_ff @(posedge clk) begin vsel_a <= va_cpu[15]; vsel_b <= vid_a[15]; end
// RAMPOOL-2026-10-27: original instances below, now pool blocks 0 / 1
// dpram_dc #(.widthad_a(15)) vram_lo
// (
//     .clock_a(clk), .address_a(va_cpu[14:0]), .data_a(bdo), .wren_a(wr & cs_vram & ~va_cpu[15]), .q_a(vlo_a),
//     .clock_b(clk), .address_b(vid_a[14:0]), .data_b(8'h00), .wren_b(vid_we & ~vid_a[15]), .q_b(vlo_b)
// );
// dpram_dc #(.widthad_a(14)) vram_hi
// (
//     .clock_a(clk), .address_a(va_cpu[13:0]), .data_a(bdo), .wren_a(wr & cs_vram & va_cpu[15]), .q_a(vhi_a),
//     .clock_b(clk), .address_b(vid_a[13:0]), .data_b(8'h00), .wren_b(vid_we & vid_a[15]), .q_b(vhi_b)
// );
assign pr_i[0].a_addr = va_cpu[14:0];
assign pr_i[0].a_d    = bdo;
assign pr_i[0].a_we   = wr & cs_vram & ~va_cpu[15];
assign pr_i[0].b_addr = vid_a[14:0];
assign pr_i[0].b_d    = 8'h00;
assign pr_i[0].b_we   = vid_we & ~vid_a[15];
assign vlo_a = pr_o[0].a_q;
assign vlo_b = pr_o[0].b_q;
assign pr_i[1].a_addr = {1'b0, va_cpu[13:0]};
assign pr_i[1].a_d    = bdo;
assign pr_i[1].a_we   = wr & cs_vram & va_cpu[15];
assign pr_i[1].b_addr = {1'b0, vid_a[13:0]};
assign pr_i[1].b_d    = 8'h00;
assign pr_i[1].b_we   = vid_we & vid_a[15];
assign vhi_a = pr_o[1].a_q;
assign vhi_b = pr_o[1].b_q;
assign vram_cpu_q = vsel_a ? vhi_a : vlo_a;
assign vram_q     = vsel_b ? vhi_b : vlo_b;

/////////////////////////////  Colour RAM / CMOS  /////////////////////////////

logic [7:0] pal[16];
always_ff @(posedge clk)
    if (wr && cs_col) pal[ba[3:0]] <= bdo;

// 5101 (Defender, 256 x 4) / 5114 (1K x 4) CMOS, D3-D0 only: MAME stores data | F0 and reads the byte back.
// Bubbles has a second 5114 for the full 8 bits.
logic [7:0] cmos_q;
// RAMPOOL-2026-10-27: original instance below, now pool block 4 (port A = CPU, port B = NVRAM, same addresses)
// dpram_dc #(.widthad_a(10)) cmos_ram
// (
//     .clock_a(clk), .address_a(defender ? {2'b00, ba[7:0]} : ba[9:0]), .data_a(cmos8 ? bdo : bdo | 8'hF0),
//     .wren_a(wr & cs_cmos), .q_a(cmos_q),
//     .clock_b(clk), .address_b(nv_addr), .data_b(nv_din), .wren_b(nv_we), .q_b(nv_dout)
// );
assign pr_i[4].a_addr = {5'd0, defender ? {2'b00, ba[7:0]} : ba[9:0]};
assign pr_i[4].a_d    = cmos8 ? bdo : bdo | 8'hF0;
assign pr_i[4].a_we   = wr & cs_cmos;
assign pr_i[4].b_addr = {5'd0, nv_addr};
assign pr_i[4].b_d    = nv_din;
assign pr_i[4].b_we   = nv_we;
assign cmos_q  = pr_o[4].a_q;
assign nv_dout = pr_o[4].b_q;

// Sinistar: 4K static RAM at D000-DFFF
logic [7:0] dram_q;
// RAMPOOL-2026-10-27: original instance below, now pool block 2 (shared with the Joust 2 BG board RAM)
// dpram_dc #(.widthad_a(12)) d000_ram
// (
//     .clock_a(clk), .address_a(ba[11:0]), .data_a(bdo), .wren_a(wr & g_dram), .q_a(dram_q),
//     .clock_b(clk)
// );
assign pr_i[2].a_addr = {3'd0, ba[11:0]};
assign pr_i[2].a_d    = bdo;
assign pr_i[2].a_we   = wr & g_dram;
assign pr_i[2].b_addr = 15'd0;
assign pr_i[2].b_d    = 8'h00;
assign pr_i[2].b_we   = 1'b0;
assign dram_q = pr_o[2].a_q;

/////////////////////////////  Special Chip  /////////////////////////////

williams_sc sc
(
    .clk(clk), .rst(cpu_rst), .run(ph == 6'd0 && !pause_x),
    .reg_we(wr & (g_sc | w_sc) & ~sc_busy), .reg_a(cpu_a[2:0]), .reg_d(cpu_do),
    .size_xor((sc2 | gen2) ? 3'd0 : 3'd4), .clip_addr(sinistar ? 16'h7400 : blaster ? 16'h9700 : gen2 ? 16'h9000 : 16'hC000),
    .window(gen2 ? w_window : sc_window),
    // ROMPOOL-2026-10-27: original: .remap_wa(remap_wa), .remap_wd(remap_wd), .remap_we(remap_we)
    .remap_en(blaster), .remap_idx(bl_remap), .remap_a_a(remap_a_a), .remap_a_q(remap_a_q), .remap_b_a(remap_b_a), .remap_b_q(remap_b_q),
    .busy(sc_busy), .a(sc_a), .dout(sc_do), .we(sc_we), .din(cpu_di), .vram_q(vram_cpu_q)
);

/////////////////////////////  PIAs  /////////////////////////////

logic [7:0] pia0_do, pia1_do, pia1_pb, pia1_pb_oe, pia0_pb, pia0_pb_oe;
logic       pia1_irqa, pia1_irqb, pia0_irqa, pia0_irqb, pia0_cb2, pia0_cb2_oe, pia0_ca2, pia0_ca2_oe, pia1_cb2;
logic       pia1_ca2, pia1_ca2_oe;
assign bg_strobe = pia1_ca2_oe ? pia1_ca2 : 1'b1;

// muxed panel (LS257 IC3 / IC4): CB2 high = player 1, low = player 2. Inferno: CA2 high = player 2.
wire p2_sel = (muxed && pia0_cb2_oe && !pia0_cb2) || ((inferno | tshoot | joust2) && pia0_ca2_oe && pia0_ca2);
wire [3:0] dial = 4'd0 - an[13:10];                                  // Conquest: P1 X, reversed, / 4
wire [7:0] pa0_in = tshoot   ? (p2_sel ? {in3[7:6], gun_x ^ {1'b0, gun_x[5:1]}} : {in0[7:6], gun_y ^ {1'b0, gun_y[5:1]}}) :
                    conquest ? {in0[7:4], dial[3:2], in0[1:0]} :
                    joust2   ? {in0[7:4], p2_sel ? in3[3:0] : in0[3:0]} :
                    (s49[8] && (sinistar || (blaster && (p2_sel ^ blastkit)))) ? s49[7:0] :
                    lottofun ? {tk_status, in0[6:0]} :
                    p2_sel   ? in3 : in0;
wire [7:0] pb0_in = conquest ? {in1[7:2], dial[1:0]} : p2_sel ? in4 : in1;

// Lotto Fun ticket dispenser
wire        tk_motor = lottofun && pia0_pb_oe[7] && !pia0_pb[7];
logic       tk_on = 1'b0, tk_status = 1'b0;
logic [21:0] tk_cnt = 22'd0;                                        // 70 ms = 3,360,000 clocks
always_ff @(posedge clk) begin
    tk_on <= tk_motor;
    if (tk_motor && !tk_on) begin tk_status <= 1'b0; tk_cnt <= 22'd0; end
    else if (tk_motor && !pause_x) begin
        tk_cnt <= (tk_cnt == 22'd3_359_999) ? 22'd0 : tk_cnt + 22'd1;
        if (tk_cnt == 22'd3_359_999) tk_status <= ~tk_status;
    end
end

// gen2 /ENDSCREEN: low from line 254 to line 7
wire endscreen = !(vline >= 9'd254 || vline < 9'd8);

// gen2 sound data bus: whichever side drives, else pulled up
assign s2_bus = (pia1_pb & pia1_pb_oe) | (s2_pa_o & s2_pa_oe & ~pia1_pb_oe) | ~(pia1_pb_oe | s2_pa_oe);
assign s2_cb2 = pia1_cb2;

// IC1 interface board: player panel
// CHIPPOOL-2026-10-27: original instance below, now in the dispatcher (pia6821 pool slot 0)
// pia6821 pia0
// (
//     .clk(clk), .rst(cpu_rst), .ce(pia_e), .cs(cs_pia0), .rw(cpu_rw), .rs(cpu_a[1:0]), .din(cpu_do), .dout(pia0_do),
//     .irqa(pia0_irqa), .irqb(pia0_irqb),
//     .pa_i(pa0_in), .pa_pins(1'b0), .pa_o(), .pa_oe(), .ca1(gen2 ? endscreen : 1'b0), .ca2_i(1'b0),
//     .ca2_o(pia0_ca2), .ca2_oe(pia0_ca2_oe),
//     .pb_i(pb0_in), .pb_o(pia0_pb), .pb_oe(pia0_pb_oe), .cb1(gen2 ? va11 : 1'b0), .cb2_i(1'b0), .cb2_o(pia0_cb2), .cb2_oe(pia0_cb2_oe)
// );
assign pia_i[0].rst     = cpu_rst;
assign pia_i[0].ce      = pia_e;
assign pia_i[0].cs      = cs_pia0;
assign pia_i[0].rw      = cpu_rw;
assign pia_i[0].rs      = cpu_a[1:0];
assign pia_i[0].din     = cpu_do;
assign pia_i[0].pa_i    = pa0_in;
assign pia_i[0].pa_pins = 1'b0;
assign pia_i[0].ca1     = gen2 ? endscreen : 1'b0;
assign pia_i[0].ca2_i   = 1'b0;
assign pia_i[0].pb_i    = pb0_in;
assign pia_i[0].cb1     = gen2 ? va11 : 1'b0;
assign pia_i[0].cb2_i   = 1'b0;
assign pia0_do     = pia_o[0].dout;
assign pia0_irqa   = pia_o[0].irqa;
assign pia0_irqb   = pia_o[0].irqb;
assign pia0_ca2    = pia_o[0].ca2_o;
assign pia0_ca2_oe = pia_o[0].ca2_oe;
assign pia0_pb     = pia_o[0].pb_o;
assign pia0_pb_oe  = pia_o[0].pb_oe;
assign pia0_cb2    = pia_o[0].cb2_o;
assign pia0_cb2_oe = pia_o[0].cb2_oe;

// IC22 ROM board: coin door in, sound select out, COUNT 240 on CA1, VA11 on CB1
// CHIPPOOL-2026-10-27: original instance below, now in the dispatcher (pia6821 pool slot 1)
// pia6821 pia1
// (
//     .clk(clk), .rst(cpu_rst), .ce(pia_e), .cs(cs_pia1), .rw(cpu_rw), .rs(cpu_a[1:0]), .din(cpu_do), .dout(pia1_do),
//     .irqa(pia1_irqa), .irqb(pia1_irqb),
//     .pa_i(in2), .pa_pins(1'b0), .pa_o(), .pa_oe(), .ca1(gen2 ? va11 : count240), .ca2_i(1'b0), .ca2_o(pia1_ca2), .ca2_oe(pia1_ca2_oe),
//     .pb_i(gen2 ? s2_bus : 8'hFF), .pb_o(pia1_pb), .pb_oe(pia1_pb_oe), .cb1(gen2 ? s2_ca2 : va11), .cb2_i(1'b0),
//     .cb2_o(pia1_cb2), .cb2_oe()
// );
assign pia_i[1].rst     = cpu_rst;
assign pia_i[1].ce      = pia_e;
assign pia_i[1].cs      = cs_pia1;
assign pia_i[1].rw      = cpu_rw;
assign pia_i[1].rs      = cpu_a[1:0];
assign pia_i[1].din     = cpu_do;
assign pia_i[1].pa_i    = in2;
assign pia_i[1].pa_pins = 1'b0;
assign pia_i[1].ca1     = gen2 ? va11 : count240;
assign pia_i[1].ca2_i   = 1'b0;
assign pia_i[1].pb_i    = gen2 ? s2_bus : 8'hFF;
assign pia_i[1].cb1     = gen2 ? s2_ca2 : va11;
assign pia_i[1].cb2_i   = 1'b0;
assign pia1_do     = pia_o[1].dout;
assign pia1_irqa   = pia_o[1].irqa;
assign pia1_irqb   = pia_o[1].irqb;
assign pia1_ca2    = pia_o[1].ca2_o;
assign pia1_ca2_oe = pia_o[1].ca2_oe;
assign pia1_pb     = pia_o[1].pb_o;
assign pia1_pb_oe  = pia_o[1].pb_oe;
assign pia1_cb2    = pia_o[1].cb2_o;

// Speed Ball third PIA (C808): IN3 / IN4
logic [7:0] pia3_do;
// CHIPPOOL-2026-10-27: original instance below, now in the dispatcher (pia6821 pool slot 2, shared with the sound boards' PIAs)
// pia6821 pia3
// (
//     .clk(clk), .rst(cpu_rst), .ce(pia_e), .cs(!sc_busy && g_pia3), .rw(cpu_rw), .rs(cpu_a[1:0]), .din(cpu_do), .dout(pia3_do),
//     .irqa(), .irqb(),
//     .pa_i(in3), .pa_pins(1'b0), .pa_o(), .pa_oe(), .ca1(1'b0), .ca2_i(1'b0), .ca2_o(), .ca2_oe(),
//     .pb_i(in4), .pb_o(), .pb_oe(), .cb1(1'b0), .cb2_i(1'b0), .cb2_o(), .cb2_oe()
// );
assign pia_i[2].rst     = cpu_rst;
assign pia_i[2].ce      = pia_e;
assign pia_i[2].cs      = !sc_busy && g_pia3;
assign pia_i[2].rw      = cpu_rw;
assign pia_i[2].rs      = cpu_a[1:0];
assign pia_i[2].din     = cpu_do;
assign pia_i[2].pa_i    = in3;
assign pia_i[2].pa_pins = 1'b0;
assign pia_i[2].ca1     = 1'b0;
assign pia_i[2].ca2_i   = 1'b0;
assign pia_i[2].pb_i    = in4;
assign pia_i[2].cb1     = 1'b0;
assign pia_i[2].cb2_i   = 1'b0;
assign pia3_do = pia_o[2].dout;

assign irq_n  = ~(pia1_irqa | pia1_irqb | (mysticm & pia0_irqb) | (tshoot & (pia0_irqa | pia0_irqb)));
assign firq_n = ~(mysticm & pia0_irqa);

// sound select lines are pulled up on the sound board; MAME: the top two are set externally (PlayBall! drives them)
wire [7:0] pb_pins = (pia1_pb & pia1_pb_oe) | ~pia1_pb_oe;
assign snd_cmd   = (blaster && !blastkit) ? pb_pins | 8'h80 : pb_pins | (playball ? 8'h00 : 8'hC0);
assign snd_cmd_r = {1'b1, pb_pins[7], pb_pins[5:0]};

/////////////////////////////  CPU read mux  /////////////////////////////

always_comb begin
    if      (g_rlo)   cpu_di = rom_d;
    else if (w_rlo)   cpu_di = rom_d;
    else if (w_palv)  cpu_di = w2_pal_q;
    else if (cs_vram) cpu_di = vram_cpu_q;
    else if (cs_rom)  cpu_di = rom_d;
    else if (d_prom)  cpu_di = rom_d;
    else if (w_tile)  cpu_di = w2_tile_q;
    else if (g_dram)  cpu_di = dram_q;
    else if (cs_cmos) cpu_di = cmos_q;
    else if (cs_vcnt) cpu_di = gen2 ? vline[7:0] : {va_line[7:2], 2'b00};
    else if (g_an)    cpu_di = an[{ba[1:0], 3'b000} +: 8];
    else if (g_pia3)  cpu_di = pia3_do;
    else if (cs_pia1) cpu_di = pia1_do;
    else if (cs_pia0) cpu_di = pia0_do;
    else              cpu_di = 8'h00;
end

/////////////////////////////  Video out  /////////////////////////////

// MAME visible area: Defender x 12-303, later boards x 6-297; lines 7-246
wire [8:0] x0 = jin ? 9'd0   : defender ? 9'd12  : gen2 ? 9'd8   : 9'd6;
wire [8:0] x1 = jin ? 9'd315 : defender ? 9'd303 : gen2 ? 9'd283 : 9'd297;

// CRT Flip: read the window back from the opposite corner (the cocktail PROMs do the same on the real board)
assign fx = crt_flip ? (x0 + x1 - hpix) : hpix;
wire [7:0] yy = y0[7:0] + y1[7:0];
assign fy = crt_flip ? (yy - va_line) : va_line;

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

function automatic [23:0] pen(input [7:0] c);
    pen = {lv_rg(c[2:0]), lv_rg(c[5:3]), lv_b(c[7:6])};
endfunction

// Each byte is read once, at its first pixel (the even one, or the odd one under CRT Flip), and held for the second
wire       first_px = (fx[0] == crt_flip);
logic [7:0] vbyte_l;
wire  [7:0] vbyte = first_px ? vram_q : vbyte_l;
always_ff @(posedge clk) if (ce_pix && first_px) vbyte_l <= vram_q;

wire [3:0] nib = fx[0] ? vbyte[3:0] : vbyte[7:4];
wire [7:0] col = pal[nib];

// Blaster per-line colour 0 / erase behind (MAME blaster_state::screen_update), read in the first microsecond of a line
logic  [7:0] p0_base, p0_line, sctl;
logic [23:0] color0 = 24'd0;
logic        erase = 1'b0;
wire  line_rd = blaster && us == 6'd0;
always_comb begin
    vid_a = {fx[8:1], fy};
    if (line_rd)
        vid_a = (ph < 6'd3) ? 16'hBB00 : (ph < 6'd6) ? {8'hBB, fy} : {8'hBC, fy};
end
always_ff @(posedge clk) begin
    if (line_rd) begin
        if (ph == 6'd2) p0_base <= vram_q;
        if (ph == 6'd5) p0_line <= vram_q;
        if (ph == 6'd8) sctl    <= vram_q;
        if (ph == 6'd9) begin
            if (bl_vctl[0] & sctl[0])                  color0 <= pen(~p0_line);
            else if (vline == 9'd7 || !bl_vctl[0])     color0 <= pen(~p0_base);
            erase <= bl_vctl[1] & sctl[1];
        end
    end
end
assign vid_we = blaster && erase && !first_px && ph[2:0] == 3'd3 && !line_rd &&
                vline >= 9'd7 && vline <= 9'd246 && hpix >= x0 && hpix <= x1;

williams2_video w2_video
(
    .clk(clk), .pc(ph[2:0]), .mysticm(mysticm), .joust2(joust2),
    .fx(fx), .fy(fy), .fg_pix(nib),
    .fg_color(w_fg), .bg_sel(w_bg), .xscroll(w_xs),
    .cpu_a(ba[10:0]), .cpu_d(bdo), .tile_we(wr & w_tile), .pal_we(wr & w_palv), .tile_q(w2_tile_q), .pal_q(w2_pal_q),
    .rom_a(tile_a), .rom_q(tile_d),
    .rgb(w2_rgb),
    .tile_pr_i(pr_i[3]), .tile_pr_o(pr_o[3]), .pal_lo_pr_i(pr_i[5]), .pal_lo_pr_o(pr_o[5]),
    .pal_hi_pr_i(pr_i[6]), .pal_hi_pr_o(pr_o[6])
);

wire [23:0] rgb = gen2 ? w2_rgb : (blaster && nib == 4'd0) ? (color0 | pen(pal[0])) : pen(col);

wire [8:0] hs_beg = 9'd336 + {{5{h_adj[3]}}, h_adj};
wire [8:0] vs_beg = 9'd248 + {{5{v_adj[3]}}, v_adj};

always_ff @(posedge clk) begin
    if (ce_pix) begin
        video_r      <= rgb[23:16];
        video_g      <= rgb[15:8];
        video_b      <= rgb[7:0];
        video_hblank <= (hpix < x0) || (hpix > x1);
        video_vblank <= (vline < y0) || (vline > y1);
        video_hs     <= (hpix >= hs_beg) && (hpix < hs_beg + 9'd24);
        video_vs     <= (vline >= vs_beg) && (vline < vs_beg + 9'd12);
    end
end

endmodule

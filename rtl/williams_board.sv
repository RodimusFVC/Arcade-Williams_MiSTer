//============================================================================
//
//  Williams 6809 raster hardware — board top
//  Copyright (C) 2026 Rodimus
//
//  Owns the shared parts: the CPU / sound chip pool (chip_pool_pkg: MC6809Es, MC6808s, PIAs, HC-55516, YM2151), the ROM
//  pool, the board RAM pool (ram_pool_pkg) and the remap PROM; the boards (CPU / video, sound, BG) drive them through bus ports.
//  Pool contract: rtl/boards/board_template.sv; the harness (POOL_MODS) rejects a board that instances its own.
//
//  Variant (MRA index 1 byte 0), all on rtl/boards/williams1 (list in williams1_main.sv):
//    0 Defender (paged ROM at C000, also Colony 7)   1 Stargate   2 Robotron   3 Joust   4 Bubbles   5 Splat
//    6 Sinistar   7 Mayday   8 Jin   9 PlayBall!   10 Alien Arena   11 Blaster (second sound board: right channel)
//    18 Blaster kit (mono)   17 Sinistar cockpit (second sound board: rear speaker on the right channel, same commands)
//    12 Inferno   13 Mystic Marathon   14 Turkey Shoot (second generation: tile background, sound board in gen2 mode)
//    15 Speed Ball (trackballs)   16 Conquest (dial)   19 Lotto Fun (ticket dispenser)
//    20 Joust 2 (gen2 + D-11298 BG sound board: rtl/boards/williams_snd/williams_bg.sv)
//
//  ioctl index 0 (MRA): the ROM pool image (packed in 4K pages by tools/make_mra.py; pool 00000-38FFF and
//    40000-4FFFF, rtl/ram_rom/rom_pool.sv), then at 0x50000 Blaster's SC remap PROM (blaster.col, 2K).
//  ROM map (MRA index 1 bytes 148-184, rom_map): 16 main-CPU pages (pool page of CPU 0000-FFFF in 4K steps; for
//    Defender pages 0-6 are the C000 window pages 1-7), 8 sound pages (sound CPU 8000-FFFF), bank base (Blaster /
//    gen2 banks: logical 10000+ from williams1_main), tile base (gen2 tile ROM), 8 sound pages for sound board 2,
//    then Joust 2's BG sound ROM bases U4 / U19 / U20 (32K each). Pages are 7 bits; FF = no ROM (reads 0).
//  Pool port B = main bus (MPU / SC). Port A = ioctl load during reset, then shared in the 8-clock pixel: clk 0 / 4
//    sound board 1, 2 / 6 sound board 2 (Blaster) or the BG board (Joust 2), 1 gen2 tile fetch; each sound CPU
//    reads its latched byte.
//  ioctl index 4: CMOS (MRA <nvram>): Defender 256 bytes, later boards 1024
//
//============================================================================

module williams_board
(
    input  logic        clk,            // 48 MHz
    input  logic        reset,
    input  logic        pause,
    input  logic  [7:0] variant,
    input  logic        no_wd,          // MRA flag: no watchdog
    input  logic        swap07,         // MRA flag: main ROM D0 / D7 swapped (MAME init_defndjeu), decoded on read
    input  logic        snd312,         // MRA flag: sound board crystal 3.12 MHz (MAME nextcent)
    output logic        ce_pix,

    input  logic  [7:0] in0,
    input  logic  [7:0] in1,
    input  logic  [7:0] in2,
    input  logic  [7:0] in3,
    input  logic  [7:0] in4,
    input  logic  [5:0] gun_x,          // Turkey Shoot
    input  logic  [5:0] gun_y,
    input  logic [31:0] an,             // trackball counters {P2 X, P2 Y, P1 X, P1 Y} (Speed Ball, Conquest)
    input  logic  [8:0] s49,            // analog 49-way stick {valid, X, Y} (Sinistar, Blaster)

    input  logic [24:0] ioctl_addr,
    input  logic  [7:0] ioctl_dout,
    input  logic        ioctl_wr0,
    input  logic [295:0] rom_map,       // MRA index 1 bytes 148-184, byte 148 in [7:0]

    input  logic  [9:0] nv_addr,        // CMOS second port (MiSTer NVRAM load / save)
    input  logic  [7:0] nv_din,
    input  logic        nv_we,
    output logic  [7:0] nv_dout,

    input  logic        crt_flip,
    input  logic  [3:0] h_adj,
    input  logic  [3:0] v_adj,

    output logic  [7:0] video_r,
    output logic  [7:0] video_g,
    output logic  [7:0] video_b,
    output logic        video_hs,
    output logic        video_vs,
    output logic        video_hblank,
    output logic        video_vblank,

    output logic signed [15:0] audio,
    output logic signed [15:0] audio_r,

    // UPDCTL-2026-10-25: main CPU write snoop for the top level's Updated Controls (williams_updctl.sv): ship facing
    output logic [15:0] cpu_wa,
    output logic  [7:0] cpu_wd,
    output logic        cpu_we          // one clock per CPU bus write (the same strobe williams1_main writes with)
);

/////////////////////////////  ROM pool  /////////////////////////////

wire [7:0] map_b[37];
genvar gi;
generate for (gi = 0; gi < 37; gi++) begin : mapb assign map_b[gi] = rom_map[gi*8 +: 8]; end endgenerate
wire [7:0] bank_base = map_b[24];
wire [7:0] tile_base = map_b[25];

// main bus: logical address from williams1_main (00000-0FFFF CPU image, 10000+ banks)
logic [18:0] rom_a;
logic  [7:0] rom_d, pool_qb;
wire  [7:0] mpage = map_b[{2'b00, rom_a[15:12]}];
wire [18:0] bank_off = rom_a - 19'h10000;
wire [18:0] main_pa  = rom_a[18:16] == 3'd0 ? {mpage[6:0], rom_a[11:0]} : {bank_base[6:0], 12'd0} + bank_off;
wire        main_ok  = rom_a[18:16] == 3'd0 ? mpage != 8'hFF : !rom_a[18];
logic       main_ok_r;
always_ff @(posedge clk) main_ok_r <= main_ok;
assign rom_d = !main_ok_r ? 8'h00 : swap07 ? {pool_qb[0], pool_qb[6:1], pool_qb[7]} : pool_qb;

// port A readers
logic [15:0] snd1_a, snd2_a;
logic [15:0] tile_a;
logic  [2:0] pc;
logic  [7:0] pool_qa, snd1_d, snd2_d;
logic  [1:0] bg_sel;
logic [14:0] bg_a;
wire        joust2 = (variant == 8'd20);
wire  [7:0] s1page = map_b[{3'b010, snd1_a[14:12]}], s2page = map_b[6'd26 + {3'b000, snd2_a[14:12]}];
wire  [7:0] bgbase = bg_sel == 2'd3 ? 8'hFF : map_b[6'd34 + {4'd0, bg_sel}];   // bank 3: open bus (reads 0)
wire  [18:0] s1_pa = {s1page[6:0], snd1_a[11:0]}, s2_pa = {s2page[6:0], snd2_a[11:0]};
wire  [18:0] t_pa  = {tile_base[6:0], 12'd0} + {3'd0, tile_a};
wire  [18:0] bg_pa = {bgbase[6:0], 12'd0} + {4'd0, bg_a};
logic [18:0] a_addr;
always_comb begin
    if (reset)                        a_addr = ioctl_addr[18:0];
    else if (pc == 3'd1)              a_addr = t_pa;
    else if (pc == 3'd2 || pc == 3'd6) a_addr = joust2 ? bg_pa : s2_pa;
    else                              a_addr = s1_pa;
end

rom_pool pool
(
    .clk(clk),
    .a_addr(a_addr), .a_din(ioctl_dout), .a_we(ioctl_wr0 && (ioctl_addr < 25'h39000 || ioctl_addr[24:16] == 9'h004)),
    .a_q(pool_qa),
    .b_addr(main_pa), .b_q(pool_qb)
);

// latch each sound CPU's byte the clock after its slot (8000-FFFF only; FF pages read 0)
logic s1_ok, s2_ok;
always_ff @(posedge clk) begin
    if (pc == 3'd0 || pc == 3'd4) s1_ok <= s1page != 8'hFF && snd1_a[15];
    if (pc == 3'd2 || pc == 3'd6) s2_ok <= joust2 ? bg_sel != 2'd3 && bgbase != 8'hFF : s2page != 8'hFF && snd2_a[15];
    if (pc == 3'd1 || pc == 3'd5) snd1_d <= s1_ok ? pool_qa : 8'h00;
    if (pc == 3'd3 || pc == 3'd7) snd2_d <= s2_ok ? pool_qa : 8'h00;
end

/////////////////////////////  Shared CPU / sound chip pool  /////////////////////////////
// CHIPPOOL-2026-10-27: chip_pool_pkg buses. Every CPU / sound chip exists once, here; the boards drive and read the
// buses (williams1_main: main CPU signals + PIA slots 0-2; williams_sndbd, williams_bg: their own slots).
//   m6809r_0: main MC6809E                      m6809r_1: Joust 2 BG board MC68B09E
//   m6800_0:  sound board MC6808                m6800_1:  second sound board MC6808 (Blaster, Sinistar cockpit)
//   pia6821[0]: interface board PIA (IC1)       pia6821[1]: ROM board PIA (IC22)
//   pia6821[2]: Speed Ball third PIA | second sound board PIA (Blaster, cockpit) | Joust 2 BG board PIA
//   pia6821[3]: sound board PIA
//   hc55516_0:  sound board CVSD decoder (Sinistar, PlayBall!, cockpit, Joust 2 BG board clock / digit; the second
//               sound board's decoder was always held in reset, so it has no slot)
//   jt51_0:     Joust 2 BG board YM2151
wire blaster = (variant == 8'd11);
wire cockpit = (variant == 8'd17);

// Main MC6809E
logic [15:0] cpu_a;
logic  [7:0] cpu_do, cpu_di;
logic        cpu_rw, fall_e, fall_q, cpu_rst, irq_n, firq_n;

chip_pool_pkg::m6809r_i_t m6809r_0_i, m6809r_1_i;
chip_pool_pkg::m6809r_o_t m6809r_0_o, m6809r_1_o;
assign m6809r_0_i.reset_n = ~cpu_rst;
assign m6809r_0_i.fall_e  = fall_e;
assign m6809r_0_i.fall_q  = fall_q;
assign m6809r_0_i.irq_n   = irq_n;
assign m6809r_0_i.firq_n  = firq_n;
assign m6809r_0_i.nmi_n   = 1'b1;
assign m6809r_0_i.d       = cpu_di;
assign cpu_a  = m6809r_0_o.a;
assign cpu_do = m6809r_0_o.dout;
assign cpu_rw = m6809r_0_o.rw;

// CHIPPOOL-2026-10-27: original instance below (was main_cpu)
// mc6809is main_cpu
// (
//     .CLK(clk), .fallE_en(fall_e), .fallQ_en(fall_q), .D(cpu_di), .DOut(cpu_do), .ADDR(cpu_a),
//     .RnW(cpu_rw), .BS(), .BA(), .nIRQ(irq_n), .nFIRQ(firq_n), .nNMI(1'b1), .AVMA(), .BUSY(),
//     .LIC(), .nHALT(1'b1), .nRESET(~cpu_rst), .nDMABREQ(1'b1), .RegData()
// );
mc6809is m6809r_0
(
    .CLK(clk), .fallE_en(m6809r_0_i.fall_e), .fallQ_en(m6809r_0_i.fall_q), .D(m6809r_0_i.d), .DOut(m6809r_0_o.dout),
    .ADDR(m6809r_0_o.a), .RnW(m6809r_0_o.rw), .BS(), .BA(), .nIRQ(m6809r_0_i.irq_n), .nFIRQ(m6809r_0_i.firq_n),
    .nNMI(m6809r_0_i.nmi_n), .AVMA(), .BUSY(), .LIC(m6809r_0_o.lic), .nHALT(1'b1), .nRESET(m6809r_0_i.reset_n),
    .nDMABREQ(1'b1), .RegData()
);

// Joust 2 BG board MC68B09E (williams_bg drives m6809r_1_i)
mc6809is m6809r_1
(
    .CLK(clk), .fallE_en(m6809r_1_i.fall_e), .fallQ_en(m6809r_1_i.fall_q), .D(m6809r_1_i.d), .DOut(m6809r_1_o.dout),
    .ADDR(m6809r_1_o.a), .RnW(m6809r_1_o.rw), .BS(), .BA(), .nIRQ(m6809r_1_i.irq_n), .nFIRQ(m6809r_1_i.firq_n),
    .nNMI(m6809r_1_i.nmi_n), .AVMA(), .BUSY(), .LIC(m6809r_1_o.lic), .nHALT(1'b1), .nRESET(m6809r_1_i.reset_n),
    .nDMABREQ(1'b1), .RegData()
);

// Sound board MC6808s (jt680x, 6802 microcode)
chip_pool_pkg::m6800_i_t m6800_0_i, m6800_1_i;
chip_pool_pkg::m6800_o_t m6800_0_o, m6800_1_o;
jt680x m6800_0
(
    .rst(m6800_0_i.rst), .clk(clk), .cen(m6800_0_i.cen), .wr(m6800_0_o.wr), .addr(m6800_0_o.a), .din(m6800_0_i.din),
    .dout(m6800_0_o.dout), .ext_halt(1'b0), .ba(), .irq(m6800_0_i.irq), .nmi(m6800_0_i.nmi),
    .irq_icf(1'b0), .irq_ocf(1'b0), .irq_tof(1'b0), .irq_sci(1'b0), .irq_cmf(1'b0), .irq2(1'b0)
);
jt680x m6800_1
(
    .rst(m6800_1_i.rst), .clk(clk), .cen(m6800_1_i.cen), .wr(m6800_1_o.wr), .addr(m6800_1_o.a), .din(m6800_1_i.din),
    .dout(m6800_1_o.dout), .ext_halt(1'b0), .ba(), .irq(m6800_1_i.irq), .nmi(m6800_1_i.nmi),
    .irq_icf(1'b0), .irq_ocf(1'b0), .irq_tof(1'b0), .irq_sci(1'b0), .irq_cmf(1'b0), .irq2(1'b0)
);

// MC6821 PIAs: slots 0 / 1 main board, 2 shared by variant, 3 sound board (variants never overlap on slot 2)
chip_pool_pkg::pia6821p_i_t [2:0] m_pia_i;
chip_pool_pkg::pia6821p_o_t [2:0] m_pia_o;
chip_pool_pkg::pia6821p_i_t       snd1_pia_i, snd2_pia_i, bg_pia_i;
chip_pool_pkg::pia6821p_o_t       snd1_pia_o, snd2_pia_o, bg_pia_o;
chip_pool_pkg::pia6821p_i_t [3:0] pia6821_i;
chip_pool_pkg::pia6821p_o_t [3:0] pia6821_o;
assign pia6821_i[0] = m_pia_i[0];
assign pia6821_i[1] = m_pia_i[1];
assign pia6821_i[2] = joust2 ? bg_pia_i : (blaster | cockpit) ? snd2_pia_i : m_pia_i[2];
assign pia6821_i[3] = snd1_pia_i;
assign m_pia_o    = pia6821_o[2:0];
assign snd2_pia_o = pia6821_o[2];
assign bg_pia_o   = pia6821_o[2];
assign snd1_pia_o = pia6821_o[3];

genvar pi;
generate
    for (pi = 0; pi < 4; pi++) begin : g_pia6821
        pia6821 u
        (
            .clk(clk), .rst(pia6821_i[pi].rst), .ce(pia6821_i[pi].ce), .cs(pia6821_i[pi].cs), .rw(pia6821_i[pi].rw),
            .rs(pia6821_i[pi].rs), .din(pia6821_i[pi].din), .dout(pia6821_o[pi].dout),
            .irqa(pia6821_o[pi].irqa), .irqb(pia6821_o[pi].irqb),
            .pa_i(pia6821_i[pi].pa_i), .pa_pins(pia6821_i[pi].pa_pins), .pa_o(pia6821_o[pi].pa_o), .pa_oe(pia6821_o[pi].pa_oe),
            .ca1(pia6821_i[pi].ca1), .ca2_i(pia6821_i[pi].ca2_i), .ca2_o(pia6821_o[pi].ca2_o), .ca2_oe(pia6821_o[pi].ca2_oe),
            .pb_i(pia6821_i[pi].pb_i), .pb_o(pia6821_o[pi].pb_o), .pb_oe(pia6821_o[pi].pb_oe),
            .cb1(pia6821_i[pi].cb1), .cb2_i(pia6821_i[pi].cb2_i), .cb2_o(pia6821_o[pi].cb2_o), .cb2_oe(pia6821_o[pi].cb2_oe)
        );
    end
endgenerate

// HC-55516 CVSD decoder
chip_pool_pkg::hc55516_i_t hc55516_0_i, snd2_hc_i;
chip_pool_pkg::hc55516_o_t hc55516_0_o, snd2_hc_o;
logic signed [15:0] hc55516_0_out;
hc55516 hc55516_0
(
    .clk(clk), .rst(hc55516_0_i.rst), .cvsd_clk(hc55516_0_i.cvsd_clk), .digit(hc55516_0_i.digit), .out(hc55516_0_out)
);
assign hc55516_0_o.out = hc55516_0_out;
assign snd2_hc_o       = '0;                      // the second sound board never has speech (its speech input is tied 0)

// Joust 2 BG board YM2151 (jotego jt51)
chip_pool_pkg::jt51_i_t jt51_0_i;
chip_pool_pkg::jt51_o_t jt51_0_o;
logic signed [15:0] jt51_0_l, jt51_0_r;
jt51 jt51_0
(
    .rst(jt51_0_i.rst), .clk(clk), .cen(jt51_0_i.cen), .cen_p1(jt51_0_i.cen_p1),
    .cs_n(jt51_0_i.cs_n), .wr_n(jt51_0_i.wr_n), .a0(jt51_0_i.a0), .din(jt51_0_i.din), .dout(jt51_0_o.dout),
    .ct1(), .ct2(), .irq_n(jt51_0_o.irq_n), .sample(), .left(jt51_0_l), .right(jt51_0_r), .xleft(), .xright()
);
assign jt51_0_o.left  = jt51_0_l;
assign jt51_0_o.right = jt51_0_r;

/////////////////////////////  Shared ROM blocks  /////////////////////////////
// ROMPOOL-2026-10-27: Blaster's SC remap PROM (blaster.col, 2K, index 0 at 0x50000), read by williams_sc on both ports
// (hi / lo nibble table entries) and loaded from the ioctl stream; the load decode does not depend on the variant.
logic [10:0] rm_a_a, rm_b_a;
logic  [7:0] rm_a_q, rm_b_q;
wire         remap_we = ioctl_wr0 && ioctl_addr[24:11] == 14'h00A0;
dpram_dc #(.widthad_a(11)) rom_remap
(
    .clock_a(clk), .address_a(remap_we ? ioctl_addr[10:0] : rm_a_a), .data_a(ioctl_dout), .wren_a(remap_we), .q_a(rm_a_q),
    .clock_b(clk), .address_b(rm_b_a), .q_b(rm_b_q)
);

/////////////////////////////  Shared RAM pool  /////////////////////////////
// RAMPOOL-2026-10-27: board RAMs in eight true dual-port blocks (rtl/ram_pool_pkg.sv; two read / write ports each, one
// clock to q as dpram_dc), each sized to its largest user; the owner is picked by variant. williams1_main (with
// williams_sc / williams2_video) drives blocks 0-6, the sound boards 7 / 5, the Joust 2 BG board 2.
//   block 0, 32K: video RAM 0000-7FFF
//   block 1, 16K: video RAM 8000-BFFF
//   block 2,  4K: D000-DFFF RAM (Sinistar, Inferno, Mystic Marathon) | Joust 2 BG board RAM 2K
//   block 3,  2K: gen2 background tile RAM
//   block 4,  1K: CMOS (port B = NVRAM load / save, same address as the CPU side)
//   block 5,  1K: gen2 palette RAM even bytes | second sound board RAM 256 (Blaster, Sinistar cockpit)
//   block 6,  1K: gen2 palette RAM odd bytes
//   block 7, 256: sound board RAM
// Remap PROM (Blaster): ROM block rom_remap below (ioctl load). The 16-entry colour RAM (pal[]) is flip-flops in
// williams1_main, not a RAM block.
localparam RAM_BLOCKS = 8;
ram_pool_pkg::pram_i_t [6:0] m_pr_i;
ram_pool_pkg::pram_o_t [6:0] m_pr_o;
ram_pool_pkg::pram_i_t       snd1_pr_i, snd2_pr_i, bg_pr_i;
ram_pool_pkg::pram_o_t       snd1_pr_o, snd2_pr_o, bg_pr_o;
ram_pool_pkg::pram_i_t [RAM_BLOCKS-1:0] pool_i;
ram_pool_pkg::pram_o_t [RAM_BLOCKS-1:0] pool_o;

assign pool_i[0] = m_pr_i[0];
assign pool_i[1] = m_pr_i[1];
assign pool_i[2] = joust2 ? bg_pr_i : m_pr_i[2];
assign pool_i[3] = m_pr_i[3];
assign pool_i[4] = m_pr_i[4];
assign pool_i[5] = (blaster | cockpit) ? snd2_pr_i : m_pr_i[5];
assign pool_i[6] = m_pr_i[6];
assign pool_i[7] = snd1_pr_i;
assign m_pr_o    = pool_o[6:0];
assign bg_pr_o   = pool_o[2];
assign snd2_pr_o = pool_o[5];
assign snd1_pr_o = pool_o[7];

genvar rp;
generate
    for (rp = 0; rp < RAM_BLOCKS; rp++) begin : rpool
        localparam int AW = (rp == 0) ? 15 : (rp == 1) ? 14 : (rp == 2) ? 12 : (rp == 3) ? 11 : (rp == 7) ? 8 : 10;
        dpram_dc #(.widthad_a(AW)) ram
        (
            .clock_a(clk), .address_a(pool_i[rp].a_addr[AW-1:0]), .data_a(pool_i[rp].a_d), .wren_a(pool_i[rp].a_we),
            .q_a(pool_o[rp].a_q),
            .clock_b(clk), .address_b(pool_i[rp].b_addr[AW-1:0]), .data_b(pool_i[rp].b_d), .wren_b(pool_i[rp].b_we),
            .q_b(pool_o[rp].b_q)
        );
    end
endgenerate

/////////////////////////////  CPU / video board  /////////////////////////////

logic [7:0] snd_cmd, snd_cmd_r, s2_bus, s2_pa_o, s2_pa_oe;
logic       s2_ca2, s2_cb2, bg_strobe;
wire        gen2 = (variant >= 8'd12 && variant <= 8'd14) || joust2;

williams1_main main_b
(
    .clk(clk), .reset(reset), .pause(pause), .variant(variant), .no_wd_flag(no_wd),
    .fall_e(fall_e), .fall_q(fall_q), .cpu_rst(cpu_rst), .irq_n(irq_n), .firq_n(firq_n),
    .cpu_di(cpu_di), .cpu_a(cpu_a), .cpu_do(cpu_do), .cpu_rw(cpu_rw),
    .rom_a(rom_a), .rom_d(rom_d), .pc(pc), .tile_a(tile_a), .tile_d(pool_qa), .bg_strobe(bg_strobe),
    .nv_addr(nv_addr), .nv_din(nv_din), .nv_we(nv_we), .nv_dout(nv_dout),
    .in0(in0), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .gun_x(gun_x), .gun_y(gun_y), .an(an), .s49(s49),
    .snd_cmd(snd_cmd), .snd_cmd_r(snd_cmd_r),
    // ROMPOOL-2026-10-27: original: .remap_wa(ioctl_addr[10:0]), .remap_wd(ioctl_dout), .remap_we(ioctl_wr0 && ioctl_addr[24:11] == 14'h00A0)
    .remap_a_a(rm_a_a), .remap_a_q(rm_a_q), .remap_b_a(rm_b_a), .remap_b_q(rm_b_q),
    .s2_bus(s2_bus), .s2_pa_o(s2_pa_o), .s2_pa_oe(s2_pa_oe), .s2_ca2(s2_ca2), .s2_cb2(s2_cb2),
    .crt_flip(crt_flip), .h_adj(h_adj), .v_adj(v_adj),
    .pia_i(m_pia_i), .pia_o(m_pia_o),
    .pr_i(m_pr_i), .pr_o(m_pr_o),
    .ce_pix(ce_pix),
    .video_r(video_r), .video_g(video_g), .video_b(video_b),
    .video_hs(video_hs), .video_vs(video_vs), .video_hblank(video_hblank), .video_vblank(video_vblank)
);

/////////////////////////////  Sound board  /////////////////////////////

logic signed [15:0] snd_l, snd_r, bg_out, cvsd;
logic        snd_cb2, bg_cb2, bg_cvsd_clk, bg_cvsd_digit;
// CHIPPOOL-2026-10-27: blaster / cockpit now declared in the pool section above (the PIA slot mux uses them)
// wire blaster = (variant == 8'd11);
// wire cockpit = (variant == 8'd17);

williams_sndbd snd_b
(
    .clk(clk), .reset(reset), .pause(pause),
    .cmd(snd_cmd), .speech(variant == 8'd6 || variant == 8'd9 || cockpit), .xtal312(snd312),
    .gen2(gen2), .bus_i(s2_bus), .bus_pins(variant == 8'd12), .bus_o(s2_pa_o), .bus_oe(s2_pa_oe),
    .hs_in(s2_cb2), .hs_out(s2_ca2), .cb1_in(joust2 & bg_cb2), .cb2_out(snd_cb2),
    .ext_cvsd(joust2), .ext_clk(bg_cvsd_clk), .ext_digit(bg_cvsd_digit), .cvsd_out(cvsd),
    .rom_a(snd1_a), .rom_d(snd1_d),
    .m6800_i(m6800_0_i), .m6800_o(m6800_0_o), .pia_i(snd1_pia_i), .pia_o(snd1_pia_o), .hc_i(hc55516_0_i), .hc_o(hc55516_0_o), .pr_i(snd1_pr_i), .pr_o(snd1_pr_o),
    .audio(snd_l)
);

// Blaster: second sound board (right channel), same program (the pool's sound pages)
williams_sndbd snd_b2
(
    .clk(clk), .reset(reset | ~(blaster | cockpit)), .pause(pause),
    .cmd(cockpit ? snd_cmd : snd_cmd_r), .speech(1'b0), .xtal312(1'b0),
    .gen2(1'b0), .bus_i(8'hFF), .bus_pins(1'b0), .bus_o(), .bus_oe(), .hs_in(1'b1), .hs_out(),
    .cb1_in(1'b0), .cb2_out(), .ext_cvsd(1'b0), .ext_clk(1'b0), .ext_digit(1'b0), .cvsd_out(),
    .rom_a(snd2_a), .rom_d(snd2_d),
    .m6800_i(m6800_1_i), .m6800_o(m6800_1_o), .pia_i(snd2_pia_i), .pia_o(snd2_pia_o), .hc_i(snd2_hc_i), .hc_o(snd2_hc_o), .pr_i(snd2_pr_i), .pr_o(snd2_pr_o),
    .audio(snd_r)
);

// Joust 2: D-11298 BG board (second 6809, YM2151, CVSD on the shared decoder above)
williams_bg bg_b
(
    .clk(clk), .reset(reset | ~joust2), .pause(pause),
    .data(s2_bus), .strobe(bg_strobe), .resetq(snd_cb2), .cb2(bg_cb2),
    .rom_sel(bg_sel), .rom_a(bg_a), .rom_d(snd2_d),
    .cvsd_clk(bg_cvsd_clk), .cvsd_digit(bg_cvsd_digit),
    .audio(bg_out),
    .m6809r_i(m6809r_1_i), .m6809r_o(m6809r_1_o), .pia_i(bg_pia_i), .pia_o(bg_pia_o), .jt51_i(jt51_0_i), .jt51_o(jt51_0_o), .pr_i(bg_pr_i), .pr_o(bg_pr_o)
);

// MAME joust2: the BG board x2 into the speaker beside the gen2 DAC; its CVSD 0.117 x 4 x 2 = 0.94 of full scale
wire signed [17:0] j2_mix = $signed({{2{snd_l[15]}}, snd_l}) + $signed({{2{bg_out[15]}}, bg_out}) +
                            $signed({{2{cvsd[15]}}, cvsd}) - ($signed({{2{cvsd[15]}}, cvsd}) >>> 4);
wire signed [15:0] j2_sat = (j2_mix > 18'sd32767) ? 16'sd32767 : (j2_mix < -18'sd32768) ? -16'sd32768 : j2_mix[15:0];

assign audio   = joust2 ? j2_sat : snd_l;
assign audio_r = (blaster | cockpit) ? snd_r : audio;

// UPDCTL-2026-10-25: CPU write snoop
assign cpu_wa = cpu_a;
assign cpu_wd = cpu_do;
assign cpu_we = fall_e & ~cpu_rw & ~cpu_rst;

endmodule

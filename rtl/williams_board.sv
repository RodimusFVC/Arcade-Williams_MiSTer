//============================================================================
//
//  Williams 6809 raster hardware — board top
//  Copyright (C) 2026 Rodimus
//
//  Owns the shared parts: one main MC6809E, the ROM pool and the sound boards. Boards export bus ports.
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
    output logic signed [15:0] audio_r
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

/////////////////////////////  Main MC6809E  /////////////////////////////

logic [15:0] cpu_a;
logic  [7:0] cpu_do, cpu_di;
logic        cpu_rw, fall_e, fall_q, cpu_rst, irq_n, firq_n;

mc6809is main_cpu
(
    .CLK(clk), .fallE_en(fall_e), .fallQ_en(fall_q), .D(cpu_di), .DOut(cpu_do), .ADDR(cpu_a),
    .RnW(cpu_rw), .BS(), .BA(), .nIRQ(irq_n), .nFIRQ(firq_n), .nNMI(1'b1), .AVMA(), .BUSY(),
    .LIC(), .nHALT(1'b1), .nRESET(~cpu_rst), .nDMABREQ(1'b1), .RegData()
);

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
    .remap_wa(ioctl_addr[10:0]), .remap_wd(ioctl_dout), .remap_we(ioctl_wr0 && ioctl_addr[24:11] == 14'h00A0),
    .s2_bus(s2_bus), .s2_pa_o(s2_pa_o), .s2_pa_oe(s2_pa_oe), .s2_ca2(s2_ca2), .s2_cb2(s2_cb2),
    .crt_flip(crt_flip), .h_adj(h_adj), .v_adj(v_adj),
    .ce_pix(ce_pix),
    .video_r(video_r), .video_g(video_g), .video_b(video_b),
    .video_hs(video_hs), .video_vs(video_vs), .video_hblank(video_hblank), .video_vblank(video_vblank)
);

/////////////////////////////  Sound board  /////////////////////////////

logic signed [15:0] snd_l, snd_r, bg_out, cvsd;
logic        snd_cb2, bg_cb2, bg_cvsd_clk, bg_cvsd_digit;
wire blaster = (variant == 8'd11);
wire cockpit = (variant == 8'd17);

williams_sndbd snd_b
(
    .clk(clk), .reset(reset), .pause(pause),
    .cmd(snd_cmd), .speech(variant == 8'd6 || variant == 8'd9 || cockpit), .xtal312(snd312),
    .gen2(gen2), .bus_i(s2_bus), .bus_pins(variant == 8'd12), .bus_o(s2_pa_o), .bus_oe(s2_pa_oe),
    .hs_in(s2_cb2), .hs_out(s2_ca2), .cb1_in(joust2 & bg_cb2), .cb2_out(snd_cb2),
    .ext_cvsd(joust2), .ext_clk(bg_cvsd_clk), .ext_digit(bg_cvsd_digit), .cvsd_out(cvsd),
    .rom_a(snd1_a), .rom_d(snd1_d),
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
    .audio(snd_r)
);

// Joust 2: D-11298 BG board (second 6809, YM2151, CVSD on the shared decoder above)
williams_bg bg_b
(
    .clk(clk), .reset(reset | ~joust2), .pause(pause),
    .data(s2_bus), .strobe(bg_strobe), .resetq(snd_cb2), .cb2(bg_cb2),
    .rom_sel(bg_sel), .rom_a(bg_a), .rom_d(snd2_d),
    .cvsd_clk(bg_cvsd_clk), .cvsd_digit(bg_cvsd_digit),
    .audio(bg_out)
);

// MAME joust2: the BG board x2 into the speaker beside the gen2 DAC; its CVSD 0.117 x 4 x 2 = 0.94 of full scale
wire signed [17:0] j2_mix = $signed({{2{snd_l[15]}}, snd_l}) + $signed({{2{bg_out[15]}}, bg_out}) +
                            $signed({{2{cvsd[15]}}, cvsd}) - ($signed({{2{cvsd[15]}}, cvsd}) >>> 4);
wire signed [15:0] j2_sat = (j2_mix > 18'sd32767) ? 16'sd32767 : (j2_mix < -18'sd32768) ? -16'sd32768 : j2_mix[15:0];

assign audio   = joust2 ? j2_sat : snd_l;
assign audio_r = (blaster | cockpit) ? snd_r : audio;

endmodule

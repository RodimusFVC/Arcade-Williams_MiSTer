//============================================================================
//
//  Williams 6809 raster hardware — board top
//  Copyright (C) 2026 Rodimus
//
//  Owns the shared parts: one main MC6809E, the program ROM image and the sound board.
//  Boards export bus ports.
//
//  Variant (MRA index 1 byte 0):
//    0: Defender (rtl/boards/williams1: no blitter, paged ROM at C000)
//
//  ioctl index 0 (MRA):
//    0x00000 - 0x0FFFF  maincpu image by CPU address (Defender: D000-FFFF; banked pages 1-7 at 0000-6FFF)
//    0x10000 - 0x17FFF  sound CPU image 8000-FFFF
//    0x18000 - 0x183FF  proms (video decoder PROMs, loaded for reference, not used)
//  ioctl index 4: CMOS, 256 bytes (MRA <nvram>)
//
//============================================================================

module williams_board
(
    input  logic        clk,            // 48 MHz
    input  logic        reset,
    input  logic        pause,
    input  logic  [7:0] variant,
    output logic        ce_pix,

    input  logic  [7:0] in0,
    input  logic  [7:0] in1,
    input  logic  [7:0] in2,

    input  logic [24:0] ioctl_addr,
    input  logic  [7:0] ioctl_dout,
    input  logic        ioctl_wr0,

    input  logic  [7:0] nv_addr,        // CMOS second port (MiSTer NVRAM load / save)
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

    output logic signed [15:0] audio
);

/////////////////////////////  ROM  /////////////////////////////

logic [15:0] rom_a;
logic  [7:0] rom_d;

dpram_dc #(.widthad_a(16)) rom_main
(
    .clock_a(clk), .address_a(ioctl_addr[15:0]), .data_a(ioctl_dout), .wren_a(ioctl_wr0 && ioctl_addr < 25'h10000),
    .clock_b(clk), .address_b(rom_a), .q_b(rom_d)
);

/////////////////////////////  Main MC6809E  /////////////////////////////

logic [15:0] cpu_a;
logic  [7:0] cpu_do, cpu_di;
logic        cpu_rw, fall_e, fall_q, cpu_rst, irq_n;

mc6809is main_cpu
(
    .CLK(clk), .fallE_en(fall_e), .fallQ_en(fall_q), .D(cpu_di), .DOut(cpu_do), .ADDR(cpu_a),
    .RnW(cpu_rw), .BS(), .BA(), .nIRQ(irq_n), .nFIRQ(1'b1), .nNMI(1'b1), .AVMA(), .BUSY(),
    .LIC(), .nHALT(1'b1), .nRESET(~cpu_rst), .nDMABREQ(1'b1), .RegData()
);

/////////////////////////////  CPU / video board  /////////////////////////////

logic [7:0] snd_cmd;

williams1_main main_b
(
    .clk(clk), .reset(reset), .pause(pause), .variant(variant),
    .fall_e(fall_e), .fall_q(fall_q), .cpu_rst(cpu_rst), .irq_n(irq_n),
    .cpu_di(cpu_di), .cpu_a(cpu_a), .cpu_do(cpu_do), .cpu_rw(cpu_rw),
    .rom_a(rom_a), .rom_d(rom_d),
    .nv_addr(nv_addr), .nv_din(nv_din), .nv_we(nv_we), .nv_dout(nv_dout),
    .in0(in0), .in1(in1), .in2(in2), .snd_cmd(snd_cmd),
    .crt_flip(crt_flip), .h_adj(h_adj), .v_adj(v_adj),
    .ce_pix(ce_pix),
    .video_r(video_r), .video_g(video_g), .video_b(video_b),
    .video_hs(video_hs), .video_vs(video_vs), .video_hblank(video_hblank), .video_vblank(video_vblank)
);

/////////////////////////////  Sound board  /////////////////////////////

williams_sndbd snd_b
(
    .clk(clk), .reset(reset), .pause(pause),
    .cmd(snd_cmd),
    .rom_wa(ioctl_addr[14:0]), .rom_wd(ioctl_dout), .rom_we(ioctl_wr0 && ioctl_addr[24:15] == 10'd2),
    .audio(audio)
);

endmodule

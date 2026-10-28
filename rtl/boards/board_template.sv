//============================================================================
//  board_template.sv - start a new Williams-core board by copying this file (NOT in files.qip, never compiled).
//  Copyright (C) 2026 Rodimus
//
//  Boards never instantiate a CPU, sound chip, ROM store or board RAM. They live ONCE in the dispatcher
//  rtl/williams_dispatcher.sv: main MC6809E m6809r_0 (this board's cpu_* ports), BG-board MC68B09E m6809r_1, sound
//  MC6808s m6800_0 / m6800_1, PIAs pia6821[3:0] (slot 0 = interface PIA, 1 = ROM-board PIA, 2 = shared by variant,
//  3 = sound board), hc55516_0, jt51_0 (chip_pool_pkg buses); the shared ROM pool (rom_pool: main bus rom_a / rom_d,
//  time-shared sound / tile readers), rom_remap (Blaster remap PROM) and the eight board RAM pool blocks
//  (ram_pool_pkg: 0 = 32K video low, 1 = 16K video high, 2 = 4K D000 RAM | BG board RAM, 3 = 2K tile RAM,
//  4 = 1K CMOS (port B = NVRAM), 5 = 1K palette low | second sound board RAM, 6 = 1K palette high, 7 = 256 B sound
//  board RAM; map in the dispatcher's "Shared RAM pool" section).
//  To add the board: copy this file to rtl/boards/<dir>/<board>.sv, add it to files.qip + verilator/williams/Makefile
//  (+ lint.sh follows files.qip), instance it in the dispatcher, put it on the variant muxes (pool_i[n] / pia6821_i[2] /
//  any chip bus) and tie the blocks it doesn't use to '0. A RAM bigger than its block = grow the block, never a
//  private dpram_dc. A RAM / chip that truly can't pool = "// POOL-EXCEPTION: <reason>" on its instance line.
//  verilator/common/pool_check.sh (POOL_MODS in verilator/williams/Makefile) enforces it.
//============================================================================

module board_template
(
    input  logic        clk,            // 48 MHz
    input  logic        reset,
    input  logic        pause,
    input  logic  [7:0] variant,

    // main MC6809E (pool slot m6809r_0, driven through the dispatcher)
    output logic        fall_e,
    output logic        fall_q,
    output logic        cpu_rst,
    output logic        irq_n,
    output logic        firq_n,
    output logic  [7:0] cpu_di,
    input  logic [15:0] cpu_a,
    input  logic  [7:0] cpu_do,
    input  logic        cpu_rw,

    // shared ROM pool, main bus (read port)
    output logic [18:0] rom_a,
    input  logic  [7:0] rom_d,

    // CMOS second port (MiSTer NVRAM load / save; pool block 4 port B)
    input  logic  [9:0] nv_addr,
    input  logic  [7:0] nv_din,
    input  logic        nv_we,
    output logic  [7:0] nv_dout,

    input  logic  [7:0] in0,
    input  logic  [7:0] in1,
    input  logic  [7:0] in2,

    // PIA pool slots 0 / 1 / 2 (chip_pool_pkg)
    output chip_pool_pkg::pia6821p_i_t [2:0] pia_i,
    input  chip_pool_pkg::pia6821p_o_t [2:0] pia_o,

    // board RAM pool (rtl/ram_pool_pkg.sv)
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

endmodule

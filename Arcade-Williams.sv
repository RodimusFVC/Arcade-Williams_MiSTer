//============================================================================
//
//  Williams 6809 raster arcade hardware for MiSTer
//  Copyright (C) 2026 Rodimus
//
//  Top level carried over from the Rodimus Exidy core (Pac-Man core lineage, MikeJ / Sorgelig)
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//
//============================================================================

module emu
(
    `include "sys/emu_ports.vh"
);

wire        CLK_SYS;
wire        locked;
wire [127:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire [10:0] ps2_key;
wire [24:0] ps2_mouse;               // [24] toggles per packet, [23:16] dy (up +), [15:8] dx, [5] / [4] dy / dx sign
wire        ioctl_download;
wire        ioctl_upload;
wire        ioctl_upload_req;
wire  [7:0] ioctl_din;
wire        ioctl_wr;
wire  [7:0] ioctl_index;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire [15:0] joystick_0, joystick_1;
wire [15:0] joy_a0;                  // left analog stick, pad 1: Y high byte, X low byte (signed, up / left negative)
wire [15:0] joy_r0, joy_r1;          // right analog sticks, pads 1 and 2
wire [15:0] joy_a1;                  // left analog stick, pad 2
wire [21:0] gamma_bus;
wire        direct_video;
wire        video_rotated;
wire        pause_cpu;
wire        hblank, vblank;

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;

assign VGA_F1 = 0;
assign VGA_SCALER = 0;
assign VGA_DISABLE = 0;
assign FB_FORCE_BLANK = 0;
assign HDMI_FREEZE = 0;
assign HDMI_BLACKOUT = 0;
assign HDMI_BOB_DEINT = 0;

wire signed [15:0] audio, audio_r;   // Blaster has a second sound board on the right; mono boards drive both
assign AUDIO_L = pause_cpu ? 16'd0 : audio;
assign AUDIO_R = pause_cpu ? 16'd0 : audio_r;
assign AUDIO_S = 1;   // signed
assign AUDIO_MIX = 0;

assign LED_DISK  = 0;
assign LED_POWER = 0;
assign LED_USER  = ioctl_download;
assign BUTTONS = 0;

///////////////////////////////////////////////////

// MRA index 1 (same layout as the Exidy core):
//   byte 0      board variant (see rtl/williams_board.sv)
//   byte 1      flags: [0] 4-way joystick, [1] sound board on a 3.12 MHz crystal (Next Century), [4] vertical, [5] no watchdog (bootleg ROMs that never clear it),
//               [6] main CPU ROM data D0 / D7 swapped (Jeutel Defender bootlegs, decoded on read), [7] vertical is ROT90
//   bytes 4-11  idle level of every bit of the 8 ports (IN0, IN1, IN2, IN0 / IN1 for player 2 on a muxed panel, -, -, -)
//   bytes 12-19 per port: DIP switch byte that supplies it (bit 7 set = none, use the idle byte)
//   bytes 20-83 input map, one byte per port bit (bit 0 first): control id, 0 = none; a pressed control inverts its bit
//   bytes 84-147 per port bit: which bit of its DIP switch byte supplies it
//   bytes 148-184 ROM pool map (rtl/williams_board.sv): 16 main pages, 8 sound pages, bank base, tile base,
//               8 sound pages for the second sound board, BG sound ROM bases U4 / U19 / U20 (Joust 2)
reg [7:0] game_var    = 8'd0;
reg [295:0] rom_map   = {296{1'b1}};
reg [7:0] game_flags  = 8'h00;
reg [5:0] in_map[64];
reg [7:0] port_idle[8] = '{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
reg [7:0] port_dip[8]  = '{8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80};
wire [7:0] map_idx8  = ioctl_addr[7:0] - 8'd20;    // bytes 20-83  -> 0-63
wire [7:0] perm_idx8 = ioctl_addr[7:0] - 8'd84;    // bytes 84-147 -> 0-63
wire [5:0] map_idx   = map_idx8[5:0];
wire [5:0] perm_idx  = perm_idx8[5:0];
wire [2:0] idle_idx  = ioctl_addr[2:0] - 3'd4;     // bytes 4-11  -> 0-7
wire [2:0] dip_idx   = ioctl_addr[2:0] - 3'd4;     // bytes 12-19 -> 0-7
reg  [2:0] dip_bit[64];
initial for (int i = 0; i < 64; i++) dip_bit[i] = i % 8;
initial for (int i = 0; i < 64; i++) in_map[i] = 6'd0;

always @(posedge CLK_SYS) begin
    if (ioctl_wr && ioctl_index == 8'd1) begin
        if (ioctl_addr >= 25'd84 && ioctl_addr < 25'd148) dip_bit[perm_idx] <= ioctl_dout[2:0];
        if (ioctl_addr == 25'd0) game_var   <= ioctl_dout;
        if (ioctl_addr == 25'd1) game_flags <= ioctl_dout;
        if (ioctl_addr >= 25'd4  && ioctl_addr < 25'd12) port_idle[idle_idx] <= ioctl_dout;
        if (ioctl_addr >= 25'd12 && ioctl_addr < 25'd20) port_dip[dip_idx]   <= ioctl_dout;
        if (ioctl_addr >= 25'd20 && ioctl_addr < 25'd84) in_map[map_idx] <= ioctl_dout[5:0];
        if (ioctl_addr >= 25'd148 && ioctl_addr < 25'd185) rom_map[(ioctl_addr[7:0] - 8'd148) * 8 +: 8] <= ioctl_dout;
    end
end

wire game_vert = game_flags[4];
wire vert_view = game_vert & ~status[12];

wire [1:0] ar = status[9:8];

assign VIDEO_ARX = (!ar) ? (vert_view ? 12'd3 : 12'd4) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? (vert_view ? 12'd4 : 12'd3) : 12'd0;

// Status bit layout kept the same as the Exidy core
`include "build_id.v"
localparam CONF_STR = {
	"WILLIAMS;;",
	"P1,Video Options;",
	"P1O89,Aspect Ratio,Original,Full screen,[ARC1],[ARC2];",
	"P1OB,HDMI Flip,Off,On;",
	"P1OM,CRT Flip,Off,On;",
	"P1O[40:37],H Position (CRT),0,+1,+2,+3,+4,+5,+6,+7,-8,-7,-6,-5,-4,-3,-2,-1;",
	"P1O[44:41],V Position (CRT),0,+1,+2,+3,+4,+5,+6,+7,-8,-7,-6,-5,-4,-3,-2,-1;",
	"P1OGI,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"P3,Pause Options;",
	"P3OJ,Pause when OSD is open,On,Off;",
	"P3OK,Dim video after 10s,On,Off;",
	"-;",
	"OR,Autosave NVRAM,On,Off;",
	"-;",
	"DIP;",
	"-;",
	"R0,Reset;",
	"J1,Btn 1,Btn 2,Btn 3,Btn 4,Coin,Start 1P,Start 2P,Pause,Btn 5,Btn 6;",
	"jn,A,B,X,Y,Select,Start,R,L;",
	"V,v",`BUILD_DATE
};

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(CLK_SYS),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),
	.video_rotated(video_rotated),

	.forced_scandoubler(forced_scandoubler),

	.buttons(buttons),
	.status(status),
	.status_menumask({direct_video}),

	.ioctl_download(ioctl_download),
	.ioctl_upload(ioctl_upload),
	.ioctl_upload_req(ioctl_upload_req),
	.ioctl_din(ioctl_din),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_index(ioctl_index),
	.ioctl_wait(1'b0),

	.joystick_0(joystick_0),
	.joystick_l_analog_0(joy_a0),
	.joystick_l_analog_1(joy_a1),
	.joystick_r_analog_0(joy_r0),
	.joystick_r_analog_1(joy_r1),
	.joystick_1(joystick_1),
	.ps2_key(ps2_key),
	.ps2_mouse(ps2_mouse)
);

////////////////////   CLOCKS   ///////////////////

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(CLK_SYS),
	.reconfig_to_pll(reconfig_to_pll),
	.reconfig_from_pll(reconfig_from_pll),
	.locked(locked)
);

wire [63:0] reconfig_to_pll;
wire [63:0] reconfig_from_pll;
wire        cfg_waitrequest;

pll_cfg pll_cfg
(
	.mgmt_clk(CLK_50M),
	.mgmt_reset(0),
	.mgmt_waitrequest(cfg_waitrequest),
	.mgmt_read(0),
	.mgmt_readdata(),
	.mgmt_write(0),
	.mgmt_address(0),
	.mgmt_writedata(0),
	.reconfig_to_pll(reconfig_to_pll),
	.reconfig_from_pll(reconfig_from_pll)
);

// Hold the board in reset until the PLL is locked and the ROM download has finished
wire reset = RESET | status[0] | buttons[1] | ioctl_download | ~locked;

///////////////////         Keyboard           //////////////////

reg kb_up = 0, kb_down = 0, kb_left = 0, kb_right = 0;
reg kb_b1 = 0, kb_b2 = 0;
reg kb_coin1 = 0, kb_coin2 = 0, kb_start1 = 0, kb_start2 = 0, kb_pause = 0, kb_service = 0, kb_tilt = 0;
reg kb_hsreset = 0, auto_up = 1;   // coin door: High Score Reset key, Auto Up / Manual Down switch (starts on Auto)

wire       pressed = ~ps2_key[9];
wire [7:0] code    = ps2_key[7:0];

always @(posedge CLK_SYS) begin
	reg old_state;
	old_state <= ps2_key[10];
	if (old_state != ps2_key[10]) begin
		case (code)
			'h16: kb_start1  <= pressed; // 1
			'h1E: kb_start2  <= pressed; // 2
			'h2E: kb_coin1   <= pressed; // 5
			'h36: kb_coin2   <= pressed; // 6
			'h46: kb_service <= pressed; // 9 (Advance)
			'h06: kb_service <= pressed; // F2
			'h45: if (pressed) auto_up <= ~auto_up; // 0 (Auto Up / Manual Down)
			'h3E: kb_hsreset <= pressed; // 8 (High Score Reset)
			'h2C: kb_tilt    <= pressed; // T
			'h4D: kb_pause   <= pressed; // P

			'h75: kb_up      <= pressed; // up
			'h72: kb_down    <= pressed; // down
			'h6B: kb_left    <= pressed; // left
			'h74: kb_right   <= pressed; // right
			'h14: kb_b1      <= pressed; // ctrl
			'h11: kb_b2      <= pressed; // alt
		endcase
	end
end

//////////////////  Arcade Buttons/Interfaces   ///////////////////////////

// Joystick bits: 0 R, 1 L, 2 D, 3 U, 4-7 Btn 1-4, 8 Coin, 9 Start 1P, 10 Start 2P, 11 Pause, 12-13 Btn 5-6
wire [3:0] dir1_raw = {joystick_0[3] | kb_up, joystick_0[2] | kb_down, joystick_0[1] | kb_left, joystick_0[0] | kb_right};
wire [3:0] dir2_raw = joystick_1[3:0];
wire [3:0] dir1, dir2;   // {U, D, L, R}

joy4way joy4way_1(.clk(CLK_SYS), .en(game_flags[0]), .in(dir1_raw), .out(dir1));
joy4way joy4way_2(.clk(CLK_SYS), .en(game_flags[0]), .in(dir2_raw), .out(dir2));

wire m_pause = joystick_0[11] | kb_pause;

// Twin-stick fire (Robotron, Splat, Inferno): Btn 1-4 = fire up / down / left / right, ORed with the right stick
// pushed past a dead zone (8-way: a diagonal gives two directions)
function [3:0] rstick(input [15:0] a);   // {right, left, down, up}
	reg signed [7:0] x, y;
	begin
		x = a[7:0]; y = a[15:8];
		rstick = {x > 8'sd40, x < -8'sd40, y > 8'sd40, y < -8'sd40};
	end
endfunction
wire [3:0] rs0 = rstick(joy_r0), rs1 = rstick(joy_r1);
wire [3:0] fire1 = joystick_0[7:4] | {rs0[3], rs0[2], rs0[1], rs0[0]};   // {R, L, D, U} on Btn 4-1
wire [3:0] fire2 = joystick_1[7:4] | {rs1[3], rs1[2], rs1[1], rs1[0]};

// control ids used by the MRA input map (same numbering as the Exidy core; 24-31 reserved for analog)
wire [63:0] ctl =
{
	16'd0,
	kb_hsreset,                                     // 47 high score reset
	auto_up,                                        // 46 Auto Up / Manual Down switch
	6'd0,                                           // 45-40 reserved
	joystick_1[5] | joystick_1[9] | joystick_1[10] | kb_start2,   // 39 P2 Btn 2 or Start (Joust 2 Start / Transform; pad 2 only)
	joystick_0[5] | joystick_0[9] | kb_start1,      // 38 P1 Btn 2 or Start (Joust 2 Start / Transform)
	dir1[3] | dir1[2], dir1[1] | dir1[0],          // 37 P1 U or D, 36 P1 L or R (49-way stick off centre)
	joystick_1[13:12],                              // 35-34 P2 Btn 6-5
	joystick_0[13:12],                              // 33-32 P1 Btn 6-5
	fire2,                                          // 31-28 P2 fire R, L, D, U (Btn 4-1 or right stick)
	fire1,                                          // 27-24 P1 fire R, L, D, U (Btn 4-1 or right stick)
	1'b0,                                           // 23 coin 3
	kb_service,                                     // 22 service
	kb_tilt,                                        // 21 tilt
	joystick_0[10] | joystick_1[10] | joystick_1[9] | kb_start2,   // 20 start 2 (pad 2's Start is Start 2P)
	joystick_0[9]  | kb_start1,                     // 19 start 1
	joystick_1[8]  | kb_coin2,                      // 18 coin 2
	joystick_0[8]  | kb_coin1,                      // 17 coin 1
	joystick_1[7:4],                                // 16-13 P2 Btn 4-1
	dir2[0], dir2[1], dir2[2], dir2[3],             // 12 R, 11 L, 10 D, 9 U
	joystick_0[7:6], joystick_0[5] | kb_b2, joystick_0[4] | kb_b1,   // 8-5 P1 Btn 4-1
	dir1[0], dir1[1], dir1[2], dir1[3],             // 4 R, 3 L, 2 D, 1 U
	1'b0                                            // 0 none
};

// Trackballs / spinner (Speed Ball AN0-AN3, Conquest dial): 8-bit position counters per player and axis, X right +,
// Y up +. Player 1: mouse, else the left analog stick, else the D-pad; player 2: its left analog stick, else its D-pad.
// Sticks and D-pads move a 16-bit position at 2930 Hz by the deflection (D-pad: half scale); the top byte is the count.
// One mouse count = half a position count.
wire signed [7:0] ax = joy_a0[7:0], ay = joy_a0[15:8], bx1 = joy_a1[7:0], by1 = joy_a1[15:8];
wire       a_on  = (ax  > 8'sd24) || (ax  < -8'sd24) || (ay  > 8'sd24) || (ay  < -8'sd24);
wire       a1_on = (bx1 > 8'sd24) || (bx1 < -8'sd24) || (by1 > 8'sd24) || (by1 < -8'sd24);
wire signed [15:0] mdx = {{7{ps2_mouse[4]}}, ps2_mouse[15:8], 1'b0} <<< 6;
wire signed [15:0] mdy = {{7{ps2_mouse[5]}}, ps2_mouse[23:16], 1'b0} <<< 6;
function signed [15:0] step(input on, input signed [7:0] v, input neg, input pos);   // stick, else D-pad
	step = on ? {{8{v[7]}}, v} : neg ? -16'sd64 : pos ? 16'sd64 : 16'sd0;
endfunction
reg [15:0] tb_x0 = 0, tb_y0 = 0, tb_x1 = 0, tb_y1 = 0;
reg [13:0] tb_div = 0;
reg        mouse_t = 0;
always @(posedge CLK_SYS) begin
	mouse_t <= ps2_mouse[24];
	tb_div  <= tb_div + 1'd1;
	if (mouse_t != ps2_mouse[24]) begin
		tb_x0 <= tb_x0 + mdx;
		tb_y0 <= tb_y0 + mdy;
	end
	else if (!tb_div) begin   // stick Y is up negative, the counter up positive
		tb_x0 <= tb_x0 + step(a_on,  ax,  dir1[1], dir1[0]);
		tb_y0 <= tb_y0 - step(a_on,  ay,  dir1[3], dir1[2]);
		tb_x1 <= tb_x1 + step(a1_on, bx1, dir2[1], dir2[0]);
		tb_y1 <= tb_y1 - step(a1_on, by1, dir2[3], dir2[2]);
	end
end

// 49-way stick (Sinistar, Blaster) from pad 1's left analog stick: seven positions per axis (MAME port_0_49way_r),
// X left = 0, Y up = 6 (both games reverse Y). Off centre it replaces the MRA's digital approximation.
function [3:0] way49(input [2:0] p);
	case (p) 3'd0: way49 = 4'h0; 3'd1: way49 = 4'h4; 3'd2: way49 = 4'h6; 3'd3: way49 = 4'h7;
	         3'd4: way49 = 4'hB; 3'd5: way49 = 4'h9; default: way49 = 4'h8; endcase
endfunction
wire [10:0] px7 = ({3'd0, ~ax[7], ax[6:0]}) * 11'd7, py7 = ({3'd0, ~ay[7], ay[6:0]}) * 11'd7;   // (v + 128) * 7
wire  [8:0] s49 = {a_on, way49(px7[10:8]), way49(3'd6 - py7[10:8])};

// Turkey Shoot gun cursor (6 bits per axis, 0 = left / top): the left analog stick sets it outright when it is
// pushed past a dead zone; otherwise pad 1's D-pad moves it (~90 steps a second)
reg  [5:0] gun_x = 6'd32, gun_y = 6'd32;
reg [18:0] gun_div = 19'd0;
always @(posedge CLK_SYS) begin
	gun_div <= gun_div + 1'd1;
	if (a_on) begin
		gun_x <= {~ax[7], ax[6:2]};
		gun_y <= {~ay[7], ay[6:2]};
	end
	else if (!gun_div) begin
		if (dir1[1] && gun_x != 6'd0)  gun_x <= gun_x - 1'd1;
		if (dir1[0] && gun_x != 6'd63) gun_x <= gun_x + 1'd1;
		if (dir1[3] && gun_y != 6'd0)  gun_y <= gun_y - 1'd1;
		if (dir1[2] && gun_y != 6'd63) gun_y <= gun_y + 1'd1;
	end
end

// DIP switches arrive from the OSD via ioctl index 254
reg [7:0] dip_sw[8] = '{8'hFF,8'hFF,8'hFF,8'hFF,8'h00,8'h00,8'h00,8'h00};
always @(posedge CLK_SYS) begin
	if (ioctl_wr && (ioctl_index == 8'd254) && !ioctl_addr[24:3])
		dip_sw[ioctl_addr[2:0]] <= ioctl_dout;
end

reg [7:0] in_port[8];
always @(posedge CLK_SYS) begin
	for (int p = 0; p < 8; p++)
		for (int b = 0; b < 8; b++)
			in_port[p][b] <= (port_dip[p][7] ? port_idle[p][b] : dip_sw[port_dip[p][2:0]][dip_bit[p*8 + b]]) ^ ctl[in_map[p*8 + b]];
end

// PAUSE SYSTEM
wire [23:0] rgb_out;
pause #(8,8,8,48) pause
(
	.*,
	.clk_sys(CLK_SYS),
	.user_button(m_pause),
	.pause_request(1'b0),
	.options(~status[20:19])
);

///////////////                 Video                  ////////////////

wire hs, vs;
wire [7:0] r, g, b;
wire ce_pix;

wire rotate_ccw = ~game_flags[7];  // ROT270 sets rotate CCW, ROT90 sets CW
wire no_rotate  = ~game_vert | status[12] | direct_video;
wire flip       = status[11];
screen_rotate screen_rotate(.*);

arcade_video #(320,24) arcade_video
(
	.*,

	.clk_video(CLK_SYS),

	.RGB_in(rgb_out),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(hs),
	.VSync(vs),

	.fx(status[18:16])
);

///////////////                 Board                  ////////////////

williams_board board
(
	.clk(CLK_SYS),
	.reset(reset),
	.pause(pause_cpu),
	.variant(game_var),
	.no_wd(game_flags[5]),
	.swap07(game_flags[6]),
	.snd312(game_flags[1]),
	.ce_pix(ce_pix),

	.in0(in_port[0]),
	.in1(in_port[1]),
	.in2(in_port[2]),
	.in3(in_port[3]),
	.in4(in_port[4]),
	.gun_x(gun_x),
	.gun_y(gun_y),
	.an({tb_x1[15:8], tb_y1[15:8], tb_x0[15:8], tb_y0[15:8]}),
	.s49(s49),

	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_wr0(ioctl_wr & (ioctl_index == 8'd0)),
	.rom_map(rom_map),

	// CMOS (MRA <nvram index="4" size="256" / "1024">): loaded with the MRA, saved when the OSD opens / closes
	.nv_addr(ioctl_addr[9:0]),
	.nv_din(ioctl_dout),
	.nv_we(ioctl_download & ioctl_wr & (ioctl_index == 8'd4)),
	.nv_dout(ioctl_din),

	.crt_flip(status[22]),
	.h_adj(status[40:37]),
	.v_adj(status[44:41]),

	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_hs(hs),
	.video_vs(vs),
	.video_hblank(hblank),
	.video_vblank(vblank),

	.audio(audio),
	.audio_r(audio_r)
);

assign ioctl_upload_req = ~status[27] & ~ioctl_download;

endmodule

// 4-way joystick: the most recently pressed direction wins (from the MiSTer Pac-Man port)
module joy4way
(
	input        clk,
	input        en,
	input  [3:0] in,
	output [3:0] out
);

reg  [3:0] mask = 4'hF;
reg  [3:0] in1 = 0, in2 = 0;
wire [3:0] innew = in1 & ~in2;

assign out = in1 & mask;

always @(posedge clk) begin
	in1 <= in;
	in2 <= in1;

	if (innew[0]) mask <= 4'b0001;
	if (innew[1]) mask <= 4'b0010;
	if (innew[2]) mask <= 4'b0100;
	if (innew[3]) mask <= 4'b1000;

	if (!(in & mask) || !en) mask <= 4'hF;
end

endmodule

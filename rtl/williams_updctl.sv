//============================================================================
//
//  Williams "Updated Controls" (Game Options): Defender family and Stargate
//  Copyright (C) 2026 Rodimus
//
//  Sits between the core's control-id vector (Arcade-Williams.sv ctl) and the MRA input map. Disabled
//  (en = 0) it is a pure pass-through: ctl_out = ctl_in, pause_btn = 0.
//  Enabled, for pad 1 (pad 2 reaches these games only through Start 2P, id 20, which passes through):
//    stick Left / Right: while the ship faces the other way, Reverse (id 32) is held (level, UPDCTL-LEVEL-2026-10-25);
//    while it faces that way, Thrust (id 5) is held. Both directions at once = neither.
//    swap56 (Stargate): Btn 5 (id 32 in, R by default) becomes Inviso (id 33 out), Btn 6 (id 33 in, L by default)
//    becomes Pause (pause_btn), so Reverse comes only from the stick. Without swap56 Btn 5 stays Reverse.
//  Facing comes from game RAM: the CPU's writes to face_addr are snooped; facing left = (data bit face_bit == face_pol).
//  Pulse: held PULSE_FR frames, then released for at least GAP_FR frames; no new pulse until the facing has changed
//  or TIMEOUT_FR frames have passed. A player's own Reverse press while the stick is held stops the auto pulses until
//  the stick is released (never fights the player). Counters run on vblank and hold while paused.
//
//============================================================================

module williams_updctl #(parameter logic [5:0] PULSE_FR = 6'd3, parameter logic [5:0] GAP_FR = 6'd3, parameter logic [5:0] TIMEOUT_FR = 6'd30)
(
    input  logic        clk,
    input  logic        reset,
    input  logic        pause,
    input  logic        en,              // OSD Controls = Mode 1 or Mode 2, and the MRA supports it
    input  logic        mode1,           // Mode 1: stick Left / Right = Reverse, facing ignored (Dar's Mode 1); else Mode 2
    input  logic        swap56,          // Stargate: Btn 5 -> Inviso, Btn 6 -> Pause
    input  logic [15:0] face_addr,
    input  logic  [2:0] face_bit,
    input  logic        face_pol,
    input  logic [15:0] wa,              // main CPU write snoop (one strobe per bus write)
    input  logic  [7:0] wd,
    input  logic        we,
    input  logic        vblank,
    input  logic [63:0] ctl_in,
    output logic [63:0] ctl_out,
    output logic        pause_btn
);

localparam int ID_L = 3, ID_R = 4, ID_THRUST = 5, ID_B5 = 32, ID_B6 = 33;

// facing, from the game's own RAM variable
logic face_left = 1'b0;
always_ff @(posedge clk) begin
    if (reset)                       face_left <= 1'b0;
    else if (we && wa == face_addr)  face_left <= (wd[face_bit] == face_pol);
end

wire want_l   = ctl_in[ID_L] & ~ctl_in[ID_R];
wire want_r   = ctl_in[ID_R] & ~ctl_in[ID_L];
wire held     = want_l | want_r;
wire mismatch = (want_l & ~face_left) | (want_r & face_left);
wire own_rev  = ~swap56 & ctl_in[ID_B5];

// UPDCTL-LEVEL-2026-10-25: Reverse is a level, held while the stick points against the facing (Dar's Defender core
// "Control: Mode 1" scheme). The game reverses once per press, so no pulses or timeouts; once the facing flips the
// same stick direction becomes Thrust. Pulse state machine (ghost reverses on Stargate HW) commented out below.
wire rev_pulse = mode1 ? (ctl_in[ID_L] | ctl_in[ID_R]) : mismatch;
wire thrust    = ~mode1 & held & ~mismatch;

/*
logic vb_r = 1'b0;
always_ff @(posedge clk) if (!pause) vb_r <= vblank;
wire  frame = vblank & ~vb_r & ~pause;

localparam logic [1:0] S_IDLE = 2'd0, S_PULSE = 2'd1, S_WAIT = 2'd2;
logic [1:0] st = S_IDLE;
logic [5:0] cnt = 6'd0;
logic       face_at = 1'b0, override = 1'b0, own_r = 1'b0;
always_ff @(posedge clk) begin
    if (reset || !en) begin
        st <= S_IDLE; cnt <= 6'd0; override <= 1'b0; own_r <= 1'b0;
    end
    else if (!pause) begin
        own_r <= own_rev;
        if (!held)                  override <= 1'b0;
        else if (own_rev && !own_r) override <= 1'b1;
        case (st)
            S_IDLE:  if (mismatch && !override && !own_rev) begin st <= S_PULSE; cnt <= 6'd0; face_at <= face_left; end
            S_PULSE: if (frame) begin
                         cnt <= cnt + 1'd1;
                         if (cnt == PULSE_FR - 6'd1) begin st <= S_WAIT; cnt <= 6'd0; end
                     end
            default: begin
                         if (frame && cnt != 6'h3F) cnt <= cnt + 1'd1;
                         if ((cnt >= GAP_FR && face_left != face_at) || cnt >= TIMEOUT_FR) st <= S_IDLE;
                     end
        endcase
    end
end

wire rev_pulse = (st == S_PULSE);
wire thrust    = held & ~mismatch;
*/

always_comb begin
    ctl_out   = ctl_in;
    pause_btn = 1'b0;
    if (en) begin
        ctl_out[ID_THRUST] = ctl_in[ID_THRUST] | thrust;
        ctl_out[ID_B5]     = own_rev | rev_pulse;
        if (swap56) begin
            ctl_out[ID_B6] = ctl_in[ID_B5];
            pause_btn      = ctl_in[ID_B6];
        end
    end
end

endmodule

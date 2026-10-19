// ============================================================================
// pia6821.sv — MC6821 / MCS6520 PIA, single-clock clock-enable model
//
// Adapted from Arcade-Qix_MiSTer rtl/sound/pia6821_sound.sv (module pia6821_sv):
// negedge processes removed, everything on posedge clk qualified by the E enable.
//
//  - register writes      : ce & cs & ~rw
//  - read side effects    : ce & cs &  rw (port data read clears IRQx1/IRQx2, CA2 read strobe)
//  - CA1/CA2/CB1/CB2 edge : detected at full clk rate (the real part latches edges
//                           asynchronously; the other side's E may be slower than a
//                           one-E-cycle strobe pulse), flags set immediately
//  - read data            : combinational from current registers/pins
// IRQ flags are set by the active edge regardless of the enable bit (datasheet);
// the enable bits only gate the IRQ outputs.
// ============================================================================

module pia6821
(
    input  logic       clk,
    input  logic       rst,
    input  logic       ce,          // E enable (one clk per E cycle)
    input  logic       cs,
    input  logic       rw,          // 1 = read
    input  logic [1:0] rs,          // RS1:RS0
    input  logic [7:0] din,
    output logic [7:0] dout,
    output logic       irqa,        // active high
    output logic       irqb,

    input  logic [7:0] pa_i,        // pin levels (caller resolves pull-ups)
    input  logic       pa_pins,     // 1: port A reads the pins for output bits too (the real 6821; MAME
                                    //    set_port_a_input_overrides_output_mask)
    output logic [7:0] pa_o,
    output logic [7:0] pa_oe,
    input  logic       ca1,
    input  logic       ca2_i,
    output logic       ca2_o,
    output logic       ca2_oe,

    input  logic [7:0] pb_i,
    output logic [7:0] pb_o,
    output logic [7:0] pb_oe,
    input  logic       cb1,
    input  logic       cb2_i,
    output logic       cb2_o,
    output logic       cb2_oe
);

logic [7:0] ddra, ora, ddrb, orb;
logic [5:0] cra, crb;
logic       irqa1, irqa2, irqb1, irqb2;
logic       ca2_out, cb2_out;
logic       ca2_pulse, cb2_pulse;     // E-restore strobes pending release
logic       ca1_d, ca2_d, cb1_d, cb2_d;

wire wr_en = ce & cs & ~rw;
wire rd_en = ce & cs &  rw;

wire rd_pa  = rd_en & (rs == 2'd0) & cra[2];
wire rd_pb  = rd_en & (rs == 2'd2) & crb[2];
wire wr_pb  = wr_en & (rs == 2'd2) & crb[2];

// active transitions (clk rate)
wire ca1_edge = cra[1] ? (ca1 & ~ca1_d)     : (~ca1 & ca1_d);
wire cb1_edge = crb[1] ? (cb1 & ~cb1_d)     : (~cb1 & cb1_d);
wire ca2_edge = cra[4] ? (ca2_i & ~ca2_d)   : (~ca2_i & ca2_d);
wire cb2_edge = crb[4] ? (cb2_i & ~cb2_d)   : (~cb2_i & cb2_d);

always_ff @(posedge clk) begin
    if (rst) begin
        ddra <= 8'h00; ora <= 8'h00; cra <= 6'h00;
        ddrb <= 8'h00; orb <= 8'h00; crb <= 6'h00;
        irqa1 <= 1'b0; irqa2 <= 1'b0; irqb1 <= 1'b0; irqb2 <= 1'b0;
        ca2_out <= 1'b1; cb2_out <= 1'b1;
        ca2_pulse <= 1'b0; cb2_pulse <= 1'b0;
        ca1_d <= ca1; ca2_d <= ca2_i; cb1_d <= cb1; cb2_d <= cb2_i;
    end else begin
        ca1_d <= ca1; ca2_d <= ca2_i; cb1_d <= cb1; cb2_d <= cb2_i;

        // ---------------- flags: clear on port read, set on active edge (set wins)
        if (rd_pa) begin irqa1 <= 1'b0; irqa2 <= 1'b0; end
        if (rd_pb) begin irqb1 <= 1'b0; irqb2 <= 1'b0; end
        if (ca1_edge)            irqa1 <= 1'b1;
        if (cb1_edge)            irqb1 <= 1'b1;
        if (~cra[5] & ca2_edge)  irqa2 <= 1'b1;
        if (~crb[5] & cb2_edge)  irqb2 <= 1'b1;

        // ---------------- CA2 output strobes (read strobe on port A data read)
        if (cra[5] & ~cra[4]) begin
            if (ce & ca2_pulse) begin ca2_out <= 1'b1; ca2_pulse <= 1'b0; end  // E restore
            if (~cra[3] & ca1_edge) ca2_out <= 1'b1;                            // CA1 restore
            if (rd_pa) begin ca2_out <= 1'b0; ca2_pulse <= cra[3]; end
        end
        // ---------------- CB2 output strobes (write strobe on port B data write)
        if (crb[5] & ~crb[4]) begin
            if (ce & cb2_pulse) begin cb2_out <= 1'b1; cb2_pulse <= 1'b0; end
            if (~crb[3] & cb1_edge) cb2_out <= 1'b1;
            if (wr_pb) begin cb2_out <= 1'b0; cb2_pulse <= crb[3]; end
        end

        // ---------------- register writes
        if (wr_en) begin
            case (rs)
                2'd0: if (cra[2]) ora <= din; else ddra <= din;
                2'd1: begin
                    cra <= din[5:0];
                    if (din[5]) begin
                        ca2_out   <= din[4] ? din[3] : 1'b1;   // manual level, or strobe idle high
                        ca2_pulse <= 1'b0;
                        irqa2     <= 1'b0;                     // CA2 output: IRQA2 flag reads 0
                    end
                end
                2'd2: if (crb[2]) orb <= din; else ddrb <= din;
                2'd3: begin
                    crb <= din[5:0];
                    if (din[5]) begin
                        cb2_out   <= din[4] ? din[3] : 1'b1;
                        cb2_pulse <= 1'b0;
                        irqb2     <= 1'b0;
                    end
                end
            endcase
        end
    end
end

assign pa_o  = ora;
assign pa_oe = ddra;
assign pb_o  = orb;
assign pb_oe = ddrb;

assign ca2_o  = ca2_out;
assign ca2_oe = cra[5];
assign cb2_o  = cb2_out;
assign cb2_oe = crb[5];

// data reads: output bits return the output register (pins are driven by this PIA), input bits the pins
always_comb begin
    case (rs)
        2'd0:    dout = cra[2] ? (pa_pins ? pa_i : (ora & ddra) | (pa_i & ~ddra)) : ddra;
        2'd1:    dout = {irqa1, irqa2 & ~cra[5], cra};
        2'd2:    dout = crb[2] ? ((orb & ddrb) | (pb_i & ~ddrb)) : ddrb;
        default: dout = {irqb1, irqb2 & ~crb[5], crb};
    endcase
end

assign irqa = (irqa1 & cra[0]) | (irqa2 & cra[3] & ~cra[5]);
assign irqb = (irqb1 & crb[0]) | (irqb2 & crb[3] & ~crb[5]);

endmodule

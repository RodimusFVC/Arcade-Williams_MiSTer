//============================================================================
//
//  Harris HC-55516 CVSD decoder (software-clocked: the 6808 drives CLK and DIGIT through its PIA)
//  Copyright (C) 2026 Rodimus
//
//  Integer model of the chip's logic as worked out in MAME devices/sound/hc55516.cpp (Gevaryahu, from the die):
//  3-bit coincidence shifter, 12-bit syllabic filter, 10-bit integrator. Rising CLK (active edge): shift in
//  DIGIT, update the syllabic filter, leak the integrator by 1/16. Falling CLK: step the integrator by
//  +/- max(2, syllabic / 64) in the direction of the last bit. The integrator freezes at +/- 0x180 against
//  the current bit. /FZ is not wired (held inactive).
//
//============================================================================

module hc55516
(
    input  logic        clk,
    input  logic        rst,
    input  logic        cvsd_clk,       // pin level
    input  logic        digit,          // pin level
    output logic signed [15:0] out
);

logic        clk_d = 1'b0;
logic  [2:0] sh = 3'd0;
logic [11:0] syl = 12'h03F;
logic signed [9:0] intg = 10'sd0;

wire frozen = (intg >= 10'sd384 && !digit) || (intg <= -10'sd384 && digit);

wire  [2:0] sh_n  = {sh[1:0], digit};
wire        coinc = (sh_n == 3'b000) || (sh_n == 3'b111);
wire [11:0] syl_up = syl + {6'd0, ~syl[11:6]};                         // + ((~syl & FC0) >> 6)
wire [11:0] syl_n  = coinc ? syl_up : syl_up + 12'hFC1;

wire signed [9:0] leak = (~intg >>> 4) + 10'sd1;                       // MAME: sext10((~int >> 4) + 1)
wire        [5:0] mag  = (syl[11:6] < 6'd2) ? 6'd2 : syl[11:6];
wire signed [9:0] step = sh[0] ? -$signed({4'd0, mag}) : $signed({4'd0, mag});

always_ff @(posedge clk) begin
    if (rst) begin
        clk_d <= cvsd_clk;
        sh    <= 3'd0;
        syl   <= 12'h03F;
        intg  <= 10'sd0;
    end else begin
        clk_d <= cvsd_clk;
        if (cvsd_clk && !clk_d) begin                                   // active edge
            sh <= sh_n;
            if (!frozen) begin
                syl  <= syl_n;
                intg <= intg + leak;
            end
        end else if (!cvsd_clk && clk_d) begin                          // inactive edge
            if (!frozen)
                intg <= intg + step;
        end
    end
end

// MAME: (int << 6) | ((int ^ 0x200) >> 4), -512..511 to full 16-bit
assign out = {intg, ~intg[9], intg[8:4]};

endmodule

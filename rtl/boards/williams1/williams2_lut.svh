// Generated from MAME williams_v.cpp williams2_state::calc_col (frgb netlist table): index = {intensity, level}.
// w2_lv: gain 0.25, offset 0 (Inferno, Turkey Shoot). w2_lv_mr/mg/mb: Mystic Marathon (gain .8/.73/.81, offset -.27/0/-.22).
function automatic [7:0] w2_lv(input [7:0] i);
    case (i)
        8'd0: w2_lv = 8'd0; 8'd1: w2_lv = 8'd0; 8'd2: w2_lv = 8'd0; 8'd3: w2_lv = 8'd0; 8'd4: w2_lv = 8'd0; 8'd5: w2_lv = 8'd0; 8'd6: w2_lv = 8'd0; 8'd7: w2_lv = 8'd1;
        8'd8: w2_lv = 8'd1; 8'd9: w2_lv = 8'd1; 8'd10: w2_lv = 8'd3; 8'd11: w2_lv = 8'd5; 8'd12: w2_lv = 8'd7; 8'd13: w2_lv = 8'd12; 8'd14: w2_lv = 8'd20; 8'd15: w2_lv = 8'd32;
        8'd16: w2_lv = 8'd0; 8'd17: w2_lv = 8'd0; 8'd18: w2_lv = 8'd0; 8'd19: w2_lv = 8'd0; 8'd20: w2_lv = 8'd0; 8'd21: w2_lv = 8'd0; 8'd22: w2_lv = 8'd0; 8'd23: w2_lv = 8'd1;
        8'd24: w2_lv = 8'd1; 8'd25: w2_lv = 8'd2; 8'd26: w2_lv = 8'd4; 8'd27: w2_lv = 8'd6; 8'd28: w2_lv = 8'd9; 8'd29: w2_lv = 8'd15; 8'd30: w2_lv = 8'd23; 8'd31: w2_lv = 8'd36;
        8'd32: w2_lv = 8'd0; 8'd33: w2_lv = 8'd0; 8'd34: w2_lv = 8'd0; 8'd35: w2_lv = 8'd0; 8'd36: w2_lv = 8'd0; 8'd37: w2_lv = 8'd0; 8'd38: w2_lv = 8'd1; 8'd39: w2_lv = 8'd2;
        8'd40: w2_lv = 8'd2; 8'd41: w2_lv = 8'd3; 8'd42: w2_lv = 8'd5; 8'd43: w2_lv = 8'd8; 8'd44: w2_lv = 8'd12; 8'd45: w2_lv = 8'd18; 8'd46: w2_lv = 8'd27; 8'd47: w2_lv = 8'd42;
        8'd48: w2_lv = 8'd0; 8'd49: w2_lv = 8'd0; 8'd50: w2_lv = 8'd0; 8'd51: w2_lv = 8'd0; 8'd52: w2_lv = 8'd0; 8'd53: w2_lv = 8'd1; 8'd54: w2_lv = 8'd2; 8'd55: w2_lv = 8'd3;
        8'd56: w2_lv = 8'd3; 8'd57: w2_lv = 8'd5; 8'd58: w2_lv = 8'd7; 8'd59: w2_lv = 8'd11; 8'd60: w2_lv = 8'd15; 8'd61: w2_lv = 8'd22; 8'd62: w2_lv = 8'd32; 8'd63: w2_lv = 8'd48;
        8'd64: w2_lv = 8'd0; 8'd65: w2_lv = 8'd0; 8'd66: w2_lv = 8'd0; 8'd67: w2_lv = 8'd1; 8'd68: w2_lv = 8'd1; 8'd69: w2_lv = 8'd1; 8'd70: w2_lv = 8'd2; 8'd71: w2_lv = 8'd4;
        8'd72: w2_lv = 8'd4; 8'd73: w2_lv = 8'd6; 8'd74: w2_lv = 8'd9; 8'd75: w2_lv = 8'd13; 8'd76: w2_lv = 8'd18; 8'd77: w2_lv = 8'd25; 8'd78: w2_lv = 8'd37; 8'd79: w2_lv = 8'd54;
        8'd80: w2_lv = 8'd0; 8'd81: w2_lv = 8'd0; 8'd82: w2_lv = 8'd1; 8'd83: w2_lv = 8'd1; 8'd84: w2_lv = 8'd1; 8'd85: w2_lv = 8'd2; 8'd86: w2_lv = 8'd3; 8'd87: w2_lv = 8'd5;
        8'd88: w2_lv = 8'd6; 8'd89: w2_lv = 8'd8; 8'd90: w2_lv = 8'd12; 8'd91: w2_lv = 8'd17; 8'd92: w2_lv = 8'd22; 8'd93: w2_lv = 8'd30; 8'd94: w2_lv = 8'd43; 8'd95: w2_lv = 8'd61;
        8'd96: w2_lv = 8'd0; 8'd97: w2_lv = 8'd1; 8'd98: w2_lv = 8'd1; 8'd99: w2_lv = 8'd2; 8'd100: w2_lv = 8'd2; 8'd101: w2_lv = 8'd4; 8'd102: w2_lv = 8'd5; 8'd103: w2_lv = 8'd7;
        8'd104: w2_lv = 8'd8; 8'd105: w2_lv = 8'd11; 8'd106: w2_lv = 8'd15; 8'd107: w2_lv = 8'd21; 8'd108: w2_lv = 8'd26; 8'd109: w2_lv = 8'd36; 8'd110: w2_lv = 8'd50; 8'd111: w2_lv = 8'd70;
        8'd112: w2_lv = 8'd1; 8'd113: w2_lv = 8'd1; 8'd114: w2_lv = 8'd2; 8'd115: w2_lv = 8'd3; 8'd116: w2_lv = 8'd4; 8'd117: w2_lv = 8'd5; 8'd118: w2_lv = 8'd7; 8'd119: w2_lv = 8'd10;
        8'd120: w2_lv = 8'd11; 8'd121: w2_lv = 8'd14; 8'd122: w2_lv = 8'd19; 8'd123: w2_lv = 8'd25; 8'd124: w2_lv = 8'd31; 8'd125: w2_lv = 8'd42; 8'd126: w2_lv = 8'd57; 8'd127: w2_lv = 8'd80;
        8'd128: w2_lv = 8'd2; 8'd129: w2_lv = 8'd2; 8'd130: w2_lv = 8'd3; 8'd131: w2_lv = 8'd4; 8'd132: w2_lv = 8'd5; 8'd133: w2_lv = 8'd7; 8'd134: w2_lv = 8'd9; 8'd135: w2_lv = 8'd12;
        8'd136: w2_lv = 8'd13; 8'd137: w2_lv = 8'd17; 8'd138: w2_lv = 8'd23; 8'd139: w2_lv = 8'd29; 8'd140: w2_lv = 8'd36; 8'd141: w2_lv = 8'd47; 8'd142: w2_lv = 8'd64; 8'd143: w2_lv = 8'd88;
        8'd144: w2_lv = 8'd3; 8'd145: w2_lv = 8'd4; 8'd146: w2_lv = 8'd5; 8'd147: w2_lv = 8'd6; 8'd148: w2_lv = 8'd8; 8'd149: w2_lv = 8'd10; 8'd150: w2_lv = 8'd12; 8'd151: w2_lv = 8'd16;
        8'd152: w2_lv = 8'd17; 8'd153: w2_lv = 8'd22; 8'd154: w2_lv = 8'd28; 8'd155: w2_lv = 8'd35; 8'd156: w2_lv = 8'd43; 8'd157: w2_lv = 8'd56; 8'd158: w2_lv = 8'd74; 8'd159: w2_lv = 8'd101;
        8'd160: w2_lv = 8'd5; 8'd161: w2_lv = 8'd6; 8'd162: w2_lv = 8'd7; 8'd163: w2_lv = 8'd9; 8'd164: w2_lv = 8'd11; 8'd165: w2_lv = 8'd13; 8'd166: w2_lv = 8'd16; 8'd167: w2_lv = 8'd20;
        8'd168: w2_lv = 8'd23; 8'd169: w2_lv = 8'd28; 8'd170: w2_lv = 8'd35; 8'd171: w2_lv = 8'd43; 8'd172: w2_lv = 8'd52; 8'd173: w2_lv = 8'd66; 8'd174: w2_lv = 8'd87; 8'd175: w2_lv = 8'd117;
        8'd176: w2_lv = 8'd7; 8'd177: w2_lv = 8'd9; 8'd178: w2_lv = 8'd11; 8'd179: w2_lv = 8'd13; 8'd180: w2_lv = 8'd15; 8'd181: w2_lv = 8'd18; 8'd182: w2_lv = 8'd21; 8'd183: w2_lv = 8'd26;
        8'd184: w2_lv = 8'd28; 8'd185: w2_lv = 8'd34; 8'd186: w2_lv = 8'd42; 8'd187: w2_lv = 8'd51; 8'd188: w2_lv = 8'd62; 8'd189: w2_lv = 8'd78; 8'd190: w2_lv = 8'd101; 8'd191: w2_lv = 8'd135;
        8'd192: w2_lv = 8'd10; 8'd193: w2_lv = 8'd12; 8'd194: w2_lv = 8'd14; 8'd195: w2_lv = 8'd17; 8'd196: w2_lv = 8'd19; 8'd197: w2_lv = 8'd23; 8'd198: w2_lv = 8'd27; 8'd199: w2_lv = 8'd32;
        8'd200: w2_lv = 8'd35; 8'd201: w2_lv = 8'd42; 8'd202: w2_lv = 8'd51; 8'd203: w2_lv = 8'd61; 8'd204: w2_lv = 8'd73; 8'd205: w2_lv = 8'd91; 8'd206: w2_lv = 8'd117; 8'd207: w2_lv = 8'd155;
        8'd208: w2_lv = 8'd15; 8'd209: w2_lv = 8'd17; 8'd210: w2_lv = 8'd20; 8'd211: w2_lv = 8'd23; 8'd212: w2_lv = 8'd26; 8'd213: w2_lv = 8'd30; 8'd214: w2_lv = 8'd35; 8'd215: w2_lv = 8'd40;
        8'd216: w2_lv = 8'd44; 8'd217: w2_lv = 8'd52; 8'd218: w2_lv = 8'd62; 8'd219: w2_lv = 8'd74; 8'd220: w2_lv = 8'd88; 8'd221: w2_lv = 8'd108; 8'd222: w2_lv = 8'd138; 8'd223: w2_lv = 8'd181;
        8'd224: w2_lv = 8'd21; 8'd225: w2_lv = 8'd24; 8'd226: w2_lv = 8'd27; 8'd227: w2_lv = 8'd31; 8'd228: w2_lv = 8'd35; 8'd229: w2_lv = 8'd39; 8'd230: w2_lv = 8'd45; 8'd231: w2_lv = 8'd52;
        8'd232: w2_lv = 8'd57; 8'd233: w2_lv = 8'd66; 8'd234: w2_lv = 8'd78; 8'd235: w2_lv = 8'd92; 8'd236: w2_lv = 8'd108; 8'd237: w2_lv = 8'd131; 8'd238: w2_lv = 8'd167; 8'd239: w2_lv = 8'd217;
        8'd240: w2_lv = 8'd29; 8'd241: w2_lv = 8'd33; 8'd242: w2_lv = 8'd37; 8'd243: w2_lv = 8'd41; 8'd244: w2_lv = 8'd45; 8'd245: w2_lv = 8'd51; 8'd246: w2_lv = 8'd58; 8'd247: w2_lv = 8'd66;
        8'd248: w2_lv = 8'd72; 8'd249: w2_lv = 8'd83; 8'd250: w2_lv = 8'd97; 8'd251: w2_lv = 8'd113; 8'd252: w2_lv = 8'd132; 8'd253: w2_lv = 8'd160; 8'd254: w2_lv = 8'd201; 8'd255: w2_lv = 8'd254;
    endcase
endfunction
function automatic [7:0] w2_lv_mr(input [7:0] i);
    case (i)
        8'd0: w2_lv_mr = 8'd0; 8'd1: w2_lv_mr = 8'd0; 8'd2: w2_lv_mr = 8'd0; 8'd3: w2_lv_mr = 8'd0; 8'd4: w2_lv_mr = 8'd0; 8'd5: w2_lv_mr = 8'd0; 8'd6: w2_lv_mr = 8'd0; 8'd7: w2_lv_mr = 8'd0;
        8'd8: w2_lv_mr = 8'd0; 8'd9: w2_lv_mr = 8'd0; 8'd10: w2_lv_mr = 8'd0; 8'd11: w2_lv_mr = 8'd0; 8'd12: w2_lv_mr = 8'd0; 8'd13: w2_lv_mr = 8'd0; 8'd14: w2_lv_mr = 8'd0; 8'd15: w2_lv_mr = 8'd0;
        8'd16: w2_lv_mr = 8'd0; 8'd17: w2_lv_mr = 8'd0; 8'd18: w2_lv_mr = 8'd0; 8'd19: w2_lv_mr = 8'd0; 8'd20: w2_lv_mr = 8'd0; 8'd21: w2_lv_mr = 8'd0; 8'd22: w2_lv_mr = 8'd0; 8'd23: w2_lv_mr = 8'd0;
        8'd24: w2_lv_mr = 8'd0; 8'd25: w2_lv_mr = 8'd0; 8'd26: w2_lv_mr = 8'd0; 8'd27: w2_lv_mr = 8'd0; 8'd28: w2_lv_mr = 8'd0; 8'd29: w2_lv_mr = 8'd0; 8'd30: w2_lv_mr = 8'd0; 8'd31: w2_lv_mr = 8'd0;
        8'd32: w2_lv_mr = 8'd0; 8'd33: w2_lv_mr = 8'd0; 8'd34: w2_lv_mr = 8'd0; 8'd35: w2_lv_mr = 8'd0; 8'd36: w2_lv_mr = 8'd0; 8'd37: w2_lv_mr = 8'd0; 8'd38: w2_lv_mr = 8'd0; 8'd39: w2_lv_mr = 8'd0;
        8'd40: w2_lv_mr = 8'd0; 8'd41: w2_lv_mr = 8'd0; 8'd42: w2_lv_mr = 8'd0; 8'd43: w2_lv_mr = 8'd0; 8'd44: w2_lv_mr = 8'd0; 8'd45: w2_lv_mr = 8'd0; 8'd46: w2_lv_mr = 8'd0; 8'd47: w2_lv_mr = 8'd0;
        8'd48: w2_lv_mr = 8'd0; 8'd49: w2_lv_mr = 8'd0; 8'd50: w2_lv_mr = 8'd0; 8'd51: w2_lv_mr = 8'd0; 8'd52: w2_lv_mr = 8'd0; 8'd53: w2_lv_mr = 8'd0; 8'd54: w2_lv_mr = 8'd0; 8'd55: w2_lv_mr = 8'd0;
        8'd56: w2_lv_mr = 8'd0; 8'd57: w2_lv_mr = 8'd0; 8'd58: w2_lv_mr = 8'd0; 8'd59: w2_lv_mr = 8'd0; 8'd60: w2_lv_mr = 8'd0; 8'd61: w2_lv_mr = 8'd0; 8'd62: w2_lv_mr = 8'd0; 8'd63: w2_lv_mr = 8'd0;
        8'd64: w2_lv_mr = 8'd0; 8'd65: w2_lv_mr = 8'd0; 8'd66: w2_lv_mr = 8'd0; 8'd67: w2_lv_mr = 8'd0; 8'd68: w2_lv_mr = 8'd0; 8'd69: w2_lv_mr = 8'd0; 8'd70: w2_lv_mr = 8'd0; 8'd71: w2_lv_mr = 8'd0;
        8'd72: w2_lv_mr = 8'd0; 8'd73: w2_lv_mr = 8'd0; 8'd74: w2_lv_mr = 8'd0; 8'd75: w2_lv_mr = 8'd0; 8'd76: w2_lv_mr = 8'd0; 8'd77: w2_lv_mr = 8'd0; 8'd78: w2_lv_mr = 8'd0; 8'd79: w2_lv_mr = 8'd0;
        8'd80: w2_lv_mr = 8'd0; 8'd81: w2_lv_mr = 8'd0; 8'd82: w2_lv_mr = 8'd0; 8'd83: w2_lv_mr = 8'd0; 8'd84: w2_lv_mr = 8'd0; 8'd85: w2_lv_mr = 8'd0; 8'd86: w2_lv_mr = 8'd0; 8'd87: w2_lv_mr = 8'd0;
        8'd88: w2_lv_mr = 8'd0; 8'd89: w2_lv_mr = 8'd0; 8'd90: w2_lv_mr = 8'd0; 8'd91: w2_lv_mr = 8'd0; 8'd92: w2_lv_mr = 8'd0; 8'd93: w2_lv_mr = 8'd0; 8'd94: w2_lv_mr = 8'd0; 8'd95: w2_lv_mr = 8'd0;
        8'd96: w2_lv_mr = 8'd0; 8'd97: w2_lv_mr = 8'd0; 8'd98: w2_lv_mr = 8'd0; 8'd99: w2_lv_mr = 8'd0; 8'd100: w2_lv_mr = 8'd0; 8'd101: w2_lv_mr = 8'd0; 8'd102: w2_lv_mr = 8'd0; 8'd103: w2_lv_mr = 8'd0;
        8'd104: w2_lv_mr = 8'd0; 8'd105: w2_lv_mr = 8'd0; 8'd106: w2_lv_mr = 8'd0; 8'd107: w2_lv_mr = 8'd0; 8'd108: w2_lv_mr = 8'd0; 8'd109: w2_lv_mr = 8'd0; 8'd110: w2_lv_mr = 8'd0; 8'd111: w2_lv_mr = 8'd5;
        8'd112: w2_lv_mr = 8'd0; 8'd113: w2_lv_mr = 8'd0; 8'd114: w2_lv_mr = 8'd0; 8'd115: w2_lv_mr = 8'd0; 8'd116: w2_lv_mr = 8'd0; 8'd117: w2_lv_mr = 8'd0; 8'd118: w2_lv_mr = 8'd0; 8'd119: w2_lv_mr = 8'd0;
        8'd120: w2_lv_mr = 8'd0; 8'd121: w2_lv_mr = 8'd0; 8'd122: w2_lv_mr = 8'd0; 8'd123: w2_lv_mr = 8'd0; 8'd124: w2_lv_mr = 8'd0; 8'd125: w2_lv_mr = 8'd0; 8'd126: w2_lv_mr = 8'd0; 8'd127: w2_lv_mr = 8'd36;
        8'd128: w2_lv_mr = 8'd0; 8'd129: w2_lv_mr = 8'd0; 8'd130: w2_lv_mr = 8'd0; 8'd131: w2_lv_mr = 8'd0; 8'd132: w2_lv_mr = 8'd0; 8'd133: w2_lv_mr = 8'd0; 8'd134: w2_lv_mr = 8'd0; 8'd135: w2_lv_mr = 8'd0;
        8'd136: w2_lv_mr = 8'd0; 8'd137: w2_lv_mr = 8'd0; 8'd138: w2_lv_mr = 8'd0; 8'd139: w2_lv_mr = 8'd0; 8'd140: w2_lv_mr = 8'd0; 8'd141: w2_lv_mr = 8'd0; 8'd142: w2_lv_mr = 8'd0; 8'd143: w2_lv_mr = 8'd64;
        8'd144: w2_lv_mr = 8'd0; 8'd145: w2_lv_mr = 8'd0; 8'd146: w2_lv_mr = 8'd0; 8'd147: w2_lv_mr = 8'd0; 8'd148: w2_lv_mr = 8'd0; 8'd149: w2_lv_mr = 8'd0; 8'd150: w2_lv_mr = 8'd0; 8'd151: w2_lv_mr = 8'd0;
        8'd152: w2_lv_mr = 8'd0; 8'd153: w2_lv_mr = 8'd0; 8'd154: w2_lv_mr = 8'd0; 8'd155: w2_lv_mr = 8'd0; 8'd156: w2_lv_mr = 8'd0; 8'd157: w2_lv_mr = 8'd0; 8'd158: w2_lv_mr = 8'd19; 8'd159: w2_lv_mr = 8'd104;
        8'd160: w2_lv_mr = 8'd0; 8'd161: w2_lv_mr = 8'd0; 8'd162: w2_lv_mr = 8'd0; 8'd163: w2_lv_mr = 8'd0; 8'd164: w2_lv_mr = 8'd0; 8'd165: w2_lv_mr = 8'd0; 8'd166: w2_lv_mr = 8'd0; 8'd167: w2_lv_mr = 8'd0;
        8'd168: w2_lv_mr = 8'd0; 8'd169: w2_lv_mr = 8'd0; 8'd170: w2_lv_mr = 8'd0; 8'd171: w2_lv_mr = 8'd0; 8'd172: w2_lv_mr = 8'd0; 8'd173: w2_lv_mr = 8'd0; 8'd174: w2_lv_mr = 8'd60; 8'd175: w2_lv_mr = 8'd155;
        8'd176: w2_lv_mr = 8'd0; 8'd177: w2_lv_mr = 8'd0; 8'd178: w2_lv_mr = 8'd0; 8'd179: w2_lv_mr = 8'd0; 8'd180: w2_lv_mr = 8'd0; 8'd181: w2_lv_mr = 8'd0; 8'd182: w2_lv_mr = 8'd0; 8'd183: w2_lv_mr = 8'd0;
        8'd184: w2_lv_mr = 8'd0; 8'd185: w2_lv_mr = 8'd0; 8'd186: w2_lv_mr = 8'd0; 8'd187: w2_lv_mr = 8'd0; 8'd188: w2_lv_mr = 8'd0; 8'd189: w2_lv_mr = 8'd29; 8'd190: w2_lv_mr = 8'd105; 8'd191: w2_lv_mr = 8'd212;
        8'd192: w2_lv_mr = 8'd0; 8'd193: w2_lv_mr = 8'd0; 8'd194: w2_lv_mr = 8'd0; 8'd195: w2_lv_mr = 8'd0; 8'd196: w2_lv_mr = 8'd0; 8'd197: w2_lv_mr = 8'd0; 8'd198: w2_lv_mr = 8'd0; 8'd199: w2_lv_mr = 8'd0;
        8'd200: w2_lv_mr = 8'd0; 8'd201: w2_lv_mr = 8'd0; 8'd202: w2_lv_mr = 8'd0; 8'd203: w2_lv_mr = 8'd0; 8'd204: w2_lv_mr = 8'd15; 8'd205: w2_lv_mr = 8'd71; 8'd206: w2_lv_mr = 8'd156; 8'd207: w2_lv_mr = 8'd255;
        8'd208: w2_lv_mr = 8'd0; 8'd209: w2_lv_mr = 8'd0; 8'd210: w2_lv_mr = 8'd0; 8'd211: w2_lv_mr = 8'd0; 8'd212: w2_lv_mr = 8'd0; 8'd213: w2_lv_mr = 8'd0; 8'd214: w2_lv_mr = 8'd0; 8'd215: w2_lv_mr = 8'd0;
        8'd216: w2_lv_mr = 8'd0; 8'd217: w2_lv_mr = 8'd0; 8'd218: w2_lv_mr = 8'd0; 8'd219: w2_lv_mr = 8'd18; 8'd220: w2_lv_mr = 8'd62; 8'd221: w2_lv_mr = 8'd126; 8'd222: w2_lv_mr = 8'd223; 8'd223: w2_lv_mr = 8'd255;
        8'd224: w2_lv_mr = 8'd0; 8'd225: w2_lv_mr = 8'd0; 8'd226: w2_lv_mr = 8'd0; 8'd227: w2_lv_mr = 8'd0; 8'd228: w2_lv_mr = 8'd0; 8'd229: w2_lv_mr = 8'd0; 8'd230: w2_lv_mr = 8'd0; 8'd231: w2_lv_mr = 8'd0;
        8'd232: w2_lv_mr = 8'd0; 8'd233: w2_lv_mr = 8'd0; 8'd234: w2_lv_mr = 8'd29; 8'd235: w2_lv_mr = 8'd75; 8'd236: w2_lv_mr = 8'd126; 8'd237: w2_lv_mr = 8'd201; 8'd238: w2_lv_mr = 8'd255; 8'd239: w2_lv_mr = 8'd255;
        8'd240: w2_lv_mr = 8'd0; 8'd241: w2_lv_mr = 8'd0; 8'd242: w2_lv_mr = 8'd0; 8'd243: w2_lv_mr = 8'd0; 8'd244: w2_lv_mr = 8'd0; 8'd245: w2_lv_mr = 8'd0; 8'd246: w2_lv_mr = 8'd0; 8'd247: w2_lv_mr = 8'd0;
        8'd248: w2_lv_mr = 8'd12; 8'd249: w2_lv_mr = 8'd45; 8'd250: w2_lv_mr = 8'd90; 8'd251: w2_lv_mr = 8'd143; 8'd252: w2_lv_mr = 8'd205; 8'd253: w2_lv_mr = 8'd255; 8'd254: w2_lv_mr = 8'd255; 8'd255: w2_lv_mr = 8'd255;
    endcase
endfunction
function automatic [7:0] w2_lv_mg(input [7:0] i);
    case (i)
        8'd0: w2_lv_mg = 8'd0; 8'd1: w2_lv_mg = 8'd0; 8'd2: w2_lv_mg = 8'd0; 8'd3: w2_lv_mg = 8'd0; 8'd4: w2_lv_mg = 8'd0; 8'd5: w2_lv_mg = 8'd1; 8'd6: w2_lv_mg = 8'd2; 8'd7: w2_lv_mg = 8'd3;
        8'd8: w2_lv_mg = 8'd3; 8'd9: w2_lv_mg = 8'd5; 8'd10: w2_lv_mg = 8'd9; 8'd11: w2_lv_mg = 8'd15; 8'd12: w2_lv_mg = 8'd22; 8'd13: w2_lv_mg = 8'd36; 8'd14: w2_lv_mg = 8'd58; 8'd15: w2_lv_mg = 8'd93;
        8'd16: w2_lv_mg = 8'd0; 8'd17: w2_lv_mg = 8'd0; 8'd18: w2_lv_mg = 8'd0; 8'd19: w2_lv_mg = 8'd1; 8'd20: w2_lv_mg = 8'd1; 8'd21: w2_lv_mg = 8'd1; 8'd22: w2_lv_mg = 8'd2; 8'd23: w2_lv_mg = 8'd4;
        8'd24: w2_lv_mg = 8'd4; 8'd25: w2_lv_mg = 8'd7; 8'd26: w2_lv_mg = 8'd12; 8'd27: w2_lv_mg = 8'd20; 8'd28: w2_lv_mg = 8'd28; 8'd29: w2_lv_mg = 8'd44; 8'd30: w2_lv_mg = 8'd69; 8'd31: w2_lv_mg = 8'd107;
        8'd32: w2_lv_mg = 8'd0; 8'd33: w2_lv_mg = 8'd0; 8'd34: w2_lv_mg = 8'd1; 8'd35: w2_lv_mg = 8'd1; 8'd36: w2_lv_mg = 8'd1; 8'd37: w2_lv_mg = 8'd2; 8'd38: w2_lv_mg = 8'd4; 8'd39: w2_lv_mg = 8'd6;
        8'd40: w2_lv_mg = 8'd6; 8'd41: w2_lv_mg = 8'd10; 8'd42: w2_lv_mg = 8'd17; 8'd43: w2_lv_mg = 8'd26; 8'd44: w2_lv_mg = 8'd35; 8'd45: w2_lv_mg = 8'd53; 8'd46: w2_lv_mg = 8'd81; 8'd47: w2_lv_mg = 8'd123;
        8'd48: w2_lv_mg = 8'd0; 8'd49: w2_lv_mg = 8'd1; 8'd50: w2_lv_mg = 8'd1; 8'd51: w2_lv_mg = 8'd2; 8'd52: w2_lv_mg = 8'd2; 8'd53: w2_lv_mg = 8'd4; 8'd54: w2_lv_mg = 8'd5; 8'd55: w2_lv_mg = 8'd8;
        8'd56: w2_lv_mg = 8'd9; 8'd57: w2_lv_mg = 8'd15; 8'd58: w2_lv_mg = 8'd22; 8'd59: w2_lv_mg = 8'd33; 8'd60: w2_lv_mg = 8'd44; 8'd61: w2_lv_mg = 8'd64; 8'd62: w2_lv_mg = 8'd95; 8'd63: w2_lv_mg = 8'd140;
        8'd64: w2_lv_mg = 8'd1; 8'd65: w2_lv_mg = 8'd1; 8'd66: w2_lv_mg = 8'd2; 8'd67: w2_lv_mg = 8'd3; 8'd68: w2_lv_mg = 8'd3; 8'd69: w2_lv_mg = 8'd5; 8'd70: w2_lv_mg = 8'd8; 8'd71: w2_lv_mg = 8'd12;
        8'd72: w2_lv_mg = 8'd13; 8'd73: w2_lv_mg = 8'd19; 8'd74: w2_lv_mg = 8'd28; 8'd75: w2_lv_mg = 8'd40; 8'd76: w2_lv_mg = 8'd53; 8'd77: w2_lv_mg = 8'd75; 8'd78: w2_lv_mg = 8'd108; 8'd79: w2_lv_mg = 8'd158;
        8'd80: w2_lv_mg = 8'd1; 8'd81: w2_lv_mg = 8'd2; 8'd82: w2_lv_mg = 8'd3; 8'd83: w2_lv_mg = 8'd4; 8'd84: w2_lv_mg = 8'd5; 8'd85: w2_lv_mg = 8'd8; 8'd86: w2_lv_mg = 8'd11; 8'd87: w2_lv_mg = 8'd16;
        8'd88: w2_lv_mg = 8'd18; 8'd89: w2_lv_mg = 8'd25; 8'd90: w2_lv_mg = 8'd36; 8'd91: w2_lv_mg = 8'd49; 8'd92: w2_lv_mg = 8'd64; 8'd93: w2_lv_mg = 8'd88; 8'd94: w2_lv_mg = 8'd125; 8'd95: w2_lv_mg = 8'd179;
        8'd96: w2_lv_mg = 8'd2; 8'd97: w2_lv_mg = 8'd3; 8'd98: w2_lv_mg = 8'd5; 8'd99: w2_lv_mg = 8'd7; 8'd100: w2_lv_mg = 8'd8; 8'd101: w2_lv_mg = 8'd12; 8'd102: w2_lv_mg = 8'd16; 8'd103: w2_lv_mg = 8'd22;
        8'd104: w2_lv_mg = 8'd25; 8'd105: w2_lv_mg = 8'd34; 8'd106: w2_lv_mg = 8'd46; 8'd107: w2_lv_mg = 8'd61; 8'd108: w2_lv_mg = 8'd78; 8'd109: w2_lv_mg = 8'd105; 8'd110: w2_lv_mg = 8'd146; 8'd111: w2_lv_mg = 8'd206;
        8'd112: w2_lv_mg = 8'd4; 8'd113: w2_lv_mg = 8'd5; 8'd114: w2_lv_mg = 8'd7; 8'd115: w2_lv_mg = 8'd10; 8'd116: w2_lv_mg = 8'd12; 8'd117: w2_lv_mg = 8'd16; 8'd118: w2_lv_mg = 8'd22; 8'd119: w2_lv_mg = 8'd29;
        8'd120: w2_lv_mg = 8'd33; 8'd121: w2_lv_mg = 8'd43; 8'd122: w2_lv_mg = 8'd57; 8'd123: w2_lv_mg = 8'd74; 8'd124: w2_lv_mg = 8'd93; 8'd125: w2_lv_mg = 8'd123; 8'd126: w2_lv_mg = 8'd168; 8'd127: w2_lv_mg = 8'd234;
        8'd128: w2_lv_mg = 8'd6; 8'd129: w2_lv_mg = 8'd7; 8'd130: w2_lv_mg = 8'd10; 8'd131: w2_lv_mg = 8'd13; 8'd132: w2_lv_mg = 8'd16; 8'd133: w2_lv_mg = 8'd21; 8'd134: w2_lv_mg = 8'd28; 8'd135: w2_lv_mg = 8'd36;
        8'd136: w2_lv_mg = 8'd40; 8'd137: w2_lv_mg = 8'd52; 8'd138: w2_lv_mg = 8'd67; 8'd139: w2_lv_mg = 8'd86; 8'd140: w2_lv_mg = 8'd107; 8'd141: w2_lv_mg = 8'd139; 8'd142: w2_lv_mg = 8'd189; 8'd143: w2_lv_mg = 8'd255;
        8'd144: w2_lv_mg = 8'd9; 8'd145: w2_lv_mg = 8'd12; 8'd146: w2_lv_mg = 8'd15; 8'd147: w2_lv_mg = 8'd19; 8'd148: w2_lv_mg = 8'd23; 8'd149: w2_lv_mg = 8'd29; 8'd150: w2_lv_mg = 8'd37; 8'd151: w2_lv_mg = 8'd46;
        8'd152: w2_lv_mg = 8'd52; 8'd153: w2_lv_mg = 8'd65; 8'd154: w2_lv_mg = 8'd82; 8'd155: w2_lv_mg = 8'd104; 8'd156: w2_lv_mg = 8'd127; 8'd157: w2_lv_mg = 8'd163; 8'd158: w2_lv_mg = 8'd218; 8'd159: w2_lv_mg = 8'd255;
        8'd160: w2_lv_mg = 8'd14; 8'd161: w2_lv_mg = 8'd18; 8'd162: w2_lv_mg = 8'd22; 8'd163: w2_lv_mg = 8'd28; 8'd164: w2_lv_mg = 8'd32; 8'd165: w2_lv_mg = 8'd40; 8'd166: w2_lv_mg = 8'd49; 8'd167: w2_lv_mg = 8'd60;
        8'd168: w2_lv_mg = 8'd67; 8'd169: w2_lv_mg = 8'd82; 8'd170: w2_lv_mg = 8'd102; 8'd171: w2_lv_mg = 8'd126; 8'd172: w2_lv_mg = 8'd153; 8'd173: w2_lv_mg = 8'd194; 8'd174: w2_lv_mg = 8'd255; 8'd175: w2_lv_mg = 8'd255;
        8'd176: w2_lv_mg = 8'd21; 8'd177: w2_lv_mg = 8'd26; 8'd178: w2_lv_mg = 8'd32; 8'd179: w2_lv_mg = 8'd38; 8'd180: w2_lv_mg = 8'd44; 8'd181: w2_lv_mg = 8'd53; 8'd182: w2_lv_mg = 8'd63; 8'd183: w2_lv_mg = 8'd76;
        8'd184: w2_lv_mg = 8'd84; 8'd185: w2_lv_mg = 8'd101; 8'd186: w2_lv_mg = 8'd124; 8'd187: w2_lv_mg = 8'd151; 8'd188: w2_lv_mg = 8'd182; 8'd189: w2_lv_mg = 8'd228; 8'd190: w2_lv_mg = 8'd255; 8'd191: w2_lv_mg = 8'd255;
        8'd192: w2_lv_mg = 8'd31; 8'd193: w2_lv_mg = 8'd36; 8'd194: w2_lv_mg = 8'd43; 8'd195: w2_lv_mg = 8'd51; 8'd196: w2_lv_mg = 8'd57; 8'd197: w2_lv_mg = 8'd67; 8'd198: w2_lv_mg = 8'd80; 8'd199: w2_lv_mg = 8'd94;
        8'd200: w2_lv_mg = 8'd104; 8'd201: w2_lv_mg = 8'd123; 8'd202: w2_lv_mg = 8'd149; 8'd203: w2_lv_mg = 8'd180; 8'd204: w2_lv_mg = 8'd214; 8'd205: w2_lv_mg = 8'd255; 8'd206: w2_lv_mg = 8'd255; 8'd207: w2_lv_mg = 8'd255;
        8'd208: w2_lv_mg = 8'd43; 8'd209: w2_lv_mg = 8'd50; 8'd210: w2_lv_mg = 8'd58; 8'd211: w2_lv_mg = 8'd68; 8'd212: w2_lv_mg = 8'd76; 8'd213: w2_lv_mg = 8'd87; 8'd214: w2_lv_mg = 8'd102; 8'd215: w2_lv_mg = 8'd118;
        8'd216: w2_lv_mg = 8'd130; 8'd217: w2_lv_mg = 8'd153; 8'd218: w2_lv_mg = 8'd182; 8'd219: w2_lv_mg = 8'd217; 8'd220: w2_lv_mg = 8'd255; 8'd221: w2_lv_mg = 8'd255; 8'd222: w2_lv_mg = 8'd255; 8'd223: w2_lv_mg = 8'd255;
        8'd224: w2_lv_mg = 8'd63; 8'd225: w2_lv_mg = 8'd71; 8'd226: w2_lv_mg = 8'd81; 8'd227: w2_lv_mg = 8'd92; 8'd228: w2_lv_mg = 8'd102; 8'd229: w2_lv_mg = 8'd115; 8'd230: w2_lv_mg = 8'd133; 8'd231: w2_lv_mg = 8'd152;
        8'd232: w2_lv_mg = 8'd167; 8'd233: w2_lv_mg = 8'd193; 8'd234: w2_lv_mg = 8'd228; 8'd235: w2_lv_mg = 8'd255; 8'd236: w2_lv_mg = 8'd255; 8'd237: w2_lv_mg = 8'd255; 8'd238: w2_lv_mg = 8'd255; 8'd239: w2_lv_mg = 8'd255;
        8'd240: w2_lv_mg = 8'd87; 8'd241: w2_lv_mg = 8'd96; 8'd242: w2_lv_mg = 8'd109; 8'd243: w2_lv_mg = 8'd122; 8'd244: w2_lv_mg = 8'd134; 8'd245: w2_lv_mg = 8'd150; 8'd246: w2_lv_mg = 8'd170; 8'd247: w2_lv_mg = 8'd193;
        8'd248: w2_lv_mg = 8'd212; 8'd249: w2_lv_mg = 8'd242; 8'd250: w2_lv_mg = 8'd255; 8'd251: w2_lv_mg = 8'd255; 8'd252: w2_lv_mg = 8'd255; 8'd253: w2_lv_mg = 8'd255; 8'd254: w2_lv_mg = 8'd255; 8'd255: w2_lv_mg = 8'd255;
    endcase
endfunction
function automatic [7:0] w2_lv_mb(input [7:0] i);
    case (i)
        8'd0: w2_lv_mb = 8'd0; 8'd1: w2_lv_mb = 8'd0; 8'd2: w2_lv_mb = 8'd0; 8'd3: w2_lv_mb = 8'd0; 8'd4: w2_lv_mb = 8'd0; 8'd5: w2_lv_mb = 8'd0; 8'd6: w2_lv_mb = 8'd0; 8'd7: w2_lv_mb = 8'd0;
        8'd8: w2_lv_mb = 8'd0; 8'd9: w2_lv_mb = 8'd0; 8'd10: w2_lv_mb = 8'd0; 8'd11: w2_lv_mb = 8'd0; 8'd12: w2_lv_mb = 8'd0; 8'd13: w2_lv_mb = 8'd0; 8'd14: w2_lv_mb = 8'd0; 8'd15: w2_lv_mb = 8'd0;
        8'd16: w2_lv_mb = 8'd0; 8'd17: w2_lv_mb = 8'd0; 8'd18: w2_lv_mb = 8'd0; 8'd19: w2_lv_mb = 8'd0; 8'd20: w2_lv_mb = 8'd0; 8'd21: w2_lv_mb = 8'd0; 8'd22: w2_lv_mb = 8'd0; 8'd23: w2_lv_mb = 8'd0;
        8'd24: w2_lv_mb = 8'd0; 8'd25: w2_lv_mb = 8'd0; 8'd26: w2_lv_mb = 8'd0; 8'd27: w2_lv_mb = 8'd0; 8'd28: w2_lv_mb = 8'd0; 8'd29: w2_lv_mb = 8'd0; 8'd30: w2_lv_mb = 8'd0; 8'd31: w2_lv_mb = 8'd0;
        8'd32: w2_lv_mb = 8'd0; 8'd33: w2_lv_mb = 8'd0; 8'd34: w2_lv_mb = 8'd0; 8'd35: w2_lv_mb = 8'd0; 8'd36: w2_lv_mb = 8'd0; 8'd37: w2_lv_mb = 8'd0; 8'd38: w2_lv_mb = 8'd0; 8'd39: w2_lv_mb = 8'd0;
        8'd40: w2_lv_mb = 8'd0; 8'd41: w2_lv_mb = 8'd0; 8'd42: w2_lv_mb = 8'd0; 8'd43: w2_lv_mb = 8'd0; 8'd44: w2_lv_mb = 8'd0; 8'd45: w2_lv_mb = 8'd0; 8'd46: w2_lv_mb = 8'd0; 8'd47: w2_lv_mb = 8'd0;
        8'd48: w2_lv_mb = 8'd0; 8'd49: w2_lv_mb = 8'd0; 8'd50: w2_lv_mb = 8'd0; 8'd51: w2_lv_mb = 8'd0; 8'd52: w2_lv_mb = 8'd0; 8'd53: w2_lv_mb = 8'd0; 8'd54: w2_lv_mb = 8'd0; 8'd55: w2_lv_mb = 8'd0;
        8'd56: w2_lv_mb = 8'd0; 8'd57: w2_lv_mb = 8'd0; 8'd58: w2_lv_mb = 8'd0; 8'd59: w2_lv_mb = 8'd0; 8'd60: w2_lv_mb = 8'd0; 8'd61: w2_lv_mb = 8'd0; 8'd62: w2_lv_mb = 8'd0; 8'd63: w2_lv_mb = 8'd0;
        8'd64: w2_lv_mb = 8'd0; 8'd65: w2_lv_mb = 8'd0; 8'd66: w2_lv_mb = 8'd0; 8'd67: w2_lv_mb = 8'd0; 8'd68: w2_lv_mb = 8'd0; 8'd69: w2_lv_mb = 8'd0; 8'd70: w2_lv_mb = 8'd0; 8'd71: w2_lv_mb = 8'd0;
        8'd72: w2_lv_mb = 8'd0; 8'd73: w2_lv_mb = 8'd0; 8'd74: w2_lv_mb = 8'd0; 8'd75: w2_lv_mb = 8'd0; 8'd76: w2_lv_mb = 8'd0; 8'd77: w2_lv_mb = 8'd0; 8'd78: w2_lv_mb = 8'd0; 8'd79: w2_lv_mb = 8'd0;
        8'd80: w2_lv_mb = 8'd0; 8'd81: w2_lv_mb = 8'd0; 8'd82: w2_lv_mb = 8'd0; 8'd83: w2_lv_mb = 8'd0; 8'd84: w2_lv_mb = 8'd0; 8'd85: w2_lv_mb = 8'd0; 8'd86: w2_lv_mb = 8'd0; 8'd87: w2_lv_mb = 8'd0;
        8'd88: w2_lv_mb = 8'd0; 8'd89: w2_lv_mb = 8'd0; 8'd90: w2_lv_mb = 8'd0; 8'd91: w2_lv_mb = 8'd0; 8'd92: w2_lv_mb = 8'd0; 8'd93: w2_lv_mb = 8'd0; 8'd94: w2_lv_mb = 8'd0; 8'd95: w2_lv_mb = 8'd17;
        8'd96: w2_lv_mb = 8'd0; 8'd97: w2_lv_mb = 8'd0; 8'd98: w2_lv_mb = 8'd0; 8'd99: w2_lv_mb = 8'd0; 8'd100: w2_lv_mb = 8'd0; 8'd101: w2_lv_mb = 8'd0; 8'd102: w2_lv_mb = 8'd0; 8'd103: w2_lv_mb = 8'd0;
        8'd104: w2_lv_mb = 8'd0; 8'd105: w2_lv_mb = 8'd0; 8'd106: w2_lv_mb = 8'd0; 8'd107: w2_lv_mb = 8'd0; 8'd108: w2_lv_mb = 8'd0; 8'd109: w2_lv_mb = 8'd0; 8'd110: w2_lv_mb = 8'd0; 8'd111: w2_lv_mb = 8'd46;
        8'd112: w2_lv_mb = 8'd0; 8'd113: w2_lv_mb = 8'd0; 8'd114: w2_lv_mb = 8'd0; 8'd115: w2_lv_mb = 8'd0; 8'd116: w2_lv_mb = 8'd0; 8'd117: w2_lv_mb = 8'd0; 8'd118: w2_lv_mb = 8'd0; 8'd119: w2_lv_mb = 8'd0;
        8'd120: w2_lv_mb = 8'd0; 8'd121: w2_lv_mb = 8'd0; 8'd122: w2_lv_mb = 8'd0; 8'd123: w2_lv_mb = 8'd0; 8'd124: w2_lv_mb = 8'd0; 8'd125: w2_lv_mb = 8'd0; 8'd126: w2_lv_mb = 8'd5; 8'd127: w2_lv_mb = 8'd78;
        8'd128: w2_lv_mb = 8'd0; 8'd129: w2_lv_mb = 8'd0; 8'd130: w2_lv_mb = 8'd0; 8'd131: w2_lv_mb = 8'd0; 8'd132: w2_lv_mb = 8'd0; 8'd133: w2_lv_mb = 8'd0; 8'd134: w2_lv_mb = 8'd0; 8'd135: w2_lv_mb = 8'd0;
        8'd136: w2_lv_mb = 8'd0; 8'd137: w2_lv_mb = 8'd0; 8'd138: w2_lv_mb = 8'd0; 8'd139: w2_lv_mb = 8'd0; 8'd140: w2_lv_mb = 8'd0; 8'd141: w2_lv_mb = 8'd0; 8'd142: w2_lv_mb = 8'd28; 8'd143: w2_lv_mb = 8'd106;
        8'd144: w2_lv_mb = 8'd0; 8'd145: w2_lv_mb = 8'd0; 8'd146: w2_lv_mb = 8'd0; 8'd147: w2_lv_mb = 8'd0; 8'd148: w2_lv_mb = 8'd0; 8'd149: w2_lv_mb = 8'd0; 8'd150: w2_lv_mb = 8'd0; 8'd151: w2_lv_mb = 8'd0;
        8'd152: w2_lv_mb = 8'd0; 8'd153: w2_lv_mb = 8'd0; 8'd154: w2_lv_mb = 8'd0; 8'd155: w2_lv_mb = 8'd0; 8'd156: w2_lv_mb = 8'd0; 8'd157: w2_lv_mb = 8'd0; 8'd158: w2_lv_mb = 8'd60; 8'd159: w2_lv_mb = 8'd147;
        8'd160: w2_lv_mb = 8'd0; 8'd161: w2_lv_mb = 8'd0; 8'd162: w2_lv_mb = 8'd0; 8'd163: w2_lv_mb = 8'd0; 8'd164: w2_lv_mb = 8'd0; 8'd165: w2_lv_mb = 8'd0; 8'd166: w2_lv_mb = 8'd0; 8'd167: w2_lv_mb = 8'd0;
        8'd168: w2_lv_mb = 8'd0; 8'd169: w2_lv_mb = 8'd0; 8'd170: w2_lv_mb = 8'd0; 8'd171: w2_lv_mb = 8'd0; 8'd172: w2_lv_mb = 8'd0; 8'd173: w2_lv_mb = 8'd33; 8'd174: w2_lv_mb = 8'd102; 8'd175: w2_lv_mb = 8'd199;
        8'd176: w2_lv_mb = 8'd0; 8'd177: w2_lv_mb = 8'd0; 8'd178: w2_lv_mb = 8'd0; 8'd179: w2_lv_mb = 8'd0; 8'd180: w2_lv_mb = 8'd0; 8'd181: w2_lv_mb = 8'd0; 8'd182: w2_lv_mb = 8'd0; 8'd183: w2_lv_mb = 8'd0;
        8'd184: w2_lv_mb = 8'd0; 8'd185: w2_lv_mb = 8'd0; 8'd186: w2_lv_mb = 8'd0; 8'd187: w2_lv_mb = 8'd0; 8'd188: w2_lv_mb = 8'd20; 8'd189: w2_lv_mb = 8'd71; 8'd190: w2_lv_mb = 8'd148; 8'd191: w2_lv_mb = 8'd255;
        8'd192: w2_lv_mb = 8'd0; 8'd193: w2_lv_mb = 8'd0; 8'd194: w2_lv_mb = 8'd0; 8'd195: w2_lv_mb = 8'd0; 8'd196: w2_lv_mb = 8'd0; 8'd197: w2_lv_mb = 8'd0; 8'd198: w2_lv_mb = 8'd0; 8'd199: w2_lv_mb = 8'd0;
        8'd200: w2_lv_mb = 8'd0; 8'd201: w2_lv_mb = 8'd0; 8'd202: w2_lv_mb = 8'd0; 8'd203: w2_lv_mb = 8'd18; 8'd204: w2_lv_mb = 8'd56; 8'd205: w2_lv_mb = 8'd113; 8'd206: w2_lv_mb = 8'd199; 8'd207: w2_lv_mb = 8'd255;
        8'd208: w2_lv_mb = 8'd0; 8'd209: w2_lv_mb = 8'd0; 8'd210: w2_lv_mb = 8'd0; 8'd211: w2_lv_mb = 8'd0; 8'd212: w2_lv_mb = 8'd0; 8'd213: w2_lv_mb = 8'd0; 8'd214: w2_lv_mb = 8'd0; 8'd215: w2_lv_mb = 8'd0;
        8'd216: w2_lv_mb = 8'd0; 8'd217: w2_lv_mb = 8'd0; 8'd218: w2_lv_mb = 8'd20; 8'd219: w2_lv_mb = 8'd59; 8'd220: w2_lv_mb = 8'd104; 8'd221: w2_lv_mb = 8'd169; 8'd222: w2_lv_mb = 8'd255; 8'd223: w2_lv_mb = 8'd255;
        8'd224: w2_lv_mb = 8'd0; 8'd225: w2_lv_mb = 8'd0; 8'd226: w2_lv_mb = 8'd0; 8'd227: w2_lv_mb = 8'd0; 8'd228: w2_lv_mb = 8'd0; 8'd229: w2_lv_mb = 8'd0; 8'd230: w2_lv_mb = 8'd0; 8'd231: w2_lv_mb = 8'd0;
        8'd232: w2_lv_mb = 8'd4; 8'd233: w2_lv_mb = 8'd33; 8'd234: w2_lv_mb = 8'd71; 8'd235: w2_lv_mb = 8'd117; 8'd236: w2_lv_mb = 8'd169; 8'd237: w2_lv_mb = 8'd245; 8'd238: w2_lv_mb = 8'd255; 8'd239: w2_lv_mb = 8'd255;
        8'd240: w2_lv_mb = 8'd0; 8'd241: w2_lv_mb = 8'd0; 8'd242: w2_lv_mb = 8'd0; 8'd243: w2_lv_mb = 8'd0; 8'd244: w2_lv_mb = 8'd0; 8'd245: w2_lv_mb = 8'd0; 8'd246: w2_lv_mb = 8'd7; 8'd247: w2_lv_mb = 8'd33;
        8'd248: w2_lv_mb = 8'd53; 8'd249: w2_lv_mb = 8'd87; 8'd250: w2_lv_mb = 8'd133; 8'd251: w2_lv_mb = 8'd186; 8'd252: w2_lv_mb = 8'd248; 8'd253: w2_lv_mb = 8'd255; 8'd254: w2_lv_mb = 8'd255; 8'd255: w2_lv_mb = 8'd255;
    endcase
endfunction

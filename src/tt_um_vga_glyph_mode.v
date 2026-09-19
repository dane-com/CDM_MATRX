/*
 * Copyright (c) 2024-2025 James Ross
 * Enhanced to display "COLEGIO DE MUNTINLUPA MICROELECTRONICS 2026!"
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_vga_glyph_mode(
	input  wire [7:0] ui_in,    // Dedicated inputs
	output wire [7:0] uo_out,   // Dedicated outputs
	input  wire [7:0] uio_in,   // IOs: Input path
	output wire [7:0] uio_out,  // IOs: Output path
	output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
	input  wire       ena,      // always 1 when the design is powered, so you can ignore it
	input  wire       clk,      // clock
	input  wire       rst_n     // reset_n - low to reset
);

	// VGA signals
	wire hsync, vsync, display_on;
	wire [10:0] hpos;
	wire [9:0] vpos;

	// TinyVGA PMOD
	assign uo_out = {hsync, RGB[0], RGB[2], RGB[4], vsync, RGB[1], RGB[3], RGB[5]};

	// Unused outputs assigned to 0.
	assign uio_out = 0;
	assign uio_oe  = 0;

	// xb represents the current column on the screen (0 to 79 on standard VGA)
	wire [7:0] xb = hpos[10:3];
	wire [6:0] x_mix = {xb[7] ^ xb[3], xb[1], xb[4], xb[1], xb[6], xb[0], xb[2]};
	wire [2:0] g_x = hpos[2:0];
	wire [5:0] yb;
	wire [3:0] _unused;
	assign {_unused, yb} = vpos / 10'd12;
	wire [5:0] g_unused;
	wire [3:0] g_y;
	assign {g_unused, g_y} = vpos - {yb, 3'b000} - {1'b0, yb, 2'b00};
	wire hl;

	// Suppress unused signals warning
	wire _unused_ok = &{ena, ui_in[5:2], uio_in};

	reg [9:0] frame;
	reg rst_drop;

	// VGA output
	hvsync_generator hvsync_gen(
		.clk(clk),
		.reset(~rst_n),
		.mode(ui_in[7:6]),
		.hsync(hsync),
		.vsync(vsync),
		.display_on(display_on),
		.hpos(hpos),
		.vpos(vpos)
	);

	// ------------------------------------------------------------------
	// ENHANCED GLYPH MAPPING: "COLEGIO DE MUNTINLUPA MICROELECTRONICS 2026!"
	// ------------------------------------------------------------------
	reg [5:0] text_glyph;
	reg is_space;
	reg is_text_col;

	always @(*) begin
		is_space = 0;
		is_text_col = 1'b1;
		
		// The string is 44 characters long. Centered on the 80-column 
		// screen by starting at column 18 and ending at 61.
		case (xb)
			8'd18: text_glyph = 6'd2;  // C
			8'd19: text_glyph = 6'd14; // O
			8'd20: text_glyph = 6'd11; // L
			8'd21: text_glyph = 6'd4;  // E
			8'd22: text_glyph = 6'd6;  // G
			8'd23: text_glyph = 6'd8;  // I
			8'd24: text_glyph = 6'd14; // O
			8'd25: begin text_glyph = 6'd0; is_space = 1'b1; end
			
			8'd26: text_glyph = 6'd3;  // D
			8'd27: text_glyph = 6'd4;  // E
			8'd28: begin text_glyph = 6'd0; is_space = 1'b1; end
			
			8'd29: text_glyph = 6'd12; // M
			8'd30: text_glyph = 6'd20; // U
			8'd31: text_glyph = 6'd13; // N
			8'd32: text_glyph = 6'd19; // T
			8'd33: text_glyph = 6'd8;  // I
			8'd34: text_glyph = 6'd13; // N
			8'd35: text_glyph = 6'd11; // L
			8'd36: text_glyph = 6'd20; // U
			8'd37: text_glyph = 6'd15; // P
			8'd38: text_glyph = 6'd0;  // A
			8'd39: begin text_glyph = 6'd0; is_space = 1'b1; end
			
			8'd40: text_glyph = 6'd12; // M
			8'd41: text_glyph = 6'd8;  // I
			8'd42: text_glyph = 6'd2;  // C
			8'd43: text_glyph = 6'd17; // R
			8'd44: text_glyph = 6'd14; // O
			8'd45: text_glyph = 6'd4;  // E
			8'd46: text_glyph = 6'd11; // L
			8'd47: text_glyph = 6'd4;  // E
			8'd48: text_glyph = 6'd2;  // C
			8'd49: text_glyph = 6'd19; // T
			8'd50: text_glyph = 6'd17; // R
			8'd51: text_glyph = 6'd14; // O
			8'd52: text_glyph = 6'd13; // N
			8'd53: text_glyph = 6'd8;  // I
			8'd54: text_glyph = 6'd2;  // C
			8'd55: text_glyph = 6'd18; // S
			8'd56: begin text_glyph = 6'd0; is_space = 1'b1; end
			
			8'd57: text_glyph = 6'd28; // 2
			8'd58: text_glyph = 6'd26; // 0
			8'd59: text_glyph = 6'd28; // 2
			8'd60: text_glyph = 6'd32; // 6
			8'd61: text_glyph = 6'd36; // !
			
			// Let the edges of the screen continue the digital rain effect
			default: begin
				text_glyph  = 6'd0;
				is_text_col = 1'b0;
			end
		endcase
	end

	// Generate the standard background rain layout for the screen edges
	wire [5:0] bg_glyph = (yb + xb) % 6'd39;
	
	// Multiplex between the intended text message and the background rain
	wire [5:0] glyph_index = is_text_col ? text_glyph : bg_glyph;

	// glyphs component
	glyphs_rom glyphs(
		.c(glyph_index),
		.y(g_y),
		.x(g_x),
		.pixel(hl)
	);

	// palette component
	wire [5:0] color;
	palette_rom palettes(
		.cid(y),
		.pid(ui_in[1:0]),
		.color(color)
	);
	
	wire [1:0] a = xb[1:0];
	wire [3:0] b = xb[5:2];
	wire [2:0] d = xb[3:2] + 2'd3;

	// column features
	wire s = ^xb[6:0]; // speed of rain
	
	// Turn off "dead columns" for the main text, but let the borders glitch normally
	wire n = is_text_col ? 1'b0 : (xb[1] ^ xb[3] ^ xb[5]);

	wire [6:0] v = (s ? frame[8:2] : frame[9:3]) - yb - x_mix;
	wire [3:0] c = {1'b0, a} + d;
	wire [6:0] e = {3'b000, b} << c;
	wire [6:0] f = v & e;
	wire [6:0] x = v >> a;
	wire [2:0] y = ~x[2:0];
	wire [9:0] drop = {1'b0, yb, 3'd0} >> s;
	wire drop_bit = ({3'd0, x_mix} + drop > frame) & ~rst_drop;
	wire [5:0] glyph_color = {6{drop_bit}} ^ color;

	wire [5:0] z = (&(~v[2:0]) & &(y)) ? 6'd63 : glyph_color;

	// Final output color mix, factoring in word spaces
	wire [5:0] RGB = (display_on & hl & ~is_space & ~(|f | n | drop_bit)) ? z : 6'd0;

	always @(posedge vsync, negedge rst_n) begin
		if (~rst_n) begin
			rst_drop <= 0;
			frame <= 0;
		end else begin
			if (&frame [9:1]) begin
				rst_drop <= 1;
			end
			frame <= frame + 10;
		end
	end

endmodule
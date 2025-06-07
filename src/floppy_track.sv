// 
// Apple ][ track read/write interface to MiST
//
// Based on the work of
// Copyright (c) 2016 Sorgelig
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the Lesser GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//
/////////////////////////////////////////////////////////////////////////

module floppy_track
(
	input         clk,  // apple IIe domain
	input         clk2, // system controller domain
	input         reset,

	output [31:0] sd_lba,
	output reg    sd_rd,
	output reg    sd_wr,
	input         sd_ack,

	input   [8:0] sd_buff_addr,
	input   [7:0] sd_buff_dout,
	output  [7:0] sd_buff_din,
	input         sd_buff_wr,

	input         change,
	input         mount,
	input   [5:0] track,    // Apple
	output        ready,    // Apple
	input         active,   // Apple

	input  [12:0] ram_addr, // Apple DPRAM
	output  [7:0] ram_do,   // Apple DPRAM
	input   [7:0] ram_di,   // Apple DPRAM
	input         ram_we,   // Apple logic + DPRAM
	output        busy      // Apple
);

assign ready = readyD2;
assign busy = busyD2;
assign sd_lba = lba;

reg  [31:0] lba;
reg   [3:0] rel_lba;

always @(posedge clk2) begin
	reg old_ack;
	reg [5:0] cur_track;
	reg old_change;
	reg saving;
	reg dirty;

	old_change <= change;
	old_ack <= sd_ack;

	if(sd_ack) {sd_rd,sd_wr} <= 0;

	if(readyi && ram_weD2) dirty <= 1;

	if(~old_change & change) begin
		readyi <= mount;
		cur_track <= 'b111111;
		busyi  <= 0;
		sd_rd <= 0;
		sd_wr <= 0;
		saving<= 0;
		dirty <= 0;
	end
	else
	if(reset) begin
		cur_track <= 'b111111;
		busyi  <= 0;
		sd_rd <= 0;
		sd_wr <= 0;
		saving<= 0;
		dirty <= 0;
	end
	else

	if(busyi) begin
		if(old_ack && ~sd_ack) begin
			if(rel_lba != 4'd12) begin
				lba <= lba + 1'd1;
				rel_lba <= rel_lba + 1'd1;
				if(saving) sd_wr <= 1;
					else sd_rd <= 1;
			end
			else
			if(saving && (cur_track != trackD2)) begin
				saving <= 0;
				cur_track <= trackD2;
				rel_lba <= 0;
                lba <= trackD2 * 8'd13; //track size = 1a00h = 13*512
				sd_rd <= 1;
			end
			else
			begin
				busyi <= 0;
				dirty <= 0;
			end
		end
	end
	else
	if(readyi && ((cur_track != trackD2) || (old_change && ~change) || (dirty && ~activeD2)))
		if (dirty && cur_track != 'b111111) begin
			saving <= 1;
			lba <= cur_track * 8'd13;
			rel_lba <= 0;
			sd_wr <= 1;
			busyi <= 1;
		end
		else
		begin
			saving <= 0;
			cur_track <= trackD2;
			rel_lba <= 0;
			lba <= trackD2 * 8'd13; //track size = 1a00h
			sd_rd <= 1;
			busyi <= 1;
			dirty <= 0;
		end
end


Gowin_DPB_trkbuf trkbuf_inst(
	.clka(clk2), // system domain
	.dina(sd_buff_dout),
	.douta(sd_buff_din),
	.ada({rel_lba, sd_buff_addr}),
 	.wrea(sd_buff_wr & sd_ack), 
	.ocea(1'b1), 
	.cea(1'b1), 
	.reseta(1'b0), 
	.clkb(clk), 
	.dinb(ram_di),
	.doutb(ram_do), 
	.adb(ram_addr), 
	.wreb(ram_we),
	.oceb(1'b1), 
	.ceb(1'b1), 
	.resetb(1'b0) 
);

reg ram_weD,ram_weD2;
reg [5:0] trackD, trackD2;
reg activeD, activeD2;

always@(posedge clk2) begin : FDD_IN
// input synchronisers
// bring flags from core clock domain into system clock domain
 { ram_weD ,ram_weD2 } <= { ram_we, ram_weD };
 { trackD ,trackD2 } <= { track, trackD };
 { activeD ,activeD2 } <= { active, activeD };
end

reg readyi, readyD, readyD2;
reg busyi, busyD, busyD2;

always@(posedge clk) begin : FDD_OUT
// output synchronisers
// bring flags from system clock domain into core clock domain
 { readyD ,readyD2 } <= { readyi, readyD };
 { busyD ,busyD2 } <= { busyi, busyD };
end


endmodule

// 
// loader_sd_card.sv
// single channel
// 2025 Stefan Voss
//
module loader_sd_card
(
	input clk,
	input reset,

	output reg [31:0] sd_lba,
	output reg sd_rd, // read request for target
	output reg sd_wr, // write request for target
	input sd_busy, // SD is busy (has accepted read or write request)

	input [8:0] sd_byte_index, // address of data byte within 512 bytes sector
	input [7:0] sd_rd_data, // data byte received from SD card
	input sd_rd_byte_strobe, // SD has read a byte to be stored in  buffer
	input sd_done, // SD is done (data has been read or written

	input sd_img_mounted,
	input [31:0] sd_img_size,
	output reg load_rom,
	output reg loader_busy,

	output reg ioctl_download,
	output reg [22:0] ioctl_addr,
	output reg [7:0] ioctl_data,
	output reg ioctl_wr,
	input ioctl_wait
);

// states of FSM
localparam [2:0]	GO4IT			= 3'd0,
					WAIT4CORE		= 3'd1,
					READ_WAIT4SD	= 3'd2,
					READING			= 3'd3,
					READ_NEXT		= 3'd4,
					DESELECT		= 3'd5,
					START			= 3'd6;

always @(posedge clk) begin

reg [2:0] io_state;
reg [22:0] addr;
reg [31:0] ch_timeout;
reg wr;
reg [8:0] cnt;
reg [4:0] core_wait_cnt;
reg [22:0] img_size;
reg img_present;
reg img_presentD;
reg boot_bin;

	img_presentD <= img_present;

	if (sd_img_mounted)
		begin
			img_present <= |sd_img_size;
			img_size <= sd_img_size[22:0];
		end 

	ioctl_wr <= wr;
	wr <= 1'b0;
	if(sd_busy) begin
		sd_rd <= 1'b0;
		sd_wr <= 1'b0; 
	end

	if(reset)
	begin
		sd_rd <= 1'b0;
		sd_wr <= 1'b0;
		wr <= 1'b0;
		load_rom <= 1'b0;
		ioctl_download <= 1'b0;
		ioctl_addr <= 23'd0;
		loader_busy <= 1'b0;
		boot_bin <= 1'b0;
		io_state <= START;
	end
	else
	begin
	case(io_state)

		START:
			begin
				if((img_present && ~img_presentD) || (img_present && ~boot_bin))
					begin
						io_state <= GO4IT;
						boot_bin <= 1'b1;
					end
			end

		GO4IT:
			begin
					loader_busy <= 1;
					load_rom <= 1'b1; 
					ch_timeout <= 32'd1508863;
					ioctl_addr <= 23'd0;
					ioctl_download <= 1'b1;
					addr <= 23'd0;
					sd_lba <= 32'd0;
					core_wait_cnt <= 5'd0;
					io_state <= WAIT4CORE;
			end

		WAIT4CORE: 
			begin
				if(ch_timeout > 0) ch_timeout <= ch_timeout - 1'd1;
				if(ch_timeout == 0 && ~ioctl_wait) 
				begin
					sd_rd <= 1'b1;
					cnt <= 9'd0;
					io_state <= READ_WAIT4SD;
				end
			end

		READ_WAIT4SD:
			if(sd_done)
				io_state <= READING;

		READING: 
			begin
				if(ioctl_addr <= img_size)
					io_state <= READ_NEXT;
				else 
				begin
					ioctl_download <= 1'b0;
					ioctl_addr <= 23'd0;
					io_state <= DESELECT;
				end
			end

		READ_NEXT:
			begin
				core_wait_cnt <= core_wait_cnt + 1'd1;
				if(~ioctl_wait && &core_wait_cnt) 
					begin
						wr <= 1'b1;
						ioctl_addr <= addr;
						addr <= addr + 1'd1;
						cnt <= cnt + 1'd1;
						if(cnt == 511) 
							begin
								sd_lba <= sd_lba + 1'd1;
								ch_timeout <= 32'd1;
								io_state <= WAIT4CORE;
							end
					end
					else
						io_state <= READING;
			end

		DESELECT:
			begin
				load_rom <= 1'b0;
				loader_busy <= 1'b0;
				io_state <= START;
			end

		default: ;

		endcase
	end // else: !if(reset)
end

Gowin_DPB_track_buffer_b trkbuf_inst_loader(
	.douta(), 
	.doutb(ioctl_data),
	.clka(clk), 
	.ocea(1'b1), 
	.cea(1'b1), 
	.reseta(1'b0), 
	.wrea(sd_rd_byte_strobe && sd_busy),// sd module
	.clkb(clk), 
	.oceb(1'b1), 
	.ceb(1'b1),
	.resetb(1'b0), 
	.wreb(1'b0),
	.ada(sd_byte_index),  // sd module
	.dina(sd_rd_data),    // sd module
	.adb(ioctl_addr[8:0]),
	.dinb(8'd0)
);

endmodule

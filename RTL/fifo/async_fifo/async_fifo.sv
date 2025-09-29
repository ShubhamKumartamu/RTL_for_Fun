`timescale 1ns/1ps
module async_fifo #(parameter DEPTH =8, DW =8)
			(
			input wire wclk, rclk, 
			input wire wrstn, rrstn,
			input wire wren, rden,
			input wire [DW-1 : 0] wr_data,
			output reg [DW-1 :0] rd_data,
			output wire full, empty
				);

				reg [$clog2(DEPTH) :0] wr_ptr, rd_ptr;
				reg [$clog2(DEPTH) :0] wr_ptr_gray, rd_ptr_gray;
				reg [$clog2(DEPTH) :0] wr_ptr_gray_d, rd_ptr_gray_d;
				reg [$clog2(DEPTH) :0] wr_ptr_gray_sync, rd_ptr_gray_sync;
				reg [DW-1 : 0] fifo [0 : DEPTH-1];

				//Write Logic

				always @(posedge wclk or negedge wrstn) begin
					if(!wrstn) begin
						wr_ptr <= 'd0;
						wr_ptr_gray <= 'd0;
					end
					else if(wren && !full) begin
						fifo[wr_ptr] <= wr_data;
						wr_ptr       <= wr_ptr + 'b1;
						wr_ptr_gray  <= (wr_ptr+1) ^ ((wr_ptr+1)>>1);
					end
				end

				//write gray pointer sync to read clock
				always @(posedge rclk or negedge rrstn) begin
					if(!rrstn) begin
						wr_ptr_gray_d <= 'd0;
						wr_ptr_gray_sync <= 'd0;
					end
					else begin
					       wr_ptr_gray_d <= wr_ptr_gray;
                                               wr_ptr_gray_sync <= wr_ptr_gray_d;
					end
				end

				//Read Logic 
				always @(posedge rclk or negedge rrstn) begin
					if(!rrstn) begin
					       rd_ptr <= 'd0;
					       rd_ptr_gray <= 'd0;
					end
					else if (rden && !empty) begin
					       rd_data <= fifo[rd_ptr];
					       rd_ptr <= rd_ptr + 'b1;
					       rd_ptr_gray <= (rd_ptr+1) ^ ((rd_ptr+1)>>1);
					end
				end

				//read gray pointer sync to write clock
					always @(posedge wclk or negedge wrstn) begin
					if(!wrstn) begin
						rd_ptr_gray_d <= 'd0;
						rd_ptr_gray_sync <= 'd0;
					end
					else begin
					       rd_ptr_gray_d <= rd_ptr_gray;
                                               rd_ptr_gray_sync <= rd_ptr_gray_d;
					end
				end
				
				//Full and empty conditions

				assign empty = (wr_ptr_gray_sync == rd_ptr_gray);

				assign full = ({~wr_ptr_gray[$clog2(DEPTH)],wr_ptr_gray[$clog2(DEPTH)-1 :0]}==rd_ptr_gray_sync);






endmodule

`timescale 1ns/1ps
module sync_fifo #(parameter DEPTH = 8,
		   parameter DATA_WID = 8)
		   (input wire wr_en, rd_en,
		    input wire clk, rstn,
	    	    input wire [DATA_WID-1 : 0] data_in,
	    	    output wire full, empty,
		    output reg data_vld,
	    	    output reg [DATA_WID-1 : 0] data_out);

	    reg [(DATA_WID)-1:0] mem [0 : DEPTH-1];
	    reg [$clog2(DEPTH)-1 : 0] wr_ptr , rd_ptr, fifo_count;

assign full = (fifo_count == DEPTH -1);
assign empty = (fifo_count == 0);

//Write logic
always @(posedge clk or negedge rstn) begin
    if(!rstn)
    	wr_ptr <= 'd0;
    else if(wr_en && !full) begin
    	mem[wr_ptr] <= data_in;
    	wr_ptr <= wr_ptr + 'b1;
    end
end

//Read logic
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
    	rd_ptr <= 'd0;
    	data_out <= 'd0;
    	data_vld <= 'b0;
    end
    else if(rd_en && !empty) begin
    	data_out <= mem[rd_ptr];
    	rd_ptr <= rd_ptr + 'b1;
    	data_vld <= 'b1;
    end
    else begin
    	data_out <= 'd0;
    	data_vld <= 'b0;
    end
end 

//Fifo Count logic
always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
    	fifo_count <= 'd0;
        end
        else begin
    	case({wr_en && !full , rd_en && !empty })
    		2'b01: fifo_count <= fifo_count - 'b1;
    		2'b10: fifo_count <= fifo_count + 'b1;
    		default : fifo_count <= fifo_count;
    	endcase
        end
end
endmodule

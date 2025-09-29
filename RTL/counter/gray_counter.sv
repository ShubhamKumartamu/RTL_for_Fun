module gray_counter #(parameter WIDTH = 5)
		(input wire clk,
            	input wire rstn,
		input wire en,
		input wire load,
		input wire [WIDTH-1:0] load_count,
		input wire [WIDTH-1:0] up_limit,
		input wire [WIDTH-1:0] down_limit,
		input wire dir,
		output wire [WIDTH-1:0] count);
	reg [WIDTH-1:0] bin_count;
	always @(posedge clk or negedge rstn) begin
		if(!rstn)
			bin_count <= 'd0;
		else if(en && load)
			bin_count <= load_count;
		else if(en && dir && bin_count==up_limit)
			bin_count <= down_limit;
		else if(en && !dir && bin_count==down_limit)
			bin_count <= up_limit;
		else if(en && dir )
			bin_count <= bin_count + 'd1;
		else if(en && !dir)
			bin_count <= bin_count - 'd1;
	end

	assign count = bin_count ^ (bin_count >> 1);
		

endmodule

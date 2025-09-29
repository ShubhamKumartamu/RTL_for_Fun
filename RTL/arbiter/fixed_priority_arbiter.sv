module fixed_priority_arbiter #(parameter N =4)
	(	input wire clk,
	       	input wire rstn,
		input wire en,
       		input wire [N-1:0] req,
		input reg [N-1:0] grant);
wire [N-1:0] nxt_grant;
	always_comb begin
		nxt_grant <= 'd0;
		if(en) begin
			for(int i = 0; i<N; i++) begin
				if(req[i]=='b1 && nxt_grant=='d0) begin
					nxt_grant[i] = 1'b1;
				end
			end
		end
	end

	//Registered output
	always @(posedge clk or negedge rstn) begin
		if(!rstn) begin
			grant <= 'd0;
		end
		else if(en)
			grant <= nxt_grant;
		else
			grant <= grant;
	end
endmodule

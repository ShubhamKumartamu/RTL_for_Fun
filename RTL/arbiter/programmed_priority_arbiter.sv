module prog_priorityArb #(parameter N =4) (
		input wire clk,
	       	input wire rstn,
		input wire en,
       		input wire [N-1:0] req,
		input logic  [$clog2(N)-1 :0] priority_idx [N],

		output reg [N-1:0] grant,
		output logic [$clog2(N)-1 :0] grant_ID
						);
wire [N-1:0] nxt_grant;
wire [$clog2(N)-1:0] nxt_grant_ID;
	always_comb begin
		nxt_grant = 'd0;
		nxt_grant_ID = 'd0;
		if(en) begin
			for(int i = 0; i<N; i++) begin
				if(req[priority_idx[i]]=='b1 && nxt_grant=='d0) begin
					nxt_grant[priority_idx[i]] = 1'b1;
					nxt_grant_ID = i;
				end
			end
		end
	end

//Registered output
	always @(posedge clk or negedge rstn) begin
		if(!rstn) begin
			grant <= 'd0;
			grant_ID <= 'd0;
		end
		else if(en) begin
			grant <= nxt_grant;
			grant_ID <= nxt_grant_ID;
		end
	end
endmodule

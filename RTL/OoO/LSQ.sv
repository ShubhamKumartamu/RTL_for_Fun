module lsq #(
    parameter N  = 16,    // number of LSQ entries
    parameter AW = 8,     // address width
    parameter DW = 8      // data width
)(
    input  wire                 clk,
    input  wire                 rstn,

    // CPU -> LSQ
    input  wire                 load_req,
    input  wire [AW-1:0]        load_addr,
    input  wire                 store_req,
    input  wire [AW-1:0]        store_addr,
    input  wire [DW-1:0]        store_data,

    // LSQ -> CPU
    output reg  [DW-1:0]        load_data,
    output reg                  load_valid,

    // LSQ -> Memory
    output wire                 mem_read_req,
    output wire [AW-1:0]        mem_read_addr,
    output wire [$clog2(N)-1:0] mem_read_id,
    output wire                 mem_write_req,
    output wire [AW-1:0]        mem_write_addr,
    output wire [DW-1:0]        mem_write_data,

    // Memory -> LSQ
    input  wire [$clog2(N)-1:0] mem_read_resp_id,
    input  wire [DW-1:0]        mem_read_data,
    input  wire                 mem_read_valid
);

typedef struct packed  {
			logic valid;
			logic [DW-1:0] data;
			logic load;
			logic [AW-1:0] addr;
			logic ready;
			} lsq_entry;

lsq_entry LSQ [N];
logic [$clog2(N)-1:0] head_ptr, tail_ptr, latest_match;
reg [N-1 : 0] store_forward_match;
logic [DW-1:0] store_forward_data;
   // Circular buffer status
    wire LSQ_full  = ((head_ptr + 1) % N == tail_ptr);
    wire LSQ_empty = (head_ptr == tail_ptr);

always_comb begin
		store_forward_match = 'd0;
	 if (load_req) begin
		for(int i =0; i<N; i++) begin
			if(LSQ[i].addr == load_addr && !LSQ[i].load && LSQ[i].valid) 
				store_forward_match[i] = 'd1;
		end
	end
	else 
		store_forward_match = 'd0;
end
always_comb begin
    latest_match = '0;
    int i = head;
    while (i != tail_ptr) begin
        if (store_forward_match[i])
            latest_match = i;
        i = (i + 1) % N;   // wrap around
    end
end
always @(posedge clk or negedge rstn) begin
	if(!rstn) begin
		store_forward_vld <= 1'b0;
		store_forward_data <= 'd0;
	end
	else if(|store_forward_match) begin
		store_forward_vld <= 1'b1;
		store_forward_data <= LSQ[latest_match].data;
	end
	else begin
		store_forward_vld <= 1'b0;\
		store_forward_data <= 'd0;
	end
end
always @(posedge clk or negedge rstn) begin
	if(!rstn) 
		head_ptr_reg <= '0;
	else
		head_ptr_reg <= head_ptr;
end
assign mem_read_req = load_req;
assign mem_read_addr = load_addr;
assign mem_read_id = head_ptr;


always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            head_ptr <= '0;
            tail_ptr <= '0;
	    load_valid <= 1'b0;
	    load_data <= 'd0;
	    mem_write_req <= 1'b0;
	    mem_write_data <= '0;
	    mem_write_addr <= '0;

            for (int i = 0; i < N; i++) begin
                LSQ[i].valid <= 1'b0;
                LSQ[i].data  <= '0;
                LSQ[i].load  <= '0;
                LSQ[i].addr  <= '0;
                LSQ[i].ready  <= '0;
            end
        end else begin
            // Enqueue new request
            if (load_req && !LSQ_full) begin
                LSQ[head_ptr].valid <= 1'b0; // not ready yet
		LSQ[head_ptr].load  <= 1'b1;
		LSQ[head_ptr].ready  <= 1'b1; 	
		LSQ[head_ptr].addr  <= load_addr;
                head_ptr <= head_ptr + 1'b1;
            end
	    else if (store_req && !LSQ_full) begin
                LSQ[head_ptr].valid <= 1'b1;
		LSQ[head_ptr].load  <= 1'b0;
		LSQ[head_ptr].ready  <= 1'b1;//For now make ready on LSQ entry allocation can change it to wait for a commit signal indicating store data is now comited nd ready

		LSQ[head_ptr].addr  <= store_addr;
		LSQ[head_ptr].data  <= store_data;
                head_ptr <= head_ptr + 1'b1;
            end

	    if(store_forward_vld) begin
		LSQ[head_ptr_reg].valid <= 1'b1; // not ready yet
		LSQ[head_ptr_reg].data  <= store_forward_data;
	    end

            // Capture memory response (out of order)
            else if (mem_read_valid) begin
                LSQ[mem_read_resp_id].data  <= mem_read_data;
                LSQ[mem_read_resp_id].valid <= 1'b1;
            end

            // Retire in-order to CPU
            if (LSQ[tail_ptr].valid && LSQ[tail_ptr].load) begin
		    load_valid <= 1'b1;
		    load_data <= LSQ[tail_ptr].data;
                LSQ[tail_ptr].valid <= 1'b0;
                tail_ptr <= tail_ptr + 1'b1;
            end
	    else if(LSQ[tail_ptr].valid && !LSQ[tail_ptr].load && LSQ[tail_ptr].ready) begin
		mem_write_req <= 1'b1;
		mem_write_addr <= LSQ[tail_ptr].addr;
		mem_write_data <= LSQ[tail_ptr].data;
		 LSQ[tail_ptr].valid <= 1'b0;
		 LSQ[tail_ptr].ready <= 1'b0;
                tail_ptr <= tail_ptr + 1'b1;
		load_valid <= 1'b0;
	    end
	    else begin 
		    load_valid <= 1'b0;
		    mem_write_req <= 1'b0;
	    end
	    
        end
    end





endmodule

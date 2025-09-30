//CPU sends read_req to this block with read_addr
//Bounded number of requests can come from CPU continuously(128 requests)
//Memory can serve requests with variable latency out of order
//This block should serve the requests in-order to the CPU
module mem_rob #(
    parameter N  = 16,
    parameter AW = 8,
    parameter DW = 8
)(
    input  wire                clk,
    input  wire                rstn,

    // CPU -> ROB
    input  wire                cpu_read_req,
    input  wire [AW-1:0]       cpu_read_addr,
    output wire [DW-1:0]       cpu_read_data,
    output wire                cpu_read_valid,

    // ROB -> MEM
    output wire [AW-1:0]       mem_read_addr,
    output wire                mem_read_req,
    output wire [$clog2(N)-1:0] mem_req_id,

    // MEM -> ROB
    input  wire [$clog2(N)-1:0] mem_resp_id,
    input  wire [DW-1:0]       mem_rd_data,
    input  wire                mem_rd_vld
);

    typedef struct packed {
        logic                  valid;
        logic [DW-1:0]         data;
    } rob_entry_t;

    rob_entry_t rob [N];
    logic [$clog2(N)-1:0] head_ptr, tail_ptr;

    // Circular buffer status
    wire rob_full  = ((head_ptr + 1) % N == tail_ptr);
    wire rob_empty = (head_ptr == tail_ptr);

    // Direct pass-through of request to memory
    assign mem_read_addr = cpu_read_addr;
    assign mem_read_req  = cpu_read_req && !rob_full;
    assign mem_req_id    = head_ptr;

    // CPU output
    assign cpu_read_valid = !rob_empty && rob[tail_ptr].valid;
    assign cpu_read_data  = rob[tail_ptr].data;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            head_ptr <= '0;
            tail_ptr <= '0;
            for (int i = 0; i < N; i++) begin
                rob[i].valid <= 1'b0;
                rob[i].data  <= '0;
            end
        end else begin
            // Enqueue new request
            if (cpu_read_req && !rob_full) begin
                rob[head_ptr].valid <= 1'b0; // not ready yet
                head_ptr <= head_ptr + 1'b1;
            end

            // Capture memory response (out of order)
            if (mem_rd_vld) begin
                rob[mem_resp_id].data  <= mem_rd_data;
                rob[mem_resp_id].valid <= 1'b1;
            end

            // Retire in-order to CPU
            if (cpu_read_valid) begin
                rob[tail_ptr].valid <= 1'b0;
                tail_ptr <= tail_ptr + 1'b1;
            end
        end
    end
endmodule

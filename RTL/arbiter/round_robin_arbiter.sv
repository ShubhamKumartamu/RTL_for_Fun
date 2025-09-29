
`timescale 1ns/1ps

module round_robinArb #(parameter N = 4) (
    input  logic                  clk,
    input  logic                  rstn,
    input  logic                  en,
    input  logic [N-1:0]          req,

    output logic [N-1:0]          grant,
    output logic [$clog2(N)-1:0]  grant_ID
);

    logic [N-1:0]                 nxt_grant;
    logic [$clog2(N)-1:0]         nxt_grant_ID;

    logic [$clog2(N)-1:0]         priority_idx [N];
    logic [$clog2(N)-1:0]         tmp_idx [N];

    // Combinational arbitration
    always_comb begin
        nxt_grant    = '0;
        nxt_grant_ID = '0;

        for (int i = 0; i < N; i++) tmp_idx[i] = priority_idx[i]; // default

        if (en) begin
            for (int i = 0; i < N; i++) begin
                if (req[priority_idx[i]] && nxt_grant == '0) begin
                    nxt_grant[priority_idx[i]] = 1'b1;
                    nxt_grant_ID              = priority_idx[i];

                    // Rotate priority list
                    for (int j = 0; j < i; j++) tmp_idx[j] = priority_idx[j];
                    for (int j = i+1; j < N; j++) tmp_idx[j-1] = priority_idx[j];
                    tmp_idx[N-1] = priority_idx[i];
                end
            end
        end
    end

    // Registered output and priority_idx update
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            grant     <= '0;
            grant_ID  <= '0;
            for (int i = 0; i < N; i++) priority_idx[i] <= i;
        end else if (en) begin
            grant     <= nxt_grant;
            grant_ID  <= nxt_grant_ID;
            for (int i = 0; i < N; i++) priority_idx[i] <= tmp_idx[i];
        end
    end
endmodule


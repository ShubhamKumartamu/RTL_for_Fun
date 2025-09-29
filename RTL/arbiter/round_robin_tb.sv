`timescale 1ns/1ps

module tb_prog_priorityArb;

    parameter N = 4;

    logic                  clk;
    logic                  rstn;
    logic                  en;
    logic [N-1:0]         req;
    logic [N-1:0]         grant;
    logic [$clog2(N)-1:0] grant_ID;

    // Instantiate DUT
    round_robinArb #(N) dut (
        .clk(clk),
        .rstn(rstn),
        .en(en),
        .req(req),
        .grant(grant),
        .grant_ID(grant_ID)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // Test stimulus
    initial begin
        rstn = 0;
        en   = 0;
        req  = 0;

        #20 rstn = 1;       // Release reset
        en   = 1;

        $display("Starting programmable priority arbiter testbench...");

        // Test round-robin priority rotation
        test_case(4'b1010, 5); // Requests from req[1] and req[3]
        test_case(4'b0110, 5); // Requests from req[1] and req[2]
        test_case(4'b1111, 5); // All requests active
        test_case(4'b0001, 5); // Only req[0]
        test_case(4'b1000, 5); // Only req[3]

        #20;
        $display("Test complete.");
        $finish;
    end

    // Task: Apply requests and check rotation
    task test_case(input logic [N-1:0] requests, input int cycles);
        begin
            req = requests;
            for (int i = 0; i < cycles; i++) begin
                @(posedge clk);
                $display("[%0t] Cycle=%0d | req=%b grant=%b grant_ID=%0d",
                         $time, i, req, grant, grant_ID);

                // Rotate requests artificially to simulate multiple requests
                req = {req[N-2:0], req[N-1]};
            end
            req = 0;
        end
    endtask

endmodule


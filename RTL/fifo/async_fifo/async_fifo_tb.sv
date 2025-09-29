`timescale 1ns/1ps
module tb_async_fifo;

    parameter DEPTH = 8;
    parameter DW    = 8;

    reg                 wclk, rclk;
    reg                 wrstn, rrstn;
    reg                 wren, rden;
    reg  [DW-1:0]      wr_data;
    wire [DW-1:0]      rd_data;
    wire                full, empty;

    integer i;

    // Reference FIFO model
    reg [DW-1:0] fifo_ref [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wr_ptr_ref, rd_ptr_ref;
    reg [$clog2(DEPTH):0] wr_ptr_gray_ref, rd_ptr_gray_ref;
    reg [$clog2(DEPTH):0] wr_ptr_gray_d_ref, wr_ptr_gray_sync_ref;
    reg [$clog2(DEPTH):0] rd_ptr_gray_d_ref, rd_ptr_gray_sync_ref;
    reg [DW-1:0] expected_data;

    // Instantiate FIFO
    async_fifo #(DEPTH, DW) uut (
        .wclk(wclk),
        .rclk(rclk),
        .wrstn(wrstn),
        .rrstn(rrstn),
        .wren(wren),
        .rden(rden),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .full(full),
        .empty(empty)
    );

    // Clock generation
    initial begin
        wclk = 0;
        forever #4 wclk = ~wclk; // 8ns period
    end

    initial begin
        rclk = 0;
        forever #6 rclk = ~rclk; // 12ns period
    end

    // Reset and stimulus
    initial begin
        wrstn = 0; rrstn = 0;
        wren = 0; rden = 0;
        wr_data = 0;

        wr_ptr_ref = 0; rd_ptr_ref = 0;
        wr_ptr_gray_ref = 0; rd_ptr_gray_ref = 0;

        wr_ptr_gray_d_ref = 0; wr_ptr_gray_sync_ref = 0;
        rd_ptr_gray_d_ref = 0; rd_ptr_gray_sync_ref = 0;

        $display("Starting async FIFO testbench...");
        #20;
        wrstn = 1; rrstn = 1;

        // Write some data
        for (i = 0; i < 10; i = i+1) begin
            write_data(i*10 + 8'hAA);
        end

        // Read some data
        for (i = 0; i < 5; i = i+1) begin
            read_data();
        end

        // Continue random read/write
        repeat (20) begin
            @(posedge wclk);
            wren = $urandom_range(0,1);
            wr_data = $urandom_range(0,255);

            @(posedge rclk);
            rden = $urandom_range(0,1);
        end

        #100;
        $display("Test complete.");
        $finish;
    end

    // Write pointer model in wclk domain
    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            wr_ptr_ref = 0;
            wr_ptr_gray_ref = 0;
        end else if (wren && !full) begin
            fifo_ref[wr_ptr_ref[$clog2(DEPTH)-1:0]] = wr_data;
            wr_ptr_ref = wr_ptr_ref + 1;
            wr_ptr_gray_ref = wr_ptr_ref ^ (wr_ptr_ref >> 1);
            $display("[%0t] WRITE: data=%h wr_ptr=%0d rd_ptr=%0d fifo_count=%0d", 
                      $time, wr_data, wr_ptr_ref, rd_ptr_ref, wr_ptr_ref-rd_ptr_ref);
        end
    end

    // Synchronize wr_ptr_gray to read clock domain
    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            wr_ptr_gray_d_ref    <= 0;
            wr_ptr_gray_sync_ref <= 0;
        end else begin
            wr_ptr_gray_d_ref    <= wr_ptr_gray_ref;
            wr_ptr_gray_sync_ref <= wr_ptr_gray_d_ref;
        end
    end

    // Read pointer model in rclk domain
    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            rd_ptr_ref = 0;
            rd_ptr_gray_ref = 0;
        end else if (rden && !empty) begin
            expected_data = fifo_ref[rd_ptr_ref[$clog2(DEPTH)-1:0]];
            if (rd_data !== expected_data) begin
                $error("[%0t] READ ERROR: expected=%h, got=%h rd_ptr=%0d wr_ptr=%0d", 
                       $time, expected_data, rd_data, rd_ptr_ref, wr_ptr_ref);
            end else begin
                $display("[%0t] READ: data=%h rd_ptr=%0d wr_ptr=%0d fifo_count=%0d", 
                         $time, rd_data, rd_ptr_ref, wr_ptr_ref, wr_ptr_ref-rd_ptr_ref);
            end
            rd_ptr_ref = rd_ptr_ref + 1;
            rd_ptr_gray_ref = rd_ptr_ref ^ (rd_ptr_ref >> 1);
        end
    end

    // Synchronize rd_ptr_gray to write clock domain
    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            rd_ptr_gray_d_ref    <= 0;
            rd_ptr_gray_sync_ref <= 0;
        end else begin
            rd_ptr_gray_d_ref    <= rd_ptr_gray_ref;
            rd_ptr_gray_sync_ref <= rd_ptr_gray_d_ref;
        end
    end

    // Tasks
    task write_data(input [DW-1:0] value);
    begin
        @(posedge wclk);
        if (!full) begin
            wren = 1;
            wr_data = value;
        end else begin
            $display("[%0t] WRITE BLOCKED: FIFO FULL", $time);
        end
        @(posedge wclk);
        wren = 0;
        wr_data = 0;
    end
    endtask

    task read_data();
    begin
        @(posedge rclk);
        if (!empty) begin
            rden = 1;
        end else begin
            $display("[%0t] READ BLOCKED: FIFO EMPTY", $time);
        end
        @(posedge rclk);
        rden = 0;
    end
    endtask

endmodule


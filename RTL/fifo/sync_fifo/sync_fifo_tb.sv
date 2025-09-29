`timescale 1ns/1ps

module tb_sync_fifo;

  // Parameters
  parameter DEPTH    = 8;
  parameter DATA_WID = 8;

  // Signals
  reg                  wr_en;
  reg                  rd_en;
  reg                  clk;
  reg                  rstn;
  reg  [DATA_WID-1:0] data_in;
  wire                 full;
  wire                 empty;
  wire                 data_vld;
  wire [DATA_WID-1:0] data_out;

  // Instantiate FIFO
  sync_fifo #(DEPTH, DATA_WID) uut (
    .wr_en(wr_en),
    .rd_en(rd_en),
    .clk(clk),
    .rstn(rstn),
    .data_in(data_in),
    .full(full),
    .empty(empty),
    .data_vld(data_vld),
    .data_out(data_out)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100 MHz clock
  end

  // Reference model
  reg [DATA_WID-1:0] fifo_ref [0:DEPTH-1];
  integer head, tail, count;

  // Test stimulus
  initial begin
    // Init
    wr_en    = 0;
    rd_en    = 0;
    rstn     = 0;
    data_in  = 0;

    head = 0;
    tail = 0;
    count = 0;

    $display("Starting testbench...");
    $monitor("%0t | wr_en=%b rd_en=%b full=%b empty=%b data_in=%h data_out=%h", 
             $time, wr_en, rd_en, full, empty, data_in, data_out);

    // Reset
    @(posedge clk);
    rstn = 0;
    @(posedge clk);
    rstn = 1;

    // Write some data
    write_data(8'hA1);
    write_data(8'hB2);
    write_data(8'hC3);

    // Read data
    read_data();
    read_data();

    // Write more data
    write_data(8'hD4);
    write_data(8'hE5);

    // Read remaining data
    read_data();
    read_data();
    read_data();

    // Test over
    #20;
    $display("Test complete.");
    $finish;
  end

  // Task: Write data to FIFO
  task write_data(input [DATA_WID-1:0] value);
    begin
      @(posedge clk);
      wr_en    = 1;
      data_in  = value;

      // Update reference model
      if (count < DEPTH) begin
        fifo_ref[tail] = value;
        tail = (tail + 1) % DEPTH;
        count = count + 1;
      end

      @(posedge clk);
      wr_en    = 0;
      data_in  = 0;
    end
  endtask

  // Task: Read data from FIFO
  task read_data();
    begin
      @(posedge clk);
      rd_en = 1;

      @(posedge clk);
      rd_en = 0;

      // Check output
      if (data_vld) begin
        if (count > 0) begin
          if (data_out !== fifo_ref[head]) begin
            $error("Data mismatch at time %0t: expected %h, got %h", 
                    $time, fifo_ref[head], data_out);
          end else begin
            $display("Check passed at time %0t: data_out=%h", $time, data_out);
          end
          head = (head + 1) % DEPTH;
          count = count - 1;
        end else begin
          $error("Read from empty FIFO at time %0t", $time);
        end
      end
    end
  endtask

endmodule


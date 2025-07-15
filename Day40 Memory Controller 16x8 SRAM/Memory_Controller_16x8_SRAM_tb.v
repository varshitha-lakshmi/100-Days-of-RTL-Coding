module tb_memory_controller;
  reg clk, rst_n, start, rw;
  reg [3:0] addr;
  reg [7:0] data_in;
  wire [7:0] data_out;
  wire ce_n, we_n, oe_n, done;

  // Instantiate Memory Controller
  memory_controller uut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .rw(rw),
    .addr(addr),
    .data_in(data_in),
    .data_out(data_out),
    .ce_n(ce_n),
    .we_n(we_n),
    .oe_n(oe_n),
    .done(done)
  );

  // Clock generation: 10ns period (100 MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test stimulus
  initial begin
    // Initialize signals
    rst_n = 0; start = 0; rw = 0; addr = 4'h0; data_in = 8'h00;
    #20; // Hold reset for 20ns
    rst_n = 1; // Release reset
    #20;
    // Write transaction: address 5, data 0xAA
    start = 1; rw = 0; addr = 4'h5; data_in = 8'hAA; #10;
    start = 0; #30; // Wait for transaction (SETUP, ACCESS, DONE)
    // Read transaction: address 5
    start = 1; rw = 1; addr = 4'h5; #10;
    start = 0; #30;
    // Reset
    rst_n = 0; #20;
    rst_n = 1; #20;
    $finish; // End simulation
  end

  // Dump waveform
  initial begin
    $dumpfile("memory_controller.vcd");
    $dumpvars(0, tb_memory_controller);
  end
endmodule
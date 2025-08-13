module tb_pipelined_multiplier;
  reg clk, rst_n, start;
  reg [7:0] a, b;
  wire [15:0] result;
  wire done;

  // Instantiate Pipelined Multiplier
  pipelined_multiplier uut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .a(a),
    .b(b),
    .result(result),
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
    rst_n = 0; start = 0; a = 0; b = 0;
    #20; // Hold reset for 20ns
    rst_n = 1; // Release reset
    #10;
    // Test 1: 5 * 3 = 15
    a = 8'd5; b = 8'd3; start = 1; #10;
    start = 0; #30;
    // Test 2: 4 * 6 = 24
    a = 8'd4; b = 8'd6; start = 1; #10;
    start = 0; #50;
    // Reset
    rst_n = 0; #20;
    rst_n = 1; #20;
    $finish; // End simulation
  end

  // Dump waveform
  initial begin
    $dumpfile("pipelined_multiplier.vcd");
    $dumpvars(0, tb_pipelined_multiplier);
  end
endmodule
module tb_floating_point_adder;
  reg clk, rst_n, start;
  reg [31:0] a, b;
  wire [31:0] result;
  wire done;

  // Instantiate Floating-Point Adder
  floating_point_adder uut (
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
    rst_n = 1; #10;
    // Test 1: 2.5 + 3.5 = 6.0
    // 2.5 = 0_10000000_01000000000000000000000 (0x40200000)
    // 3.5 = 0_10000001_11000000000000000000000 (0x40600000)
    // 6.0 = 0_10000010_10000000000000000000000 (0x40C00000)
    a = 32'h40200000; b = 32'h40600000; start = 1; #10;
    start = 0; #50;
    // Test 2: 1.5 + 2.0 = 3.5
    // 1.5 = 0_10000000_10000000000000000000000 (0x3FC00000)
    // 2.0 = 0_10000000_00000000000000000000000 (0x40000000)
    // 3.5 = 0_10000001_11000000000000000000000 (0x40600000)
    a = 32'h3FC00000; b = 32'h40000000; start = 1; #10;
    start = 0; #50;
    // Reset
    rst_n = 0; #20;
    rst_n = 1; #20;
    $finish;
  end

  // Dump waveform
  initial begin
    $dumpfile("floating_point_adder.vcd");
    $dumpvars(0, tb_floating_point_adder);
  end
endmodule
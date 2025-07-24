module tb_matrix_multiplier;
  reg clk, rst_n, start;
  reg [7:0] a11, a12, a21, a22;
  reg [7:0] b11, b12, b21, b22;
  wire [15:0] c11, c12, c21, c22;
  wire done;

  // Instantiate Matrix Multiplier
  matrix_multiplier uut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .a11(a11), .a12(a12), .a21(a21), .a22(a22),
    .b11(b11), .b12(b12), .b21(b21), .b22(b22),
    .c11(c11), .c12(c12), .c21(c21), .c22(c22),
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
    rst_n = 0; start = 0;
    a11 = 0; a12 = 0; a21 = 0; a22 = 0;
    b11 = 0; b12 = 0; b21 = 0; b22 = 0;
    #20; // Hold reset for 20ns
    rst_n = 1; // Release reset
    #20;
    // Test: A = [2,3;4,5], B = [1,2;3,4]
    a11 = 8'd2; a12 = 8'd3; a21 = 8'd4; a22 = 8'd5;
    b11 = 8'd1; b12 = 8'd2; b21 = 8'd3; b22 = 8'd4;
    start = 1; #10;
    start = 0;
    #50; // Wait for computation
    // Reset
    rst_n = 0; #20;
    rst_n = 1; #20;
    $finish; // End simulation
  end

  // Dump waveform
  initial begin
    $dumpfile("matrix_multiplier.vcd");
    $dumpvars(0, tb_matrix_multiplier);
  end
endmodule
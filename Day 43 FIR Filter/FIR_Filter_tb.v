module tb_fir_filter;
  reg clk, rst_n, valid_in;
  reg signed [7:0] x_in;
  wire signed [15:0] y_out;
  wire valid_out;

  // Instantiate FIR Filter
  fir_filter uut (
    .clk(clk),
    .rst_n(rst_n),
    .x_in(x_in),
    .valid_in(valid_in),
    .y_out(y_out),
    .valid_out(valid_out)
  );

  // Clock generation: 10ns period (100 MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test stimulus
  initial begin
    // Initialize signals
    rst_n = 0; valid_in = 0; x_in = 8'd0;
    #20; // Hold reset for 20ns
    rst_n = 1; // Release reset
    #20;
    // Input sequence: 0 (4 samples), 10 (4 samples), 0 (4 samples)
    repeat (4) begin
      valid_in = 1; x_in = 8'd0; #10;
      valid_in = 0; #30;
    end
    repeat (4) begin
      valid_in = 1; x_in = 8'd10; #10;
      valid_in = 0; #30;
    end
    repeat (4) begin
      valid_in = 1; x_in = 8'd0; #10;
      valid_in = 0; #30;
    end
    // Reset
    rst_n = 0; #20;
    rst_n = 1; #20;
    $finish; // End simulation
  end

  // Dump waveform
  initial begin
    $dumpfile("fir_filter.vcd");
    $dumpvars(0, tb_fir_filter);
  end
endmodule
module tb_simple_cpu_data_path;
  reg clk, rst_n;
  wire [7:0] result;
  wire done;

  // Instantiate Simple CPU Data Path
  simple_cpu_data_path uut (
    .clk(clk),
    .rst_n(rst_n),
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
    rst_n = 0;
    #20; // Hold reset for 20ns
    rst_n = 1; // Release reset
    #200; // Wait for 4 instructions (4 * ~50ns)
    rst_n = 0; #20;
    rst_n = 1; #20;
    $finish; // End simulation
  end

  // Dump waveform
  initial begin
    $dumpfile("simple_cpu_data_path.vcd");
    $dumpvars(0, tb_simple_cpu_data_path);
  end
endmodule
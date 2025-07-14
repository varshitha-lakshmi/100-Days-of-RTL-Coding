module tb_spi_master;
  reg clk, rst_n, start;
  reg [7:0] data_in;
  wire sclk, mosi, cs, done;

  // Instantiate SPI Master Controller
  spi_master uut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .data_in(data_in),
    .sclk(sclk),
    .mosi(mosi),
    .cs(cs),
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
    rst_n = 0; start = 0; data_in = 8'h00;
    #20; // Hold reset for 20ns
    rst_n = 1; // Release reset
    #20;
    // Start SPI write transaction
    data_in = 8'hAA; // Data to write (10101010)
    start = 1; #10;
    start = 0; #10000; // Wait ~10µs (8 SCLK cycles + overhead)
    // Reset
    rst_n = 0; #20;
    rst_n = 1; #20;
    $finish; // End simulation
  end

  // Dump waveform
  initial begin
    $dumpfile("spi_master.vcd");
    $dumpvars(0, tb_spi_master);
  end
endmodule
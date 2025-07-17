module tb_uart_to_spi_bridge;
  reg clk, rst_n, rx;
  wire sclk, mosi, cs_n, done;

  // Instantiate UART-to-SPI Bridge
  uart_to_spi_bridge uut (
    .clk(clk),
    .rst_n(rst_n),
    .rx(rx),
    .sclk(sclk),
    .mosi(mosi),
    .cs_n(cs_n),
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
    rst_n = 0; rx = 1;
    #20; // Hold reset for 20ns
    rst_n = 1; // Release reset
    #20;
    // Send UART frame: 0xAA (10101010, LSB first, start=0, stop=1)
    rx = 0; #104160; // Start bit (104160ns = 10416 clocks at 9600 baud)
    rx = 0; #104160; // Bit 0
    rx = 1; #104160; // Bit 1
    rx = 0; #104160; // Bit 2
    rx = 1; #104160; // Bit 3
    rx = 0; #104160; // Bit 4
    rx = 1; #104160; // Bit 5
    rx = 0; #104160; // Bit 6
    rx = 1; #104160; // Bit 7
    rx = 1; #104160; // Stop bit
    #20000; // Wait for SPI transfer (~10µs)
    // Reset
    rst_n = 0; #20;
    rst_n = 1; #20;
    $finish; // End simulation
  end

  // Dump waveform
  initial begin
    $dumpfile("uart_to_spi_bridge.vcd");
    $dumpvars(0, tb_uart_to_spi_bridge);
  end
endmodule
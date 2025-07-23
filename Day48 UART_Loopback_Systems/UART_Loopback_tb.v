module tb_uart_loopback;
  reg clk, rst_n, start;
  reg [7:0] data_in;
  wire [7:0] data_out;
  wire tx_done, rx_done, error;

  // Instantiate UART Loopback
  uart_loopback uut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .data_in(data_in),
    .data_out(data_out),
    .tx_done(tx_done),
    .rx_done(rx_done),
    .error(error)
  );

  // Clock generation: 10ns period (100 MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test stimulus
  initial begin
    // Initialize signals
    rst_n = 0; start = 0; data_in = 8'h0;
    #20; // Hold reset for 20ns
    rst_n = 1; // Release reset
    #20;
    // Test 1: Transmit and receive 0x55
    data_in = 8'h55;
    start = 1; #10;
    start = 0;
    #110000; // Wait for transmission/reception (~10417 cycles/bit * 10 bits)
    // Test 2: Transmit and receive 0xAA
    data_in = 8'hAA;
    start = 1; #10;
    start = 0;
    #110000;
    // Reset
    rst_n = 0; #20;
    rst_n = 1; #20;
    $finish; // End simulation
  end

  // Dump waveform
  initial begin
    $dumpfile("uart_loopback.vcd");
    $dumpvars(0, tb_uart_loopback);
  end
endmodule
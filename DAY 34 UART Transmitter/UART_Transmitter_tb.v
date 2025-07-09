module tb_uart_transmitter;
  reg clk, rst_n, tx_start;
  reg [7:0] data_in;
  wire tx, tx_done;

  // Instantiate UART Transmitter
  uart_transmitter uut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .tx_start(tx_start),
    .tx(tx),
    .tx_done(tx_done)
  );

  // Clock generation: 10ns period (100 MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test stimulus
  initial begin
    // Initialize signals
    rst_n = 0; tx_start = 0; data_in = 8'b0;
    #20; // Hold reset for 20ns
    rst_n = 1; // Release reset
    #20;
    // Transmit first data: 10101010
    data_in = 8'b10101010; tx_start = 1; #10;
    tx_start = 0; #110000; // Wait ~104170ns (10 bits at 9600 baud)
    // Transmit second data: 11110000
    data_in = 8'b11110000; tx_start = 1; #10;
    tx_start = 0; #110000;
    rst_n = 0; #20; // Reset
    rst_n = 1; #20;
    $finish; // End simulation
  end

  // Dump waveform
  initial begin
    $dumpfile("uart_transmitter.vcd");
    $dumpvars(0, tb_uart_transmitter);
  end
endmodule
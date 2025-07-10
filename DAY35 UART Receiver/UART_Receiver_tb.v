module tb_uart_receiver;
  reg clk, rst_n, rx;
  wire [7:0] data_out;
  wire rx_done;

  // Instantiate UART Receiver
  uart_receiver uut (
    .clk(clk),
    .rst_n(rst_n),
    .rx(rx),
    .data_out(data_out),
    .rx_done(rx_done)
  );

  // Clock generation: 10ns period (100 MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test stimulus
  initial begin
    // Initialize signals
    rst_n = 0; rx = 1; // Idle state (high)
    #20; // Hold reset for 20ns
    rst_n = 1; // Release reset
    #20;
    // Transmit first data: 10101010
    rx = 0; #104170; // Start bit (0) for 1 baud period (~10417 cycles)
    rx = 0; #104170; // Bit 0
    rx = 1; #104170; // Bit 1
    rx = 0; #104170; // Bit 2
    rx = 1; #104170; // Bit 3
    rx = 0; #104170; // Bit 4
    rx = 1; #104170; // Bit 5
    rx = 0; #104170; // Bit 6
    rx = 1; #104170; // Bit 7
    rx = 1; #104170; // Stop bit (1)
    rx = 1; #104170; // Idle
    // Transmit second data: 11110000
    rx = 0; #104170; // Start bit
    rx = 0; #104170; // Bit 0
    rx = 0; #104170; // Bit 1
    rx = 0; #104170; // Bit 2
    rx = 0; #104170; // Bit 3
    rx = 1; #104170; // Bit 4
    rx = 1; #104170; // Bit 5
    rx = 1; #104170; // Bit 6
    rx = 1; #104170; // Bit 7
    rx = 1; #104170; // Stop bit
    rx = 1; #104170; // Idle
    rst_n = 0; #20; // Reset
    rst_n = 1; #20;
    $finish; // End simulation
  end

  // Dump waveform
  initial begin
    $dumpfile("uart_receiver.vcd");
    $dumpvars(0, tb_uart_receiver);
  end
endmodule
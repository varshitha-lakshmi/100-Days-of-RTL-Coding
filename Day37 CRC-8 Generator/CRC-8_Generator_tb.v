module tb_crc8_generator;
  reg clk, rst_n, data_in, enable;
  wire [7:0] crc_out;

  // Instantiate CRC-8 Generator
  crc8_generator uut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .enable(enable),
    .crc_out(crc_out)
  );

  // Clock generation: 10ns period
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test stimulus
  initial begin
    // Initialize signals
    rst_n = 0; enable = 0; data_in = 0;
    #20; // Hold reset for 20ns
    rst_n = 1; // Release reset
    #10;
    // Send 8-bit data: 10101010 (LSB first)
    enable = 1;
    data_in = 0; #10; // Bit 0
    data_in = 1; #10; // Bit 1
    data_in = 0; #10; // Bit 2
    data_in = 1; #10; // Bit 3
    data_in = 0; #10; // Bit 4
    data_in = 1; #10; // Bit 5
    data_in = 0; #10; // Bit 6
    data_in = 1; #10; // Bit 7
    enable = 0; #20;
    // Reset and send another data: 11110000
    rst_n = 0; #20;
    rst_n = 1; #10;
    enable = 1;
    data_in = 0; #10; // Bit 0
    data_in = 0; #10; // Bit 1
    data_in = 0; #10; // Bit 2
    data_in = 0; #10; // Bit 3
    data_in = 1; #10; // Bit 4
    data_in = 1; #10; // Bit 5
    data_in = 1; #10; // Bit 6
    data_in = 1; #10; // Bit 7
    enable = 0; #20;
    $finish; // End simulation
  end

  // Dump waveform
  initial begin
    $dumpfile("crc8_generator.vcd");
    $dumpvars(0, tb_crc8_generator);
  end
endmodule
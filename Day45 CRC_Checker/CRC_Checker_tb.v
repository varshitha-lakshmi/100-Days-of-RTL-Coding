module tb_crc_checker;
  reg clk, rst_n, start, data_valid;
  reg [7:0] data_in;
  wire error, done;

  // Instantiate CRC Checker
  crc_checker uut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .data_in(data_in),
    .data_valid(data_valid),
    .error(error),
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
    rst_n = 0; start = 0; data_valid = 0; data_in = 8'h0;
    #20; // Hold reset for 20ns
    rst_n = 1; // Release reset
    #20;
    // Valid CRC test: data=0xAA, CRC=0xD8 (for polynomial 0x07)
    start = 1; #10;
    start = 0;
    repeat (8) begin
      data_valid = 1; data_in = 8'hAA; #10;
      data_valid = 0; #10;
    end
    repeat (8) begin
      data_valid = 1; data_in = 8'hD8; #10;
      data_valid = 0; #10;
    end
    #20;
    // Invalid CRC test: data=0xAA, CRC=0xFF (incorrect)
    start = 1; #10;
    start = 0;
    repeat (8) begin
      data_valid = 1; data_in = 8'hAA; #10;
      data_valid = 0; #10;
    end
    repeat (8) begin
      data_valid = 1; data_in = 8'hFF; #10;
      data_valid = 0; #10;
    end
    #20;
    // Reset
    rst_n = 0; #20;
    rst_n = 1; #20;
    $finish; // End simulation
  end

  // Dump waveform
  initial begin
    $dumpfile("crc_checker.vcd");
    $dumpvars(0, tb_crc_checker);
  end
endmodule
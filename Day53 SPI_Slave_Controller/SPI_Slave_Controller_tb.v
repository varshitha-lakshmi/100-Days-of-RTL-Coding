module tb_spi_slave_controller;
  reg clk, rst_n, sclk, mosi, ss_n;
  reg [7:0] data_in;
  wire [7:0] data_out;
  wire miso, done;

  // Instantiate SPI Slave Controller
  spi_slave_controller uut (
    .clk(clk),
    .rst_n(rst_n),
    .sclk(sclk),
    .mosi(mosi),
    .ss_n(ss_n),
    .miso(miso),
    .data_out(data_out),
    .data_in(data_in),
    .done(done)
  );

  // Clock generation: 10ns period (100 MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // SCLK generation: 1 MHz (1us period)
  initial begin
    sclk = 0;
    forever #500 sclk = ~sclk; // 1 MHz
  end

  // Test stimulus
  initial begin
    // Initialize signals
    rst_n = 0; sclk = 0; mosi = 0; ss_n = 1; data_in = 8'h5A;
    #20; // Hold reset
    rst_n = 1;
    #1000; // Wait for stability
    // Start transaction
    ss_n = 0;
    #1000;
    // Send 0xA5
    send_byte(8'hA5);
    #1000;
    // End transaction
    ss_n = 1;
    #1000;
    // Reset
    rst_n = 0; #20;
    rst_n = 1; #1000;
    $finish;
  end

  // Task to send 8-bit data
  task send_byte(input [7:0] data);
    integer i;
    begin
      for (i = 7; i >= 0; i = i - 1) begin
        mosi = data[i];
        #500; // Wait for SCLK low
        #500; // Wait for SCLK high
      end
    end
  endtask

  // Dump waveform
  initial begin
    $dumpfile("spi_slave_controller.vcd");
    $dumpvars(0, tb_spi_slave_controller);
  end
endmodule
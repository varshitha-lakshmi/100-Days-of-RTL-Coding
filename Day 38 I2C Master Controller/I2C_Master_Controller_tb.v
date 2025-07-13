module tb_i2c_master;
  reg clk, rst_n, start;
  reg [6:0] addr;
  reg [7:0] data;
  wire scl, sda, done;

  // Instantiate I2C Master Controller
  i2c_master uut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .addr(addr),
    .data(data),
    .scl(scl),
    .sda(sda),
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
    rst_n = 0; start = 0; addr = 7'h00; data = 8'h00;
    #20; // Hold reset for 20ns
    rst_n = 1; // Release reset
    #20;
    // Start I2C write transaction
    addr = 7'h3C; // Slave address
    data = 8'hAA; // Data to write
    start = 1; #10;
    start = 0; #20000; // Wait ~20µs (2 SCL periods for transaction)
    // Reset
    rst_n = 0; #20;
    rst_n = 1; #20;
    $finish; // End simulation
  end

  // Dump waveform
  initial begin
    $dumpfile("i2c_master.vcd");
    $dumpvars(0, tb_i2c_master);
  end
endmodule
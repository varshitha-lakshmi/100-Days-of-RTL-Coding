module tb_i2c_slave_controller;
  reg clk, rst_n, scl, sda_in;
  reg [7:0] data_in;
  wire [7:0] data_out;
  wire done, ack;
  wire sda;

  // Instantiate I2C Slave Controller
  i2c_slave_controller uut (
    .clk(clk),
    .rst_n(rst_n),
    .scl(scl),
    .sda(sda),
    .data_out(data_out),
    .data_in(data_in),
    .done(done),
    .ack(ack)
  );

  // Clock generation: 10ns period (100 MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // SCL generation: 100 kHz (10us period)
  initial begin
    scl = 1;
    forever #5000 scl = ~scl; // 100 kHz
  end

  // SDA driver
  assign sda = sda_in ? 1'bz : 1'b0;

  // Test stimulus
  initial begin
    // Initialize signals
    rst_n = 0; sda_in = 1; data_in = 8'hA5;
    #20; // Hold reset
    rst_n = 1;
    #10000; // Wait for stability
    // Start condition
    sda_in = 0; // SDA falls while SCL high
    #10000;
    // Send address 0x50 + Write (0)
    send_byte({7'h50, 1'b0});
    #10000; // Wait for ACK
    // Send data 0xA5
    send_byte(8'hA5);
    #10000; // Wait for ACK
    // Stop condition
    sda_in = 0; #5000;
    sda_in = 1; // SDA rises while SCL high
    #20000;
    $finish;
  end

  // Task to send 8-bit data
  task send_byte(input [7:0] data);
    integer i;
    begin
      for (i = 7; i >= 0; i = i - 1) begin
        sda_in = data[i];
        #5000; // Wait for SCL low
        #5000; // Wait for SCL high
      end
    end
  endtask

  // Dump waveform
  initial begin
    $dumpfile("i2c_slave_controller.vcd");
    $dumpvars(0, tb_i2c_slave_controller);
  end
endmodule
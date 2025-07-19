module tb_wishbone_master;
  reg clk, rst_n, start, we_i;
  reg [3:0] addr_i;
  reg [7:0] data_i;
  wire [3:0] adr_o;
  wire [7:0] dat_o;
  wire we_o, cyc_o, stb_o;
  reg [7:0] dat_i;
  reg ack_i;
  wire [7:0] data_o;
  wire done;

  // Instantiate Wishbone Master
  wishbone_master uut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .we_i(we_i),
    .addr_i(addr_i),
    .data_i(data_i),
    .adr_o(adr_o),
    .dat_o(dat_o),
    .dat_i(dat_i),
    .we_o(we_o),
    .cyc_o(cyc_o),
    .stb_o(stb_o),
    .ack_i(ack_i),
    .data_o(data_o),
    .done(done)
  );

  // Simulated slave memory (8-bit data, 4-bit address)
  reg [7:0] mem [0:15];
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      ack_i <= 0;
    else if (cyc_o && stb_o)
      ack_i <= 1; // One-cycle ACK delay
    else
      ack_i <= 0;
  end
  always @(posedge clk) begin
    if (cyc_o && stb_o && we_o)
      mem[adr_o] <= dat_o; // Write
    dat_i <= mem[adr_o]; // Read
  end

  // Clock generation: 10ns period (100 MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test stimulus
  initial begin
    // Initialize signals
    rst_n = 0; start = 0; we_i = 0; addr_i = 4'h0; data_i = 8'h0; dat_i = 8'h0; ack_i = 0;
    #20; // Hold reset for 20ns
    rst_n = 1; // Release reset
    #20;
    // Preload memory for read test
    mem[5] = 8'h55;
    // Write transaction: addr=5, data=0xAA
    we_i = 1; addr_i = 4'h5; data_i = 8'hAA;
    start = 1; #10;
    start = 0; #50; // Wait for transaction
    #20;
    // Read transaction: addr=5
    we_i = 0; addr_i = 4'h5; data_i = 8'h0;
    start = 1; #10;
    start = 0; #50; // Wait for transaction
    // Reset
    rst_n = 0; #20;
    rst_n = 1; #20;
    $finish; // End simulation
  end

  // Dump waveform
  initial begin
    $dumpfile("wishbone_master.vcd");
    $dumpvars(0, tb_wishbone_master);
  end
endmodule
module tb_axi_lite_master;
  reg clk, rst_n, start, we_i;
  reg [31:0] addr_i, data_i;
  wire [31:0] addr_o, data_o;
  wire [3:0] wstrb_o;
  wire awvalid_o, wvalid_o, bready_o;
  reg awready_i, wready_i;
  reg [1:0] bresp_i;
  reg bvalid_i;
  wire arvalid_o, rready_o;
  reg arready_i;
  reg [31:0] data_i_r;
  reg [1:0] rresp_i;
  reg rvalid_i;
  wire [31:0] data_o_r;
  wire error, done;

  // Instantiate AXI-Lite Master
  axi_lite_master uut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .we_i(we_i),
    .addr_i(addr_i),
    .data_i(data_i),
    .addr_o(addr_o),
    .data_o(data_o),
    .wstrb_o(wstrb_o),
    .awvalid_o(awvalid_o),
    .awready_i(awready_i),
    .wvalid_o(wvalid_o),
    .wready_i(wready_i),
    .bresp_i(bresp_i),
    .bvalid_i(bvalid_i),
    .bready_o(bready_o),
    .arvalid_o(arvalid_o),
    .arready_i(arready_i),
    .data_i_r(data_i_r),
    .rresp_i(rresp_i),
    .rvalid_i(rvalid_i),
    .rready_o(rready_o),
    .data_o_r(data_o_r),
    .error(error),
    .done(done)
  );

  // Simulated slave (32-bit data, 32-bit address)
  reg [31:0] mem [0:15];
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      awready_i <= 0;
      wready_i <= 0;
      bvalid_i <= 0;
      arready_i <= 0;
      rvalid_i <= 0;
    end else begin
      awready_i <= awvalid_o; // One-cycle delay
      wready_i <= wvalid_o;
      arready_i <= arvalid_o;
      if (awvalid_o && awready_i && wvalid_o && wready_i) begin
        mem[addr_o[5:2]] <= data_o; // Write to memory
        bvalid_i <= 1;
        bresp_i <= 2'b00; // OKAY response
      end else begin
        bvalid_i <= 0;
      end
      if (arvalid_o && arready_i) begin
        rvalid_i <= 1;
        data_i_r <= mem[addr_o[5:2]]; // Read from memory
        rresp_i <= 2'b00; // OKAY response
      end else begin
        rvalid_i <= 0;
      end
    end
  end

  // Clock generation: 10ns period (100 MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test stimulus
  initial begin
    // Initialize signals
    rst_n = 0; start = 0; we_i = 0; addr_i = 32'h0; data_i = 32'h0;
    awready_i = 0; wready_i = 0; bresp_i = 2'b00; bvalid_i = 0;
    arready_i = 0; data_i_r = 32'h0; rresp_i = 2'b00; rvalid_i = 0;
    #20; // Hold reset for 20ns
    rst_n = 1; // Release reset
    #20;
    // Preload memory for read test
    mem[4] = 32'hCAFEBABE;
    // Write transaction: addr=0x1000, data=0xDEADBEEF
    we_i = 1; addr_i = 32'h1000; data_i = 32'hDEADBEEF;
    start = 1; #10;
    start = 0; #50; // Wait for transaction
    #20;
    // Read transaction: addr=0x1000
    we_i = 0; addr_i = 32'h1000; data_i = 32'h0;
    start = 1; #10;
    start = 0; #50; // Wait for transaction
    // Reset
    rst_n = 0; #20;
    rst_n = 1; #20;
    $finish; // End simulation
  end

  // Dump waveform
  initial begin
    $dumpfile("axi_lite_master.vcd");
    $dumpvars(0, tb_axi_lite_master);
  end
endmodule
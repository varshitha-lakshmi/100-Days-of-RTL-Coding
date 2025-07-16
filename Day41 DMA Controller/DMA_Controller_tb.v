module tb_dma_controller;
  reg clk, rst_n, start;
  reg [3:0] src_addr, dst_addr;
  reg [7:0] mem_data_out;
  wire [3:0] mem_addr;
  wire [7:0] mem_data_in;
  wire mem_we_n, mem_ce_n, done;

  // Instantiate DMA Controller
  dma_controller uut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .src_addr(src_addr),
    .dst_addr(dst_addr),
    .mem_addr(mem_addr),
    .mem_data_in(mem_data_in),
    .mem_we_n(mem_we_n),
    .mem_ce_n(mem_ce_n),
    .mem_data_out(mem_data_out),
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
    rst_n = 0; start = 0; src_addr = 4'h0; dst_addr = 4'h0;
    #20; // Hold reset for 20ns
    rst_n = 1; // Release reset
    #20;
    // Preload memory for simulation
    uut.mem[5] = 8'hAA; // Data at source address 5
    // Start DMA transfer: src_addr=5, dst_addr=A
    src_addr = 4'h5; dst_addr = 4'hA;
    start = 1; #10;
    start = 0; #50; // Wait for transfer (READ, WRITE, DONE)
    // Reset
    rst_n = 0; #20;
    rst_n = 1; #20;
    $finish; // End simulation
  end

  // Memory data output for simulation
  assign mem_data_out = uut.mem[mem_addr];

  // Dump waveform
  initial begin
    $dumpfile("dma_controller.vcd");
    $dumpvars(0, tb_dma_controller);
  end
endmodule
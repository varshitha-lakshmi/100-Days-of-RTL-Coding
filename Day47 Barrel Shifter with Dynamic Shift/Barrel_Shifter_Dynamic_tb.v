module tb_barrel_shifter_dynamic;
  reg clk, rst_n, valid_in;
  reg [31:0] data_in;
  reg [4:0] shift_amt;
  reg direction;
  wire [31:0] data_out;
  wire valid_out;

  // Instantiate Barrel Shifter
  barrel_shifter_dynamic uut (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(valid_in),
    .data_in(data_in),
    .shift_amt(shift_amt),
    .direction(direction),
    .data_out(data_out),
    .valid_out(valid_out)
  );

  // Clock generation: 10ns period (100 MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test stimulus
  initial begin
    // Initialize signals
    rst_n = 0; valid_in = 0; data_in = 32'h0; shift_amt = 5'h0; direction = 0;
    #20; // Hold reset for 20ns
    rst_n = 1; // Release reset
    #20;
    // Test 1: Left shift by 0
    data_in = 32'hA5A5A5A5; shift_amt = 5'd0; direction = 0;
    valid_in = 1; #10;
    valid_in = 0; #30;
    // Test 2: Left shift by 2
    data_in = 32'hA5A5A5A5; shift_amt = 5'd2; direction = 0;
    valid_in = 1; #10;
    valid_in = 0; #30;
    // Test 3: Right shift by 2
    data_in = 32'hA5A5A5A5; shift_amt = 5'd2; direction = 1;
    valid_in = 1; #10;
    valid_in = 0; #30;
    // Test 4: Right shift by 4
    data_in = 32'hA5A5A5A5; shift_amt = 5'd4; direction = 1;
    valid_in = 1; #10;
    valid_in = 0; #30;
    // Reset
    rst_n = 0; #20;
    rst_n = 1; #20;
    $finish; // End simulation
  end

  // Dump waveform
  initial begin
    $dumpfile("barrel_shifter_dynamic.vcd");
    $dumpvars(0, tb_barrel_shifter_dynamic);
  end
endmodule
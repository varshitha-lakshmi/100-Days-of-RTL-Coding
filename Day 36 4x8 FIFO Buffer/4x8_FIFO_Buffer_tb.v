
module tb_fifo_4x8;
  reg clk, rst_n, wr_en, rd_en;
  reg [7:0] data_in;
  wire [7:0] data_out;
  wire full, empty;

  // Instantiate 4x8 FIFO Buffer
  fifo_4x8 uut (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out),
    .full(full),
    .empty(empty)
  );

  // Clock generation: 10ns period
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test stimulus
  initial begin
    // Initialize signals
    rst_n = 0; wr_en = 0; rd_en = 0; data_in = 8'b0;
    #20; // Hold reset for 20ns
    rst_n = 1; // Release reset
    #10;
    // Write 4 data words to fill FIFO
    wr_en = 1; data_in = 8'b10101010; #10; // Write 1
    data_in = 8'b11110000; #10; // Write 2
    data_in = 8'b00001111; #10; // Write 3
    data_in = 8'b01010101; #10; // Write 4 (FIFO full)
    wr_en = 0; #10;
    // Read 2 data words
    rd_en = 1; #20; // Read 10101010, 11110000
    rd_en = 0; #10;
    // Write 1 more data word
    wr_en = 1; data_in = 8'b11001100; #10;
    wr_en = 0; #10;
    // Read remaining data words
    rd_en = 1; #30; // Read 00001111, 01010101, 11001100
    rd_en = 0; #10;
    // Reset
    rst_n = 0; #20;
    rst_n = 1; #10;
    $finish; // End simulation
  end

  // Dump waveform
  initial begin
    $dumpfile("fifo_4x8.vcd");
    $dumpvars(0, tb_fifo_4x8);
  end
endmodule
```

### Explanation
- **Purpose**: This testbench verifies the 4x8 FIFO Buffer’s functionality by performing write and read operations, testing full and empty conditions, and resetting the FIFO.
- **Signals**:
  - Inputs: `clk` (10ns period), `rst_n` (active-low reset), `wr_en` (write enable), `rd_en` (read enable), `data_in[7:0]` (8-bit input data).
  - Outputs: `data_out[7:0]` (8-bit output data), `full` (FIFO full flag), `empty` (FIFO empty flag).
- **Stimulus**:
  - Resets the FIFO for 20ns.
  - Writes four 8-bit data words (10101010, 11110000, 00001111, 01010101) to fill the FIFO (full flag high).
  - Reads two words (10101010, 11110000).
  - Writes one more word (11001100).
  - Reads the remaining three words (00001111, 01010101, 11001100), emptying the FIFO (empty flag high).
  - Resets the FIFO again.
- **Waveform Generation**:
  - The testbench generates a VCD file (`fifo_4x8.vcd`) for waveform viewing.
  - Expected waveform shows:
    - `clk`: Toggles every 5ns (10ns period).
    - `rst_n`: Low for 20ns, high for 120ns, low for 20ns, high for 10ns.
    - `wr_en`: High for four writes, then one write.
    - `rd_en`: High for two reads, then three reads.
    - `data_in[7:0]`: Input data during writes.
    - `data_out[7:0]`: Output data during reads.
    - `full`: High when count=4 (after four writes).
    - `empty`: High when count=0 (after reset, after reading all data).
    - `count[2:0]`: Increments/decrements with writes/reads (0 to 4).

### Instructions to Use the Testbench
1. **Save the Files**:
   - Save the FIFO module code (from the Day 36 response) as `fifo_4x8.v`.
   - Save the testbench code above as `tb_fifo_4x8.v`.

2. **Simulate**:
   - Use a simulator like Icarus Verilog, ModelSim, or Vivado. For Icarus Verilog, run:
     ```bash
     iverilog -o tb_fifo_4x8 tb_fifo_4x8.v fifo_4x8.v
     vvp tb_fifo_4x8
     ```
   - Open the generated `fifo_4x8.vcd` in GTKWave or your simulator’s waveform viewer.

3. **View Waveforms**:
   - In GTKWave, add signals: `clk`, `rst_n`, `wr_en`, `rd_en`, `data_in[7:0]`, `data_out[7:0]`, `full`, `empty`, `uut.wr_ptr`, `uut.rd_ptr`, `uut.count`.
   - Zoom to show key write/read cycles (e.g., 0–150ns for initial writes/reads).
   - Capture the waveform as a PNG for the PowerPoint slide.

4. **Integration with Day 36 Post**:
   - Use the waveform image to replace the “[Insert Waveform Image]” placeholder in the PowerPoint slide described in the Day 36 response.
   - Ensure the slide includes the FIFO module code and waveform description for consistency.

### Notes
- **Context**: This testbench is designed for the 4x8 FIFO Buffer from Day 36, complementing the UART modules (Days 34–35) for data buffering in communication systems.
- **Simulation Time**: The testbench runs for ~160ns, covering reset, writes, reads, and another reset. Adjust the `#` delays if you need a longer or shorter simulation.
- **Time Zone**: Given the current time (7:48 PM IST on July 11, 2025), you may want to schedule the Day 36 post for morning IST (e.g., 8–10 AM on July 12, 2025) for maximum visibility.
- **Next Steps**: If you need the testbench for a different day (e.g., Days 29–35) or assistance with simulation, waveform capture, or slide creation for Day 36, please clarify. For Day 37, consider topics like a CRC Generator or an I2C Controller.

Would you like assistance with running the simulation, capturing the waveform, or creating the Day 36 slide? Alternatively, do you need the testbench for a different day or a specific modification to this testbench?

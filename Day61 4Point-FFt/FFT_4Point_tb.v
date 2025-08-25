module tb_fft_4point;
    reg clk, rst_n, start;
    reg [31:0] x0_real, x0_imag, x1_real, x1_imag;
    reg [31:0] x2_real, x2_imag, x3_real, x3_imag;
    wire [31:0] y0_real, y0_imag, y1_real, y1_imag;
    wire [31:0] y2_real, y2_imag, y3_real, y3_imag;
    wire done;

    // Instantiate FFT Module
    fft_4point uut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .x0_real(x0_real), .x0_imag(x0_imag),
        .x1_real(x1_real), .x1_imag(x1_imag),
        .x2_real(x2_real), .x2_imag(x2_imag),
        .x3_real(x3_real), .x3_imag(x3_imag),
        .y0_real(y0_real), .y0_imag(y0_imag),
        .y1_real(y1_real), .y1_imag(y1_imag),
        .y2_real(y2_real), .y2_imag(y2_imag),
        .y3_real(y3_real), .y3_imag(y3_imag),
        .done(done)
    );

    // Clock generation: 10ns period (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus and self-checking
    initial begin
        // Initialize signals
        rst_n = 0; start = 0;
        x0_real = 0; x0_imag = 0;
        x1_real = 0; x1_imag = 0;
        x2_real = 0; x2_imag = 0;
        x3_real = 0; x3_imag = 0;
        #20; // Hold reset for 20ns
        rst_n = 1; #10;
        // Test: x0 = x1 = x2 = x3 = 1 + j0 (0x00010000, 0x00000000)
        // Expected: y0 ≈ 4 + j0 (0x00040000, 0x00000000)
        //           y1 ≈ 0 + j0, y2 ≈ 0 + j0, y3 ≈ 0 + j0
        x0_real = 32'h00010000; x0_imag = 32'h00000000;
        x1_real = 32'h00010000; x1_imag = 32'h00000000;
        x2_real = 32'h00010000; x2_imag = 32'h00000000;
        x3_real = 32'h00010000; x3_imag = 32'h00000000;
        start = 1; #10;
        start = 0;
        // Wait for pipeline completion
        wait (done);
        #10;
        // Self-checking (tolerance ±0.001, ~0x00000400 in 16.16)
        if (y0_real >= 32'h0003FC00 && y0_real <= 32'h00040400 &&
            y0_imag >= 32'h00000000 && y0_imag <= 32'h00000400 &&
            y1_real >= 32'h00000000 && y1_real <= 32'h00000400 &&
            y1_imag >= 32'h00000000 && y1_imag <= 32'h00000400 &&
            y2_real >= 32'h00000000 && y2_real <= 32'h00000400 &&
            y2_imag >= 32'h00000000 && y2_imag <= 32'h00000400 &&
            y3_real >= 32'h00000000 && y3_real <= 32'h00000400 &&
            y3_imag >= 32'h00000000 && y3_imag <= 32'h00000400)
            $display("Test Passed: y0 = %h + j%h, y1 = %h + j%h, y2 = %h + j%h, y3 = %h + j%h",
                     y0_real, y0_imag, y1_real, y1_imag, y2_real, y2_imag, y3_real, y3_imag);
        else
            $display("Test Failed: y0 = %h + j%h, y1 = %h + j%h, y2 = %h + j%h, y3 = %h + j%h",
                     y0_real, y0_imag, y1_real, y1_imag, y2_real, y2_imag, y3_real, y3_imag);
        // Reset
        rst_n = 0; #20;
        rst_n = 1; #20;
        $finish;
    end

    // Dump waveform
    initial begin
        $dumpfile("fft_4point.vcd");
        $dumpvars(0, tb_fft_4point);
    end
endmodule
module tb_matrix_mult;
    reg clk, rst_n, start;
    reg [31:0] a11, a12, a21, a22;
    reg [31:0] b11, b12, b21, b22;
    wire [31:0] c11, c12, c21, c22;
    wire done;

    // Instantiate Matrix Multiplier
    matrix_mult uut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .a11(a11), .a12(a12), .a21(a21), .a22(a22),
        .b11(b11), .b12(b12), .b21(b21), .b22(b22),
        .c11(c11), .c12(c12), .c21(c21), .c22(c22),
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
        a11 = 0; a12 = 0; a21 = 0; a22 = 0;
        b11 = 0; b12 = 0; b21 = 0; b22 = 0;
        #20; // Hold reset for 20ns
        rst_n = 1; #10;
        // Test: A = [[1, 2], [3, 4]], B = [[5, 6], [7, 8]]
        // Expected: C = [[19, 22], [43, 50]] (16.16 format)
        a11 = 32'h00010000; a12 = 32'h00020000; // 1, 2
        a21 = 32'h00030000; a22 = 32'h00040000; // 3, 4
        b11 = 32'h00050000; b12 = 32'h00060000; // 5, 6
        b21 = 32'h00070000; b22 = 32'h00080000; // 7, 8
        start = 1; #10;
        start = 0;
        // Wait for pipeline completion
        wait (done);
        #10;
        // Self-checking (tolerance ±0.001, ~0x00000400 in 16.16)
        if (c11 >= 32'h0012FC00 && c11 <= 32'h00130400 && // 19
            c12 >= 32'h0015FC00 && c12 <= 32'h00160400 && // 22
            c21 >= 32'h002AFC00 && c21 <= 32'h002B0400 && // 43
            c22 >= 32'h0031FC00 && c22 <= 32'h00320400)   // 50
            $display("Test Passed: c11 = %h, c12 = %h, c21 = %h, c22 = %h",
                     c11, c12, c21, c22);
        else
            $display("Test Failed: c11 = %h, c12 = %h, c21 = %h, c22 = %h",
                     c11, c12, c21, c22);
        // Reset
        rst_n = 0; #20;
        rst_n = 1; #20;
        $finish;
    end

    // Dump waveform
    initial begin
        $dumpfile("matrix_mult.vcd");
        $dumpvars(0, tb_matrix_mult);
    end
endmodule
module tb_fma_float;
    reg clk, rst_n, start;
    reg [31:0] a, b, c;
    wire [31:0] result;
    wire done;

    // Instantiate FMA Unit
    fma_float uut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .a(a), .b(b), .c(c),
        .result(result), .done(done)
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
        a = 0; b = 0; c = 0;
        #20; // Hold reset for 20ns
        rst_n = 1; #10;
        // Test: A = 2.0 (0x40000000), B = 3.0 (0x40400000), C = 4.0 (0x40800000)
        // Expected: (2 * 3) + 4 = 10.0 (0x41200000)
        a = 32'h40000000; b = 32'h40400000; c = 32'h40800000;
        start = 1; #10;
        start = 0;
        // Wait for pipeline completion
        wait (done);
        #10;
        // Self-checking (exact match for simplicity)
        if (result == 32'h41200000)
            $display("Test Passed: result = %h (10.0)", result);
        else
            $display("Test Failed: result = %h, Expected = 41200000", result);
        // Reset
        rst_n = 0; #20;
        rst_n = 1; #20;
        $finish;
    end

    // Dump waveform
    initial begin
        $dumpfile("fma_float.vcd");
        $dumpvars(0, tb_fma_float);
    end
endmodule
module tb_float_multiplier;
    reg clk, rst_n, start;
    reg [31:0] a, b;
    wire [31:0] result;
    wire done;

    // Instantiate Floating-Point Multiplier
    float_multiplier uut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .a(a), .b(b), .result(result), .done(done)
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
        a = 0; b = 0;
        #20; // Hold reset for 20ns
        rst_n = 1; #10;
        // Test: A = 1.5 (0x3FC00000), B = 2.0 (0x40000000)
        // Expected: 1.5 * 2.0 = 3.0 (0x40400000)
        a = 32'h3FC00000; // 1.5
        b = 32'h40000000; // 2.0
        start = 1; #10;
        start = 0;
        // Wait for pipeline completion
        wait (done);
        #10;
        // Self-checking
        if (result == 32'h40400000)
            $display("Test Passed: Result = %h (3.0)", result);
        else
            $display("Test Failed: Result = %h, Expected = 40400000", result);
        // Reset
        rst_n = 0; #20;
        rst_n = 1; #20;
        $finish;
    end

    // Dump waveform
    initial begin
        $dumpfile("float_multiplier.vcd");
        $dumpvars(0, tb_float_multiplier);
    end
endmodule
module tb_cordic_sincos;
    reg clk, rst_n, start;
    reg [31:0] theta;
    wire [31:0] sin_out, cos_out;
    wire done;

    // Instantiate CORDIC Sine/Cosine Generator
    cordic_sincos uut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .theta(theta), .sin_out(sin_out), .cos_out(cos_out), .done(done)
    );

    // Clock generation: 10ns period (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus and self-checking
    initial begin
        // Initialize signals
        rst_n = 0; start = 0; theta = 0;
        #20; // Hold reset for 20ns
        rst_n = 1; #10;
        // Test: theta = pi/4 (0x3243F6A8, ~0.785 radians)
        // Expected: sin(pi/4) ≈ 0.707 (0x2D413CCC), cos(pi/4) ≈ 0.707 (0x2D413CCC)
        theta = 32'h3243F6A8;
        start = 1; #10;
        start = 0;
        // Wait for pipeline completion
        wait (done);
        #10;
        // Self-checking (tolerance ±0.001, ~0x00008000 in 1.31 format)
        if (sin_out >= 32'h2D40BCCC && sin_out <= 32'h2D41FCCC &&
            cos_out >= 32'h2D40BCCC && cos_out <= 32'h2D41FCCC)
            $display("Test Passed: sin_out = %h, cos_out = %h", sin_out, cos_out);
        else
            $display("Test Failed: sin_out = %h, cos_out = %h, Expected ~2D413CCC", sin_out, cos_out);
        // Reset
        rst_n = 0; #20;
        rst_n = 1; #20;
        $finish;
    end

    // Dump waveform
    initial begin
        $dumpfile("cordic_sincos.vcd");
        $dumpvars(0, tb_cordic_sincos);
    end
endmodule
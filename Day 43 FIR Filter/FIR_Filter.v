module fir_filter (
    input wire clk,          // Input clock (100 MHz)
    input wire rst_n,        // Active-low reset
    input wire [7:0] x_in,   // 8-bit signed input sample
    input wire valid_in,     // Input valid signal
    output reg [15:0] y_out, // 16-bit signed output (to handle multiplication)
    output reg valid_out     // Output valid signal
);
    // Coefficients: [1, 2, 2, 1] (fixed, 8-bit signed)
    wire signed [7:0] coeff [0:3];
    assign coeff[0] = 8'd1;
    assign coeff[1] = 8'd2;
    assign coeff[2] = 8'd2;
    assign coeff[3] = 8'd1;

    // Shift register for input samples
    reg signed [7:0] samples [0:3];
    reg [2:0] sample_count;  // Increased to 3 bits to avoid truncation

    // Multiply-accumulate registers
    reg signed [15:0] mult [0:3];
    reg signed [15:0] sum;

    // Combined logic for shift register and multiply-accumulate
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            samples[0] <= 0;
            samples[1] <= 0;
            samples[2] <= 0;
            samples[3] <= 0;
            sample_count <= 0;
            valid_out <= 0;
            y_out <= 0;
            mult[0] <= 0;
            mult[1] <= 0;
            mult[2] <= 0;
            mult[3] <= 0;
            sum <= 0;
        end else begin
            if (valid_in) begin
                // Shift register update
                samples[0] <= x_in;
                samples[1] <= samples[0];
                samples[2] <= samples[1];
                samples[3] <= samples[2];
                sample_count <= sample_count + 1;
                valid_out <= (sample_count >= 3); // Valid after 4 samples

                // Multiply-accumulate
                mult[0] <= samples[0] * coeff[0];
                mult[1] <= samples[1] * coeff[1];
                mult[2] <= samples[2] * coeff[2];
                mult[3] <= samples[3] * coeff[3];
                sum <= mult[0] + mult[1] + mult[2] + mult[3];
                if (sample_count >= 3)
                    y_out <= sum;
                else
                    y_out <= y_out; // Maintain current value
            end else begin
                valid_out <= 0;
                y_out <= y_out; // Maintain current value
                sample_count <= sample_count; // Maintain count
            end
        end
    end
endmodule

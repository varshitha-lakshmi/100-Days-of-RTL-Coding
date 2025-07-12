module crc8_generator (
    input wire clk,          // Input clock
    input wire rst_n,        // Active-low reset
    input wire data_in,      // Serial data input
    input wire enable,       // Enable CRC computation
    output reg [7:0] crc_out // 8-bit CRC output
);
    parameter POLY = 8'h07;  // CRC-8-ATM polynomial: x^8 + x^2 + x + 1

    // CRC shift register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_out <= 8'h00; // Initialize CRC to 0
        end else if (enable) begin
            // XOR input data with MSB of CRC, shift, and apply polynomial
            crc_out <= {crc_out[6:0], 1'b0} ^ (data_in ^ crc_out[7] ? POLY : 8'h00);
        end
    end
endmodule

module crc_checker (
    input wire clk,          // Input clock (100 MHz)
    input wire rst_n,        // Active-low reset
    input wire start,        // Start CRC check
    input wire [7:0] data_in,// 8-bit data or CRC input
    input wire data_valid,   // Input valid signal
    output reg error,        // Error flag (0=no error, 1=error)
    output reg done          // Check complete
);
    // CRC-8 polynomial: x^8 + x^2 + x^1 + 1 (0x07)
    parameter POLY = 9'h107; // 9-bit to include leading 1
    parameter IDLE = 2'd0, DATA = 2'd1, CRC = 2'd2, CHECK = 2'd3;
    reg [1:0] state, next_state;
    reg [7:0] crc_reg;       // CRC shift register
    reg [3:0] bit_count;     // Bit counter for 8-bit data/CRC

    // FSM: State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // FSM: Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start)
                    next_state = DATA;
            end
            DATA: begin
                if (data_valid && bit_count == 7)
                    next_state = CRC;
            end
            CRC: begin
                if (data_valid && bit_count == 7)
                    next_state = CHECK;
            end
            CHECK: begin
                next_state = IDLE;
            end
        endcase
    end

    // CRC calculation and output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_reg <= 8'h0;
            bit_count <= 4'h0;
            error <= 0;
            done <= 0;
        end else begin
            error <= 0;
            done <= 0;
            case (state)
                IDLE: begin
                    crc_reg <= 8'h0;
                    bit_count <= 4'h0;
                end
                DATA: begin
                    if (data_valid) begin
                        crc_reg <= {crc_reg[6:0], 1'b0} ^ (crc_reg[7] ? POLY[7:0] : 8'h0) ^ {7'b0, data_in[7-bit_count]};
                        bit_count <= bit_count + 1;
                    end
                end
                CRC: begin
                    if (data_valid) begin
                        crc_reg <= {crc_reg[6:0], 1'b0} ^ (crc_reg[7] ? POLY[7:0] : 8'h0) ^ {7'b0, data_in[7-bit_count]};
                        bit_count <= bit_count + 1;
                    end
                end
                CHECK: begin
                    error <= (crc_reg != 8'h0); // Non-zero remainder indicates error
                    done <= 1;
                    bit_count <= 4'h0;
                end
            endcase
        end
    end
endmodule

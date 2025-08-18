module float_divider (
    input wire clk,          // 100 MHz clock
    input wire rst_n,        // Active-low reset
    input wire start,        // Start computation
    input wire [31:0] a, b,  // 32-bit IEEE 754 inputs (dividend, divisor)
    output wire [31:0] result, // 32-bit IEEE 754 result
    output reg done          // Computation complete
);
    parameter IDLE = 2'd0, INPUT = 2'd1, DIV = 2'd2, NORM = 2'd3, ROUND = 2'd0;
    reg [1:0] state, next_state;
    reg [7:0] exp_a, exp_b, exp_result, exp_result_reg;
    reg [23:0] mant_a, mant_b, mant_quotient, mant_quotient_reg;
    reg [47:0] remainder, dividend;
    reg [5:0] div_count; // Counter for division iterations
    reg sign_a, sign_b, sign_result, sign_result_reg;
    reg guard, round_bit, sticky;
    wire [31:0] result_reg;

    // Pipeline registers
    reg [31:0] a_reg, b_reg;

    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (start && b[30:0] != 31'b0) next_state = INPUT; // Check for non-zero divisor
            INPUT: next_state = DIV;
            DIV: if (div_count == 6'd24) next_state = NORM; else next_state = DIV;
            NORM: next_state = ROUND;
            ROUND: next_state = IDLE;
        endcase
    end

    // Division and pipeline logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 32'b0;
            b_reg <= 32'b0;
            exp_a <= 8'b0;
            exp_b <= 8'b0;
            mant_a <= 24'b0;
            mant_b <= 24'b0;
            sign_a <= 1'b0;
            sign_b <= 1'b0;
            sign_result <= 1'b0;
            exp_result <= 8'b0;
            mant_quotient <= 24'b0;
            mant_quotient_reg <= 24'b0;
            remainder <= 48'b0;
            dividend <= 48'b0;
            div_count <= 6'b0;
            guard <= 1'b0;
            round_bit <= 1'b0;
            sticky <= 1'b0;
            sign_result_reg <= 1'b0;
            exp_result_reg <= 8'b0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        a_reg <= a;
                        b_reg <= b;
                    end
                end
                INPUT: begin
                    sign_a <= a_reg[31];
                    sign_b <= b_reg[31];
                    exp_a <= a_reg[30:23];
                    exp_b <= b_reg[30:23];
                    mant_a <= {1'b1, a_reg[22:0]}; // Implicit leading 1
                    mant_b <= {1'b1, b_reg[22:0]};
                    sign_result <= a_reg[31] ^ b_reg[31];
                    exp_result <= (a_reg[30:23] == 8'b0 || b_reg[30:23] == 8'b0) ? 8'b0 :
                                 (a_reg[30:23] - b_reg[30:23] + 8'd127);
                    dividend <= {1'b1, a_reg[22:0], 24'b0}; // Align for division
                    remainder <= 48'b0;
                    div_count <= 6'b0;
                end
                DIV: begin
                    if (remainder >= {24'b0, mant_b}) begin
                        remainder <= remainder - {24'b0, mant_b};
                        mant_quotient <= (mant_quotient << 1) | 1'b1;
                    end else begin
                        mant_quotient <= mant_quotient << 1;
                    end
                    remainder <= {remainder[46:0], dividend[47-div_count]};
                    div_count <= div_count + 6'd1;
                end
                NORM: begin
                    if (mant_quotient[23]) begin
                        mant_quotient_reg <= mant_quotient;
                        exp_result_reg <= exp_result;
                        guard <= mant_quotient[22];
                        round_bit <= mant_quotient[21];
                        sticky <= |mant_quotient[20:0];
                    end else begin
                        mant_quotient_reg <= mant_quotient << 1;
                        exp_result_reg <= (exp_result == 8'b0) ? 8'b0 : exp_result - 8'd1;
                        guard <= mant_quotient[21];
                        round_bit <= mant_quotient[20];
                        sticky <= |mant_quotient[19:0];
                    end
                    sign_result_reg <= sign_result;
                end
                ROUND: begin
                    if (round_bit && (guard || sticky || mant_quotient_reg[0]))
                        mant_quotient_reg <= (mant_quotient_reg == 24'hFFFFFF) ? 24'h800000 : mant_quotient_reg + 24'd1;
                    done <= 1'b1;
                end
            endcase
        end
    end

    // Output assignment
    assign result = (state == ROUND) ? {sign_result_reg, exp_result_reg, mant_quotient_reg[22:0]} : 32'b0;
endmodule

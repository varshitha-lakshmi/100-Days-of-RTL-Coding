module float_multiplier (
    input wire clk,          // 100 MHz clock
    input wire rst_n,        // Active-low reset
    input wire start,        // Start computation
    input wire [31:0] a, b,  // 32-bit IEEE 754 inputs
    output wire [31:0] result, // 32-bit IEEE 754 result
    output reg done          // Computation complete
);
    parameter IDLE = 2'd0, INPUT = 2'd1, MUL = 2'd2, NORM = 2'd3;
    reg [1:0] state, next_state;
    reg [7:0] exp_a, exp_b, exp_result, exp_result_reg;
    reg [23:0] mant_a, mant_b, mant_result, mant_result_reg;
    reg [47:0] mant_product;
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
            IDLE: if (start) next_state = INPUT;
            INPUT: next_state = MUL;
            MUL: next_state = NORM;
            NORM: next_state = IDLE;
        endcase
    end

    // Pipeline logic
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
            mant_result <= 24'b0;
            mant_product <= 48'b0;
            guard <= 1'b0;
            round_bit <= 1'b0;
            sticky <= 1'b0;
            sign_result_reg <= 1'b0;
            exp_result_reg <= 8'b0;
            mant_result_reg <= 24'b0;
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
                                 (a_reg[30:23] + b_reg[30:23] - 8'd127);
                end
                MUL: begin
                    mant_product <= mant_a * mant_b;
                    sign_result_reg <= sign_result;
                    exp_result_reg <= exp_result;
                end
                NORM: begin
                    if (mant_product[47]) begin
                        mant_result <= mant_product[47:24];
                        exp_result <= (exp_result_reg == 8'hFF) ? 8'hFF : exp_result_reg + 8'd1;
                        guard <= mant_product[23];
                        round_bit <= mant_product[22];
                        sticky <= |mant_product[21:0];
                    end else begin
                        mant_result <= mant_product[46:23];
                        exp_result <= exp_result_reg;
                        guard <= mant_product[22];
                        round_bit <= mant_product[21];
                        sticky <= |mant_product[20:0];
                    end
                    // Rounding (round-to-nearest, ties to even)
                    if (round_bit && (guard || sticky || mant_result[0]))
                        mant_result <= (mant_result == 24'hFFFFFF) ? 24'h800000 : mant_result + 24'd1;
                    mant_result_reg <= mant_result;
                    sign_result_reg <= sign_result_reg;
                    exp_result_reg <= exp_result;
                    done <= 1'b1;
                end
            endcase
        end
    end

    // Output assignment
    assign result = (state == NORM) ? {sign_result_reg, exp_result_reg, mant_result_reg[22:0]} : 32'b0;
endmodule

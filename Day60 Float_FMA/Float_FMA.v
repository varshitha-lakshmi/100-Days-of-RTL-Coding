

module fma_float (
    input wire clk,          // 100 MHz clock
    input wire rst_n,        // Active-low reset
    input wire start,        // Start computation
    input wire [31:0] a,     // Input A (IEEE 754 32-bit)
    input wire [31:0] b,     // Input B (IEEE 754 32-bit)
    input wire [31:0] c,     // Input C (IEEE 754 32-bit)
    output wire [31:0] result, // Result (A * B) + C (IEEE 754 32-bit)
    output reg done          // Computation complete
);
    // State machine parameters
    parameter IDLE = 2'd0, MULT = 2'd1, ALIGN = 2'd2, ADD = 2'd3, NORM = 2'd0;
    
    // Pipeline registers
    reg [1:0] state, next_state;
    reg [31:0] a_reg, b_reg, c_reg;
    reg sign_prod, sign_c, sign_result;
    reg [7:0] exp_a, exp_b, exp_c, exp_prod, exp_result;
    reg [23:0] mant_a, mant_b, mant_c, mant_prod, mant_result;
    reg [47:0] prod; // Product of mantissas
    reg [47:0] mant_c_aligned;
    reg [8:0] exp_diff; // Exponent difference for alignment
    reg guard, round_bit, sticky;
    reg [31:0] result_reg;

    // State machine: Update state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // State machine: Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (start && !a[31] && !b[31] && !c[31]) next_state = MULT; // Non-negative inputs
            MULT: next_state = ALIGN;
            ALIGN: next_state = ADD;
            ADD: next_state = NORM;
            NORM: next_state = IDLE;
        endcase
    end

    // FMA computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 32'b0; b_reg <= 32'b0; c_reg <= 32'b0;
            sign_prod <= 1'b0; sign_c <= 1'b0; sign_result <= 1'b0;
            exp_a <= 8'b0; exp_b <= 8'b0; exp_c <= 8'b0;
            exp_prod <= 8'b0; exp_result <= 8'b0;
            mant_a <= 24'b0; mant_b <= 24'b0; mant_c <= 24'b0;
            mant_prod <= 24'b0; mant_result <= 24'b0;
            prod <= 48'b0; mant_c_aligned <= 48'b0;
            exp_diff <= 9'b0; guard <= 1'b0; round_bit <= 1'b0; sticky <= 1'b0;
            result_reg <= 32'b0; done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        a_reg <= a; b_reg <= b; c_reg <= c;
                    end
                end
                MULT: begin
                    // Extract sign, exponent, mantissa
                    sign_prod <= a_reg[31] ^ b_reg[31]; // Fixed: Use sign_prod
                    sign_c <= c_reg[31];                // Fixed: Use sign_c
                    exp_a <= a_reg[30:23];
                    exp_b <= b_reg[30:23];
                    exp_c <= c_reg[30:23];
                    mant_a <= {1'b1, a_reg[22:0]}; // Implicit leading 1
                    mant_b <= {1'b1, b_reg[22:0]};
                    mant_c <= {1'b1, c_reg[22:0]};
                    // Compute product: mantissa and exponent
                    prod <= mant_a * mant_b; // 48-bit product
                    exp_prod <= (exp_a == 8'b0 || exp_b == 8'b0) ? 8'b0 :
                                (exp_a + exp_b - 8'd127);
                end
                ALIGN: begin
                    // Align C to product
                    exp_diff <= $signed({1'b0, exp_prod}) - $signed({1'b0, exp_c});
                    if (exp_diff[8] || exp_diff == 9'b0) begin
                        mant_c_aligned <= {mant_c, 24'b0};
                        exp_result <= exp_prod;
                    end else if (exp_diff > 9'd47) begin
                        mant_c_aligned <= 48'b0; // C too small
                        exp_result <= exp_prod;
                    end else begin
                        mant_c_aligned <= mant_c << (24 - exp_diff);
                        exp_result <= exp_c;
                    end
                    mant_prod <= prod[47:24];
                    guard <= prod[23];
                    round_bit <= prod[22];
                    sticky <= |prod[21:0];
                end
                ADD: begin
                    // Add/subtract based on signs
                    if (sign_prod == sign_c) begin
                        mant_result <= prod[47:24] + mant_c_aligned[47:24];
                        sign_result <= sign_prod;
                    end else begin
                        if (prod[47:24] >= mant_c_aligned[47:24]) begin
                            mant_result <= prod[47:24] - mant_c_aligned[47:24];
                            sign_result <= sign_prod;
                        end else begin
                            mant_result <= mant_c_aligned[47:24] - prod[47:24];
                            sign_result <= sign_c;
                        end
                    end
                end
                NORM: begin
                    // Normalize and round
                    if (mant_result[23]) begin
                        result_reg <= {sign_result, exp_result, mant_result[22:0]};
                    end else if (mant_result != 24'b0) begin
                        mant_result <= mant_result << 1;
                        exp_result <= (exp_result == 8'b0) ? 8'b0 : exp_result - 8'd1;
                        result_reg <= {sign_result, exp_result, mant_result[22:0]};
                    end else begin
                        result_reg <= 32'b0; // Zero result
                    end
                    done <= 1'b1;
                end
            endcase
        end
    end

    // Output assignment
    assign result = result_reg;
endmodule

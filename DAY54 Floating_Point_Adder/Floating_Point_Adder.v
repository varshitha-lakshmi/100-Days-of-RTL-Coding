module barrel_shifter (
    input wire [23:0] data_in,   // Input data to shift
    input wire [7:0] shift_amt,  // Shift amount (0 to 255)
    output reg [23:0] data_out   // Shifted output
);
    always @(*) begin
        if (shift_amt >= 24)
            data_out = 24'b0; // Shift beyond width results in 0
        else
            data_out = data_in >> shift_amt; // Synthesizable with barrel shifter
    end
endmodule

module sticky_bit_calculator (
    input wire [23:0] data_in,   // Shifted data
    input wire [7:0] shift_amt,  // Shift amount
    output reg sticky            // Sticky bit
);
    integer i;
    always @(*) begin
        sticky = 1'b0;
        if (shift_amt > 2 && shift_amt <= 24) begin
            for (i = 0; i < shift_amt - 2 && i < 22; i = i + 1) begin
                sticky = sticky | data_in[i];
            end
        end else if (shift_amt > 24) begin
            sticky = |data_in; // OR all bits if shift exceeds width
        end
    end
endmodule

module floating_point_adder (
    input wire clk,          // 100 MHz clock
    input wire rst_n,        // Active-low reset
    input wire start,        // Start addition
    input wire [31:0] a, b,  // 32-bit IEEE 754 inputs
    output reg [31:0] result, // 32-bit IEEE 754 result
    output reg done          // Addition complete
);
    // IEEE 754: 1-bit sign, 8-bit exponent, 23-bit mantissa
    parameter IDLE = 2'd0, ALIGN = 2'd1, ADD = 2'd2, NORM = 2'd3;
    reg [1:0] state, next_state;
    reg [7:0] exp_a, exp_b, exp_diff, exp_result;
    reg [23:0] mant_a, mant_b, mant_shifted, mant_sum;
    reg sign_a, sign_b, sign_result;
    reg [23:0] mant_result;
    reg guard, round_bit, sticky;
    wire [23:0] shift_out;
    wire sticky_bit;

    // Instantiate barrel shifter
    barrel_shifter shifter (
        .data_in((exp_a >= exp_b) ? mant_b : mant_a),
        .shift_amt(exp_diff),
        .data_out(shift_out)
    );

    // Instantiate sticky bit calculator
    sticky_bit_calculator sticky_calc (
        .data_in(shift_out),
        .shift_amt(exp_diff),
        .sticky(sticky_bit)
    );

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
            IDLE: if (start) next_state = ALIGN;
            ALIGN: next_state = ADD;
            ADD: next_state = NORM;
            NORM: next_state = IDLE;
        endcase
    end

    // Pipeline stages
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            exp_result <= 8'b0;
            mant_result <= 24'b0;
            sign_result <= 1'b0;
            result <= 32'b0;
            done <= 1'b0;
            guard <= 1'b0;
            round_bit <= 1'b0;
            sticky <= 1'b0;
            exp_a <= 8'b0;
            exp_b <= 8'b0;
            mant_a <= 24'b0;
            mant_b <= 24'b0;
            exp_diff <= 8'b0;
            mant_shifted <= 24'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        sign_a <= a[31];
                        sign_b <= b[31];
                        exp_a <= a[30:23];
                        exp_b <= b[30:23];
                        mant_a <= {1'b1, a[22:0]}; // Implicit leading 1
                        mant_b <= {1'b1, b[22:0]};
                    end
                end
                ALIGN: begin
                    done <= 1'b0;
                    // Align smaller exponent
                    exp_diff <= (exp_a >= exp_b) ? (exp_a - exp_b) : (exp_b - exp_a);
                    exp_result <= (exp_a >= exp_b) ? exp_a : exp_b;
                    mant_shifted <= shift_out;
                    sign_result <= (exp_a >= exp_b) ? sign_a : sign_b;
                    // Compute guard, round, sticky bits
                    guard <= (exp_diff > 0) ? shift_out[0] : 1'b0;
                    round_bit <= (exp_diff > 1) ? shift_out[1] : 1'b0;
                    sticky <= (exp_diff > 2) ? sticky_bit : 1'b0;
                end
                ADD: begin
                    done <= 1'b0;
                    // Add or subtract mantissas
                    if (sign_a == sign_b)
                        mant_sum <= mant_a + mant_shifted;
                    else
                        mant_sum <= (mant_a >= mant_shifted) ? (mant_a - mant_shifted) : (mant_shifted - mant_a);
                end
                NORM: begin
                    done <= 1'b1;
                    // Normalize result
                    if (mant_sum[23]) begin // Shift right if carry
                        mant_result <= mant_sum >> 1;
                        exp_result <= (exp_result == 8'hFF) ? 8'hFF : exp_result + 8'd1; // Prevent overflow
                        guard <= mant_sum[0];
                        round_bit <= guard;
                        sticky <= sticky | round_bit;
                    end else begin
                        mant_result <= mant_sum;
                    end
                    // Rounding (round-to-nearest-even)
                    if (round_bit && (guard || sticky || mant_result[0])) begin
                        if (mant_result == 24'hFFFFFF) begin // Handle mantissa overflow
                            mant_result <= 24'h800000; // Reset to 1.0
                            exp_result <= (exp_result == 8'hFF) ? 8'hFF : exp_result + 8'd1;
                        end else begin
                            mant_result <= mant_result + 24'd1;
                        end
                    end
                    result <= {sign_result, exp_result, mant_result[22:0]};
                end
            endcase
        end
    end
endmodule

module float_adder (
    input wire clk, rst_n, start,
    input wire [31:0] a, b,
    output wire [31:0] result,
    output reg done
);
    parameter IDLE = 2'd0, ALIGN = 2'd1, ADD = 2'd2, NORM = 2'd3;
    reg [1:0] state, next_state;
    reg [7:0] exp_a, exp_b, exp_diff, exp_result;
    reg [23:0] mant_a, mant_b, mant_shifted, mant_sum;
    reg sign_a, sign_b, sign_result;
    reg [23:0] mant_result;
    reg guard, round_bit, sticky;
    wire [23:0] shift_out;
    reg [31:0] result_reg;

    // Barrel shifter for alignment
    always @(*) begin
        mant_shifted = 24'b0;
        if (exp_diff == 8'd0) mant_shifted = (exp_a >= exp_b) ? mant_b : mant_a;
        else if (exp_diff == 8'd1) mant_shifted = {(exp_a >= exp_b) ? mant_b[22:0] : mant_a[22:0], 1'b0};
        else if (exp_diff == 8'd2) mant_shifted = {(exp_a >= exp_b) ? mant_b[21:0] : mant_a[21:0], 2'b0};
        else if (exp_diff == 8'd3) mant_shifted = {(exp_a >= exp_b) ? mant_b[20:0] : mant_a[20:0], 3'b0};
        else if (exp_diff == 8'd4) mant_shifted = {(exp_a >= exp_b) ? mant_b[19:0] : mant_a[19:0], 4'b0};
        else if (exp_diff == 8'd5) mant_shifted = {(exp_a >= exp_b) ? mant_b[18:0] : mant_a[18:0], 5'b0};
        else if (exp_diff == 8'd6) mant_shifted = {(exp_a >= exp_b) ? mant_b[17:0] : mant_a[17:0], 6'b0};
        else if (exp_diff == 8'd7) mant_shifted = {(exp_a >= exp_b) ? mant_b[16:0] : mant_a[16:0], 7'b0};
        else if (exp_diff == 8'd8) mant_shifted = {(exp_a >= exp_b) ? mant_b[15:0] : mant_a[15:0], 8'b0};
        else if (exp_diff == 8'd9) mant_shifted = {(exp_a >= exp_b) ? mant_b[14:0] : mant_a[14:0], 9'b0};
        else if (exp_diff == 8'd10) mant_shifted = {(exp_a >= exp_b) ? mant_b[13:0] : mant_a[13:0], 10'b0};
        else if (exp_diff == 8'd11) mant_shifted = {(exp_a >= exp_b) ? mant_b[12:0] : mant_a[12:0], 11'b0};
        else if (exp_diff == 8'd12) mant_shifted = {(exp_a >= exp_b) ? mant_b[11:0] : mant_a[11:0], 12'b0};
        else if (exp_diff == 8'd13) mant_shifted = {(exp_a >= exp_b) ? mant_b[10:0] : mant_a[10:0], 13'b0};
        else if (exp_diff == 8'd14) mant_shifted = {(exp_a >= exp_b) ? mant_b[9:0] : mant_a[9:0], 14'b0};
        else if (exp_diff == 8'd15) mant_shifted = {(exp_a >= exp_b) ? mant_b[8:0] : mant_a[8:0], 15'b0};
        else if (exp_diff == 8'd16) mant_shifted = {(exp_a >= exp_b) ? mant_b[7:0] : mant_a[7:0], 16'b0};
        else if (exp_diff == 8'd17) mant_shifted = {(exp_a >= exp_b) ? mant_b[6:0] : mant_a[6:0], 17'b0};
        else if (exp_diff == 8'd18) mant_shifted = {(exp_a >= exp_b) ? mant_b[5:0] : mant_a[5:0], 18'b0};
        else if (exp_diff == 8'd19) mant_shifted = {(exp_a >= exp_b) ? mant_b[4:0] : mant_a[4:0], 19'b0};
        else if (exp_diff == 8'd20) mant_shifted = {(exp_a >= exp_b) ? mant_b[3:0] : mant_a[3:0], 20'b0};
        else if (exp_diff == 8'd21) mant_shifted = {(exp_a >= exp_b) ? mant_b[2:0] : mant_a[2:0], 21'b0};
        else if (exp_diff == 8'd22) mant_shifted = {(exp_a >= exp_b) ? mant_b[1:0] : mant_a[1:0], 22'b0};
        else if (exp_diff == 8'd23) mant_shifted = {(exp_a >= exp_b) ? mant_b[0] : mant_a[0], 23'b0};
        else mant_shifted = 24'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (start) next_state = ALIGN;
            ALIGN: next_state = ADD;
            ADD: next_state = NORM;
            NORM: next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 32'b0; done <= 1'b0; exp_result <= 8'b0;
            mant_result <= 24'b0; sign_result <= 1'b0;
            guard <= 1'b0; round_bit <= 1'b0; sticky <= 1'b0;
            exp_a <= 8'b0; exp_b <= 8'b0; mant_a <= 24'b0; mant_b <= 24'b0;
            exp_diff <= 8'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        sign_a <= a[31]; sign_b <= b[31];
                        exp_a <= a[30:23]; exp_b <= b[30:23];
                        mant_a <= {1'b1, a[22:0]}; mant_b <= {1'b1, b[22:0]};
                    end
                end
                ALIGN: begin
                    exp_diff <= (exp_a >= exp_b) ? (exp_a - exp_b) : (exp_b - exp_a);
                    exp_result <= (exp_a >= exp_b) ? exp_a : exp_b;
                    sign_result <= (exp_a >= exp_b) ? sign_a : sign_b;
                    guard <= (exp_diff > 0) ? mant_shifted[0] : 1'b0;
                    round_bit <= (exp_diff > 1) ? mant_shifted[1] : 1'b0;
                    sticky <= (exp_diff > 2) ? |mant_shifted[23:2] : 1'b0;
                end
                ADD: begin
                    if (sign_a == sign_b)
                        mant_sum <= mant_a + mant_shifted;
                    else
                        mant_sum <= (mant_a >= mant_shifted) ? (mant_a - mant_shifted) : (mant_shifted - mant_a);
                end
                NORM: begin
                    if (mant_sum[23]) begin
                        mant_result <= mant_sum >> 1;
                        exp_result <= (exp_result == 8'hFF) ? 8'hFF : exp_result + 8'd1;
                        guard <= mant_sum[0];
                        round_bit <= guard;
                        sticky <= sticky | round_bit;
                    end else begin
                        mant_result <= mant_sum;
                    end
                    if (round_bit && (guard || sticky || mant_result[0]))
                        mant_result <= (mant_result == 24'hFFFFFF) ? 24'h800000 : mant_result + 24'd1;
                    result_reg <= {sign_result, exp_result, mant_result[22:0]};
                    done <= 1'b1;
                end
            endcase
        end
    end
    assign result = result_reg;
endmodule

module float_multiplier (
    input wire clk, rst_n, start,
    input wire [31:0] a, b,
    output wire [31:0] result,
    output reg done
);
    parameter IDLE = 2'd0, MUL = 2'd1, NORM = 2'd2;
    reg [1:0] state, next_state;
    reg [7:0] exp_result;
    reg [23:0] mant_a, mant_b;
    reg [47:0] mant_product;
    reg sign_result;
    reg [23:0] mant_result;
    reg [31:0] result_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (start) next_state = MUL;
            MUL: next_state = NORM;
            NORM: next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 32'b0; done <= 1'b0;
            exp_result <= 8'b0; mant_result <= 24'b0;
            sign_result <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        sign_result <= a[31] ^ b[31];
                        exp_result <= a[30:23] + b[30:23] - 8'd127;
                        mant_a <= {1'b1, a[22:0]};
                        mant_b <= {1'b1, b[22:0]};
                    end
                end
                MUL: begin
                    mant_product <= mant_a * mant_b;
                end
                NORM: begin
                    if (mant_product[47]) begin
                        mant_result <= mant_product[47:24];
                        exp_result <= (exp_result == 8'hFF) ? 8'hFF : exp_result + 8'd1;
                    end else begin
                        mant_result <= mant_product[46:23];
                    end
                    if (mant_result[22:0] == 23'h7FFFFF && mant_product[47])
                        exp_result <= (exp_result == 8'hFF) ? 8'hFF : exp_result + 8'd1;
                    result_reg <= {sign_result, exp_result, mant_result[22:0]};
                    done <= 1'b1;
                end
            endcase
        end
    end
    assign result = result_reg;
endmodule

module float_mac (
    input wire clk,          // 100 MHz clock
    input wire rst_n,        // Active-low reset
    input wire start,        // Start computation
    input wire [31:0] a, b, c, // 32-bit IEEE 754 inputs (A * B + C)
    output wire [31:0] result, // 32-bit IEEE 754 result
    output reg done          // Computation complete
);
    parameter IDLE = 2'd0, INPUT = 2'd1, MUL = 2'd2, ADD = 2'd3, OUTPUT = 2'd0;
    reg [1:0] state, next_state;
    wire [31:0] mul_result, add_result;
    wire mul_done, add_done;
    reg [31:0] result_reg;

    // Instantiate multiplier and adder
    float_multiplier mul (
        .clk(clk), .rst_n(rst_n), .start(start),
        .a(a), .b(b), .result(mul_result), .done(mul_done)
    );
    float_adder add (
        .clk(clk), .rst_n(rst_n), .start(mul_done),
        .a(mul_result), .b(c), .result(add_result), .done(add_done)
    );

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
            MUL: if (mul_done) next_state = ADD;
            ADD: if (add_done) next_state = OUTPUT;
            OUTPUT: next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 32'b0;
            done <= 1'b0;
        end else if (state == ADD && add_done) begin
            result_reg <= add_result;
            done <= 1'b1;
        end
    end

    assign result = result_reg;
endmodule

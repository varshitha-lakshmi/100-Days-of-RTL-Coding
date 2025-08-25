module fft_4point (
    input wire clk,          // 100 MHz clock
    input wire rst_n,        // Active-low reset
    input wire start,        // Start computation
    input wire [31:0] x0_real, x0_imag, // Input 0 (16.16 fixed-point)
    input wire [31:0] x1_real, x1_imag, // Input 1
    input wire [31:0] x2_real, x2_imag, // Input 2
    input wire [31:0] x3_real, x3_imag, // Input 3
    output wire [31:0] y0_real, y0_imag, // Output 0 (16.16 fixed-point)
    output wire [31:0] y1_real, y1_imag, // Output 1
    output wire [31:0] y2_real, y2_imag, // Output 2
    output wire [31:0] y3_real, y3_imag, // Output 3
    output reg done          // Computation complete
);
    // State machine parameters
    parameter IDLE = 2'd0, INPUT = 2'd1, BUTTERFLY = 2'd2, OUTPUT = 2'd3;
    
    // Pipeline registers
    reg [1:0] state, next_state;
    reg [31:0] x0_r_reg, x0_i_reg, x1_r_reg, x1_i_reg;
    reg [31:0] x2_r_reg, x2_i_reg, x3_r_reg, x3_i_reg;
    reg [31:0] t0_r, t0_i, t1_r, t1_i, t2_r, t2_i, t3_r, t3_i;
    reg [31:0] y0_r_reg, y0_i_reg, y1_r_reg, y1_i_reg;
    reg [31:0] y2_r_reg, y2_i_reg, y3_r_reg, y3_i_reg;
    reg [63:0] prod1, prod2; // Intermediate products
    
    // Twiddle factors (1.31 fixed-point, from Day 58 CORDIC)
    wire [31:0] w0_real = 32'h7FFFFFFF; // 1.0
    wire [31:0] w0_imag = 32'h00000000; // 0.0
    wire [31:0] w1_real = 32'h00000000; // 0.0
    wire [31:0] w1_imag = 32'h80000000; // -1.0
    
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
            IDLE: if (start) next_state = INPUT;
            INPUT: next_state = BUTTERFLY;
            BUTTERFLY: next_state = OUTPUT;
            OUTPUT: next_state = IDLE;
        endcase
    end

    // FFT computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x0_r_reg <= 32'b0; x0_i_reg <= 32'b0;
            x1_r_reg <= 32'b0; x1_i_reg <= 32'b0;
            x2_r_reg <= 32'b0; x2_i_reg <= 32'b0;
            x3_r_reg <= 32'b0; x3_i_reg <= 32'b0;
            t0_r <= 32'b0; t0_i <= 32'b0;
            t1_r <= 32'b0; t1_i <= 32'b0;
            t2_r <= 32'b0; t2_i <= 32'b0;
            t3_r <= 32'b0; t3_i <= 32'b0;
            y0_r_reg <= 32'b0; y0_i_reg <= 32'b0;
            y1_r_reg <= 32'b0; y1_i_reg <= 32'b0;
            y2_r_reg <= 32'b0; y2_i_reg <= 32'b0;
            y3_r_reg <= 32'b0; y3_i_reg <= 32'b0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        x0_r_reg <= x0_real; x0_i_reg <= x0_imag;
                        x1_r_reg <= x1_real; x1_i_reg <= x1_imag;
                        x2_r_reg <= x2_real; x2_i_reg <= x2_imag;
                        x3_r_reg <= x3_real; x3_i_reg <= x3_imag;
                    end
                end
                INPUT: begin
                    // First butterfly stage: (x0, x2), (x1, x3)
                    t0_r <= $signed(x0_r_reg) + $signed(x2_r_reg);
                    t0_i <= $signed(x0_i_reg) + $signed(x2_i_reg);
                    t2_r <= $signed(x0_r_reg) - $signed(x2_r_reg);
                    t2_i <= $signed(x0_i_reg) - $signed(x2_i_reg);
                    t1_r <= $signed(x1_r_reg) + $signed(x3_r_reg);
                    t1_i <= $signed(x1_i_reg) + $signed(x3_i_reg);
                    t3_r <= $signed(x1_r_reg) - $signed(x3_r_reg);
                    t3_i <= $signed(x1_i_reg) - $signed(x3_i_reg);
                end
                BUTTERFLY: begin
                    // Second butterfly stage with twiddle factors
                    // y0 = t0 + t1, y2 = t0 - t1
                    y0_r_reg <= $signed(t0_r) + $signed(t1_r);
                    y0_i_reg <= $signed(t0_i) + $signed(t1_i);
                    y2_r_reg <= $signed(t0_r) - $signed(t1_r);
                    y2_i_reg <= $signed(t0_i) - $signed(t1_i);
                    // y1 = t2 + t3 * W1, y3 = t2 - t3 * W1
                    prod1 <= ($signed(t3_r) * $signed(w1_real)) - ($signed(t3_i) * $signed(w1_imag));
                    prod2 <= ($signed(t3_r) * $signed(w1_imag)) + ($signed(t3_i) * $signed(w1_real));
                    y1_r_reg <= $signed(t2_r) + $signed(prod1[46:15]); // Truncate to 16.16
                    y1_i_reg <= $signed(t2_i) + $signed(prod2[46:15]);
                    y3_r_reg <= $signed(t2_r) - $signed(prod1[46:15]);
                    y3_i_reg <= $signed(t2_i) - $signed(prod2[46:15]);
                    done <= 1'b1;
                end
                OUTPUT: begin
                    done <= 1'b0;
                end
            endcase
        end
    end

    // Output assignments
    assign y0_real = y0_r_reg; assign y0_imag = y0_i_reg;
    assign y1_real = y1_r_reg; assign y1_imag = y1_i_reg;
    assign y2_real = y2_r_reg; assign y2_imag = y2_i_reg;
    assign y3_real = y3_r_reg; assign y3_imag = y3_i_reg;
endmodule

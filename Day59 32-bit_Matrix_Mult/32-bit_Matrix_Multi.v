module matrix_mult (
    input wire clk,          // 100 MHz clock
    input wire rst_n,        // Active-low reset
    input wire start,        // Start computation
    input wire [31:0] a11, a12, a21, a22, // Matrix A elements (16.16 fixed-point)
    input wire [31:0] b11, b12, b21, b22, // Matrix B elements (16.16 fixed-point)
    output wire [31:0] c11, c12, c21, c22, // Matrix C elements (16.16 fixed-point)
    output reg done          // Computation complete
);
    // State machine parameters
    parameter IDLE = 2'd0, LOAD = 2'd1, MULT = 2'd2, ACCUM = 2'd3;
    
    // Pipeline registers
    reg [1:0] state, next_state;
    reg [31:0] a11_reg, a12_reg, a21_reg, a22_reg;
    reg [31:0] b11_reg, b12_reg, b21_reg, b22_reg;
    reg [63:0] prod1, prod2, prod3, prod4; // Intermediate products
    reg [31:0] c11_reg, c12_reg, c21_reg, c22_reg;
    
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
            IDLE: if (start) next_state = LOAD;
            LOAD: next_state = MULT;
            MULT: next_state = ACCUM;
            ACCUM: next_state = IDLE;
        endcase
    end

    // Matrix multiplication logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a11_reg <= 32'b0; a12_reg <= 32'b0; a21_reg <= 32'b0; a22_reg <= 32'b0;
            b11_reg <= 32'b0; b12_reg <= 32'b0; b21_reg <= 32'b0; b22_reg <= 32'b0;
            prod1 <= 64'b0; prod2 <= 64'b0; prod3 <= 64'b0; prod4 <= 64'b0;
            c11_reg <= 32'b0; c12_reg <= 32'b0; c21_reg <= 32'b0; c22_reg <= 32'b0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        a11_reg <= a11; a12_reg <= a12;
                        a21_reg <= a21; a22_reg <= a22;
                        b11_reg <= b11; b12_reg <= b12;
                        b21_reg <= b21; b22_reg <= b22;
                    end
                end
                LOAD: begin
                    // Compute products: C = A * B
                    // c11 = a11*b11 + a12*b21
                    // c12 = a11*b12 + a12*b22
                    // c21 = a21*b11 + a22*b21
                    // c22 = a21*b12 + a22*b22
                    prod1 <= $signed(a11_reg) * $signed(b11_reg);
                    prod2 <= $signed(a12_reg) * $signed(b21_reg);
                    prod3 <= $signed(a11_reg) * $signed(b12_reg);
                    prod4 <= $signed(a12_reg) * $signed(b22_reg);
                end
                MULT: begin
                    prod1 <= $signed(a21_reg) * $signed(b11_reg);
                    prod2 <= $signed(a22_reg) * $signed(b21_reg);
                    prod3 <= $signed(a21_reg) * $signed(b12_reg);
                    prod4 <= $signed(a22_reg) * $signed(b22_reg);
                end
                ACCUM: begin
                    // Accumulate and truncate to 16.16 (shift right by 16)
                    c11_reg <= ($signed(prod1) + $signed(prod2)) >>> 16;
                    c12_reg <= ($signed(prod3) + $signed(prod4)) >>> 16;
                    c21_reg <= ($signed(prod1) + $signed(prod2)) >>> 16;
                    c22_reg <= ($signed(prod3) + $signed(prod4)) >>> 16;
                    done <= 1'b1;
                end
            endcase
        end
    end

    // Output assignments
    assign c11 = c11_reg;
    assign c12 = c12_reg;
    assign c21 = c21_reg;
    assign c22 = c22_reg;
endmodule

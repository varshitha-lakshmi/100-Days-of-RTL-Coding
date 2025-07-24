module matrix_multiplier (
    input wire clk,          // Input clock (100 MHz)
    input wire rst_n,        // Active-low reset
    input wire start,        // Start multiplication
    input wire [7:0] a11, a12, a21, a22, // Matrix A elements
    input wire [7:0] b11, b12, b21, b22, // Matrix B elements
    output reg [15:0] c11, c12, c21, c22, // Matrix C elements (result)
    output reg done          // Multiplication complete
);
    // FSM states
    parameter IDLE = 2'd0, LOAD = 2'd1, COMPUTE = 2'd2, OUTPUT = 2'd3;
    reg [1:0] state, next_state;
    reg [7:0] a11_reg, a12_reg, a21_reg, a22_reg; // Matrix A registers
    reg [7:0] b11_reg, b12_reg, b21_reg, b22_reg; // Matrix B registers
    reg [15:0] c11_reg, c12_reg, c21_reg, c22_reg; // Result registers

    // FSM: State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // FSM: Next state logic (combinational)
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start)
                    next_state = LOAD;
            end
            LOAD: begin
                next_state = COMPUTE;
            end
            COMPUTE: begin
                next_state = OUTPUT;
            end
            OUTPUT: begin
                next_state = IDLE;
            end
        endcase
    end

    // Sequential logic for matrix multiplication and done signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a11_reg <= 0; a12_reg <= 0; a21_reg <= 0; a22_reg <= 0;
            b11_reg <= 0; b12_reg <= 0; b21_reg <= 0; b22_reg <= 0;
            c11_reg <= 0; c12_reg <= 0; c21_reg <= 0; c22_reg <= 0;
            c11 <= 0; c12 <= 0; c21 <= 0; c22 <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                end
                LOAD: begin
                    a11_reg <= a11; a12_reg <= a12;
                    a21_reg <= a21; a22_reg <= a22;
                    b11_reg <= b11; b12_reg <= b12;
                    b21_reg <= b21; b22_reg <= b22;
                    done <= 0;
                end
                COMPUTE: begin
                    c11_reg <= a11_reg * b11_reg + a12_reg * b21_reg;
                    c12_reg <= a11_reg * b12_reg + a12_reg * b22_reg;
                    c21_reg <= a21_reg * b11_reg + a22_reg * b21_reg;
                    c22_reg <= a21_reg * b12_reg + a22_reg * b22_reg;
                    done <= 0;
                end
                OUTPUT: begin
                    c11 <= c11_reg; c12 <= c12_reg;
                    c21 <= c21_reg; c22 <= c22_reg;
                    done <= 1;
                end
            endcase
        end
    end
endmodule

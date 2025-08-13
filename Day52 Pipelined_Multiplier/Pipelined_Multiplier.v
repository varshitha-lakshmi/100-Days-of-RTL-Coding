module pipelined_multiplier (
    input wire clk,          // 100 MHz clock
    input wire rst_n,        // Active-low reset
    input wire start,        // Start multiplication
    input wire [7:0] a, b,   // 8-bit inputs
    output reg [15:0] result, // 16-bit result
    output reg done          // Multiplication complete
);
    // FSM states
    parameter IDLE = 2'd0, STAGE1 = 2'd1, STAGE2 = 2'd2, STAGE3 = 2'd3;
    reg [1:0] state, next_state;
    reg [7:0] a_reg, b_reg; // Stage 1: Input registers
    reg [15:0] mult_reg;    // Stage 2: Multiplication result
    reg [15:0] result_reg;  // Stage 3: Output register

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
                    next_state = STAGE1;
            end
            STAGE1: begin
                next_state = STAGE2;
            end
            STAGE2: begin
                next_state = STAGE3;
            end
            STAGE3: begin
                next_state = IDLE;
            end
        endcase
    end

    // Pipeline stages
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 0;
            b_reg <= 0;
            mult_reg <= 0;
            result_reg <= 0;
            result <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        a_reg <= a;
                        b_reg <= b;
                    end
                end
                STAGE1: begin
                    mult_reg <= a_reg * b_reg; // Multiplication
                    done <= 0;
                end
                STAGE2: begin
                    result_reg <= mult_reg; // Store result
                    done <= 0;
                end
                STAGE3: begin
                    result <= result_reg; // Output result
                    done <= 1;
                end
            endcase
        end
    end
endmodule

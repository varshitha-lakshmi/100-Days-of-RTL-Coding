module cordic_sincos (
    input wire clk,          // 100 MHz clock
    input wire rst_n,        // Active-low reset
    input wire start,        // Start computation
    input wire [31:0] theta, // Input angle (2.30 fixed-point, radians)
    output wire [31:0] sin_out, // Sine output (1.31 fixed-point)
    output wire [31:0] cos_out, // Cosine output (1.31 fixed-point)
    output reg done          // Computation complete
);
    // Fixed-point format: 1.31 for sin/cos, 2.30 for theta
    // CORDIC parameters
    parameter STAGES = 16;
    parameter IDLE = 2'd0, COMPUTE = 2'd1, OUTPUT = 2'd2;
    
    // Registers
    reg [1:0] state, next_state;
    reg [31:0] x, y, z;
    reg [31:0] x_next, y_next, z_next;
    reg [4:0] stage_count;
    reg [31:0] sin_reg, cos_reg;
    
    // Arctangent table (2.30 fixed-point, precomputed for 16 stages)
    reg [31:0] atan_table [0:15];
    initial begin
        atan_table[0]  = 32'h3243F6A8; // atan(2^0)  = 0.785398163 (pi/4)
        atan_table[1]  = 32'h1DAC6705; // atan(2^-1) = 0.463647609
        atan_table[2]  = 32'h0FADBAFC; // atan(2^-2) = 0.244978663
        atan_table[3]  = 32'h07F56EA6; // atan(2^-3) = 0.124354994
        atan_table[4]  = 32'h03FEAB76; // atan(2^-4) = 0.062418809
        atan_table[5]  = 32'h01FFD55B; // atan(2^-5) = 0.031260175
        atan_table[6]  = 32'h00FFFAA6; // atan(2^-6) = 0.015626271
        atan_table[7]  = 32'h007FFF55; // atan(2^-7) = 0.007812655
        atan_table[8]  = 32'h003FFFE9; // atan(2^-8) = 0.003906334
        atan_table[9]  = 32'h001FFFF8; // atan(2^-9) = 0.001953167
        atan_table[10] = 32'h000FFFFE; // atan(2^-10) = 0.000976586
        atan_table[11] = 32'h0007FFFF; // atan(2^-11) = 0.000488281
        atan_table[12] = 32'h0003FFFF; // atan(2^-12) = 0.000244141
        atan_table[13] = 32'h0001FFFF; // atan(2^-13) = 0.000122070
        atan_table[14] = 32'h0000FFFF; // atan(2^-14) = 0.000061035
        atan_table[15] = 32'h00007FFF; // atan(2^-15) = 0.000030518
    end
    
    // CORDIC gain (1.31 fixed-point, ~0.607252935)
    parameter CORDIC_GAIN = 32'h26DD3B6A;

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
            IDLE: if (start) next_state = COMPUTE;
            COMPUTE: if (stage_count == STAGES - 1) next_state = OUTPUT;
            OUTPUT: next_state = IDLE;
        endcase
    end

    // CORDIC iteration logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x <= 32'b0;
            y <= 32'b0;
            z <= 32'b0;
            stage_count <= 5'b0;
            sin_reg <= 32'b0;
            cos_reg <= 32'b0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        x <= CORDIC_GAIN; // Initialize x to 1/K
                        y <= 32'b0;       // Initialize y to 0
                        z <= theta;       // Initialize z to input angle
                        stage_count <= 5'b0;
                    end
                end
                COMPUTE: begin
                    // CORDIC rotation
                    if (z[31]) begin // z < 0
                        x_next <= x + (y >> stage_count);
                        y_next <= y - (x >> stage_count);
                        z_next <= z + atan_table[stage_count];
                    end else begin // z >= 0
                        x_next <= x - (y >> stage_count);
                        y_next <= y + (x >> stage_count);
                        z_next <= z - atan_table[stage_count];
                    end
                    x <= x_next;
                    y <= y_next;
                    z <= z_next;
                    stage_count <= stage_count + 5'd1;
                end
                OUTPUT: begin
                    sin_reg <= y; // 1.31 fixed-point
                    cos_reg <= x; // 1.31 fixed-point
                    done <= 1'b1;
                end
            endcase
        end
    end

    // Output assignment
    assign sin_out = sin_reg;
    assign cos_out = cos_reg;
endmodule

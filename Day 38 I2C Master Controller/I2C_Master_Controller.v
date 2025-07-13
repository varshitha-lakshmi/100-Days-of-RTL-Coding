module i2c_master (
    input wire clk,          // Input clock (100 MHz)
    input wire rst_n,        // Active-low reset
    input wire start,        // Start transaction signal
    input wire [6:0] addr,   // 7-bit slave address
    input wire [7:0] data,   // 8-bit data to write
    output reg scl,          // I2C clock line
    output reg sda,          // I2C data line
    output reg done          // Transaction complete signal
);
    parameter CLK_FREQ = 100_000_000; // 100 MHz clock
    parameter SCL_FREQ = 100_000;     // 100 kHz SCL
    parameter CLK_PER_SCL = CLK_FREQ / SCL_FREQ / 2; // 500 clocks per SCL half-period

    // States
    parameter IDLE = 3'd0, START = 3'd1, ADDR = 3'd2, WR = 3'd3, DATA = 3'd4, STOP = 3'd5;
    reg [2:0] state, next_state;
    reg [9:0] clk_counter;   // Counter for SCL timing
    reg [3:0] bit_counter;   // Counts address and data bits
    reg [7:0] shift_reg;     // Shift register for address and data

    // Clock divider for SCL
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_counter <= 0;
            scl <= 1;
        end else begin
            if (clk_counter == CLK_PER_SCL - 1) begin
                clk_counter <= 0;
                scl <= ~scl; // Toggle SCL
            end else begin
                clk_counter <= clk_counter + 1;
            end
        end
    end

    // FSM: State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else if (clk_counter == CLK_PER_SCL - 1 && scl == 0) // Update at SCL low
            state <= next_state;
    end

    // FSM: Next state and output logic
    always @(*) begin
        next_state = state;
        sda = 1;
        done = 0;
        case (state)
            IDLE: begin
                if (start)
                    next_state = START;
            end
            START: begin
                sda = 0; // Start condition: SDA low while SCL high
                next_state = ADDR;
            end
            ADDR: begin
                sda = shift_reg[7]; // Send address and write bit
                if (bit_counter == 4'd8)
                    next_state = WR;
            end
            WR: begin
                sda = 1; // Placeholder for ACK (not implemented)
                next_state = DATA;
            end
            DATA: begin
                sda = shift_reg[7]; // Send data bits
                if (bit_counter == 4'd7)
                    next_state = STOP;
            end
            STOP: begin
                sda = 0; // Stop condition: SDA high while SCL high
                done = 1;
                next_state = IDLE;
            end
        endcase
    end

    // Shift register and bit counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 8'b0;
            bit_counter <= 4'b0;
        end else if (clk_counter == CLK_PER_SCL - 1 && scl == 0) begin
            if (state == IDLE && start) begin
                shift_reg <= {addr, 1'b0}; // Load address + write bit
                bit_counter <= 4'b0;
            end else if (state == ADDR) begin
                shift_reg <= {shift_reg[6:0], 1'b0};
                bit_counter <= bit_counter + 1;
            end else if (state == WR) begin
                shift_reg <= data; // Load data
                bit_counter <= 4'b0;
            end else if (state == DATA) begin
                shift_reg <= {shift_reg[6:0], 1'b0};
                bit_counter <= bit_counter + 1;
            end
        end
    end
endmodule

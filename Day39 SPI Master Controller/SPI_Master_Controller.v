module spi_master (
    input wire clk,          // Input clock (100 MHz)
    input wire rst_n,        // Active-low reset
    input wire start,        // Start transaction signal
    input wire [7:0] data_in,// 8-bit data to write
    output reg sclk,         // SPI clock
    output reg mosi,         // Master out, slave in
    output reg cs,           // Chip select (active-low)
    output reg done          // Transaction complete signal
);
    parameter CLK_FREQ = 100_000_000; // 100 MHz clock
    parameter SCLK_FREQ = 1_000_000;  // 1 MHz SCLK
    parameter CLK_PER_SCLK = CLK_FREQ / SCLK_FREQ / 2; // 50 clocks per SCLK half-period

    // States
    parameter IDLE = 2'd0, SETUP = 2'd1, TRANSFER = 2'd2, DONE = 2'd3;
    reg [1:0] state, next_state;
    reg [6:0] clk_counter;   // Counter for SCLK timing
    reg [3:0] bit_counter;   // Counts 8 data bits
    reg [7:0] shift_reg;     // Shift register for data

    // SCLK generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_counter <= 0;
            sclk <= 0; // Mode 0: SCLK idle low
        end else begin
            if (clk_counter == CLK_PER_SCLK - 1) begin
                clk_counter <= 0;
                if (state == TRANSFER)
                    sclk <= ~sclk; // Toggle SCLK during transfer
            end else begin
                clk_counter <= clk_counter + 1;
            end
        end
    end

    // FSM: State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else if (clk_counter == CLK_PER_SCLK - 1 && sclk == 0)
            state <= next_state;
    end

    // FSM: Next state and output logic
    always @(*) begin
        next_state = state;
        cs = 1; // CS high (inactive) by default
        mosi = 0;
        done = 0;
        case (state)
            IDLE: begin
                if (start)
                    next_state = SETUP;
            end
            SETUP: begin
                cs = 0; // Activate CS
                next_state = TRANSFER;
            end
            TRANSFER: begin
                cs = 0;
                mosi = shift_reg[7]; // Send MSB first
                if (bit_counter == 4'd7)
                    next_state = DONE;
            end
            DONE: begin
                cs = 0;
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
        end else if (clk_counter == CLK_PER_SCLK - 1 && sclk == 0) begin
            if (state == IDLE && start) begin
                shift_reg <= data_in; // Load data
                bit_counter <= 4'b0;
            end else if (state == TRANSFER) begin
                shift_reg <= {shift_reg[6:0], 1'b0}; // Shift left
                bit_counter <= bit_counter + 1;
            end
        end
    end
endmodule

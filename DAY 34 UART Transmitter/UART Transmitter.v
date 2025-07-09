module uart_transmitter (
    input wire clk,          // Input clock (100 MHz)
    input wire rst_n,        // Active-low reset
    input wire [7:0] data_in,// 8-bit data to transmit
    input wire tx_start,     // Start transmission signal
    output reg tx,           // Serial output
    output reg tx_done       // Transmission complete signal
);
    parameter CLK_FREQ = 100_000_000; // 100 MHz clock
    parameter BAUD_RATE = 9600;       // 9600 baud
    parameter BAUD_TICK = CLK_FREQ / BAUD_RATE; // 10417 clocks per baud

    // States
    parameter IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    reg [1:0] state, next_state;
    reg [13:0] baud_counter;  // Counter for baud rate (up to 10417)
    reg [3:0] bit_counter;    // Counts 8 data bits
    reg [7:0] shift_reg;      // Shift register for data

    // Baud rate counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            baud_counter <= 0;
        else if (baud_counter == BAUD_TICK - 1)
            baud_counter <= 0;
        else
            baud_counter <= baud_counter + 1;
    end

    wire baud_tick = (baud_counter == BAUD_TICK - 1);

    // FSM: State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else if (baud_tick)
            state <= next_state;
    end

    // FSM: Next state and output logic
    always @(*) begin
        next_state = state;
        tx = 1'b1; // Default: idle/stop bit
        tx_done = 1'b0;
        case (state)
            IDLE: begin
                if (tx_start) begin
                    next_state = START;
                end
            end
            START: begin
                tx = 1'b0; // Start bit
                next_state = DATA;
            end
            DATA: begin
                tx = shift_reg[0]; // Send LSB first
                if (bit_counter == 4'd7)
                    next_state = STOP;
            end
            STOP: begin
                tx = 1'b1; // Stop bit
                tx_done = 1'b1;
                next_state = IDLE;
            end
        endcase
    end

    // Shift register and bit counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 8'b0;
            bit_counter <= 4'b0;
        end else if (baud_tick) begin
            if (state == IDLE && tx_start) begin
                shift_reg <= data_in; // Load data
                bit_counter <= 4'b0;
            end else if (state == DATA) begin
                shift_reg <= {1'b0, shift_reg[7:1]}; // Shift right
                bit_counter <= bit_counter + 1;
            end
        end
    end
endmodule

module uart_receiver (
    input wire clk,          // Input clock (100 MHz)
    input wire rst_n,        // Active-low reset
    input wire rx,           // Serial input
    output reg [7:0] data_out,// 8-bit received data
    output reg rx_done       // Reception complete signal
);
    parameter CLK_FREQ = 100_000_000; // 100 MHz clock
    parameter BAUD_RATE = 9600;       // 9600 baud
    parameter BAUD_TICK = CLK_FREQ / BAUD_RATE; // 10417 clocks per baud
    parameter HALF_BAUD = BAUD_TICK / 2; // Sample at mid-bit

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

    wire baud_tick = (baud_counter == HALF_BAUD); // Sample at mid-bit

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
        rx_done = 1'b0;
        case (state)
            IDLE: begin
                if (!rx) // Detect start bit (low)
                    next_state = START;
            end
            START: begin
                next_state = DATA;
            end
            DATA: begin
                if (bit_counter == 4'd7)
                    next_state = STOP;
            end
            STOP: begin
                if (rx) // Verify stop bit (high)
                    rx_done = 1'b1;
                next_state = IDLE;
            end
        endcase
    end

    // Shift register and bit counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 8'b0;
            bit_counter <= 4'b0;
            data_out <= 8'b0;
        end else if (baud_tick) begin
            if (state == START) begin
                bit_counter <= 4'b0;
            end else if (state == DATA) begin
                shift_reg <= {rx, shift_reg[7:1]}; // Shift in received bit
                bit_counter <= bit_counter + 1;
            end else if (state == STOP) begin
                data_out <= shift_reg; // Output received data
            end
        end
    end
endmodule

module uart_transmitter (
    input wire clk,          // 100 MHz clock
    input wire rst_n,        // Active-low reset
    input wire tx_start,     // Start transmission
    input wire [7:0] tx_data,// 8-bit data to transmit
    output reg tx,           // Serial output
    output reg tx_done       // Transmission complete
);
    parameter CLK_FREQ = 100_000_000; // 100 MHz
    parameter BAUD_RATE = 9600;
    parameter CLK_PER_BIT = CLK_FREQ / BAUD_RATE; // 10417 cycles
    parameter IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    reg [1:0] state, next_state;
    reg [13:0] clk_count; // Supports up to 16384 cycles
    reg [7:0] data_reg;
    reg [2:0] bit_index;

    // FSM: State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // FSM: Next state and output logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (tx_start)
                    next_state = START;
            end
            START: begin
                if (clk_count == CLK_PER_BIT - 1)
                    next_state = DATA;
            end
            DATA: begin
                if (clk_count == CLK_PER_BIT - 1 && bit_index == 7)
                    next_state = STOP;
            end
            STOP: begin
                if (clk_count == CLK_PER_BIT - 1)
                    next_state = IDLE;
            end
        endcase
    end

    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx <= 1; // Idle high
            tx_done <= 0;
            clk_count <= 0;
            bit_index <= 0;
            data_reg <= 0;
        end else begin
            tx_done <= 0;
            case (state)
                IDLE: begin
                    tx <= 1;
                    clk_count <= 0;
                    bit_index <= 0;
                    if (tx_start)
                        data_reg <= tx_data;
                end
                START: begin
                    tx <= 0; // Start bit
                    if (clk_count < CLK_PER_BIT - 1)
                        clk_count <= clk_count + 1;
                    else
                        clk_count <= 0;
                end
                DATA: begin
                    tx <= data_reg[bit_index];
                    if (clk_count < CLK_PER_BIT - 1)
                        clk_count <= clk_count + 1;
                    else begin
                        clk_count <= 0;
                        bit_index <= bit_index + 1;
                    end
                end
                STOP: begin
                    tx <= 1; // Stop bit
                    if (clk_count < CLK_PER_BIT - 1)
                        clk_count <= clk_count + 1;
                    else begin
                        clk_count <= 0;
                        tx_done <= 1;
                    end
                end
            endcase
        end
    end
endmodule

module uart_receiver (
    input wire clk,          // 100 MHz clock
    input wire rst_n,        // Active-low reset
    input wire rx,           // Serial input
    output reg [7:0] rx_data,// 8-bit received data
    output reg rx_done,      // Reception complete
    output reg rx_error      // Framing error
);
    parameter CLK_FREQ = 100_000_000; // 100 MHz
    parameter BAUD_RATE = 9600;
    parameter CLK_PER_BIT = CLK_FREQ / BAUD_RATE; // 10417 cycles
    parameter IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    reg [1:0] state, next_state;
    reg [13:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] data_reg;

    // FSM: State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // FSM: Next state and output logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (!rx) // Detect start bit
                    next_state = START;
            end
            START: begin
                if (clk_count == CLK_PER_BIT / 2 - 1)
                    next_state = (!rx) ? DATA : IDLE; // Verify start bit
            end
            DATA: begin
                if (clk_count == CLK_PER_BIT - 1 && bit_index == 7)
                    next_state = STOP;
            end
            STOP: begin
                if (clk_count == CLK_PER_BIT - 1)
                    next_state = IDLE;
            end
        endcase
    end

    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= 0;
            rx_done <= 0;
            rx_error <= 0;
            clk_count <= 0;
            bit_index <= 0;
            data_reg <= 0;
        end else begin
            rx_done <= 0;
            rx_error <= 0;
            case (state)
                IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;
                end
                START: begin
                    if (clk_count < CLK_PER_BIT / 2 - 1)
                        clk_count <= clk_count + 1;
                    else
                        clk_count <= 0;
                end
                DATA: begin
                    if (clk_count < CLK_PER_BIT - 1)
                        clk_count <= clk_count + 1;
                    else begin
                        clk_count <= 0;
                        data_reg[bit_index] <= rx;
                        bit_index <= bit_index + 1;
                    end
                end
                STOP: begin
                    if (clk_count < CLK_PER_BIT - 1)
                        clk_count <= clk_count + 1;
                    else begin
                        clk_count <= 0;
                        rx_data <= data_reg;
                        rx_done <= 1;
                        rx_error <= (rx != 1); // Check stop bit
                    end
                end
            endcase
        end
    end
endmodule

module uart_loopback (
    input wire clk,          // 100 MHz clock
    input wire rst_n,        // Active-low reset
    input wire start,        // Start transmission
    input wire [7:0] data_in,// 8-bit input data
    output wire [7:0] data_out, // 8-bit received data
    output wire tx_done,     // Transmission complete
    output wire rx_done,     // Reception complete
    output wire error        // Error flag (data mismatch or framing)
);
    wire tx_wire;
    wire rx_error;

    // Instantiate UART Transmitter
    uart_transmitter tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(start),
        .tx_data(data_in),
        .tx(tx_wire),
        .tx_done(tx_done)
    );

    // Instantiate UART Receiver
    uart_receiver rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rx(tx_wire),
        .rx_data(data_out),
        .rx_done(rx_done),
        .rx_error(rx_error)
    );

    // Error detection: data mismatch or framing error
    assign error = rx_done ? (data_in != data_out || rx_error) : 0;
endmodule

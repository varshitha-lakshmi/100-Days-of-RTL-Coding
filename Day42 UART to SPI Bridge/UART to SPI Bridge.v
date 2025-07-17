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
    parameter CLK_FREQ = 100_000_000;
    parameter SCLK_FREQ = 1_000_000;
    parameter CLK_PER_SCLK = CLK_FREQ / SCLK_FREQ / 2; // 50 clocks per SCLK half-period
    parameter IDLE = 2'd0, SETUP = 2'd1, TRANSFER = 2'd2, DONE = 2'd3;
    reg [1:0] state, next_state;
    reg [6:0] clk_counter;
    reg [3:0] bit_counter;
    reg [7:0] shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_counter <= 0;
            sclk <= 0;
        end else begin
            if (clk_counter == CLK_PER_SCLK - 1) begin
                clk_counter <= 0;
                if (state == TRANSFER)
                    sclk <= ~sclk;
            end else
                clk_counter <= clk_counter + 1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else if (clk_counter == CLK_PER_SCLK - 1 && sclk == 0)
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        cs = 1;
        mosi = 0;
        done = 0;
        case (state)
            IDLE: if (start) next_state = SETUP;
            SETUP: begin cs = 0; next_state = TRANSFER; end
            TRANSFER: begin
                cs = 0;
                mosi = shift_reg[7];
                if (bit_counter == 4'd7) next_state = DONE;
            end
            DONE: begin cs = 0; done = 1; next_state = IDLE; end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 8'b0;
            bit_counter <= 4'b0;
        end else if (clk_counter == CLK_PER_SCLK - 1 && sclk == 0) begin
            if (state == IDLE && start) begin
                shift_reg <= data_in;
                bit_counter <= 4'b0;
            end else if (state == TRANSFER) begin
                shift_reg <= {shift_reg[6:0], 1'b0};
                bit_counter <= bit_counter + 1;
            end
        end
    end
endmodule

module uart_to_spi_bridge (
    input wire clk,          // Input clock (100 MHz)
    input wire rst_n,        // Active-low reset
    input wire rx,           // UART receive line
    output wire sclk,        // SPI clock
    output wire mosi,        // SPI master out, slave in
    output wire cs_n,        // SPI chip select (active-low)
    output wire done         // Transfer complete
);
    // UART parameters
    parameter CLK_FREQ = 100_000_000; // 100 MHz
    parameter BAUD_RATE = 9600;
    parameter CLK_PER_BAUD = CLK_FREQ / BAUD_RATE; // ~10416 clocks per baud

    // SPI parameters
    parameter SCLK_FREQ = 1_000_000; // 1 MHz
    parameter CLK_PER_SCLK = CLK_FREQ / SCLK_FREQ / 2; // 50 clocks per SCLK half-period

    // Top-level FSM states
    parameter IDLE = 2'd0, RX_WAIT = 2'd1, SPI_START = 2'd2, SPI_WAIT = 2'd3;
    reg [1:0] state, next_state;

    // UART receiver signals
    reg [13:0] baud_counter;
    reg [3:0] bit_counter;
    reg [7:0] rx_data;
    reg rx_done;

    // SPI master signals
    reg spi_start;
    wire spi_done;
    reg [7:0] spi_data_in;

    // UART receiver logic
    reg rx_shift;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_counter <= 0;
            bit_counter <= 0;
            rx_data <= 8'b0;
            rx_done <= 0;
            rx_shift <= 0;
        end else begin
            if (state == RX_WAIT) begin
                if (baud_counter == CLK_PER_BAUD / 2 - 1) begin
                    baud_counter <= 0;
                    if (bit_counter == 0 && rx == 0) // Start bit
                        rx_shift <= 1;
                    else if (rx_shift) begin
                        if (bit_counter < 9) begin
                            rx_data <= {rx, rx_data[7:1]}; // Shift in data
                            bit_counter <= bit_counter + 1;
                        end
                        if (bit_counter == 8) // Data complete
                            rx_done <= 1;
                        if (bit_counter == 9) begin // Stop bit
                            rx_shift <= 0;
                            bit_counter <= 0;
                            rx_done <= 0;
                        end
                    end
                end else
                    baud_counter <= baud_counter + 1;
            end else begin
                baud_counter <= 0;
                bit_counter <= 0;
                rx_shift <= 0;
                rx_done <= 0;
            end
        end
    end

    // Instantiate SPI Master
    spi_master spi_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(spi_start),
        .data_in(spi_data_in),
        .sclk(sclk),
        .mosi(mosi),
        .cs(cs_n),
        .done(spi_done)
    );

    // Top-level FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        spi_start = 0;
        spi_data_in = 8'b0;
        case (state)
            IDLE: begin
                if (rx == 0) // Detect UART start bit
                    next_state = RX_WAIT;
            end
            RX_WAIT: begin
                if (rx_done) begin
                    spi_data_in = rx_data;
                    next_state = SPI_START;
                end
            end
            SPI_START: begin
                spi_start = 1;
                spi_data_in = rx_data;
                next_state = SPI_WAIT;
            end
            SPI_WAIT: begin
                if (spi_done)
                    next_state = IDLE;
            end
        endcase
    end

    assign done = (state == SPI_WAIT && spi_done);
endmodule

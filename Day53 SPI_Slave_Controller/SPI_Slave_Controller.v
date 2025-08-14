module spi_slave_controller (
    input wire clk,          // 100 MHz clock
    input wire rst_n,        // Active-low reset
    input wire sclk,         // SPI clock (1 MHz)
    input wire mosi,         // Master Out Slave In
    input wire ss_n,         // Slave Select (active-low)
    output reg miso,         // Master In Slave Out
    output reg [7:0] data_out, // Received data
    input wire [7:0] data_in,  // Data to send
    output reg done          // Transaction complete
);
    parameter IDLE = 2'd0, TRANSFER = 2'd1, COMPLETE = 2'd2;
    reg [1:0] state, next_state;
    reg [7:0] shift_reg_in, shift_reg_out;
    reg [3:0] bit_count;
    reg sclk_reg, mosi_reg, ss_n_reg; // Synchronize inputs

    // Synchronize SCLK, MOSI, and SS_N to avoid metastability
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_reg <= 0;
            mosi_reg <= 0;
            ss_n_reg <= 1;
        end else begin
            sclk_reg <= sclk;
            mosi_reg <= mosi;
            ss_n_reg <= ss_n;
        end
    end

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
                if (!ss_n_reg)
                    next_state = TRANSFER;
            end
            TRANSFER: begin
                if (bit_count == 8 && sclk_reg && !sclk)
                    next_state = COMPLETE;
            end
            COMPLETE: begin
                if (ss_n_reg)
                    next_state = IDLE;
            end
        endcase
    end

    // Sequential logic for data transfer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_in <= 0;
            shift_reg_out <= 0;
            bit_count <= 0;
            miso <= 0;
            data_out <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    bit_count <= 0;
                    done <= 0;
                    shift_reg_out <= data_in; // Load data to send
                end
                TRANSFER: begin
                    if (!sclk_reg && sclk) begin // Sample on SCLK rising edge (Mode 0)
                        shift_reg_in <= {shift_reg_in[6:0], mosi_reg};
                        bit_count <= bit_count + 1;
                    end else if (sclk_reg && !sclk) begin // Shift on SCLK falling edge
                        miso <= shift_reg_out[7];
                        shift_reg_out <= {shift_reg_out[6:0], 1'b0};
                    end
                end
                COMPLETE: begin
                    data_out <= shift_reg_in;
                    done <= 1;
                end
            endcase
        end
    end
endmodule

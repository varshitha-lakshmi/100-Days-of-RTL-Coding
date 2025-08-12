module i2c_slave_controller (
    input wire clk,          // 100 MHz clock
    input wire rst_n,        // Active-low reset
    inout wire sda,          // I2C data line (bidirectional)
    input wire scl,          // I2C clock line
    output reg [7:0] data_out, // Data read from slave
    input wire [7:0] data_in,  // Data to write to slave
    output reg done,          // Transaction complete
    output reg ack            // ACK/NACK status (0=ACK, 1=NACK)
);
    parameter SLAVE_ADDR = 7'h50; // Slave address
    parameter CLK_FREQ = 100_000_000; // 100 MHz
    parameter I2C_FREQ = 100_000; // 100 kHz
    parameter CLK_PER_I2C = CLK_FREQ / I2C_FREQ; // 1000 cycles
    parameter IDLE = 3'd0, ADDR = 3'd1, ACK1 = 3'd2, DATA = 3'd3, ACK2 = 3'd4, STOP = 3'd5;

    reg [2:0] state, next_state;
    reg [6:0] addr_reg;
    reg [7:0] data_reg;
    reg [3:0] bit_count;
    reg sda_out, sda_oe; // SDA output and output enable
    reg sda_reg, scl_reg; // Synchronize SDA and SCL
    reg start_detected, stop_detected;
    reg rw; // Read (1) or Write (0)

    // Synchronize SDA and SCL to avoid metastability
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_reg <= 1;
            scl_reg <= 1;
        end else begin
            sda_reg <= sda;
            scl_reg <= scl;
        end
    end

    // Detect start (SDA falls while SCL high) and stop (SDA rises while SCL high)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_detected <= 0;
            stop_detected <= 0;
        end else begin
            start_detected <= scl_reg && sda_reg && !sda;
            stop_detected <= scl_reg && !sda_reg && sda;
        end
    end

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
                if (start_detected)
                    next_state = ADDR;
            end
            ADDR: begin
                if (bit_count == 7 && scl_reg && !scl)
                    next_state = ACK1;
            end
            ACK1: begin
                if (scl_reg && !scl)
                    next_state = DATA;
            end
            DATA: begin
                if (bit_count == 8 && scl_reg && !scl)
                    next_state = ACK2;
            end
            ACK2: begin
                if (scl_reg && !scl)
                    next_state = stop_detected ? STOP : IDLE;
            end
            STOP: begin
                next_state = IDLE;
            end
        endcase
    end

    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_reg <= 0;
            data_reg <= 0;
            bit_count <= 0;
            sda_out <= 1;
            sda_oe <= 0;
            data_out <= 0;
            done <= 0;
            ack <= 1;
            rw <= 0;
        end else begin
            done <= 0;
            case (state)
                IDLE: begin
                    bit_count <= 0;
                    sda_oe <= 0;
                    sda_out <= 1;
                    ack <= 1;
                end
                ADDR: begin
                    if (!scl_reg && scl) begin // Sample on SCL rising edge
                        addr_reg[6-bit_count] <= sda_reg;
                        bit_count <= bit_count + 1;
                    end
                end
                ACK1: begin
                    if (!scl_reg && scl) begin
                        sda_oe <= 1;
                        sda_out <= (addr_reg == SLAVE_ADDR) ? 0 : 1; // ACK if address matches
                        ack <= (addr_reg != SLAVE_ADDR); // NACK if no match
                        rw <= sda_reg; // Capture R/W bit
                    end
                end
                DATA: begin
                    if (!scl_reg && scl) begin
                        if (rw) begin // Read: slave sends data
                            sda_oe <= 1;
                            sda_out <= data_in[7-bit_count];
                        end else begin // Write: slave receives data
                            data_reg[7-bit_count] <= sda_reg;
                        end
                        bit_count <= bit_count + 1;
                    end
                end
                ACK2: begin
                    if (!scl_reg && scl) begin
                        if (rw) begin
                            sda_oe <= 0; // Master sends ACK
                        end else begin
                            sda_oe <= 1;
                            sda_out <= 0; // Slave ACKs received data
                            data_out <= data_reg;
                            done <= 1;
                        end
                    end
                end
                STOP: begin
                    done <= 1;
                    sda_oe <= 0;
                    sda_out <= 1;
                end
            endcase
        end
    end

    // SDA tristate buffer
    assign sda = sda_oe ? sda_out : 1'bz;
endmodule

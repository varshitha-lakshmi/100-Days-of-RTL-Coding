module wishbone_master (
    input wire clk,          // Input clock (100 MHz)
    input wire rst_n,        // Active-low reset
    input wire start,        // Start transaction
    input wire we_i,         // Write enable (1=write, 0=read)
    input wire [3:0] addr_i, // 4-bit address input
    input wire [7:0] data_i, // 8-bit data input (for write)
    output reg [3:0] adr_o,  // Wishbone address output
    output reg [7:0] dat_o,  // Wishbone data output
    input wire [7:0] dat_i,  // Wishbone data input
    output reg we_o,         // Wishbone write enable
    output reg cyc_o,        // Wishbone cycle signal
    output reg stb_o,        // Wishbone strobe signal
    input wire ack_i,        // Wishbone acknowledge input
    output reg [7:0] data_o, // Data output (for read)
    output reg done          // Transaction complete
);
    // FSM states
    parameter IDLE = 2'd0, SETUP = 2'd1, WAIT_ACK = 2'd2, DONE = 2'd3;
    reg [1:0] state, next_state;

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
        adr_o = 4'b0;
        dat_o = 8'b0;
        we_o = 0;
        cyc_o = 0;
        stb_o = 0;
        data_o = 8'b0;
        done = 0;
        case (state)
            IDLE: begin
                if (start)
                    next_state = SETUP;
            end
            SETUP: begin
                adr_o = addr_i;
                dat_o = data_i;
                we_o = we_i;
                cyc_o = 1;
                stb_o = 1;
                next_state = WAIT_ACK;
            end
            WAIT_ACK: begin
                adr_o = addr_i;
                dat_o = data_i;
                we_o = we_i;
                cyc_o = 1;
                stb_o = 1;
                if (ack_i) begin
                    data_o = (we_i) ? 8'b0 : dat_i; // Capture read data
                    next_state = DONE;
                end
            end
            DONE: begin
                done = 1;
                next_state = IDLE;
            end
        endcase
    end
endmodule

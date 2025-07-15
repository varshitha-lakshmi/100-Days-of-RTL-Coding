module memory_controller (
    input wire clk,          // Input clock (100 MHz)
    input wire rst_n,        // Active-low reset
    input wire start,        // Start transaction signal
    input wire rw,           // Read (1) or Write (0)
    input wire [3:0] addr,   // 4-bit address (16 locations)
    input wire [7:0] data_in,// 8-bit data input
    output reg [7:0] data_out,// 8-bit data output
    output reg ce_n,         // Chip enable (active-low)
    output reg we_n,         // Write enable (active-low)
    output reg oe_n,         // Output enable (active-low)
    output reg done          // Transaction complete signal
);
    // States
    parameter IDLE = 2'd0, SETUP = 2'd1, ACCESS = 2'd2, DONE = 2'd3;
    reg [1:0] state, next_state;
    reg [7:0] mem [0:15];    // 16x8 SRAM model for simulation

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
        ce_n = 1; // Inactive by default
        we_n = 1;
        oe_n = 1;
        done = 0;
        case (state)
            IDLE: begin
                if (start)
                    next_state = SETUP;
            end
            SETUP: begin
                ce_n = 0; // Enable chip
                next_state = ACCESS;
            end
            ACCESS: begin
                ce_n = 0;
                if (rw) begin // Read operation
                    oe_n = 0;
                    data_out = mem[addr];
                end else begin // Write operation
                    we_n = 0;
                    mem[addr] = data_in;
                end
                next_state = DONE;
            end
            DONE: begin
                ce_n = 0;
                done = 1;
                next_state = IDLE;
            end
        endcase
    end
endmodule

module axi_lite_master (
    input wire clk,          // Input clock (100 MHz)
    input wire rst_n,        // Active-low reset
    input wire start,        // Start transaction
    input wire we_i,         // Write enable (1=write, 0=read)
    input wire [31:0] addr_i,// 32-bit address input
    input wire [31:0] data_i,// 32-bit data input (for write)
    output reg [31:0] addr_o,// AXI-Lite address output (AW/AR)
    output reg [31:0] data_o,// AXI-Lite data output (W)
    output reg [3:0] wstrb_o,// Write strobe (byte enables)
    output reg awvalid_o,    // Address write valid
    input wire awready_i,    // Address write ready
    output reg wvalid_o,     // Write data valid
    input wire wready_i,     // Write data ready
    input wire [1:0] bresp_i,// Write response
    input wire bvalid_i,     // Write response valid
    output reg bready_o,     // Write response ready
    output reg arvalid_o,    // Address read valid
    input wire arready_i,    // Address read ready
    input wire [31:0] data_i_r, // AXI-Lite data input (R)
    input wire [1:0] rresp_i,// Read response
    input wire rvalid_i,     // Read data valid
    output reg rready_o,     // Read data ready
    output reg [31:0] data_o_r, // Data output (for read)
    output reg error,        // Error flag (non-zero response)
    output reg done          // Transaction complete
);
    // FSM states
    parameter IDLE = 3'd0, AW = 3'd1, W = 3'd2, B = 3'd3, AR = 3'd4, R = 3'd5;
    reg [2:0] state, next_state;

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
        addr_o = 32'h0;
        data_o = 32'h0;
        wstrb_o = 4'h0;
        awvalid_o = 0;
        wvalid_o = 0;
        bready_o = 0;
        arvalid_o = 0;
        rready_o = 0;
        data_o_r = 32'h0;
        error = 0;
        done = 0;
        case (state)
            IDLE: begin
                if (start)
                    next_state = we_i ? AW : AR;
            end
            AW: begin
                addr_o = addr_i;
                awvalid_o = 1;
                if (awready_i)
                    next_state = W;
            end
            W: begin
                data_o = data_i;
                wstrb_o = 4'hF; // All bytes enabled
                wvalid_o = 1;
                if (wready_i)
                    next_state = B;
            end
            B: begin
                bready_o = 1;
                if (bvalid_i) begin
                    error = (bresp_i != 2'b00); // Non-OKAY response
                    done = 1;
                    next_state = IDLE;
                end
            end
            AR: begin
                addr_o = addr_i;
                arvalid_o = 1;
                if (arready_i)
                    next_state = R;
            end
            R: begin
                rready_o = 1;
                if (rvalid_i) begin
                    data_o_r = data_i_r;
                    error = (rresp_i != 2'b00); // Non-OKAY response
                    done = 1;
                    next_state = IDLE;
                end
            end
        endcase
    end
endmodule

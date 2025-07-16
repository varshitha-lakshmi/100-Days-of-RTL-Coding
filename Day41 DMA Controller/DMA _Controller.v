module dma_controller (

    input wire clk,          // Input clock (100 MHz)

    input wire rst_n,        // Active-low reset

    input wire start,        // Start DMA transfer

    input wire [3:0] src_addr, // Source address (4-bit)

    input wire [3:0] dst_addr, // Destination address (4-bit)

    output reg [3:0] mem_addr, // Memory address

    output reg [7:0] mem_data_in, // Data to memory

    output reg mem_we_n,     // Write enable (active-low)

    output reg mem_ce_n,     // Chip enable (active-low)

    input wire [7:0] mem_data_out, // Data from memory

    output reg done          // Transfer complete

);

    // States

    parameter IDLE = 2'd0, READ = 2'd1, WRITE = 2'd2, DONE = 2'd3;

    reg [1:0] state, next_state;

    reg [7:0] data_buffer;   // Temporary data storage



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

        mem_addr = 4'b0;

        mem_data_in = 8'b0;

        mem_we_n = 1;

        mem_ce_n = 1;

        done = 0;

        case (state)

            IDLE: begin

                if (start)

                    next_state = READ;

            end

            READ: begin

                mem_addr = src_addr;

                mem_ce_n = 0;

                data_buffer = mem_data_out;

                next_state = WRITE;

            end

            WRITE: begin

                mem_addr = dst_addr;

                mem_data_in = data_buffer;

                mem_ce_n = 0;

                mem_we_n = 0;

                next_state = DONE;

            end

            DONE: begin

                done = 1;

                next_state = IDLE;

            end

        endcase

    end

endmodule


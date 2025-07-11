module fifo_4x8 (
    input wire clk,          // Input clock
    input wire rst_n,        // Active-low reset
    input wire wr_en,        // Write enable
    input wire rd_en,        // Read enable
    input wire [7:0] data_in,// 8-bit data input
    output reg [7:0] data_out,// 8-bit data output
    output wire full,        // FIFO full flag
    output wire empty        // FIFO empty flag
);
    reg [7:0] mem [0:3];     // 4x8 memory array (4 words, 8-bit data)
    reg [2:0] wr_ptr;        // 3-bit write pointer (0 to 3)
    reg [2:0] rd_ptr;        // 3-bit read pointer (0 to 3)
    reg [2:0] count;         // Number of stored words

    // Full and empty flags
    assign full = (count == 3'd4);
    assign empty = (count == 3'd0);

    // Write and read logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 3'b0;
            rd_ptr <= 3'b0;
            count <= 3'b0;
            data_out <= 8'b0;
        end else begin
            // Write operation
            if (wr_en && !full) begin
                mem[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end
            // Read operation
            if (rd_en && !empty) begin
                data_out <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
            end
        end
    end
endmodule

module barrel_shifter_dynamic (
    input wire clk,          // Input clock (100 MHz)
    input wire rst_n,        // Active-low reset
    input wire valid_in,     // Input valid signal
    input wire [31:0] data_in, // 32-bit input data
    input wire [4:0] shift_amt, // 5-bit shift amount
    input wire direction,    // Shift direction (0=left, 1=right)
    output reg [31:0] data_out, // 32-bit output data
    output reg valid_out     // Output valid signal
);
    // Combinational shift result
    reg [31:0] shift_result;

    // Combinational barrel shifter logic
    always @(*) begin
        if (direction) begin // Right shift
            case (shift_amt)
                5'd0:  shift_result = data_in;
                5'd1:  shift_result = {1'b0, data_in[31:1]};
                5'd2:  shift_result = {2'b0, data_in[31:2]};
                5'd3:  shift_result = {3'b0, data_in[31:3]};
                5'd4:  shift_result = {4'b0, data_in[31:4]};
                5'd5:  shift_result = {5'b0, data_in[31:5]};
                5'd6:  shift_result = {6'b0, data_in[31:6]};
                5'd7:  shift_result = {7'b0, data_in[31:7]};
                5'd8:  shift_result = {8'b0, data_in[31:8]};
                5'd9:  shift_result = {9'b0, data_in[31:9]};
                5'd10: shift_result = {10'b0, data_in[31:10]};
                5'd11: shift_result = {11'b0, data_in[31:11]};
                5'd12: shift_result = {12'b0, data_in[31:12]};
                5'd13: shift_result = {13'b0, data_in[31:13]};
                5'd14: shift_result = {14'b0, data_in[31:14]};
                5'd15: shift_result = {15'b0, data_in[31:15]};
                5'd16: shift_result = {16'b0, data_in[31:16]};
                5'd17: shift_result = {17'b0, data_in[31:17]};
                5'd18: shift_result = {18'b0, data_in[31:18]};
                5'd19: shift_result = {19'b0, data_in[31:19]};
                5'd20: shift_result = {20'b0, data_in[31:20]};
                5'd21: shift_result = {21'b0, data_in[31:21]};
                5'd22: shift_result = {22'b0, data_in[31:22]};
                5'd23: shift_result = {23'b0, data_in[31:23]};
                5'd24: shift_result = {24'b0, data_in[31:24]};
                5'd25: shift_result = {25'b0, data_in[31:25]};
                5'd26: shift_result = {26'b0, data_in[31:26]};
                5'd27: shift_result = {27'b0, data_in[31:27]};
                5'd28: shift_result = {28'b0, data_in[31:28]};
                5'd29: shift_result = {29'b0, data_in[31:29]};
                5'd30: shift_result = {30'b0, data_in[31:30]};
                5'd31: shift_result = {31'b0, data_in[31]};
                default: shift_result = data_in;
            endcase
        end else begin // Left shift
            case (shift_amt)
                5'd0:  shift_result = data_in;
                5'd1:  shift_result = {data_in[30:0], 1'b0};
                5'd2:  shift_result = {data_in[29:0], 2'b0};
                5'd3:  shift_result = {data_in[28:0], 3'b0};
                5'd4:  shift_result = {data_in[27:0], 4'b0};
                5'd5:  shift_result = {data_in[26:0], 5'b0};
                5'd6:  shift_result = {data_in[25:0], 6'b0};
                5'd7:  shift_result = {data_in[24:0], 7'b0};
                5'd8:  shift_result = {data_in[23:0], 8'b0};
                5'd9:  shift_result = {data_in[22:0], 9'b0};
                5'd10: shift_result = {data_in[21:0], 10'b0};
                5'd11: shift_result = {data_in[20:0], 11'b0};
                5'd12: shift_result = {data_in[19:0], 12'b0};
                5'd13: shift_result = {data_in[18:0], 13'b0};
                5'd14: shift_result = {data_in[17:0], 14'b0};
                5'd15: shift_result = {data_in[16:0], 15'b0};
                5'd16: shift_result = {data_in[15:0], 16'b0};
                5'd17: shift_result = {data_in[14:0], 17'b0};
                5'd18: shift_result = {data_in[13:0], 18'b0};
                5'd19: shift_result = {data_in[12:0], 19'b0};
                5'd20: shift_result = {data_in[11:0], 20'b0};
                5'd21: shift_result = {data_in[10:0], 21'b0};
                5'd22: shift_result = {data_in[9:0], 22'b0};
                5'd23: shift_result = {data_in[8:0], 23'b0};
                5'd24: shift_result = {data_in[7:0], 24'b0};
                5'd25: shift_result = {data_in[6:0], 25'b0};
                5'd26: shift_result = {data_in[5:0], 26'b0};
                5'd27: shift_result = {data_in[4:0], 27'b0};
                5'd28: shift_result = {data_in[3:0], 28'b0};
                5'd29: shift_result = {data_in[2:0], 29'b0};
                5'd30: shift_result = {data_in[1:0], 30'b0};
                5'd31: shift_result = {data_in[0], 31'b0};
                default: shift_result = data_in;
            endcase
        end
    end

    // Sequential output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 32'h0;
            valid_out <= 0;
        end else if (valid_in) begin
            data_out <= shift_result;
            valid_out <= 1;
        end else begin
            valid_out <= 0;
        end
    end
endmodule

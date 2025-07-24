module simple_cpu_data_path (
    input wire clk,          // Input clock (100 MHz)
    input wire rst_n,        // Active-low reset
    output reg [7:0] result, // Result output
    output reg done          // Instruction execution complete
);
    // Instruction format: [3:2]=opcode, [1:0]=destination register
    // Opcode: 00=LOAD, 01=ADD
    parameter LOAD = 2'b00, ADD = 2'b01;
    parameter IDLE = 2'd0, FETCH = 2'd1, EXECUTE = 2'd2, WRITE_BACK = 2'd3;

    // Internal signals
    reg [3:0] pc; // 4-bit program counter (16 addresses)
    reg [7:0] inst_mem [0:15]; // 16x8-bit instruction memory
    reg [7:0] reg_file [0:3]; // 4x8-bit register file
    reg [7:0] inst; // Current instruction
    reg [1:0] opcode, dest_reg;
    reg [7:0] alu_out;
    reg [1:0] state, next_state;
    reg [7:0] op1, op2; // ALU operands

    // Initialize instruction memory (example program)
    initial begin
        inst_mem[0] = {LOAD, 2'd0}; // LOAD R0, mem[0]
        inst_mem[1] = {LOAD, 2'd1}; // LOAD R1, mem[1]
        inst_mem[2] = {ADD, 2'd2};  // ADD R2, R0, R1
        inst_mem[3] = {LOAD, 2'd3}; // LOAD R3, mem[3]
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
                if (pc < 4) // Run for 4 instructions
                    next_state = FETCH;
            end
            FETCH: begin
                next_state = EXECUTE;
            end
            EXECUTE: begin
                next_state = WRITE_BACK;
            end
            WRITE_BACK: begin
                next_state = IDLE;
            end
        endcase
    end

    // Sequential logic for data path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 0;
            result <= 0;
            done <= 0;
            reg_file[0] <= 0; reg_file[1] <= 0;
            reg_file[2] <= 0; reg_file[3] <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                end
                FETCH: begin
                    inst <= inst_mem[pc];
                    opcode <= inst_mem[pc][3:2];
                    dest_reg <= inst_mem[pc][1:0];
                    done <= 0;
                end
                EXECUTE: begin
                    case (opcode)
                        LOAD: begin
                            reg_file[dest_reg] <= pc + 8'd10; // Example: load PC+10
                        end
                        ADD: begin
                            op1 <= reg_file[0]; // R0 as operand 1
                            op2 <= reg_file[1]; // R1 as operand 2
                            alu_out <= reg_file[0] + reg_file[1];
                        end
                    endcase
                    done <= 0;
                end
                WRITE_BACK: begin
                    if (opcode == ADD)
                        reg_file[dest_reg] <= alu_out;
                    result <= reg_file[dest_reg];
                    pc <= pc + 1;
                    done <= 1;
                end
            endcase
        end
    end
endmodule

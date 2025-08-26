`timescale 1ns / 1ps
`include "/home/aedu46/AI_HW_Verilog/RV32I_Project/src/defines.sv"

module ControlUnit (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    output logic        regFileWe,
    output logic [ 3:0] aluControl,
    output logic        aluSrcMuxSel,
    output logic        busWe,
    output logic [ 2:0] RFWDSrcMuxSel,
    output logic        branch,
    output logic        jal,
    output logic        jalr,
    output logic [ 2:0] L_mode,
    output logic [ 2:0] S_mode,
    output logic        PC_En
);
    wire  [6:0] opcode = instrCode[6:0];
    wire  [3:0] operator = {instrCode[30], instrCode[14:12]};
    logic [9:0] signals;
    assign {PC_En, regFileWe, aluSrcMuxSel, busWe, RFWDSrcMuxSel, branch, jal, jalr} = signals;
    assign L_mode = operator[2:0];
    assign S_mode = operator[2:0];

    /********************** Multi-Cycle **********************/
    typedef enum {
        FETCH,
        DECODE,
        R_EXECUTE,
        I_EXECUTE,
        B_EXECUTE,
        LU_EXECUTE,
        AU_EXECUTE,
        J_EXECUTE,
        JL_EXECUTE,
        S_EXECUTE,
        S_MEM_ACCESS,
        L_EXECUTE,
        L_MEM_ACCESS,
        L_WB
    } state_e;

    state_e state, next_state;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= FETCH;
        end else begin
            state <= next_state;
        end
    end

    //Next State
    always_comb begin
        next_state = FETCH;
        case (state)
            FETCH: next_state = DECODE;
            DECODE: begin
                case (opcode)
                    `OP_TYPE_R:  next_state = R_EXECUTE;
                    `OP_TYPE_I:  next_state = I_EXECUTE;
                    `OP_TYPE_B:  next_state = B_EXECUTE;
                    `OP_TYPE_LU: next_state = LU_EXECUTE;
                    `OP_TYPE_AU: next_state = AU_EXECUTE;
                    `OP_TYPE_J:  next_state = J_EXECUTE;
                    `OP_TYPE_JL: next_state = JL_EXECUTE;
                    `OP_TYPE_S:  next_state = S_EXECUTE;
                    `OP_TYPE_L:  next_state = L_EXECUTE;
                endcase
            end
            R_EXECUTE: next_state = FETCH;
            I_EXECUTE: next_state = FETCH;
            B_EXECUTE: next_state = FETCH;
            LU_EXECUTE: next_state = FETCH;
            AU_EXECUTE: next_state = FETCH;
            J_EXECUTE: next_state = FETCH;
            JL_EXECUTE: next_state = FETCH;
            S_EXECUTE: next_state = S_MEM_ACCESS;
            S_MEM_ACCESS: next_state = FETCH;
            L_EXECUTE: next_state = L_MEM_ACCESS;
            L_MEM_ACCESS: next_state = L_WB;
            L_WB: next_state = FETCH;
        endcase
    end

    //Control Signal
    //{PC_En, regFileWe, aluSrcMuxSel, busWe, RFWDSrcMuxSel, branch, jal, jalr} = signals;
    always_comb begin
        signals = 10'b0;
        case (state)
            FETCH:        signals = 10'b1_0_0_0_000_0_0_0;
            DECODE:       signals = 10'b0_0_0_0_000_0_0_0;
            R_EXECUTE:    signals = 10'b0_1_0_0_000_0_0_0;
            I_EXECUTE:    signals = 10'b0_1_1_0_000_0_0_0;
            B_EXECUTE:    signals = 10'b0_0_0_0_000_1_0_0;
            LU_EXECUTE:   signals = 10'b0_1_0_0_010_0_0_0;
            AU_EXECUTE:   signals = 10'b0_1_0_0_011_0_0_0;
            J_EXECUTE:    signals = 10'b0_1_0_0_100_0_1_0;
            JL_EXECUTE:   signals = 10'b0_1_0_0_100_0_1_1;
            S_EXECUTE:    signals = 10'b0_0_1_0_000_0_0_0;
            S_MEM_ACCESS: signals = 10'b0_0_1_1_000_0_0_0;
            L_EXECUTE:    signals = 10'b0_0_1_0_001_0_0_0;
            L_MEM_ACCESS: signals = 10'b0_0_1_0_001_0_0_0;
            L_WB:         signals = 10'b0_1_1_0_001_0_0_0;
        endcase
    end

    //ALU_Control
    always_comb begin
        aluControl = `ADD;
        case (state)
            R_EXECUTE:    aluControl = operator;
            I_EXECUTE:    begin
                if (operator == 4'b1101) aluControl = operator;
                else aluControl = {1'b0, operator[2:0]};
            end
            B_EXECUTE:    aluControl = operator;
        endcase
    end

    /********************** Single-Cycle **********************/
    // always_comb begin
    //     signals = 9'b0;
    //     case (opcode)
    //         //{regFileWe, aluSrcMuxSel, busWe, RFWDSrcMuxSel, branch, jal, jalr} = signals;
    //         `OP_TYPE_R:  signals = 9'b1_0_0_000_0_0_0;
    //         `OP_TYPE_S:  signals = 9'b0_1_1_000_0_0_0;
    //         `OP_TYPE_L:  signals = 9'b1_1_0_001_0_0_0;
    //         `OP_TYPE_I:  signals = 9'b1_1_0_000_0_0_0;
    //         `OP_TYPE_B:  signals = 9'b0_0_0_000_1_0_0;
    //         `OP_TYPE_LU: signals = 9'b1_0_0_010_0_0_0;
    //         `OP_TYPE_AU: signals = 9'b1_0_0_011_0_0_0;
    //         `OP_TYPE_J:  signals = 9'b1_0_0_100_0_1_0;
    //         `OP_TYPE_JL: signals = 9'b1_0_0_100_0_1_1;
    //     endcase
    // end

    // always_comb begin
    //     aluControl = `ADD;
    //     case (opcode)
    //         `OP_TYPE_R: aluControl = operator;
    //         `OP_TYPE_B: aluControl = operator;
    //         `OP_TYPE_I: begin
    //             if (operator == 4'b1101) aluControl = operator;
    //             else aluControl = {1'b0, operator[2:0]};
    //         end
    //     endcase
    // end
endmodule

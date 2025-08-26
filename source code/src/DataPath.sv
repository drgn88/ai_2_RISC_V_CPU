`timescale 1ns / 1ps
`include "/home/aedu46/AI_HW_Verilog/RV32I_Project/src/defines.sv"

module DataPath (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    output logic [31:0] instrMemAddr,
    input  logic        regFileWe,
    input  logic [ 3:0] aluControl,
    input  logic        aluSrcMuxSel,
    output logic [31:0] busAddr,
    output logic [31:0] busWData,
    input  logic [31:0] busRData,
    input  logic [ 2:0] RFWDSrcMuxSel,
    input  logic        branch,
    input  logic        jal,
    input  logic        jalr,
    input  logic [ 2:0] L_mode,
    input  logic [ 2:0] S_mode,
    input  logic        PC_En
);

    logic [31:0] aluResult, RFData1, RFData2;
    logic [31:0] PCSrcData, PCOutData;
    logic [31:0] aluSrcMuxOut, immExt, RFWDSrcMuxOut, PC_Imm_AdderSrcMuxOut;
    logic [31:0] PC_4_AdderResult, PC_Imm_AdderResult, PCSrcMuxOut;
    logic PCSrcMuxSel;
    logic btaken;

    logic [31:0] load_value;
    logic [31:0] store_value;

    //Decode Register
    logic [31:0] REG_RFData1, REG_RFData2, REG_immExt;

    //Execute Register
    logic [31:0] REG_aluResult, REG_Store_Value, REG_PCSrcMuxOut;
    logic [31:0] REG_busRData;

    //Memory Access Reigster

    assign instrMemAddr = PCOutData;
    // assign busAddr = REG_aluResult;
    assign busAddr = aluResult;
    assign busWData = REG_Store_Value;

    // RegisterFile U_RegFile (
    //     .clk(clk),
    //     .we (regFileWe),
    //     .RA1(instrCode[19:15]),
    //     .RA2(instrCode[24:20]),
    //     .WA (instrCode[11:7]),
    //     .WD (RFWDSrcMuxOut),
    //     .RD1(RFData1),
    //     .RD2(RFData2)
    // );

    /************ Verdi Simulation ************/

    RegisterFile U_RegFile (
        .clk(clk),
        .test_reset(reset),
        .we (regFileWe),
        .RA1(instrCode[19:15]),
        .RA2(instrCode[24:20]),
        .WA (instrCode[11:7]),
        .WD (RFWDSrcMuxOut),
        .RD1(RFData1),
        .RD2(RFData2)
    );

    register U_REG_RFData1 (
        .clk(clk),
        .reset(reset),
        .d(RFData1),
        .q(REG_RFData1)
    );

    register U_REG_RFData2 (
        .clk(clk),
        .reset(reset),
        .d(RFData2),
        .q(REG_RFData2)
    );

    mux_2x1 U_AluSrcMux (
        .sel(aluSrcMuxSel),
        .x0 (REG_RFData2),
        .x1 (REG_immExt),
        .y  (aluSrcMuxOut)
    );

    mux_5x1 U_RFWDSrcMux (
        .sel(RFWDSrcMuxSel),
        .x0 (aluResult),
        .x1 (load_value),
        .x2 (REG_immExt),
        .x3 (PC_Imm_AdderResult),
        .x4 (PC_4_AdderResult),
        .y  (RFWDSrcMuxOut)
    );

    alu U_ALU (
        .aluControl(aluControl),
        .a         (REG_RFData1),
        .b         (aluSrcMuxOut),
        .result    (aluResult),
        .btaken    (btaken)
    );

    // register U_REG_aluResult (
    //     .clk(clk),
    //     .reset(reset),
    //     .d(aluResult),
    //     .q(REG_aluResult)
    // );

    immExtend U_ImmExtend (
        .instrCode(instrCode),
        .immExt   (immExt)
    );

    register U_REG_ImmExtend (
        .clk(clk),
        .reset(reset),
        .d(immExt),
        .q(REG_immExt)
    );

    mux_2x1 U_PC_Imm_AdderSrcMux (
        .sel(jalr),
        .x0 (PCOutData),
        .x1 (REG_RFData1),
        .y  (PC_Imm_AdderSrcMuxOut)
    );

    adder U_PC_Imm_Adder (
        .a(REG_immExt),
        .b(PC_Imm_AdderSrcMuxOut),
        .y(PC_Imm_AdderResult)
    );

    adder U_PC_4_Adder (
        .a(32'd4),
        .b(PCOutData),
        .y(PC_4_AdderResult)
    );

    assign PCSrcMuxSel = jal | (btaken & branch);

    mux_2x1 U_PCSrcMux (
        .sel(PCSrcMuxSel),
        .x0 (PC_4_AdderResult),
        .x1 (PC_Imm_AdderResult),
        .y  (PCSrcMuxOut)
    );

    register U_REG_PCSrcMux (
        .clk(clk),
        .reset(reset),
        .d(PCSrcMuxOut),
        .q(REG_PCSrcMuxOut)
    );


    register_en U_PC (
        .clk  (clk),
        .reset(reset),
        .en   (PC_En),
        .d    (REG_PCSrcMuxOut),
        .q    (PCOutData)
    );

    register U_REG_busRData (
        .clk(clk),
        .reset(reset),
        .d(busRData),
        .q(REG_busRData)
    );

    Load_Value_Decision U_Load_Value_Decision (
        .L_mode(L_mode),
        .addr(aluResult),
        .ram_read_data(REG_busRData),

        .load_value(load_value)
    );

    Store_Value_Decision U_Store_Value_Decision (
        .S_mode(S_mode),
        .addr(aluResult),
        .ram_read_data(busRData),
        .reg_file_data(REG_RFData2),

        .store_value(store_value)
    );

    register U_REG_Store_Value (
        .clk(clk),
        .reset(reset),
        .d(store_value),
        .q(REG_Store_Value)
    );

endmodule

module alu (
    input  logic [ 3:0] aluControl,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result,
    output logic        btaken
);

    always_comb begin
        result = 32'bx;
        case (aluControl)
            `ADD:  result = a + b;
            `SUB:  result = a - b;
            `SLL:  result = a << b;
            `SRL:  result = a >> b;
            `SRA:  result = $signed(a) >>> b;
            `SLT:  result = ($signed(a) < $signed(b)) ? 1 : 0;
            `SLTU: result = (a < b) ? 1 : 0;
            `XOR:  result = a ^ b;
            `OR:   result = a | b;
            `AND:  result = a & b;
        endcase
    end

    always_comb begin : branch
        btaken = 1'b0;
        case (aluControl[2:0])
            `BEQ:  btaken = (a == b);
            `BNE:  btaken = (a != b);
            `BLT:  btaken = ($signed(a) < $signed(b));
            `BGE:  btaken = ($signed(a) >= $signed(b));
            `BLTU: btaken = (a < b);
            `BGEU: btaken = (a >= b);
        endcase
    end
endmodule

module RegisterFile (
    input  logic        clk,
    input  logic        test_reset,     // 동시 Memory접근 불가에 의해 리셋을 테스트용으로 줌
    input  logic        we,
    input  logic [ 4:0] RA1,
    input  logic [ 4:0] RA2,
    input  logic [ 4:0] WA,
    input  logic [31:0] WD,
    output logic [31:0] RD1,
    output logic [31:0] RD2
);
    logic [31:0] mem[0:2**5-1];

    // initial begin  // for simulation test
    //     for (int i = 0; i < 32; i++) begin
    //         mem[i] = 10 + i;
    //     end
    //     mem[31] = 32'h3322_11ff;
    //     mem[1]  = 32'h0000_0004;
    //     mem[2]  = 32'h0000_0008;
    // end

    always_ff @(posedge clk) begin
        if (we) mem[WA] <= WD;
    end

    /************ Verdi Simulation ************/

    // always_ff @(posedge clk) begin
    //     if(test_reset) begin
    //         for (int i = 0; i < 32; i++) begin
    //         mem[i] = 10 + i;
    //     end
    //     mem[31] = 32'h3322_11ff;
    //     mem[1]  = 32'h0000_0004;
    //     mem[2]  = 32'h0000_0008;
    //     // mem[1]  = 32'hFF00_0000;
    //     // mem[2]  = 32'h4;
    //     // mem[3]  = -16;
    //     end
    //     else if (we) mem[WA] <= WD;
    // end

    assign RD1 = (RA1 != 0) ? mem[RA1] : 32'b0;
    assign RD2 = (RA2 != 0) ? mem[RA2] : 32'b0;
endmodule

module register_en (
    input  logic        clk,
    input  logic        reset,
    input  logic        en,
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            q <= 0;
        end else begin
            if (en) q <= d;
        end
    end
endmodule

module register (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            q <= 0;
        end else begin
            q <= d;
        end
    end
endmodule

module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);
    assign y = a + b;
endmodule

module mux_2x1 (
    input  logic        sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    output logic [31:0] y
);
    always_comb begin
        y = 32'bx;
        case (sel)
            1'b0: y = x0;
            1'b1: y = x1;
        endcase
    end
endmodule

module mux_5x1 (
    input  logic [ 2:0] sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    input  logic [31:0] x2,
    input  logic [31:0] x3,
    input  logic [31:0] x4,
    output logic [31:0] y
);
    always_comb begin
        y = 32'bx;
        case (sel)
            3'b000: y = x0;
            3'b001: y = x1;
            3'b010: y = x2;
            3'b011: y = x3;
            3'b100: y = x4;
        endcase
    end
endmodule

module immExtend (
    input  logic [31:0] instrCode,
    output logic [31:0] immExt
);
    wire [6:0] opcode = instrCode[6:0];
    wire [2:0] func3 = instrCode[14:12];

    always_comb begin
        immExt = 32'bx;
        case (opcode)
            `OP_TYPE_R: immExt = 32'bx;  // R-Type
            `OP_TYPE_L: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            `OP_TYPE_S:
            immExt = {
                {20{instrCode[31]}}, instrCode[31:25], instrCode[11:7]
            };  // S-Type
            `OP_TYPE_I: begin
                case (func3)
                    3'b001:  immExt = {27'b0, instrCode[24:20]};  // SLLI
                    3'b101:  immExt = {27'b0, instrCode[24:20]};  // SRLI, SRAI
                    3'b011:  immExt = {20'b0, instrCode[31:20]};  // SLTIU
                    default: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
                endcase
            end
            `OP_TYPE_B:
            immExt = {
                {20{instrCode[31]}},
                instrCode[7],
                instrCode[30:25],
                instrCode[11:8],
                1'b0
            };
            `OP_TYPE_LU:
            immExt = {
                instrCode[31:12], 12'b0
            };  //이거 자체가 shift해준거임
            `OP_TYPE_AU:
            immExt = {
                instrCode[31:12], 12'b0
            };  //이거 자체가 shift해준거임
            `OP_TYPE_J:
            immExt = {
                {12{instrCode[31]}},
                instrCode[19:12],
                instrCode[20],
                instrCode[30:21],
                1'b0
            };
            `OP_TYPE_JL: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
        endcase
    end
endmodule

module Load_Value_Decision (
    input logic [ 2:0] L_mode,
    input logic [31:0] addr,
    input logic [31:0] ram_read_data,

    output logic [31:0] load_value
);

    always_comb begin
        load_value = 32'bz;
        case (L_mode)
            `LB: begin
                load_value = 32'bz;
                case (addr[1:0])
                    2'b00:
                    load_value = {{{24{ram_read_data[7]}}}, ram_read_data[7:0]};
                    2'b01:
                    load_value = {
                        {{24{ram_read_data[15]}}}, ram_read_data[15:8]
                    };
                    2'b10:
                    load_value = {
                        {{24{ram_read_data[23]}}}, ram_read_data[23:16]
                    };
                    2'b11:
                    load_value = {
                        {{24{ram_read_data[31]}}}, ram_read_data[31:24]
                    };
                endcase
            end
            `LH: begin
                load_value = 32'bz;
                case (addr[1])
                    1'b0:
                    load_value = {
                        {{16{ram_read_data[15]}}}, ram_read_data[15:0]
                    };
                    1'b1:
                    load_value = {
                        {{16{ram_read_data[31]}}}, ram_read_data[31:16]
                    };
                endcase
            end
            `LW: load_value = ram_read_data;
            `LBU: begin
                load_value = 32'bz;
                case (addr[1:0])
                    2'b00: load_value = {24'b0, ram_read_data[7:0]};
                    2'b01: load_value = {24'b0, ram_read_data[15:8]};
                    2'b10: load_value = {24'b0, ram_read_data[23:16]};
                    2'b11: load_value = {24'b0, ram_read_data[31:24]};
                endcase
            end
            `LHU: begin
                load_value = 32'bz;
                case (addr[1])
                    1'b0: load_value = {16'b0, ram_read_data[15:0]};
                    1'b1: load_value = {16'b0, ram_read_data[31:16]};
                endcase
            end
        endcase
    end

endmodule

module Store_Value_Decision (
    input logic [ 2:0] S_mode,
    input logic [31:0] addr,
    input logic [31:0] ram_read_data,
    input logic [31:0] reg_file_data,

    output logic [31:0] store_value
);

    always_comb begin
        store_value = 32'bz;
        case (S_mode)
            `SB: begin
                store_value = 32'bz;
                case (addr[1:0])
                    2'b00:
                    store_value = {ram_read_data[31:8], reg_file_data[7:0]};
                    2'b01:
                    store_value = {
                        ram_read_data[31:16],
                        reg_file_data[15:8],
                        ram_read_data[7:0]
                    };
                    2'b10:
                    store_value = {
                        ram_read_data[31:24],
                        reg_file_data[23:16],
                        ram_read_data[15:0]
                    };
                    2'b11:
                    store_value = {reg_file_data[31:24], ram_read_data[23:0]};
                endcase
            end
            `SH: begin
                store_value = 32'bz;
                case (addr[1])
                    1'b0:
                    store_value = {ram_read_data[31:16], reg_file_data[15:0]};
                    1'b1:
                    store_value = {reg_file_data[31:16], ram_read_data[15:0]};
                endcase
            end
            `SW: store_value = reg_file_data;
        endcase
    end

endmodule

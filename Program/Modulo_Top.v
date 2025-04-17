`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// program_counter.v
// -----------------------------------------------------------------------------
module program_counter (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] pc_in,
    output reg  [31:0] pc_out
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc_out <= 32'b0;
        else
            pc_out <= pc_in;
    end
endmodule

// -----------------------------------------------------------------------------
// adder1.v  (PC + 4)
// -----------------------------------------------------------------------------
module adder1 (
    input  wire [31:0] pc_out,
    output wire [31:0] adder1_out
);
    assign adder1_out = pc_out + 4;
endmodule

// -----------------------------------------------------------------------------
// instruction_memory.v
// -----------------------------------------------------------------------------
module instruction_memory (
    input  wire [31:0] address,
    output wire [31:0] instruction
);
    reg [31:0] RAM[63:0];
    integer    i;
    initial begin
        // 1) limpa toda a ROM com NOPs (32'b0 = sll $0,$0,0)
        for (i = 0; i < 64; i = i + 1)
            RAM[i] = 32'b0;
        // 2) carrega instruções reais
        RAM[0]  = 32'b001000_00000_01000_0000000000000000; // addi $t0,$zero,0
        RAM[1]  = 32'b001000_00000_01001_0000000000101000; // addi $t1,$zero,40
        RAM[2]  = 32'b101011_01000_01001_0000000000000000; // sw   $t1,0($t0)
        RAM[3]  = 32'b001000_00000_01001_0000000000010010; // addi $t1,$zero,18
        RAM[4]  = 32'b101011_01000_01001_0000000000000100; // sw   $t1,4($t0)
        RAM[5]  = 32'b100011_01000_10000_0000000000000000; // lw   $s0,0($t0)
        RAM[6]  = 32'b100011_01000_10001_0000000000000100; // lw   $s1,4($t0)
        RAM[7]  = 32'b000000_10000_10001_10010_00000_101010; // slt  $s2,$s0,$s1
        RAM[8]  = 32'b000100_10010_01000_0000000000000010; // beq  $s2,$t0,set_one
        RAM[9]  = 32'b001000_00000_01001_0000000000000001; // addi $t1,$zero,1
        RAM[10] = 32'b101011_01000_01001_0000000000001100; // sw   $t1,12($t0)
        RAM[11] = 32'b000010_00000_00000_0000000000001001; // j    end
        RAM[12] = 32'b001000_00000_01001_0000000000000000; // set_one: addi $t1,$zero,0
        RAM[13] = 32'b101011_01000_01001_0000000000001100; // sw   $t1,12($t0)
        RAM[14] = 32'b100011_01000_10011_0000000000001100; // end: lw $s3,12($t0)
    end

    // word‑addressing
    assign instruction = RAM[address >> 2];
endmodule

// -----------------------------------------------------------------------------
// main_decoder.v
// -----------------------------------------------------------------------------
module main_decoder(
    input  wire [5:0] op,
    output reg        regdst,
    output reg        alusrc,
    output reg        memtoreg,
    output reg        regwrite,
    output reg        memwrite,
    output reg        branch,
    output reg [1:0]  ALUop
);
    always @(*) begin
        // DEFAULTS
        regdst   = 0;
        alusrc   = 0;
        memtoreg = 0;
        regwrite = 0;
        memwrite = 0;
        branch   = 0;
        ALUop    = 2'b00;
        case (op)
          6'b000000: begin // R‑type
            regdst   = 1;
            regwrite = 1;
            ALUop    = 2'b10;
          end
          6'b100011: begin // lw
            alusrc   = 1;
            memtoreg = 1;
            regwrite = 1;
          end
          6'b101011: begin // sw
            alusrc   = 1;
            memwrite = 1;
          end
          6'b000100: begin // beq
            branch   = 1;
            ALUop    = 2'b01;
          end
          6'b001000: begin // addi
            alusrc   = 1;
            regwrite = 1;
            ALUop    = 2'b00;
          end
          default: begin
            // mantêm defaults
          end
        endcase
    end
endmodule

// -----------------------------------------------------------------------------
// ALU_decoder.v
// -----------------------------------------------------------------------------
module ALU_decoder(
    input  wire [1:0] ALUop,
    input  wire [5:0] funct,
    output reg  [2:0] ALU_control
);
    always @(*) begin
        // DEFAULT = ADD
        ALU_control = 3'b010;
        case (ALUop)
          2'b00: ALU_control = 3'b010; // lw/sw
          2'b01: ALU_control = 3'b110; // beq
          2'b10: begin                 // R‑type
            case (funct)
              6'b100000: ALU_control = 3'b010; // ADD
              6'b100010: ALU_control = 3'b110; // SUB
              6'b100100: ALU_control = 3'b000; // AND
              6'b100101: ALU_control = 3'b001; // OR
              6'b101010: ALU_control = 3'b111; // SLT
              default:   ALU_control = 3'b010; // NOP
            endcase
          end
        endcase
    end
endmodule

// -----------------------------------------------------------------------------
// mux1.v
// -----------------------------------------------------------------------------
module mux1 (
    input  wire [4:0] Rt,
    input  wire [4:0] Rd,
    input  wire       regdst,
    output wire [4:0] WriteReg
);
    assign WriteReg = regdst ? Rd : Rt;
endmodule

// -----------------------------------------------------------------------------
// register_file.v
// -----------------------------------------------------------------------------
module register_file (
    input  wire        clk,
    input  wire        regwrite,
    input  wire [4:0]  ReadReg1,
    input  wire [4:0]  ReadReg2,
    input  wire [4:0]  WriteReg,
    input  wire [31:0] WriteData,
    output wire [31:0] ReadData1,
    output wire [31:0] ReadData2
);
    reg [31:0] regs [0:31];
    integer    i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'b0;
    end
    assign ReadData1 = regs[ReadReg1];
    assign ReadData2 = regs[ReadReg2];

    always @(posedge clk) begin
        if (regwrite && WriteReg != 0)
            regs[WriteReg] <= WriteData;
    end
endmodule

// -----------------------------------------------------------------------------
// sign_extend.v
// -----------------------------------------------------------------------------
module sign_extend (
    input  wire [15:0] immediate,
    output wire [31:0] Extend32
);
    assign Extend32 = {{16{immediate[15]}}, immediate};
endmodule

// -----------------------------------------------------------------------------
// shift_left.v
// -----------------------------------------------------------------------------
module shift_left (
    input  wire [31:0] in,
    output wire [31:0] out
);
    assign out = in << 2;
endmodule

// -----------------------------------------------------------------------------
// adder2.v
// -----------------------------------------------------------------------------
module adder2 (
    input  wire [31:0] adder1_out,
    input  wire [31:0] ShiftOut,
    output wire [31:0] adder2_out
);
    assign adder2_out = adder1_out + ShiftOut;
endmodule

// -----------------------------------------------------------------------------
// mux2.v
// -----------------------------------------------------------------------------
module mux2 (
    input  wire [31:0] ReadData2,
    input  wire [31:0] Extend32,
    input  wire       alusrc,
    output wire [31:0] ALU_B
);
    assign ALU_B = alusrc ? Extend32 : ReadData2;
endmodule

// -----------------------------------------------------------------------------
// ALU.v
// -----------------------------------------------------------------------------
module ALU (
    input  wire [2:0]  ALU_Control,
    input  wire [31:0] A,
    input  wire [31:0] B,
    output reg  [31:0] ALU_result,
    output wire        zero
);
    always @(*) begin
        case (ALU_Control)
            3'b000: ALU_result = A & B;
            3'b001: ALU_result = A | B;
            3'b010: ALU_result = A + B;
            3'b110: ALU_result = A - B;
            3'b111: ALU_result = (A < B) ? 1 : 0;
            default: ALU_result = 0;
        endcase
    end
    assign zero = (ALU_result == 0);
endmodule

// -----------------------------------------------------------------------------
// And_Gate.v
// -----------------------------------------------------------------------------
module And_Gate (
    input  wire branch,
    input  wire zero,
    output wire AndGateOut
);
    assign AndGateOut = branch & zero;
endmodule

// -----------------------------------------------------------------------------
// mux4.v
// -----------------------------------------------------------------------------
module mux4 (
    input  wire [31:0] adder1_out,
    input  wire [31:0] adder2_out,
    input  wire       AndGateOut,
    output reg  [31:0] pc_in
);
    always @(*) begin
        if (AndGateOut === 1'b1)
            pc_in = adder2_out;
        else
            pc_in = adder1_out;
    end
endmodule

// -----------------------------------------------------------------------------
// data_memory.v  ← ALTERADO PARA usar RAM
// -----------------------------------------------------------------------------
module data_memory (
    input  wire        clk,
    input  wire        write_enable,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);
    // renomeado de 'mem' para 'RAM' para que testbench acesse dut.data_mem.RAM[…]
    reg [31:0] RAM [0:31];

    always @(posedge clk) begin
        if (write_enable)
            RAM[address[31:2]] <= write_data;
        read_data <= RAM[address[31:2]];
    end
endmodule

// -----------------------------------------------------------------------------
// mux3.v
// -----------------------------------------------------------------------------
module mux3 (
    input  wire [31:0] read_data,
    input  wire [31:0] ALU_result,
    input  wire       memtoreg,
    output wire [31:0] WriteData_reg
);
    assign WriteData_reg = memtoreg ? read_data : ALU_result;
endmodule

// -----------------------------------------------------------------------------
// mips_cpu.v
// -----------------------------------------------------------------------------
module mips_cpu (
    input  wire clock,
    input  wire reset
);
    wire [31:0] pc_in, pc_out, instruction;
    wire        regdst, alusrc, memtoreg, regwrite, memwrite, branch;
    wire [1:0]  ALUop;
    wire [4:0]  WriteReg;
    wire [31:0] read_data1, read_data2, Extend32, ALU_B, ShiftOut;
    wire [2:0]  ALU_control;
    wire        zero;
    wire [31:0] ALU_result, adder1_out, adder2_out, read_data, WriteData_reg;
    wire        AndGateOut;

    program_counter pc_inst    (.clk(clock),      .reset(reset),     .pc_in(pc_in),      .pc_out(pc_out));
    adder1          adder1_inst(.pc_out(pc_out), .adder1_out(adder1_out));
    instruction_memory inst_mem(.address(pc_out), .instruction(instruction));
    main_decoder    main_dec   (.op(instruction[31:26]),
                                .regdst(regdst), .alusrc(alusrc),
                                .memtoreg(memtoreg), .regwrite(regwrite),
                                .memwrite(memwrite), .branch(branch),
                                .ALUop(ALUop));
    register_file   regfile    (.clk(clock), .regwrite(regwrite),
                                .ReadReg1(instruction[25:21]),
                                .ReadReg2(instruction[20:16]),
                                .WriteReg(WriteReg),
                                .WriteData(WriteData_reg),
                                .ReadData1(read_data1),
                                .ReadData2(read_data2));
    sign_extend     sign_ext   (.immediate(instruction[15:0]), .Extend32(Extend32));
    shift_left      left_shift(.in(Extend32), .out(ShiftOut));
    adder2          adder2_inst(.adder1_out(adder1_out), .ShiftOut(ShiftOut), .adder2_out(adder2_out));
    ALU_decoder     alu_dec    (.ALUop(ALUop), .funct(instruction[5:0]), .ALU_control(ALU_control));
    mux2            mux2_inst  (.ReadData2(read_data2), .Extend32(Extend32), .alusrc(alusrc), .ALU_B(ALU_B));
    ALU             alu_inst   (.ALU_Control(ALU_control), .A(read_data1), .B(ALU_B), .ALU_result(ALU_result), .zero(zero));
    And_Gate        and_inst   (.branch(branch), .zero(zero), .AndGateOut(AndGateOut));
    mux4            mux4_inst  (.adder1_out(adder1_out), .adder2_out(adder2_out), .AndGateOut(AndGateOut), .pc_in(pc_in));
    data_memory     data_mem   (.clk(clock), .write_enable(memwrite), .address(ALU_result), .write_data(read_data2), .read_data(read_data));
    mux3            mux3_inst  (.read_data(read_data), .ALU_result(ALU_result), .memtoreg(memtoreg), .WriteData_reg(WriteData_reg));
    mux1            mux1_inst  (.Rt(instruction[20:16]), .Rd(instruction[15:11]), .regdst(regdst), .WriteReg(WriteReg));
endmodule

// -----------------------------------------------------------------------------
// top.v — para síntese/simulação no EDA Playground
// -----------------------------------------------------------------------------
module top (
    input  wire clock,
    input  wire reset
);
    mips_cpu u_mips_cpu (
        .clock(clock),
        .reset(reset)
    );
endmodule

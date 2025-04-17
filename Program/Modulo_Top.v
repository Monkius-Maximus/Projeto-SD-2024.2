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
    output reg  [31:0] instruction
);
    reg [31:0] mem [0:31];
    initial begin
        mem[0]  = 32'b00100000000010000000000000000000; // addi $t0,$zero,0
        mem[1]  = 32'b00100000000010010000000000101000; // addi $t1,$zero,40
        mem[2]  = 32'b10101101000010010000000000000000; // sw   $t1,0($t0)
        mem[3]  = 32'b00100000000010010000000000100110; // addi $t1,$zero,38
        mem[4]  = 32'b10101101000010010000000000000100; // sw   $t1,4($t0)
        mem[5]  = 32'b10001101000100000000000000000000; // lw   $s0,0($t0)
        mem[6]  = 32'b10001101000100010000000000000100; // lw   $s1,4($t0)
        mem[7]  = 32'b00000010000100011001000000101010; // slt  $s2,$s0,$s1
        mem[8]  = 32'b00010010010010000000000000000010; // beq  $s2,$t0,set_one
        mem[9]  = 32'b00100000000010010000000000000001; // addi $t1,$zero,1
        mem[10] = 32'b10101101000010010000000000001100; // sw   $t1,12($t0)
        mem[11] = 32'b00001000000000000000000000001001; // j    end
        mem[12] = 32'b00100000000010010000000000000000; // set_one: addi $t1,$zero,0
        mem[13] = 32'b10101101000010010000000000001100; // sw   $t1,12($t0)
        mem[14] = 32'b10001101000100110000000000001100; // end: lw $s3,12($t0)
    end
    always @(*) begin
        instruction = mem[address[31:2]];
    end
endmodule

// -----------------------------------------------------------------------------
// main_decoder.v
// -----------------------------------------------------------------------------
module main_decoder (
    input  wire [5:0] op,
    output reg        regdst,
    output reg        regwrite,
    output reg        alusrc,
    output reg        memtoreg,
    output reg        memwrite,
    output reg        branch,
    output reg [1:0]  ALUop
);
    always @(*) begin
        case (op)
            6'b000000: begin // R-type
                regdst   = 1; regwrite = 1; alusrc   = 0;
                memtoreg = 0; memwrite = 0; branch   = 0;
                ALUop    = 2'b10;
            end
            6'b100011: begin // lw
                regdst   = 0; regwrite = 1; alusrc   = 1;
                memtoreg = 1; memwrite = 0; branch   = 0;
                ALUop    = 2'b00;
            end
            6'b101011: begin // sw
                regdst   = 0; regwrite = 0; alusrc   = 1;
                memtoreg = 0; memwrite = 1; branch   = 0;
                ALUop    = 2'b00;
            end
            6'b000100: begin // beq
                regdst   = 0; regwrite = 0; alusrc   = 0;
                memtoreg = 0; memwrite = 0; branch   = 1;
                ALUop    = 2'b01;
            end
            6'b001000: begin // addi
                regdst   = 0; regwrite = 1; alusrc   = 1;
                memtoreg = 0; memwrite = 0; branch   = 0;
                ALUop    = 2'b00;
            end
            default: begin
                regdst   = 0; regwrite = 0; alusrc   = 0;
                memtoreg = 0; memwrite = 0; branch   = 0;
                ALUop    = 2'b00;
            end
        endcase
    end
endmodule

// -----------------------------------------------------------------------------
// mux1.v
// -----------------------------------------------------------------------------
module mux1 (
    input  wire [4:0] inst20_16,
    input  wire [4:0] inst15_11,
    input  wire       RegDst,
    output wire [4:0] WriteReg
);
    assign WriteReg = RegDst ? inst15_11 : inst20_16;
endmodule

// -----------------------------------------------------------------------------
// register_file.v
// -----------------------------------------------------------------------------
module register_file (
    input  wire        clk,
    input  wire        write_enable,
    input  wire [4:0]  read_address1,
    input  wire [4:0]  read_address2,
    input  wire [4:0]  write_address,
    input  wire [31:0] write_data,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);
    reg [31:0] regs [0:31];
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'b0;
    end
    assign read_data1 = regs[read_address1];
    assign read_data2 = regs[read_address2];
    always @(posedge clk) begin
        if (write_enable && write_address != 0)
            regs[write_address] <= write_data;
    end
endmodule

// -----------------------------------------------------------------------------
// SignExtend.v
// -----------------------------------------------------------------------------
module SignExtend (
    input  wire [15:0] inst15_0,
    output wire [31:0] Extend32
);
    assign Extend32 = {{16{inst15_0[15]}}, inst15_0};
endmodule

// -----------------------------------------------------------------------------
// mux2.v
// -----------------------------------------------------------------------------
module mux2 (
    input  wire        ALUSrc,
    input  wire [31:0] read_data2,
    input  wire [31:0] Extend32,
    output wire [31:0] ALU_B
);
    assign ALU_B = ALUSrc ? Extend32 : read_data2;
endmodule

// -----------------------------------------------------------------------------
// ShiftLeft2.v
// -----------------------------------------------------------------------------
module ShiftLeft2 (
    input  wire [31:0] ShiftIn,
    output wire [31:0] ShiftOut
);
    assign ShiftOut = ShiftIn << 2;
endmodule

// -----------------------------------------------------------------------------
// ALU_decoder.v
// -----------------------------------------------------------------------------
module ALU_decoder (
    input  wire [5:0]  funct,
    input  wire [1:0]  ALUop,
    output reg  [2:0]  ALU_control
);
    always @(*) begin
        case (ALUop)
            2'b00: ALU_control = 3'b010; // add
            2'b01: ALU_control = 3'b110; // sub
            2'b10: begin
                case (funct)
                    6'b100000: ALU_control = 3'b010; // add
                    6'b100010: ALU_control = 3'b110; // sub
                    6'b100100: ALU_control = 3'b000; // and
                    6'b100101: ALU_control = 3'b001; // or
                    6'b101010: ALU_control = 3'b111; // slt
                    default:   ALU_control = 3'bxxx;
                endcase
            end
            default: ALU_control = 3'bxxx;
        endcase
    end
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
    input  wire        AndGateOut,
    output wire [31:0] pc_in
);
    assign pc_in = AndGateOut ? adder2_out : adder1_out;
endmodule

// -----------------------------------------------------------------------------
// data_memory.v
// -----------------------------------------------------------------------------
module data_memory (
    input  wire        clk,
    input  wire        write_enable,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);
    reg [31:0] mem [0:31];
    always @(posedge clk) begin
        if (write_enable)
            mem[address[31:2]] <= write_data;
        read_data <= mem[address[31:2]];
    end
endmodule

// -----------------------------------------------------------------------------
// mux3.v
// -----------------------------------------------------------------------------
module mux3 (
    input  wire [31:0] read_data,
    input  wire [31:0] ALU_result,
    input  wire        memtoreg,
    output wire [31:0] WriteData_reg
);
    assign WriteData_reg = memtoreg ? read_data : ALU_result;
endmodule

// -----------------------------------------------------------------------------
// mips_cpu.v
// -----------------------------------------------------------------------------
module mips_cpu (
    input  wire        clock,
    input  wire        reset
);
    // wires internos
    wire [31:0] pc_in, pc_out, instruction;
    wire        regdst, regwrite, alusrc, memtoreg, memwrite, branch;
    wire [1:0]  ALUop;
    wire [4:0]  WriteReg;
    wire [31:0] read_data1, read_data2, Extend32, ALU_B, ShiftOut;
    wire [2:0]  ALU_control;
    wire        zero;
    wire [31:0] ALU_result, adder1_out, adder2_out, read_data, WriteData_reg;
    wire        AndGateOut;

    program_counter pc_inst (
        .clk(clock),
        .reset(reset),
        .pc_in(pc_in),
        .pc_out(pc_out)
    );

    adder1 adder1_inst (
        .pc_out(pc_out),
        .adder1_out(adder1_out)
    );

    instruction_memory inst_mem (
        .address(pc_out),
        .instruction(instruction)
    );

    main_decoder main_dec (
        .op(instruction[31:26]),
        .regdst(regdst),
        .regwrite(regwrite),
        .alusrc(alusrc),
        .memtoreg(memtoreg),
        .memwrite(memwrite),
        .branch(branch),
        .ALUop(ALUop)
    );

    mux1 mux1_inst (
        .inst20_16(instruction[20:16]),
        .inst15_11(instruction[15:11]),
        .RegDst(regdst),
        .WriteReg(WriteReg)
    );

    register_file reg_file (
        .clk(clock),
        .write_enable(regwrite),
        .read_address1(instruction[25:21]),
        .read_address2(instruction[20:16]),
        .write_address(WriteReg),
        .write_data(WriteData_reg),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    SignExtend sign_ext (
        .inst15_0(instruction[15:0]),
        .Extend32(Extend32)
    );

    mux2 mux2_inst (
        .ALUSrc(alusrc),
        .read_data2(read_data2),
        .Extend32(Extend32),
        .ALU_B(ALU_B)
    );

    ShiftLeft2 shift_left (
        .ShiftIn(Extend32),
        .ShiftOut(ShiftOut)
    );

    ALU_decoder alu_dec (
        .funct(instruction[5:0]),
        .ALUop(ALUop),
        .ALU_control(ALU_control)
    );

    ALU alu (
        .ALU_Control(ALU_control),
        .A(read_data1),
        .B(ALU_B),
        .ALU_result(ALU_result),
        .zero(zero)
    );

    adder2 adder2_inst (
        .adder1_out(adder1_out),
        .ShiftOut(ShiftOut),
        .adder2_out(adder2_out)
    );

    And_Gate and_gate (
        .branch(branch),
        .zero(zero),
        .AndGateOut(AndGateOut)
    );

    mux4 mux4_inst (
        .adder1_out(adder1_out),
        .adder2_out(adder2_out),
        .AndGateOut(AndGateOut),
        .pc_in(pc_in)
    );

    data_memory data_mem (
        .clk(clock),
        .write_enable(memwrite),
        .address(ALU_result),
        .write_data(read_data2),
        .read_data(read_data)
    );

    mux3 mux3_inst (
        .read_data(read_data),
        .ALU_result(ALU_result),
        .memtoreg(memtoreg),
        .WriteData_reg(WriteData_reg)
    );
endmodule

// -----------------------------------------------------------------------------
// top.v — instância única para síntese/simulação
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

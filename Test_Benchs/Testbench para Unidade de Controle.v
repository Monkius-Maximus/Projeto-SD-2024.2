`timescale 1ns/1ps

module tb_control_unit;
    reg [5:0] opcode;
    wire RegDst, ALUSrc, MemtoReg, RegWrite;
    wire MemRead, MemWrite, Branch;
    wire [1:0] ALUOp;
    
    control_unit dut(
        .opcode(opcode),
        .RegDst(RegDst),
        .ALUSrc(ALUSrc),
        .MemtoReg(MemtoReg),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .ALUOp(ALUOp)
    );
    
    initial begin
        // Teste R-type
        opcode = 6'b000000;
        #10;
        
        // Teste lw
        opcode = 6'b100011;
        #10;
        
        // Teste sw
        opcode = 6'b101011;
        #10;
        
        // Teste beq
        opcode = 6'b000100;
        #10;
        
        $finish;
    end
    
    initial begin
        $monitor("Time=%t Opcode=%b | RegDst=%b ALUSrc=%b MemtoReg=%b RegWrite=%b",
                 $time, opcode, RegDst, ALUSrc, MemtoReg, RegWrite);
    end
endmodule
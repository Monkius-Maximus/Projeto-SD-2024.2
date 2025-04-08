module mips_core(
    input wire clk,
    input wire reset
);
    // Conexões principais
    wire [31:0] PC, next_PC, instruction;
    wire [31:0] read_data1, read_data2, write_data;
    wire [31:0] ALU_result, mem_read_data;
    wire [31:0] sign_ext_out, ALU_srcB;
    wire [4:0] write_reg;
    wire [3:0] ALU_control;
    wire zero_flag;
    
    // Sinais de controle
    wire RegDst, ALUSrc, MemtoReg, RegWrite;
    wire MemRead, MemWrite, Branch;
    wire [1:0] ALUOp;

    // Instanciação dos módulos principais
    pc_register pc_reg(.clk(clk), .reset(reset), .next_PC(next_PC), .PC(PC));
    pc_adder pc_add(.current_PC(PC), .next_PC(next_PC));
    instruction_memory imem(.PC(PC), .instruction(instruction));
    
    control_unit ctrl(
        .opcode(instruction[31:26]),
        .RegDst(RegDst),
        .ALUSrc(ALUSrc),
        .MemtoReg(MemtoReg),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .ALUOp(ALUOp)
    );
    
    mux2x1 #(5) reg_dst_mux(
        .in0(instruction[20:16]),
        .in1(instruction[15:11]),
        .sel(RegDst),
        .out(write_reg)
    );
    
    register_file reg_file(
        .clk(clk),
        .reset(reset),
        .read_reg1(instruction[25:21]),
        .read_reg2(instruction[20:16]),
        .write_reg(write_reg),
        .write_data(write_data),
        .reg_write(RegWrite),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );
    
    sign_extend sign_ext(.imm_in(instruction[15:0]), .imm_out(sign_ext_out));
    
    mux2x1 alu_src_mux(
        .in0(read_data2),
        .in1(sign_ext_out),
        .sel(ALUSrc),
        .out(ALU_srcB)
    );
    
    ALU alu(
        .srcA(read_data1),
        .srcB(ALU_srcB),
        .ALU_control(ALU_control),
        .ALU_result(ALU_result),
        .zero(zero_flag)
    );
    
    data_memory dmem(
        .clk(clk),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .address(ALU_result),
        .write_data(read_data2),
        .read_data(mem_read_data)
    );
    
    mux2x1 mem_to_reg_mux(
        .in0(ALU_result),
        .in1(mem_read_data),
        .sel(MemtoReg),
        .out(write_data)
    );
    
    // Lógica de desvio
    wire branch_taken = Branch & zero_flag;
    wire [31:0] branch_target = PC + 4 + (sign_ext_out << 2);
    mux2x1 branch_mux(
        .in0(PC + 4),
        .in1(branch_target),
        .sel(branch_taken),
        .out(next_PC)
    );
endmodule
`timescale 1ns/1ps

module tb_mips_cpu;
  // Clock e reset para o DUT
  reg clock;
  reg reset;

  // Instanciação do processador MIPS completo
  mips_cpu dut (
    .clock(clock),
    .reset(reset)
  );

  //====================================================================
  // 1) Instâncias e sinais dos testes modulares
  //====================================================================

  // --- Adder1 (PC + 4) ---
  reg  [31:0] tb1_pc_out;
  wire [31:0] tb1_adder1_out;
  adder1 adder1_tb (
    .pc_out(tb1_pc_out),
    .adder1_out(tb1_adder1_out)
  );

  // --- Adder2 (branch target) ---
  reg  [31:0] tb2_adder1_out, tb2_shiftout;
  wire [31:0] tb2_adder2_out;
  adder2 adder2_tb (
    .adder1_out(tb2_adder1_out),
    .ShiftOut(tb2_shiftout),
    .adder2_out(tb2_adder2_out)
  );

  // --- ALU ---
  reg  [2:0]  tbALU_ctrl;
  reg  [31:0] tbALU_A, tbALU_B;
  wire [31:0] tbALU_result;
  wire        tbALU_zero;
  ALU alu_tb (
    .ALU_Control(tbALU_ctrl),
    .A(tbALU_A),
    .B(tbALU_B),
    .ALU_result(tbALU_result),
    .zero(tbALU_zero)
  );

  // --- ALU Decoder ---
  reg  [1:0]  tbDec_op;
  reg  [5:0]  tbDec_funct;
  wire [2:0]  tbDec_control;
  ALU_decoder alu_dec_tb (
    .ALUop(tbDec_op),
    .funct(tbDec_funct),
    .ALU_control(tbDec_control)
  );

  // --- And_Gate ---
  reg         tb_and_branch, tb_and_zero;
  wire        tb_and_out;
  And_Gate and_tb (
    .branch(tb_and_branch),
    .zero(tb_and_zero),
    .AndGateOut(tb_and_out)
  );

  // --- Data Memory ---
  reg         tb_dm_we;
  reg  [31:0] tb_dm_addr, tb_dm_wdata;
  wire [31:0] tb_dm_rdata;
  data_memory dm_tb (
    .clk(clock),
    .write_enable(tb_dm_we),
    .address(tb_dm_addr),
    .write_data(tb_dm_wdata),
    .read_data(tb_dm_rdata)
  );

  //====================================================================
  // 2) Geração de clock e reset
  //====================================================================
  initial begin
    clock = 0;
    forever #5 clock = ~clock;  // 100 MHz
  end

  initial begin
    reset = 1;
    #15;
    reset = 0;
  end

  //====================================================================
  // 3) Testes modulares (rodam em paralelo)
  //====================================================================

  // Adder1
  initial begin
    $display("\n[TB1] adder1 (PC+4) Tests");
    tb1_pc_out = 0;    #10;
    $display(" pc_out=0    -> sum=%0d (exp=4)", tb1_adder1_out);
    tb1_pc_out = 32'h00000004; #10;
    $display(" pc_out=4    -> sum=%0d (exp=8)", tb1_adder1_out);
  end

  // Adder2
  initial begin
    #30;
    $display("\n[TB2] adder2 (branch target) Tests");
    tb2_adder1_out = 4; tb2_shiftout = 8;  #10;
    $display(" in1=4, shift=8 -> out=%0d (exp=12)", tb2_adder2_out);
    tb2_adder1_out = 16; tb2_shiftout = 4; #10;
    $display(" in1=16,shift=4 -> out=%0d (exp=20)", tb2_adder2_out);
  end

  // ALU
  initial begin
    #60;
    $display("\n[TB3] ALU Tests");
    tbALU_A = 5; tbALU_B = 3; tbALU_ctrl = 3'b000; #10;
    $display(" AND: 5 & 3 = %0d (exp=1)", tbALU_result);
    tbALU_ctrl = 3'b001; #10;
    $display(" OR:  5 | 3 = %0d (exp=7)", tbALU_result);
    tbALU_ctrl = 3'b010; #10;
    $display(" ADD: 5 + 3 = %0d (exp=8)", tbALU_result);
    tbALU_ctrl = 3'b110; #10;
    $display(" SUB: 5 - 3 = %0d (exp=2)", tbALU_result);
    tbALU_ctrl = 3'b111; #10;
    $display(" SLT: 5 < 3 = %0d (exp=0)", tbALU_result);
  end

  // ALU Decoder
  initial begin
    #120;
    $display("\n[TB4] ALU_decoder Tests");
    tbDec_op = 2'b00; tbDec_funct = 6'bxxxxxx; #10;
    $display(" op=00 -> ctrl=%b (exp=010)", tbDec_control);
    tbDec_op = 2'b01;                #10;
    $display(" op=01 -> ctrl=%b (exp=110)", tbDec_control);
    tbDec_op = 2'b10; tbDec_funct = 6'b100000; #10;
    $display(" add funct -> ctrl=%b (exp=010)", tbDec_control);
    tbDec_funct = 6'b101010;           #10;
    $display(" slt funct -> ctrl=%b (exp=111)", tbDec_control);
  end

  // And_Gate
  initial begin
    #180;
    $display("\n[TB5] And_Gate Tests");
    tb_and_branch = 1; tb_and_zero = 1; #10;
    $display(" 1 & 1 -> %b (exp=1)", tb_and_out);
    tb_and_zero   = 0; #10;
    $display(" 1 & 0 -> %b (exp=0)", tb_and_out);
  end

  // Data Memory
  initial begin
    #240;
    $display("\n[TB6] data_memory Tests");
    tb_dm_we    = 1;
    tb_dm_addr  = 0;
    tb_dm_wdata = 42;
    #10;
    tb_dm_we    = 0;
    tb_dm_addr  = 0;
    #10;
    $display(" read_data = %0d (exp=42)", tb_dm_rdata);
  end

  //====================================================================
  // 4) Monitor do DUT completo (mips_cpu)
  //====================================================================
  initial begin
    #300;
    $display("\n[TB_DUT] Início do monitor do mips_cpu");
    $display("Time(ns)\tPC\tInstr\tWriteData\tZero");
    $display("--------------------------------------------------");
    forever begin
      @(posedge clock);
      #1;
      $display("%0t\t%h\t%h\t%h\t%b",
        $time,
        dut.pc_inst.pc_out,
        dut.inst_mem.RAM[dut.pc_inst.pc_out>>2],  // leitura direta da ROM
        dut.WriteData_reg,
        dut.zero
      );
    end
  end

  //====================================================================
  // 5) Fim geral dos testes (sem $finish aqui!)
  //====================================================================
  initial begin
    #600;
    $display("\n>>> TODOS OS TESTES MODULARES COMPLETOS <<<");
    // note que NÃO fechamos a simulação aqui com $finish,
    // para permitir o bloco de febre rodar logo em seguida.
  end

  //====================================================================
  // 6) Resultado do tratamento de febre
  //====================================================================
  initial begin
    #650;  // aguarda um pouquinho após os testes
   $display("\n[TB_FEBRE] Verificando data_memory[3] (offset 12 bytes) ...");
    //  é nessa célula (12/4 = índice 3) que o seu programa grava 1=“febre” ou 0=“sem febre”
    if (dut.data_mem.RAM[3] === 1)
      $display(">>> Paciente COM FEBRE <<<");
    else if (dut.data_mem.RAM[3] === 0)
      $display(">>> Paciente SEM FEBRE <<<");
    else
      $display(">>> Resultado INDETERMINADO <<<");
    $display("\n>>> SIMULAÇÃO FINALIZADA <<<");
    $finish;  // agora sim, encerramos a simulação
  end

endmodule

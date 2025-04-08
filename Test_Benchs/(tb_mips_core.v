`timescale 1ns/1ps

module tb_mips_core;
    reg clk;
    reg reset;
    
    mips_core dut(.clk(clk), .reset(reset));
    
    // Geração de clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Estímulos e monitoramento
    initial begin
        reset = 1;
        #20 reset = 0;
        
        // Executa por 10 ciclos
        #100;
        $display("Estado final:");
        $display("Reg[2] = %h", dut.reg_file.registers[2]);
        $display("Reg[3] = %h", dut.reg_file.registers[3]);
        $display("Reg[4] = %h", dut.reg_file.registers[4]);
        $display("Mem[0] = %h", dut.dmem.mem[0]);
        $finish;
    end
    
    initial begin
        $monitor("Time = %t | PC = %h | Instr = %h", 
                $time, dut.PC, dut.instruction);
    end
endmodule
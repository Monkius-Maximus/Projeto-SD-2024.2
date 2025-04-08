`timescale 1ns/1ps

module tb_pc_register;
    reg clk;
    reg reset;
    reg [31:0] next_PC;
    wire [31:0] PC;
    
    pc_register dut(
        .clk(clk),
        .reset(reset),
        .next_PC(next_PC),
        .PC(PC)
    );
    
    // Geração de clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Estímulos
    initial begin
        // Reset inicial
        reset = 1;
        next_PC = 32'h00000000;
        #10;
        
        // Libera reset e testa atualização
        reset = 0;
        next_PC = 32'h00000004;
        #10;
        
        next_PC = 32'h00000008;
        #10;
        
        next_PC = 32'h0000000C;
        #10;
        
        $finish;
    end
    
    // Monitoramento
    initial begin
        $monitor("Time = %t | Reset = %b | Next_PC = %h | PC = %h", 
                 $time, reset, next_PC, PC);
    end
endmodule
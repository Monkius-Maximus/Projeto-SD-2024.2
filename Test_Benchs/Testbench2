`timescale 1ns/1ps

module tb_pc_adder;
    reg [31:0] current_PC;
    wire [31:0] next_PC;
    
    pc_adder dut(
        .current_PC(current_PC),
        .next_PC(next_PC)
    );
    
    // Estímulos
    initial begin
        current_PC = 32'h00000000;
        #10;
        
        current_PC = 32'h00000004;
        #10;
        
        current_PC = 32'h00000008;
        #10;
        
        $finish;
    end
    
    // Monitoramento
    initial begin
        $monitor("Time = %t | Current_PC = %h | Next_PC = %h", 
                 $time, current_PC, next_PC);
    end
endmodule
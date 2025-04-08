`timescale 1ns/1ps

module tb_sign_extend;
    reg [15:0] imm_in;
    wire [31:0] imm_out;
    
    sign_extend dut(.imm_in(imm_in), .imm_out(imm_out));
    
    initial begin
        // Teste positivo
        imm_in = 16'h7FFF;
        #10;
        
        // Teste negativo
        imm_in = 16'h8000;
        #10;
        
        $finish;
    end
    
    initial begin
        $monitor("Time=%t ImmIn=%h | ImmOut=%h",
                 $time, imm_in, imm_out);
    end
endmodule
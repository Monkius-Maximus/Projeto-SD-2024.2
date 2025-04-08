`timescale 1ns/1ps

module tb_mux;
    reg [31:0] in0, in1;
    reg sel;
    wire [31:0] out;
    
    mux2x1 #(32) dut(.in0(in0), .in1(in1), .sel(sel), .out(out));
    
    initial begin
        in0 = 32'hAAAA_AAAA;
        in1 = 32'h5555_5555;
        
        sel = 0;
        #10;
        
        sel = 1;
        #10;
        
        $finish;
    end
    
    initial begin
        $monitor("Time=%t Sel=%b | In0=%h In1=%h Out=%h",
                 $time, sel, in0, in1, out);
    end
endmodule
`timescale 1ns/1ps

module tb_data_memory;
    reg clk;
    reg MemWrite, MemRead;
    reg [31:0] address, write_data;
    wire [31:0] read_data;
    
    data_memory dut(
        .clk(clk),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .address(address),
        .write_data(write_data),
        .read_data(read_data)
    );
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    initial begin
        // Escrita
        MemWrite = 1;
        MemRead = 0;
        address = 32'h00000004;
        write_data = 32'hDEADBEEF;
        #10;
        
        // Leitura
        MemWrite = 0;
        MemRead = 1;
        #10;
        
        $finish;
    end
    
    initial begin
        $monitor("Time=%t | Address=%h | WriteData=%h | ReadData=%h",
                 $time, address, write_data, read_data);
    end
endmodule
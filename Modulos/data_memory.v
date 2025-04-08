module data_memory(
    input wire clk,
    input wire MemWrite,
    input wire MemRead,
    input wire [31:0] address,
    input wire [31:0] write_data,
    output wire [31:0] read_data
);
    reg [31:0] mem[0:255];
    
    assign read_data = MemRead ? mem[address[9:2]] : 32'b0;
    
    always @(posedge clk) begin
        if(MemWrite)
            mem[address[9:2]] <= write_data;
    end
endmodule
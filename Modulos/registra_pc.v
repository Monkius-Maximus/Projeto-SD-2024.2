module pc_register(
    input wire clk,
    input wire reset,
    input wire [31:0] next_PC,
    output reg [31:0] PC
);
    always @(posedge clk or posedge reset) begin
        if(reset)
            PC <= 32'h00000000;  // Valor inicial do PC
        else
            PC <= next_PC;      // Atualiza o PC
    end
endmodule
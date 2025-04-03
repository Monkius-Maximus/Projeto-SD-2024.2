module pc_adder(
    input wire [31:0] current_PC,
    output wire [31:0] next_PC
);
    assign next_PC = current_PC + 4;  // Soma constante 4
endmodule
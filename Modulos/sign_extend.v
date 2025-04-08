module sign_extend(
    input wire [15:0] imm_in,
    output wire [31:0] imm_out
);
    assign imm_out = {{16{imm_in[15]}}, imm_in};
endmodule
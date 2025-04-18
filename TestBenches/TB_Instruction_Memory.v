module instruction_memory_tb;

    // Inputs
    reg [31:0] address;

    // Outputs
    wire [31:0] instruction;

    // Instantiate the instruction_memory module
    instruction_memory uut (
        .address(address),
        .instruction(instruction)
    );

    initial begin
        // Monitor signals for debugging
        $monitor("Time = %0t, ADDR = %0d, INSTRUCTION = %b (hex: %h)", 
                 $time, address, instruction, instruction);

        // Test sequence
        #10;
        
        // Read instruction at address 0
        address = 0;
        #10;

        // Read instruction at address 4
        address = 4;
        #10;

        // Read instruction at address 8
        address = 8;
        #10;

        // Read instruction at address 12
        address = 12;
        #10;

        // Read instruction at address 16
        address = 16;
        #10;

        // Read instruction at address 20
        address = 20;
        #10;

        // Read instruction at address 24
        address = 24;
        #10;

        // Read instruction at address 28
        address = 28;
        #10;

        // Read instruction at address 32
        address = 32;
        #10;

        // Read instruction at address 36
        address = 36;
        #10;

        // Read instruction at address 40
        address = 40;
        #10;

        // Read instruction at address 44
        address = 44;
        #10;

        // Read instruction at address 48
        address = 48;
        #10;

        // Read instruction at address 52
        address = 52;
        #10;

        // Finish simulation
        $finish;
    end

endmodule
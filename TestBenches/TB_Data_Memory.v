module data_memory_tb;

    // Inputs
    reg clk;
    reg write_enable;
    reg [31:0] address;
    reg [31:0] write_data;

    // Output
    wire [31:0] read_data;

    // Instantiate the data_memory module
    data_memory uut (
        .clk(clk),
        .write_enable(write_enable),
        .address(address),
        .write_data(write_data),
        .read_data(read_data)
    );

    // Clock generation
    always begin
        #5 clk = ~clk; // Clock with a period of 10 units
    end

    initial begin
        // Initialize Inputs
        clk = 0;
        write_enable = 0;
        address = 0;
        write_data = 0;

        // Monitor signals for debugging
        $monitor("Time = %0t, CLK = %b, WE = %b, ADDR = %0d, WRITE_DATA = %0d, READ_DATA = %0d", 
                  $time, clk, write_enable, address[5:0], write_data, read_data);

        // Test sequence
        #10;
        
        // Write data to address 3
        write_enable = 1;
        address = 3;
        write_data = 45;
        #10;

        // Disable write and read from address 3
        write_enable = 0;
        #10;

        // Write data to address 5
        write_enable = 1;
        address = 5;
        write_data = 78;
        #10;

        // Disable write and read from address 5
        write_enable = 0;
        address = 5;
        #10;

        // Read from address 3
        address = 3;
        #10;

        // Write data to address 7
        write_enable = 1;
        address = 7;
        write_data = 123;
        #10;

        // Disable write and read from address 7
        write_enable = 0;
        #10;

        // Read from address 3, 5, and 7 again
        address = 3;
        #10;
        address = 5;
        #10;
        address = 7;
        #10;

        // Finish simulation
        $finish;
    end

endmodule

`timescale 1ns / 1ps

module top_module_tb;

    // Parameters
    parameter CLOCK_PERIOD = 20; // 50 MHz clock (20ns period)
    
    // Inputs
    reg clk;
    reg rst_n;
    reg rx;
    reg din_en;
    reg start_sending;
    
    // Outputs
    wire spi_clock;
    wire spi_data;
    wire cs_n;
    
    // Instantiate the Unit Under Test (UUT)
    top_module uut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .din_en(din_en),
        .start_sending(start_sending),
        .spi_clock(spi_clock),
        .spi_data(spi_data),
        .cs_n(cs_n)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLOCK_PERIOD/2) clk = ~clk;
    end
    
    // Test procedure
    initial begin
        // Initialize inputs
        rst_n = 0;
        rx = 1; // UART idle state is high
        din_en = 1;
        start_sending = 1;
        
        // Reset the system
        #100;
        rst_n = 1;
        #100;
        
        // Test UART reception and memory storage
        $display("Testing UART reception and memory storage...");
        din_en = 0; // Enable UART data storage
        
        // Simulate UART reception of 3 bytes (24 bits)
        // Start bit (0) + 8 data bits (0x55) + stop bit (1)
        rx = 0; // Start bit
        #(400*CLOCK_PERIOD); // Wait for 10 clock cycles (simplified)
        
        // Data bits (0x55 = 01010101)
        rx = 1; #(400*CLOCK_PERIOD);
        rx = 0; #(400*CLOCK_PERIOD);
        rx = 1; #(400*CLOCK_PERIOD);
        rx = 0; #(400*CLOCK_PERIOD);
        rx = 1; #(400*CLOCK_PERIOD);
        rx = 0; #(400*CLOCK_PERIOD);
        rx = 1; #(400*CLOCK_PERIOD);
        rx = 0; #(400*CLOCK_PERIOD);
        
        rx = 1; // Stop bit
        #(400*CLOCK_PERIOD);
        
        // Repeat for second byte (0xAA)
        rx = 0; // Start bit
        #(400*CLOCK_PERIOD);
        
        // Data bits (0xAA = 10101010)
        rx = 0; #(400*CLOCK_PERIOD);
        rx = 1; #(400*CLOCK_PERIOD);
        rx = 0; #(400*CLOCK_PERIOD);
        rx = 1; #(400*CLOCK_PERIOD);
        rx = 0; #(400*CLOCK_PERIOD);
        rx = 1; #(400*CLOCK_PERIOD);
        rx = 0; #(400*CLOCK_PERIOD);
        rx = 1; #(400*CLOCK_PERIOD);
        
        rx = 1; // Stop bit
        #(400*CLOCK_PERIOD);
        
        // Repeat for third byte (0x12)
        rx = 0; // Start bit
        #(400*CLOCK_PERIOD);
        
        // Data bits (0x12 = 00010010)
        rx = 0; #(400*CLOCK_PERIOD);
        rx = 1; #(400*CLOCK_PERIOD);
        rx = 0; #(400*CLOCK_PERIOD);
        rx = 0; #(400*CLOCK_PERIOD);
        rx = 1; #(400*CLOCK_PERIOD);
        rx = 0; #(400*CLOCK_PERIOD);
        rx = 0; #(400*CLOCK_PERIOD);
        rx = 0; #(400*CLOCK_PERIOD);
        
        rx = 1; // Stop bit
        #(400*CLOCK_PERIOD);
        
        
        rx = 0; // Start bit
                #(400*CLOCK_PERIOD); // Wait for 10 clock cycles (simplified)
                
                // Data bits (0x55 = 01010101)
                rx = 1; #(400*CLOCK_PERIOD);
                rx = 0; #(400*CLOCK_PERIOD);
                rx = 1; #(400*CLOCK_PERIOD);
                rx = 0; #(400*CLOCK_PERIOD);
                rx = 1; #(400*CLOCK_PERIOD);
                rx = 0; #(400*CLOCK_PERIOD);
                rx = 1; #(400*CLOCK_PERIOD);
                rx = 0; #(400*CLOCK_PERIOD);
                
                rx = 1; // Stop bit
                #(400*CLOCK_PERIOD);
                
                // Repeat for second byte (0xAA)
                rx = 0; // Start bit
                #(400*CLOCK_PERIOD);
                
                // Data bits (0xAA = 10101010)
                rx = 0; #(400*CLOCK_PERIOD);
                rx = 1; #(400*CLOCK_PERIOD);
                rx = 0; #(400*CLOCK_PERIOD);
                rx = 1; #(400*CLOCK_PERIOD);
                rx = 0; #(400*CLOCK_PERIOD);
                rx = 1; #(400*CLOCK_PERIOD);
                rx = 0; #(400*CLOCK_PERIOD);
                rx = 1; #(400*CLOCK_PERIOD);
                
                rx = 1; // Stop bit
                #(400*CLOCK_PERIOD);
                
                // Repeat for third byte (0x12)
                rx = 0; // Start bit
                #(400*CLOCK_PERIOD);
                
                // Data bits (0x12 = 00010010)
                rx = 0; #(400*CLOCK_PERIOD);
                rx = 1; #(400*CLOCK_PERIOD);
                rx = 0; #(400*CLOCK_PERIOD);
                rx = 0; #(400*CLOCK_PERIOD);
                rx = 1; #(400*CLOCK_PERIOD);
                rx = 0; #(400*CLOCK_PERIOD);
                rx = 0; #(400*CLOCK_PERIOD);
                rx = 0; #(400*CLOCK_PERIOD);
                
                rx = 1; // Stop bit
                #(400*CLOCK_PERIOD);
                
                rx = 0; // Start bit
                        #(400*CLOCK_PERIOD); // Wait for 10 clock cycles (simplified)
                        
                        // Data bits (0x55 = 01010101)
                        rx = 1; #(400*CLOCK_PERIOD);
                        rx = 0; #(400*CLOCK_PERIOD);
                        rx = 1; #(400*CLOCK_PERIOD);
                        rx = 0; #(400*CLOCK_PERIOD);
                        rx = 1; #(400*CLOCK_PERIOD);
                        rx = 0; #(400*CLOCK_PERIOD);
                        rx = 1; #(400*CLOCK_PERIOD);
                        rx = 0; #(400*CLOCK_PERIOD);
                        
                        rx = 1; // Stop bit
                        #(400*CLOCK_PERIOD);
                        
                        // Repeat for second byte (0xAA)
                        rx = 0; // Start bit
                        #(400*CLOCK_PERIOD);
                        
                        // Data bits (0xAA = 10101010)
                        rx = 0; #(400*CLOCK_PERIOD);
                        rx = 1; #(400*CLOCK_PERIOD);
                        rx = 0; #(400*CLOCK_PERIOD);
                        rx = 1; #(400*CLOCK_PERIOD);
                        rx = 0; #(400*CLOCK_PERIOD);
                        rx = 1; #(400*CLOCK_PERIOD);
                        rx = 0; #(400*CLOCK_PERIOD);
                        rx = 1; #(400*CLOCK_PERIOD);
                        
                        rx = 1; // Stop bit
                        #(400*CLOCK_PERIOD);
                        
                        // Repeat for third byte (0x12)
                        rx = 0; // Start bit
                        #(400*CLOCK_PERIOD);
                        
                        // Data bits (0x12 = 00010010)
                        rx = 0; #(400*CLOCK_PERIOD);
                        rx = 1; #(400*CLOCK_PERIOD);
                        rx = 0; #(400*CLOCK_PERIOD);
                        rx = 0; #(400*CLOCK_PERIOD);
                        rx = 1; #(400*CLOCK_PERIOD);
                        rx = 0; #(400*CLOCK_PERIOD);
                        rx = 0; #(400*CLOCK_PERIOD);
                        rx = 0; #(400*CLOCK_PERIOD);
                        
                        rx = 1; // Stop bit
                        #(400*CLOCK_PERIOD);
                        
        // Disable UART storage
        din_en = 1;
        #1000;
        
        // Test SPI transmission
        $display("Testing SPI transmission...");
        start_sending = 0; // Start SPI transmission
        #100;
        //start_sending = 1; // Release button
        
        // Wait for SPI transmission to complete
        #10000;
        
        $display("Test completed");
        $finish;
    end
    
    // Monitor SPI signals
    always @(posedge clk) begin
        if (!cs_n) begin
            $display("SPI Transaction - Clock: %b, Data: %b, CS: %b", 
                    spi_clock, spi_data, cs_n);
        end
    end
    
endmodule

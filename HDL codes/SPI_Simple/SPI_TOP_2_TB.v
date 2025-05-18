`timescale 1ns / 1ps

module spi_top_tb();
    // Testbench signals
    reg clk;
    reg rst_n;
    wire spi_clock;
    wire spi_data;
    wire status_led;
    wire cs_n;
    
    // Instantiate the Unit Under Test (UUT)
    spi_top_2 uut (
        .clk(clk),
        .rst_n(rst_n),
        .spi_clock(spi_clock),
        .spi_data(spi_data),
        .status_led(status_led),
        .cs_n(cs_n)
    );
    
    // Clock generation - 100 MHz (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Toggle every 5ns (10ns period)
    end
    
    // SPI data capture - to verify what's being sent
    reg [23:0] captured_data;
    integer bit_count;
    
    // Monitor the SPI signals
    always @(negedge spi_clock) begin
        if (bit_count < 24) begin
            captured_data = {captured_data[22:0], spi_data};
            bit_count = bit_count + 1;
            $display("Bit %d received: %b", bit_count, spi_data);
        end
    end
    
    // Test procedure
    initial begin
        // Initialize signals
        rst_n = 0;
        bit_count = 0;
        captured_data = 24'h0;
        
        // Apply reset
        #100;
        rst_n  = 1;
        
        // Wait for transmission to complete (adjust time as needed)
        // This depends on spi_clock frequency and bit count
        #10000;
        
        // Check captured data against expected value
        $display("Expected data: 24'hA53CF1");
        $display("Captured data: %h", captured_data);
        
        if (captured_data == 24'hABCDEF)
            $display("TEST PASSED: Data matched expected value");
        else
            $display("TEST FAILED: Data mismatch");
            
        // Check status LED
        if (status_led)
            $display("Status LED is ON - Transmission complete");
        else
            $display("Status LED is OFF - Transmission not reported as complete");
            
        // End simulation
        #1000;
        $finish;
    end
    
    // Waveform generation
    initial begin
        $dumpfile("spi_top_tb.vcd");
        $dumpvars(0, spi_top_tb);
    end
    
endmodule
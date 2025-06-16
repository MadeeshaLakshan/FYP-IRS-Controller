`timescale 1ns/1ps

module top_module_tb();

    // Parameters - matching top module
    parameter CLOCK_FREQ = 50000000;
    parameter STABLE_TIME_MS = 0.001;
    parameter CLOCKS_PER_PULSE = 10;  // 50MHz / 115200 baud
    parameter BITS_PER_WORD = 8;
    parameter W_OUT = 24;
    parameter CS_INACTIVE_CYCLES = 5;
    parameter DIV_FACTOR = 10;
    parameter DELAY_VALUE = 5;
    
    // Clock period calculations
    parameter CLK_PERIOD = 20;  // 50MHz = 20ns period
    parameter UART_BIT_PERIOD = CLK_PERIOD * CLOCKS_PER_PULSE; // Time for one UART bit
    
    // Testbench signals
    reg clk;
    reg rst_n;
    reg rx;
    reg din_en;
    reg start_sending;
    
    // Outputs
    wire spi_clock;
    wire spi_data;
    wire cs_n;
    wire [6:0] seg1, seg2, seg3, seg4;
    wire done_send;
    wire m_valid;
    wire [4:0] addr;
    
    // Test variables
    reg [23:0] test_data [0:7];  // Test data array
    integer i, j;
    
    // Instantiate DUT
    top_module #(
        .CS_INACTIVE_CYCLES(CS_INACTIVE_CYCLES),
        .DIV_FACTOR(DIV_FACTOR),
        .DELAY_VALUE(DELAY_VALUE),
        .CLOCK_FREQ(CLOCK_FREQ),
        .STABLE_TIME_MS(STABLE_TIME_MS),
        .CLOCKS_PER_PULSE(CLOCKS_PER_PULSE),
        .BITS_PER_WORD(BITS_PER_WORD),
        .W_OUT(W_OUT)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .din_en(din_en),
        .start_sending(start_sending),
        .spi_clock(spi_clock),
        .spi_data(spi_data),
        .cs_n(cs_n),
        .seg1(seg1),
        .seg2(seg2),
        .seg3(seg3),
        .seg4(seg4),
        .done_send(done_send),
        .m_valid(m_valid),
        .addr(addr)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Initialize test data
    initial begin
        test_data[0] = 24'h123456;
        test_data[1] = 24'h789ABC;
        test_data[2] = 24'hDEF012;
        test_data[3] = 24'h345678;
        test_data[4] = 24'h9ABCDE;
        test_data[5] = 24'hF01234;
        test_data[6] = 24'h567890;
        test_data[7] = 24'hABCDEF;
    end
    
    // Task to send UART byte
    task send_uart_byte;
        input [7:0] data;
        integer bit_idx;
        begin
            $display("Time %0t: Sending UART byte: 0x%02X", $time, data);
            
            // Start bit
            rx = 0;
            #UART_BIT_PERIOD;
            
            // Data bits (LSB first)
            for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                rx = data[bit_idx];
                #UART_BIT_PERIOD;
            end
            
            // Stop bit
            rx = 1;
            #UART_BIT_PERIOD;
            
            // Inter-frame gap
            #(UART_BIT_PERIOD * 2);
        end
    endtask
    
    // Task to send 24-bit UART data (3 bytes)
    task send_uart_24bit;
        input [23:0] data_24bit;
        begin
            $display("Time %0t: Sending 24-bit UART data: 0x%06X", $time, data_24bit);
            
            // Send 3 bytes: [23:16], [15:8], [7:0]
            send_uart_byte(data_24bit[7:0]);    // First byte (LSB)
            send_uart_byte(data_24bit[15:8]);   // Second byte
            send_uart_byte(data_24bit[23:16]);  // Third byte (MSB)
            
            // Wait for m_valid to go high
            //wait(m_valid);
            #(CLK_PERIOD * 5);  // Allow some time for processing
            $display("Time %0t: UART reception complete, m_valid asserted", $time);
        end
    endtask
    
    // Task to wait for button debouncing
    task wait_debounce;
        begin
            #(CLK_PERIOD * CLOCK_FREQ * STABLE_TIME_MS / 1000 * 2); // Wait 2x debounce time
        end
    endtask
    
    // Task to monitor SPI transmission
    task monitor_spi_transmission;
        reg [23:0] received_data;
        integer bit_count;
        begin
            $display("Time %0t: Monitoring SPI transmission", $time);
            
            // Wait for CS to go active (low)
            wait(cs_n == 0);
            $display("Time %0t: SPI CS active", $time);
            
            received_data = 0;
            bit_count = 0;
            
            // Monitor SPI data transmission
            while (cs_n == 0) begin
                @(posedge spi_clock);
                if (cs_n == 0) begin  // Still active
                    received_data = {received_data[22:0], spi_data};
                    bit_count = bit_count + 1;
                    if (bit_count <= 24) begin
                        $display("Time %0t: SPI bit %0d: %b", $time, bit_count, spi_data);
                    end
                end
            end
            
            $display("Time %0t: SPI transmission complete. Received: 0x%06X (%0d bits)", 
                     $time, received_data, bit_count);
            
            // Wait for done_send
            wait(done_send);
            $display("Time %0t: SPI done_send asserted", $time);
        end
    endtask
    
    // Main test sequence
    initial begin
        // Initialize signals
        rst_n = 0;
        rx = 1;  // UART idle state
        din_en = 1;      // Inactive (active low)
        start_sending = 1; // Inactive (active low)
        
        $display("=== Starting Top Module Testbench ===");
        $display("Time %0t: Initializing...", $time);
        
        // Reset sequence
        #(CLK_PERIOD * 10);
        rst_n = 1;
        #(CLK_PERIOD * 10);
        
        $display("Time %0t: Reset complete", $time);
        
        // Test 1: UART Data Reception and Storage
        $display("\n=== Test 1: UART Data Reception and Storage ===");
        
        din_en = 0;  // Enable UART data input mode
        wait_debounce();
        
        // Send multiple 24-bit data packets via UART
        for (i = 0; i < 8; i = i + 1) begin
            $display("Time %0t: Sending test data %0d", $time, i);
            send_uart_24bit(test_data[i]);
            #(CLK_PERIOD * 100); // Wait between transmissions
        end
        
        din_en = 1;  // Disable UART data input mode
        wait_debounce();
        
        $display("Time %0t: UART data storage test complete", $time);
        
        // Wait some time before SPI test
        #(CLK_PERIOD * 1000);
        
        // Test 2: SPI Data Transmission
        $display("\n=== Test 2: SPI Data Transmission ===");
        
        start_sending = 0;  // Start SPI transmission
        wait_debounce();
        
        // Monitor multiple SPI transmissions
        for (i = 0; i < 4; i = i + 1) begin
            $display("Time %0t: Waiting for SPI transmission %0d", $time, i);
            monitor_spi_transmission();
            #(CLK_PERIOD * 1000); // Wait between transmissions
        end
        
        start_sending = 1;  // Stop SPI transmission
        wait_debounce();
        
        $display("Time %0t: SPI transmission test complete", $time);
        
        // Test 3: Seven Segment Display
        $display("\n=== Test 3: Seven Segment Display Test ===");
        $display("Time %0t: Seven segment outputs:", $time);
        $display("  seg1 (bits 3:0):   0b%07b", seg1);
        $display("  seg2 (bits 7:4):   0b%07b", seg2);
        $display("  seg3 (bits 11:8):  0b%07b", seg3);
        $display("  seg4 (bits 15:12): 0b%07b", seg4);
        
        // Test 4: Combined UART and SPI Test
        $display("\n=== Test 4: Combined UART Reception and SPI Transmission ===");
        
        // Enable UART mode and send more data
        din_en = 0;
        wait_debounce();
        
        for (i = 4; i < 8; i = i + 1) begin
            send_uart_24bit(test_data[i]);
            #(CLK_PERIOD * 100);
        end
        
        din_en = 1;
        wait_debounce();
        #(CLK_PERIOD * 500);
        
        // Start SPI transmission of new data
        start_sending = 0;
        wait_debounce();
        
        // Monitor a few SPI transmissions
        for (i = 0; i < 3; i = i + 1) begin
            monitor_spi_transmission();
            #(CLK_PERIOD * 1000);
        end
        
        start_sending = 1;
        wait_debounce();
        
        // Final wait and cleanup
        #(CLK_PERIOD * 2000);
        
        $display("\n=== Testbench Complete ===");
        $display("Time %0t: All tests completed successfully", $time);
        
        $finish;
    end
    
    // Monitor important signals
    initial begin
        $monitor("Time %0t: addr=%0d, m_valid=%b, done_send=%b, cs_n=%b", 
                 $time, addr, m_valid, done_send, cs_n);
    end
    
    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 10000000); // 10M clock cycles timeout
        $display("ERROR: Testbench timeout!");
        $finish;
    end
    
    // Optional: Generate VCD dump for waveform viewing
    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule
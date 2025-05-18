`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/08/2025 12:46:59 AM
// Design Name: 
// Module Name: SPI_TOP
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SPI_Top
  (
   // Clock and Reset
   input        i_Clk,          // FPGA Clock
   input        i_Rst_n,        // FPGA Reset (active low)
   
   // Simple control interface
   input        i_Start_Transmission,  // Button/switch to start transmission
   
   // Status outputs
   output       o_Busy,         // LED to indicate busy status
   output       o_Done,         // LED to indicate completion
   
   // SPI Interface to external device
   output       o_SPI_Clk,      // SPI Clock
   input        i_SPI_MISO,     // SPI MISO
   output       o_SPI_MOSI,     // SPI MOSI
   output       o_SPI_CS_n      // SPI Chip Select (active low)
   );
   
  // Parameters for SPI Master
  parameter SPI_MODE = 3 ;
  parameter CLKS_PER_HALF_BIT = 4;  // Adjust based on your FPGA clock and desired SPI speed
  parameter MAX_BYTES_PER_CS = 1;    // 3 bytes for 24-bit data
  parameter CS_INACTIVE_CLKS = 5;    // Keep CS inactive for 5 clocks between transmissions
  
  // Constant predefined test data array (can be modified to your needs)
  // This example includes 4 predefined 24-bit values
  parameter DATA_COUNT = 4;
  reg [23:0] test_data [0:DATA_COUNT-1];
  
  // Initialize test data
  initial begin
    test_data[0] = 24'hAA5500;  // Test pattern 1
    test_data[1] = 24'h55AA00;  // Test pattern 2
    test_data[2] = 24'h123456;  // Test pattern 3
    test_data[3] = 24'hFEDCBA;  // Test pattern 4
  end
  
  // Control registers and state machine
  reg [1:0] r_state;
  localparam STATE_IDLE = 2'b00;
  localparam STATE_SETUP = 2'b01;
  localparam STATE_TRANSMITTING = 2'b10;
  localparam STATE_DONE = 2'b11;
  
  reg [23:0] r_tx_data;
  reg r_tx_dv;
  reg [1:0] r_data_index;
  reg r_busy;
  reg r_done;
  
  // Debounce start signal
  reg r_start_prev;
  wire w_start_edge;
  
  always @(posedge i_Clk) begin
    r_start_prev <= i_Start_Transmission;
  end
  
  assign w_start_edge = i_Start_Transmission & ~r_start_prev;
  
  // SPI Master signals
  wire w_tx_ready;
  wire w_rx_dv;
  wire [23:0] w_rx_byte;
  wire [$clog2(MAX_BYTES_PER_CS+1)-1:0] w_rx_count;
  
  // Instantiate SPI Master module
  SPI_Master_With_Single_CS 
    #(.SPI_MODE(SPI_MODE),
      .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT),
      .MAX_BYTES_PER_CS(MAX_BYTES_PER_CS),
      .CS_INACTIVE_CLKS(CS_INACTIVE_CLKS)
     ) SPI_Master_Inst
   (
    // Control/Data Signals
    .i_Rst_L(i_Rst_n),
    .i_Clk(i_Clk),
    
    // TX Signals
    .i_TX_Count(1'b1),  // Always send 3 bytes (24 bits)
    .i_TX_Byte(r_tx_data),          // Current data word to transmit
    .i_TX_DV(r_tx_dv),              // Data valid pulse
    .o_TX_Ready(w_tx_ready),        // Ready for next byte
    
    // RX Signals
    .o_RX_Count(w_rx_count),        // Not specifically used
    .o_RX_DV(w_rx_dv),
    .o_RX_Byte(w_rx_byte),          // Received data (can be monitored in simulation)
    
    // SPI Interface
    .o_SPI_Clk(o_SPI_Clk),
    .i_SPI_MISO(i_SPI_MISO),
    .o_SPI_MOSI(o_SPI_MOSI),
    .o_SPI_CS_n(o_SPI_CS_n)
   );
   
  // State machine for controlling transmissions
  always @(posedge i_Clk or negedge i_Rst_n) begin
    if (~i_Rst_n) begin
      r_state <= STATE_IDLE;
      r_tx_dv <= 1'b0;
      r_tx_data <= 24'h000000;
      r_data_index <= 2'b00;
      r_busy <= 1'b0;
      r_done <= 1'b0;
    end else begin
      case (r_state)
        STATE_IDLE: begin
          r_tx_dv <= 1'b0;
          r_busy <= 1'b0;
          
          if (w_start_edge) begin
            r_data_index <= 2'b00;
            r_state <= STATE_SETUP;
            r_busy <= 1'b1;
            r_done <= 1'b0;
          end
        end
        
        STATE_SETUP: begin
          // Prepare data for transmission
          r_tx_data <= test_data[r_data_index];
          r_tx_dv <= 1'b1;  // Assert data valid for one clock cycle
          r_state <= STATE_TRANSMITTING;
        end
        
        STATE_TRANSMITTING: begin
          r_tx_dv <= 1'b0;  // Deassert data valid
          
          // Wait for SPI transmission to complete
          if (w_tx_ready && o_SPI_CS_n) begin  // CS_n high indicates transaction complete
            if (r_data_index < DATA_COUNT-1) begin
              // Move to next data word
              r_data_index <= r_data_index + 1'b1;
              r_state <= STATE_SETUP;
            end else begin
              // All data transmitted
              r_state <= STATE_DONE;
            end
          end
        end
        
        STATE_DONE: begin
          r_busy <= 1'b0;
          r_done <= 1'b1;
          
          // Return to idle when start signal is deasserted
          if (!i_Start_Transmission) begin
            r_state <= STATE_IDLE;
          end
        end
        
        default: begin
          r_state <= STATE_IDLE;
        end
      endcase
    end
  end
  
  // Output assignments
  assign o_Busy = r_busy;
  assign o_Done = r_done;
  
endmodule

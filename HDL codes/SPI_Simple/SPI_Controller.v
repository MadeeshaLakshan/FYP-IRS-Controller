`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/29/2020 10:55:37 PM
// Design Name: 
// Module Name: spiControl
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

/*
module spiControl(
    input  clk, //On-board Zynq clock (100 MHz)
    input  rst_n,
    input [23:0] data_in,
    input  load_data, //Signal indicates new data for transmission
    output reg done_send,//Signal indicates data has been sent over spi interface
    output     spi_clock,//10MHz max
    output reg spi_data,
    output reg cs_n
);

reg [2:0] counter=0;
reg [4:0] dataCount;
reg [23:0] shiftReg;
reg [1:0] state;
reg clock_10;
reg CE;

assign spi_clock = (CE == 1) ? clock_10 : 1'b1;


always @(posedge clk)
begin
    if(counter != 4)
        counter <= counter + 1;
    else
        counter <= 0;
end

initial
    clock_10 <= 0;

always @(posedge clk)
begin
    if(counter == 4)
        clock_10 <= ~clock_10;
end

localparam IDLE = 'd0,
           SEND = 'd1,
           DONE = 'd2;

always @(negedge clock_10)
begin
    if(~rst_n)
    begin
        state <= IDLE;
        dataCount <= 0;
        done_send <= 1'b0;
        CE <= 0;
        cs_n <= 1;
        spi_data <= 1'b1;
    end
    else
    begin
        case(state)
            IDLE:begin
                if(load_data)
                begin
                    cs_n <= 1;
                    shiftReg <= data_in;
                    state <= SEND;
                    dataCount <= 0;
                    cs_n <= 0;
                end
            end
            SEND:begin
                cs_n <= 0;
                spi_data <= shiftReg[23];
                shiftReg <= {shiftReg[22:0],1'b0};
                CE <= 1;
                if(dataCount != 23)
                    dataCount <= dataCount + 1;
                else
                begin
                    state <= DONE;
                end
            end
            DONE:begin
                CE <= 0;
                cs_n<=1;
                done_send <= 1'b1;
                if(!load_data)
                begin
                    done_send <= 1'b0;
                    state <= IDLE;
                end
            end
        endcase
    end
end

    
    
endmodule*/
 
// CS inactive cycle
module spiControl (
    input  clk, //On-board Zynq clock (100 MHz)
    input  rst_n,
    input [23:0] data_in,
    input  load_data, //Signal indicates new data for transmission
    output reg done_send,//Signal indicates data has been sent over spi interface
    output     spi_clock,//10MHz max
    output reg spi_data,
    output reg cs_n
);

reg [2:0] counter=0;
reg [4:0] dataCount;
reg [7:0] cs_inactive_counter; // Counter for CS inactive cycles
reg [23:0] shiftReg;
reg [1:0] state; // 2 bits for 4 states (IDLE, CS_INACTIVE, SEND, DONE)
reg clock_10;
reg CE;
assign spi_clock = (CE == 1) ? clock_10 : 1'b1;

// Clock divider: 100MHz to 10MHz (divide by 5)
always @(posedge clk)
begin
    if(counter != 4)
        counter <= counter + 1;
    else
        counter <= 0;
end

initial
    clock_10 <= 0;

always @(posedge clk)
begin
    if(counter == 4)
        clock_10 <= ~clock_10;
end
localparam CS_INACTIVE_CYCLES = 8'd5;  // Default cs_n inactive time (in clock cycles)
// State definitions
localparam IDLE = 2'd0,
           CS_INACTIVE = 2'd1,
           SEND = 2'd2,
           DONE = 2'd3;

// Main state machine
always @(negedge clock_10 or negedge rst_n)
begin
    if(~rst_n)
    begin
        state <= IDLE;
        dataCount <= 0;
        done_send <= 1'b0;
        CE <= 0;
        spi_data <= 1'b1;
        cs_n <= 1'b1;  // Initialize cs_n to inactive state (high)
        cs_inactive_counter <= 0;
    end
    else
    begin
        case(state)
            IDLE: begin
                cs_n <= 1'b1;  // Ensure cs_n is inactive in IDLE
                CE <= 0;
                done_send <= 1'b0;
                
                if(load_data) begin
                    shiftReg <= data_in;
                    cs_inactive_counter <= 0;
                    state <= CS_INACTIVE;
                end
            end
            
            CS_INACTIVE: begin
                cs_n <= 1'b0;  // Keep cs_n inactive during this state
                
                
                if(cs_inactive_counter < CS_INACTIVE_CYCLES)
                    cs_inactive_counter <= cs_inactive_counter + 1;
                else begin
                    cs_n <= 1'b0;  // Activate cs_n after inactive period
                    dataCount <= 0;
                    CE <= 0;
                    state <= SEND;
                end
            end
            
            SEND: begin
                cs_n <= 1'b0;  // Keep cs_n active during transmission
                CE <= 1;       // Enable SPI clock
                spi_data <= shiftReg[23];
                shiftReg <= {shiftReg[22:0], 1'b0};
                
                if(dataCount != 23)
                    dataCount <= dataCount + 1;
                else
                    state <= DONE;
            end
            
            DONE: begin
                CE <= 0;
                cs_n <= 1'b1;  // Set cs_n back to inactive state when done
                done_send <= 1'b1;
                
                if(!load_data)
                    state <= IDLE;
            end
        endcase
    end
end
    
endmodule
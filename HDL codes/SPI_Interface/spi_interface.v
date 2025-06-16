`timescale 1ns / 1ps

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

module spi_interface #(
    parameter CS_INACTIVE_CYCLES = 5,DELAY_VALUE = 5 // Default cs_n inactive time (in clock cycles)
)(
    //input  clk,
    input  rst_n,
    input  clk_div,
    input [23:0] data_in,
    input  load_data, //Signal indicates new data for transmission
    output reg done_send,//Signal indicates data has been sent over spi interface
    output     spi_clock,//10MHz max
    output reg spi_data,
    output reg cs_n
);

reg [4:0] dataCount;
reg [$clog2(CS_INACTIVE_CYCLES)-1:0] cs_inactive_counter; // Counter for CS inactive cycles
reg [$clog2(DELAY_VALUE)-1:0] delay_counter;
reg [23:0] shiftReg;
reg CE;

assign spi_clock = (CE == 1) ? clk_div : 1'b1;

reg [1:0] state;
// State definitions
localparam IDLE = 2'd0,
           CS_INACTIVE = 2'd1,
           SEND = 2'd2,
           DONE = 2'd3;

// Main state machine
always @(negedge clk_div or negedge rst_n)
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
        shiftReg <=0 ;
    end
    else
    begin
        case(state)
            IDLE: begin
                cs_n <= 1'b1;  // Ensure cs_n is inactive in IDLE
                CE <= 0;
                //done_send <= 1'b1;
                
                if(load_data) begin
                    shiftReg <= data_in;
                    cs_inactive_counter <= 0;
                    delay_counter <= 0;
                    state <= CS_INACTIVE;
                    done_send <= 1'b0; 
                end else done_send           <= 1'b1;
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
                cs_n <= 1'b1;
                spi_data <= 1'b1;  // Set cs_n back to inactive state when done
                //done_send <= 1'b1;
            
                
                if(!load_data)begin
                    if(delay_counter==DELAY_VALUE)begin
                        state <= IDLE;
                        done_send <= 1'b1;end  
                     else delay_counter <= delay_counter+1;
                    end
            end
        endcase
    end
end
    
endmodule

`timescale 1ns/1ps

module top_module(
    input clk,
    input rst_n,
    input rx,
    input din_en,
    input start_sending,
    output spi_clock,
    output spi_data,
    output cs_n,
    // Debug signals
    output [6:0] seg1,seg2,seg3,seg4,
    output done_send,
    output m_valid,
    output [4:0] addr
);

    parameter   CS_INACTIVE_CYCLES = 1000,
                DIV_FACTOR = 100,
                DELAY_VALUE = 50000,
                CLOCK_FREQ = 50000000,
                STABLE_TIME_MS = 10,
                CLOCKS_PER_PULSE = 434,
                BITS_PER_WORD =8,
                W_OUT = 24 ;

    // Internal signals
    wire debounced_start,debounced_din_en,we,clk_div,load_data; 
    wire [W_OUT-1:0] controller_data_in,controller_data_out;
    wire [23:0] mem_data;


    uart_rx #(.CLOCKS_PER_PULSE(CLOCKS_PER_PULSE),.BITS_PER_WORD(BITS_PER_WORD),.W_OUT(W_OUT) ) uart_inst(
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .m_valid(m_valid),
        .m_data(controller_data_in)
);

    clock_divider #(.DIV_FACTOR(DIV_FACTOR)) clk_div_inst (
        .clk(clk),
        .clk_div(clk_div) 
    );

    spi_interface #(.CS_INACTIVE_CYCLES(CS_INACTIVE_CYCLES),.DELAY_VALUE(DELAY_VALUE)) spi_inst (
//        .clk(clk),
        .rst_n(rst_n),
        .clk_div(clk_div),
        .data_in(mem_data),
        .load_data(load_data),
        .done_send(done_send),
        .spi_clock(spi_clock),
        .spi_data(spi_data),
        .cs_n(cs_n)
    );

    debouncer #(.CLOCK_FREQ(CLOCK_FREQ),.STABLE_TIME_MS(STABLE_TIME_MS)) debouncer_inst_0 (
        .clk(clk),
        .rst_n(rst_n),
        .debounce(start_sending),
        .stable(debounced_start)
    );

    debouncer #(.CLOCK_FREQ(CLOCK_FREQ),.STABLE_TIME_MS(STABLE_TIME_MS)) debouncer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .debounce(din_en),
        .stable(debounced_din_en)
    );

    data_mem memory_inst (
        .clk(clk),
        .we(we),
        .data_in(controller_data_out),
        .addr(addr),
        .data_out(mem_data)
    );
    
    controller controller_inst (
        .clk(clk),
        .rst_n(rst_n),
        .clk_div(clk_div),
        .done_send(done_send),
        .start_sending(debounced_start),
        .addr(addr), // Address can be changed as needed
        .we(we),
        .load_data(load_data), // Load data signal (can be controlled as needed)
        .din_en(debounced_din_en), // Data input enable
        .data_valid(m_valid), // Data valid signal
        .data_in(controller_data_in),
        .data_out(controller_data_out)
    );

    sev_seg_decorder sev_seg_inst_0(
        .digit(controller_data_in[3:0]),
        .seg(seg1)
    );

    sev_seg_decorder sev_seg_inst_1(
        .digit(controller_data_in[7:4]),
        .seg(seg2)
    );

    sev_seg_decorder sev_seg_inst_2(
        .digit(controller_data_in[11:8]),
        .seg(seg3)
    );

    sev_seg_decorder sev_seg_inst_3(
        .digit(controller_data_in[15:12]),
        .seg(seg4)
    );
    
endmodule
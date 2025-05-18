module spi_top_2(
    input  clk,    // On-board Zynq clock (100 MHz)
    input  rst_n,
    output spi_clock,
    output spi_data,
    output reg status_led,
    output cs_n  // Optional status LED for debugging
);

    // Hardcoded 24-bit data to send
    reg [23:0] data_to_send ; // Example 24-bit data (can be changed as needed)
    
    // Signals for SPI contro
    reg load_data;
    wire done_send;
    
    // State machine for sending data
    reg [1:0] state;
    localparam IDLE     = 2'd0,
               SENDING  = 2'd1,
               COMPLETE = 2'd2;
    
    // Instantiate the SPI controller
    // Note: Assuming spiControl has been modified to handle 24-bit data
    spiControl spi_inst(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_to_send),  // Now passing 24-bit data
        .load_data(load_data),
        .done_send(done_send),
        .spi_clock(spi_clock),
        .spi_data(spi_data),
        .cs_n(cs_n)
    );
    
    // Simple state machine to initiate transmission
    always @(posedge clk) begin
        if (~rst_n) begin
            state <= IDLE;
            load_data <= 1'b0;
            status_led <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    load_data <= 1'b0;
                    status_led <= 1'b0;
                    // Start transmission immediately after reset or idle
                    state <= SENDING;
                end
                
                SENDING: begin
                    data_to_send <= 24'hABCDEF;  // Set the data (could be modified if needed)
                    load_data <= 1'b1;
                    
                    if (done_send) begin
                        load_data <= 1'b0;
                        state <= COMPLETE;
                    end
                end
                
                COMPLETE: begin
                    status_led <= 1'b1;  // Indicate completion
                    // Stay in COMPLETE state
                    // Can add logic to restart transmission if needed
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
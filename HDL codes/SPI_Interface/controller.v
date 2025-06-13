/*module controller (
    input clk,
    input rst_n,
    input clk_div,
    input done_send,
    input start_sending,      // User input: low = start SPI transmission
    input din_en,            // User input: low = enable UART data storage
    input data_valid,        // From UART RX (m_valid)
    output reg [4:0] addr,
    output reg we,
    output reg load_data
);

    // State definitions
    localparam IDLE         = 3'b000,
               UART_STORE   = 3'b001,
               SPI_PREP     = 3'b010,
               SPI_LOAD     = 3'b011,
               SPI_WAIT     = 3'b100,
               SPI_NEXT     = 3'b101,
               SPI_DONE     = 3'b110;

    reg [2:0] current_state, next_state;
    
    // Address counters
    reg [4:0] uart_addr_counter;    // For UART data storage
    reg [4:0] spi_addr_counter;     // For SPI data transmission
    
    // Maximum addresses (adjust based on your memory size)
    localparam UART_ADDR_MAX = 5'd15;  // Assuming 16 locations for UART storage
    localparam SPI_ADDR_MAX = 5'd15;   // Assuming 16 locations for SPI transmission
    
    // Edge detection for load_data acknowledgment
    reg load_data_prev;
    wire load_data_ack;
    
    always @(posedge clk_div or negedge rst_n) begin
        if (!rst_n)
            load_data_prev <= 1'b0;
        else
            load_data_prev <= load_data;
    end
    
    assign load_data_ack = load_data && !load_data_prev;

    // FSM sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // FSM combinational logic
    always @(*) begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (!din_en) begin
                    // UART data storage mode
                    next_state = UART_STORE;
                    next_state = UART_STORE;
                end else if (!start_sending) begin
                    // SPI transmission mode
                    next_state = SPI_PREP;
                end
            end
            
            UART_STORE: begin
                if (din_en) begin
                    // din_en went high, return to idle
                    next_state = IDLE;
                end
                // Stay in this state while din_en is low and store incoming UART data
            end
            
            SPI_PREP: begin
                // Prepare for SPI transmission
                next_state = SPI_LOAD;
            end
            
            SPI_LOAD: begin
                // Load data signal sent to SPI interface
                next_state = SPI_WAIT;
            end
            
            SPI_WAIT: begin
                if (done_send) begin
                    if (spi_addr_counter >= SPI_ADDR_MAX) begin
                        next_state = SPI_DONE;
                    end else begin
                        next_state = SPI_NEXT;
                    end
                end
            end
            
            SPI_NEXT: begin
                // Move to next address and load next data
                next_state = SPI_LOAD;
            end
            
            SPI_DONE: begin
                if (start_sending) begin
                    // start_sending went high, return to idle
                    next_state = IDLE;
                end
            end
        endcase
    end

    // Output logic and counters
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr <= 5'b0;
            we <= 1'b0;
            load_data <= 1'b0;
            uart_addr_counter <= 5'b0;
            spi_addr_counter <= 5'b0;
        end else begin
            // Default values
            we <= 1'b0;
            load_data <= 1'b0;
            
            case (current_state)
                IDLE: begin
                    // Reset counters when entering idle
                    if (!din_en) begin
                        // Entering UART mode, keep current UART counter
                        addr <= uart_addr_counter;
                    end else if (!start_sending) begin
                        // Entering SPI mode, reset SPI counter
                        spi_addr_counter <= 5'b0;
                        addr <= 5'b0;
                    end
                end
                
                UART_STORE: begin
                    addr <= uart_addr_counter;
                    
                    // Store UART data when valid data arrives
                    if (data_valid) begin
                        we <= 1'b1;
                        if (uart_addr_counter < UART_ADDR_MAX) begin
                            uart_addr_counter <= uart_addr_counter + 1'b1;
                        end else begin
                            uart_addr_counter <= 5'b0; // Wrap around
                        end
                    end
                end
                
                SPI_PREP: begin
                    // Set address for first SPI transmission
                    addr <= spi_addr_counter;
                end
                
                SPI_LOAD: begin
                    // Send load_data signal to SPI interface
                    load_data <= 1'b1;
                    addr <= spi_addr_counter;
                end
                
                SPI_WAIT: begin
                    // Wait for SPI transmission to complete
                    addr <= spi_addr_counter;
                end
                
                SPI_NEXT: begin
                    // Move to next address
                    spi_addr_counter <= spi_addr_counter + 1'b1;
                    addr <= spi_addr_counter + 1'b1;
                end
                
                SPI_DONE: begin
                    // Transmission complete, maintain current state
                    addr <= spi_addr_counter;
                end
            endcase*/
				
				
	module controller (
    input clk,                // Fast clock (UART domain)
    input rst_n,
    input clk_div,            // Slow clock (controller domain)
    input done_send,
    input start_sending,
    input din_en,
    input data_valid,         // From UART (fast clock domain)
    input [23:0] data_in,     // From UART (fast clock domain)
    output reg [4:0] addr,
    output reg we,
    output reg load_data,
    output reg [23:0] data_out // To memory
);

    // State parameters
    localparam IDLE        = 3'b000;
    localparam STORE_DATA  = 3'b001;
    localparam PREPARE_SPI = 3'b010;
    localparam LOAD_SPI    = 3'b011;
    localparam WAIT_SPI    = 3'b100;

    reg [2:0] state;
    reg [4:0] mem_addr;
    reg spi_active;
    
      // Memory parameters
      localparam MEM_SIZE = 16;
      localparam LAST_ADDR = 7;//MEM_SIZE - 1;
      
    // Handshake signals
    reg [23:0] data_buffer;
    reg data_ready;          // Flag indicating data is available
    reg data_ack;            // Acknowledge from slow domain

  // Synchronizer for data_valid (fast to slow domain)
    reg data_valid_sync0, data_valid_sync1;
    always @(posedge clk_div or negedge rst_n) begin
        if (!rst_n) begin
            data_valid_sync0 <= 0;
            data_valid_sync1 <= 0;
        end else begin
            data_valid_sync0 <= data_valid;
            data_valid_sync1 <= data_valid_sync0;
        end
    end

    // Detect rising edge of synchronized data_valid
   wire data_valid_edge = data_valid_sync1 && !data_ack;

    // Fast clock domain: Capture UART data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_buffer <= 0;
            data_ready <= 0;
        end else if (data_valid && !data_ready) begin
            data_buffer <= data_in;
            data_ready <= 1;
        end else if (data_ack) begin
            data_ready <= 0;
        end
    end

    // Slow clock domain: Controller logic
    always @(posedge clk_div or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            addr <= 0;
            mem_addr <= 0;
            we <= 0;
            load_data <= 0;
            spi_active <= 0;
            data_ack <= 0;
            data_out <= 0;
        end
        else begin
            // Default outputs
            we <= 0;
            load_data <= 0;
            data_ack <= 0;

            case (state)
                IDLE: begin
                    if (!din_en) begin
                        state <= STORE_DATA;
                        mem_addr <= 0;
                        spi_active <= 0;
                    end
                    else if (!start_sending && din_en) begin
                        state <= PREPARE_SPI;
                        mem_addr <= 0;
                        spi_active <= 1;
                    end
                end

                STORE_DATA: begin
                    if (data_ready) begin
                        // Store the buffered data
                        we <= 1;
                        addr <= mem_addr;
                        data_out <= data_buffer;
                        data_ack <= 1;
                        
                        if (mem_addr < LAST_ADDR)
                            mem_addr <= mem_addr + 1;
                        else
                            mem_addr <= 0;
                    end

                    if (din_en)
                        state <= IDLE;
                end

                PREPARE_SPI: begin
                    addr <= mem_addr;
                    state <= LOAD_SPI;
                end

                LOAD_SPI: begin
                    load_data <= 1;
                    state <= WAIT_SPI;
                end

                WAIT_SPI: begin
                    if (done_send) begin
                        if (mem_addr < LAST_ADDR) begin
                            mem_addr <= mem_addr + 1;
                            state <= PREPARE_SPI;
                        end
                        else begin
                            //state <= IDLE;
                            spi_active <= 0;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
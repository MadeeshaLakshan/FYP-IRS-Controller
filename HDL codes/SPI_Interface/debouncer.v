module debouncer #(
    parameter CLOCK_FREQ = 50000000, // 50 MHz
    parameter STABLE_TIME_MS = 10
    ) (
    input clk,
    input rst_n,
    input debounce,
    output stable
);

localparam COUNTER_MAX = (CLOCK_FREQ * STABLE_TIME_MS)/1000;

reg [1:0] ff_i;
reg       ff_0;
reg [$clog2(COUNTER_MAX)-1:0] counter;

wire clear_counter ,couter_max;

//remove any metastability
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ff_i <= 2'b00;
    end else begin
        ff_i <= {ff_i[0], debounce};
    end
end
assign clear_counter = ff_i[1] ^ ff_i[0];

//count the stable signal
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 0;
    end else if (clear_counter) begin
        counter <= 0;
    end else if (counter < COUNTER_MAX) begin
        counter <= counter + 1;
    end
end    

//check if the counter has reached the maximum value
assign couter_max = (counter == COUNTER_MAX);
//output the stable signal
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ff_0 <= 1'b0;
    end else if (clear_counter) begin
        ff_0 <= debounce;
    end else if (couter_max) begin
        ff_0 <= ff_i[1];
    end
end
assign stable = ff_0;
endmodule
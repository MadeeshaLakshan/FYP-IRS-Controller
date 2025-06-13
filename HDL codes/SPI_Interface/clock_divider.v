module clock_divider #(
    parameter DIV_FACTOR = 10
) (
    input clk,
    output reg  clk_div
);
    reg[$clog2(DIV_FACTOR)-1:0] counter = 0;

    always @(posedge clk) begin
        if (counter != DIV_FACTOR - 1) begin
            counter <= counter + 1;
        end else begin
            counter <= 0;
        end
    end
    initial
        clk_div <= 0;

    always @(posedge clk) begin
        if (counter == DIV_FACTOR - 1) begin
            clk_div <= ~clk_div;
        end
    end
    
endmodule
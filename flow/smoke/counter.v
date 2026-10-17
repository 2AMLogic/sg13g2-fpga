// Throwaway smoke fixture for the klt digital flow (issue #5). Not the tile.
module counter (
    input  wire       clk,
    input  wire       rst,   // synchronous, active high
    output reg  [7:0] q
);
    always @(posedge clk) begin
        if (rst) q <= 8'd0;
        else     q <= q + 8'd1;
    end
endmodule

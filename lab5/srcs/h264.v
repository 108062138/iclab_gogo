module h264(
    input              clk,
    input              rst_n,
    input              in_valid_data,
    input      [7:0]   data,
    input              in_valid_param,
    input      [3:0]   index,
    input              mode,
    input      [5-1:0]   QP,
    output reg         out_valid,
    output reg [32-1:0]  out_value
);

always @(posedge clk or negedge rst_n) begin
    out_valid = 0;
    out_value = 0;
end

endmodule
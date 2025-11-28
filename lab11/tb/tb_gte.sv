module tb_gte;

wire clk;
wire rst_n;
wire in_valid_data;
wire [7:0] data;
wire in_valid_cmd;
wire [17:0] cmd;
wire busy;

gte u_GTE(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid_data(in_valid_data),
    .data(data),
    .in_valid_cmd(in_valid_cmd),
    .cmd(cmd),
    .busy(busy)
);

PATTERN u_GTE_PATTERN(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid_data(in_valid_data),
    .data(data),
    .in_valid_cmd(in_valid_cmd),
    .cmd(cmd),
    .busy(busy)
);

endmodule
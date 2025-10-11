module BRAM_single_port #(
    parameter addr_width = 7,
    parameter data_width = 128
) (
    input                        clk,
    input                        rst_n,
    input                        we,
    input      [data_width-1:0]  strobe,
    input      [addr_width-1:0]  addr,
    input      [data_width-1:0]  din,
    output reg [data_width-1:0]  dout
);
reg [data_width-1:0] mem [0:(1<<addr_width)-1];
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout <= 0;
    end else begin
        if (we) begin
            mem[addr] <= (din & strobe) | (mem[addr] & ~strobe);
        end
        dout <= mem[addr];
    end
end
endmodule
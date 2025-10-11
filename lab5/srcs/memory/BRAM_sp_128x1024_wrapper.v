// to imitate SRAM behavior, we should add flip flop to BRAM's I/O
module BRAM_sp_128x1024_wrapper #(
    parameter addr_width = 7,
    parameter data_width = 1024
)(
    input                        clk,
    input                        rst_n,
    input                        we,
    input      [data_width-1:0]  strobe,
    input      [addr_width-1:0]  addr,
    input      [data_width-1:0]  din,
    output reg [data_width-1:0]  dout
);
wire [data_width-1:0] bram_dout;

reg [data_width-1:0] bram_din;
reg [addr_width-1:0]  bram_addr;
reg                  bram_we;
reg [data_width-1:0] bram_strobe;

BRAM_single_port_128x1024 #(
    .addr_width(addr_width),
    .data_width(data_width)
) u_BRAM_single_port_128x1024 (
    .clk(clk),
    .rst_n(rst_n),
    .we(bram_we),
    .strobe(bram_strobe),
    .addr(bram_addr),
    .din(bram_din),
    .dout(bram_dout)
);

always @(posedge clk) begin
    // Register inputs to BRAM
    bram_we <= we;
    bram_strobe <= strobe;
    bram_addr <= addr;
    bram_din <= din;
    // Register output from BRAM
    dout <= bram_dout;
    
end

endmodule
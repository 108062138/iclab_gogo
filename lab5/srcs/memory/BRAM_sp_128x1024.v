module BRAM_single_port_128x1024 #(
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

// localparam blk_data_width = data_width >> 3; // 128
// localparam num_blk_involved = data_width / blk_data_width; // 8
// genvar i;
// generate
//     for (i = 0; i < num_blk_involved; i = i + 1) begin : gen_bram_single_port
//         BRAM_single_port #(
//             .addr_width(addr_width),
//             .data_width(blk_data_width)
//         ) u_BRAM_single_port (
//             .clk(clk),
//             .rst_n(rst_n),
//             .we(we),
//             .strobe(strobe[(i+1)*blk_data_width-1:i*blk_data_width]),
//             .addr(addr),
//             .din(din[(i+1)*blk_data_width-1:i*blk_data_width]),
//             .dout(dout[(i+1)*blk_data_width-1:i*blk_data_width])
//         );
//     end
// endgenerate

localparam big_h = 128;
localparam big_w = 1024;

reg [big_w-1:0] mem [0:big_h-1];
reg [32-1:0] cnt;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        dout <= 0;
        cnt <= 0;
    end else begin
        if(we)begin
            mem[addr] <= (din & strobe) | (mem[addr] & ~strobe);
            cnt <= cnt+1;
        end
        dout <= mem[addr];
    end

end

endmodule
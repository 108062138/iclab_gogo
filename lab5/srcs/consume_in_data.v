`include "h264_def.vh"

module consume_in_data (
    input clk,
    input rst_n,
    input [`tc_state_width-1:0] tc_state,
    input in_valid_data, // should be asserted as 1 once enter rcv data??
    input [`din_width-1:0] data,
    output reg                  consume_in_data_vec_wen,
    output reg [`sram_addr_width-1:0] consume_in_data_vec_addr,
    output reg [`sram_row_width-1:0]  consume_in_data_vec_data,
    output reg [`sram_row_width-1:0]  consume_in_data_vec_strobe,
    output done_rcv_in_data
);

localparam at_most_rcv_data = 16384;
localparam at_most_snd_vec = 128;

localparam int ROW_CHUNKS = `sram_row_width / `din_width; // 1024/8=128
localparam int JW         = (ROW_CHUNKS <= 1) ? 1 : $clog2(ROW_CHUNKS);

reg [`sram_row_width-1:0] row_buffer, n_row_buffer;
reg [16-1:0] rcv_cnt, n_rcv_cnt;
reg [16-1:0] snd_cnt, n_snd_cnt;
reg [7-1:0] at_j;
reg [8-1:0] at_i;
assign done_rcv_in_data = (snd_cnt == at_most_snd_vec);

always @(*) begin
    at_j = ROW_CHUNKS[JW-1:0] - rcv_cnt[JW-1:0] - 1;
    at_i = snd_cnt[`sram_addr_width-1:0];
end

always @* begin
    n_snd_cnt                 = snd_cnt;
    consume_in_data_vec_wen   = 1'b0;
    consume_in_data_vec_addr  = at_i;
    consume_in_data_vec_strobe= {`sram_row_width{1'b0}};
    consume_in_data_vec_data  = row_buffer;   // default; overridden on last byte
    if (tc_state == `tc_rcv_in_data && snd_cnt < at_most_snd_vec && at_j==0 && (rcv_cnt != 0)) begin
        n_snd_cnt                 = snd_cnt + 16'd1;
        consume_in_data_vec_wen   = 1'b1;
        consume_in_data_vec_addr  = at_i;
        consume_in_data_vec_strobe= {`sram_row_width{1'b1}};
        consume_in_data_vec_data  = n_row_buffer;
    end
end

always @* begin
    n_rcv_cnt    = rcv_cnt;
    n_row_buffer = row_buffer;
    if (tc_state == `tc_rcv_in_data && in_valid_data) begin
        n_row_buffer[(at_j*`din_width) +: `din_width] = data;
        n_rcv_cnt = rcv_cnt + 1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        rcv_cnt <= 0;
        snd_cnt <= 0;
        row_buffer <= 0;
    end else begin
        rcv_cnt <= n_rcv_cnt;
        snd_cnt <= n_snd_cnt;
        row_buffer <= n_row_buffer;
    end
end

endmodule
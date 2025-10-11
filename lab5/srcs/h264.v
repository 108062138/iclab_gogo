module h264 #(
    parameter din_width = 8,
    parameter dout_width = 32,
    parameter mode_width = 4,
    parameter index_width = 4,
    parameter QP_width = 5
)(
    input               clk,
    input               rst_n,
    input               in_valid_data,
    input      [din_width-1:0]    data,
    input               in_valid_param,
    input      [index_width-1:0]    index,
    input               mode,
    input      [QP_width-1:0]  QP,
    output reg          out_valid,
    output reg [dout_width-1:0] out_value
);

localparam sram_addr_width = 7;
localparam sram_row_width = 1024;

localparam tc_idle = 0;
localparam tc_rcv_in_data = 1;
localparam tc_rcv_in_param = 2;
localparam tc_consume_frame = 3;
localparam tc_done = 4;
localparam tc_state_width = 4;

reg [tc_state_width-1:0] tc_state, n_tc_state;
reg tc_wen;
reg [sram_row_width-1:0]  tc_strobe;
reg [sram_row_width-1:0]  tc_din;
reg [sram_addr_width-1:0]  tc_addr;
wire [sram_row_width-1:0] tc_dout;

wire                       consume_in_data_wen;
wire [sram_addr_width-1:0] consume_in_data_addr;
wire [sram_row_width-1:0]  consume_in_data_wdata;
wire [sram_row_width-1:0]  consume_in_data_strobe;

wire                       consume_frame_wen;
wire [sram_addr_width-1:0] consume_frame_addr;
wire [sram_row_width-1:0]  consume_frame_wdata;
wire [sram_row_width-1:0]  consume_frame_strobe;

wire [index_width-1:0] ff_index;
wire [mode_width-1:0] ff_mode;
wire [QP_width-1:0] ff_QP;

wire done_rcv_in_data, done_rcv_in_param, done_consume_frame;

always @(*) begin
    case(tc_state)
    tc_rcv_in_data:begin
        tc_wen = consume_in_data_wen;
        tc_addr = consume_in_data_addr;
        tc_din = consume_in_data_wdata;
        tc_strobe = consume_in_data_strobe;
    end
    tc_consume_frame:begin
        tc_wen =    consume_frame_wen;
        tc_addr =   consume_frame_addr;
        tc_din =    consume_frame_wdata;
        tc_strobe = consume_frame_strobe;
    end
    default:begin
        tc_wen = 0;
        tc_addr = 0;
        tc_din = 0;
        tc_strobe = 0;
    end
    endcase
end

always @(*) begin
    case(tc_state)
    tc_idle:begin
        n_tc_state = tc_rcv_in_data;
    end
    tc_rcv_in_data: begin
        if(done_rcv_in_data) n_tc_state = tc_rcv_in_param;
        else n_tc_state = tc_rcv_in_data;
    end
    tc_rcv_in_param: begin
        if(done_rcv_in_param) n_tc_state = tc_consume_frame;
        else n_tc_state = tc_rcv_in_param;
    end
    tc_consume_frame:begin
        if(done_consume_frame) n_tc_state = tc_done;
        else n_tc_state = tc_consume_frame;
    end
    tc_done:begin
        n_tc_state = tc_rcv_in_param;
    end
    default: n_tc_state = tc_state;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        tc_state <= tc_idle;
    end else begin
        tc_state <= n_tc_state;
    end
end

BRAM_sp_128x1024_wrapper #(.addr_width(sram_addr_width), .data_width(sram_row_width)) u_BRAM_sp_128x1024_wrapper (
    .clk(clk),
    .rst_n(rst_n),
    .we(tc_wen),
    .strobe(tc_strobe),
    .addr(tc_addr),
    .din(tc_din),
    .dout(tc_dout)
);

consume_in_data #( .tc_state_width(tc_state_width), .addr_width(sram_addr_width), .din_width(din_width), .sram_row_width(sram_row_width)) u_consume_in_data (
    .clk(clk),
    .rst_n(rst_n),
    .tc_state(tc_state),
    .in_valid_data(in_valid_data),
    .data(data),
    .consume_in_data_vec_wen(consume_in_data_wen),
    .consume_in_data_vec_data(consume_in_data_wdata),
    .consume_in_data_vec_addr(consume_in_data_addr),
    .consume_in_data_vec_strobe(consume_in_data_strobe),
    .done_rcv_in_data(done_rcv_in_data)
);

consume_in_param #( .tc_state_width(tc_state_width), .QP_width(QP_width), .index_width(index_width), .mode_width(mode_width)) u_consume_in_param (
    .clk(clk),
    .rst_n(rst_n),
    .tc_state(tc_state),
    .in_valid_param(in_valid_param),
    .QP(QP),
    .index(index),
    .mode(mode),
    .ff_QP(ff_QP),
    .ff_index(ff_index),
    .ff_mode(ff_mode),
    .done_rcv_in_param(done_rcv_in_param)
);

consume_single_frame  #( .tc_state_width(tc_state_width), .QP_width(QP_width), .index_width(index_width), .mode_width(mode_width), .sram_addr_width(sram_addr_width), .sram_row_width(sram_row_width) )u_consume_single_frame(
    .clk(clk),
    .rst_n(rst_n),
    .tc_state(tc_state),
    .ff_QP(ff_QP),
    .ff_index(ff_index),
    .ff_mode(ff_mode),
    .sram_addr(consume_frame_addr),
    .sram_wen(consume_frame_wen),
    .sram_strobe(consume_frame_strobe),
    .sram_wdata(consume_frame_wdata),
    .sram_dout(tc_dout),
    .done_consume_frame(done_consume_frame)
);

endmodule
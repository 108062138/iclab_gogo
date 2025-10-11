module consume_in_param #(
    parameter tc_state_width = 4,
    parameter QP_width = 5,
    parameter index_width = 4,
    parameter mode_width = 4
) (
    input clk,
    input rst_n,
    input [tc_state_width-1:0] tc_state,
    input in_valid_param,
    input [QP_width-1:0] QP,
    input [index_width-1:0] index,
    input mode,
    output reg [QP_width-1:0] ff_QP,
    output reg [index_width-1:0] ff_index,
    output reg [mode_width-1:0] ff_mode,
    output done_rcv_in_param
);

localparam at_most_rcv_param = 4;

localparam tc_idle = 0;
localparam tc_rcv_in_data = 1;
localparam tc_rcv_in_param = 2;
localparam tc_consume_frame = 3;
localparam tc_done = 4;

reg [3:0] cnt, n_cnt;
reg [QP_width-1:0] n_ff_QP;
reg [index_width-1:0] n_ff_index;
reg [mode_width-1:0] n_ff_mode;

assign done_rcv_in_param = (cnt==at_most_rcv_param);

always @(*) begin
    n_cnt      = cnt;
    n_ff_QP    = ff_QP;
    n_ff_index = ff_index;
    n_ff_mode  = ff_mode;

    if(tc_state==tc_rcv_in_param)begin
        if(in_valid_param)begin
            if(cnt==0)begin
                n_ff_index = index;
                n_ff_QP = QP;
            end
            n_ff_mode[mode_width - cnt - 1] = mode;
            n_cnt = cnt + 1;
        end
    end else if(tc_state==tc_done) begin
        n_cnt = 0;
        n_ff_QP = ff_QP;
        n_ff_index = ff_index;
        n_ff_mode = ff_mode;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        cnt <= 0;
        ff_QP    <= 0;
        ff_index <= 0;
        ff_mode  <= 0;
    end else begin 
        cnt <= n_cnt;
        ff_QP    <= n_ff_QP;
        ff_index <= n_ff_index;
        ff_mode  <= n_ff_mode;
    end
end

endmodule
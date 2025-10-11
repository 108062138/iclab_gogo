module consume_single_frame #(
    parameter tc_state_width = 4,
    parameter QP_width = 5,
    parameter index_width = 4,
    parameter mode_width = 4,
    parameter sram_addr_width = 7,
    parameter sram_row_width = 1024
)(
    input clk,
    input rst_n,
    input [tc_state_width-1:0] tc_state,
    input [QP_width-1:0] ff_QP,
    input [index_width-1:0] ff_index,
    input [mode_width-1:0] ff_mode,
    output reg [sram_addr_width-1:0] sram_addr,
    output reg [sram_addr_width-1:0] sram_wen,
    output reg [sram_row_width-1:0] sram_strobe,
    output reg [sram_row_width-1:0] sram_wdata,
    input [sram_row_width-1:0] sram_dout,
    output done_consume_frame
);

localparam tc_idle = 0;
localparam tc_rcv_in_data = 1;
localparam tc_rcv_in_param = 2;
localparam tc_consume_frame = 3;
localparam tc_done = 4;

localparam csf_idle = 0;
localparam csf_load_frame = 1;
localparam csf_load_T_L = 2;
localparam csf_predict = 3;
localparam csf_int_trans = 4;
localparam csf_quantize = 5;
localparam csf_de_quantize = 6;
localparam csf_rev_int_trans = 7;
localparam csf_recover = 8;
localparam csf_done_frame = 9;
localparam csf_state_width = 5;

localparam frame_h = 32;
localparam frame_w = 32*8;
localparam macro_blk_size = 128;

reg [csf_state_width-1:0] csf_state, n_csf_state;
reg [frame_w-1:0] frame [0:frame_h-1];
reg [frame_w-1:0] n_frame [0:frame_h-1];
reg [4:0] load_frame_cnt, n_load_frame_cnt;
reg [macro_blk_size-1:0] A[0:4-1];
reg [macro_blk_size-1:0] B [0:4-1];
wire [sram_addr_width-1:0] blk_base_addr;
wire [sram_addr_width-1:0] target_addr;

assign done_consume_frame = (csf_state==csf_done_frame);
assign blk_base_addr = ff_index << 3;

always @(*) begin
    n_load_frame_cnt = load_frame_cnt;
    if(csf_state==csf_load_frame)begin
        n_load_frame_cnt = load_frame_cnt + 1;
    end else if(csf_state==csf_idle) begin
        n_load_frame_cnt = 0;
    end
end

always @(*) begin
    case (csf_state)
        csf_idle: begin
            if(tc_state==tc_consume_frame)begin
                n_csf_state = csf_load_frame;
            end else begin
                n_csf_state = csf_idle;
            end
        end
        csf_load_frame: begin
            // for now, naive pull out the content and store them into big frame
            if(load_frame_cnt<15) n_csf_state = csf_load_frame;
            else n_csf_state = csf_load_T_L;
        end
        csf_load_T_L: n_csf_state = csf_predict;
        csf_predict: n_csf_state = csf_int_trans;
        csf_int_trans: n_csf_state = csf_quantize;
        csf_quantize: n_csf_state = csf_de_quantize;
        csf_de_quantize: n_csf_state = csf_rev_int_trans;
        csf_rev_int_trans: n_csf_state = csf_recover;
        csf_recover: n_csf_state = csf_done_frame;
        csf_done_frame: n_csf_state = csf_idle;
        default: begin
            n_csf_state = csf_state;
        end
    endcase
end

always @(*) begin
    // update frame reg when possible
    {A[0], B[0], A[1], B[1], A[2], B[2], A[3], B[3]} = sram_dout;
    n_frame = frame;
    if(csf_state==csf_load_frame && load_frame_cnt>=3)begin
        if(load_frame_cnt==3)begin
            n_frame[0] = {A[0], B[0]};
            n_frame[1] = {A[1], B[1]};
            n_frame[2] = {A[2], B[2]};
            n_frame[3] = {A[3], B[3]};
        end else if(load_frame_cnt==4)begin
            n_frame[4] = {A[0], B[0]};
            n_frame[5] = {A[1], B[1]};
            n_frame[6] = {A[2], B[2]};
            n_frame[7] = {A[3], B[3]};
        end else if(load_frame_cnt==5)begin
            n_frame[8] = {A[0], B[0]};
            n_frame[9] = {A[1], B[1]};
            n_frame[10] = {A[2], B[2]};
            n_frame[11] = {A[3], B[3]};
        end else if(load_frame_cnt==6)begin
            n_frame[12] = {A[0], B[0]};
            n_frame[13] = {A[1], B[1]};
            n_frame[14] = {A[2], B[2]};
            n_frame[15] = {A[3], B[3]};
        end else if(load_frame_cnt==7)begin
            n_frame[16] = {A[0], B[0]};
            n_frame[17] = {A[1], B[1]};
            n_frame[18] = {A[2], B[2]};
            n_frame[19] = {A[3], B[3]};
        end else if(load_frame_cnt==8)begin
            n_frame[20] = {A[0], B[0]};
            n_frame[21] = {A[1], B[1]};
            n_frame[22] = {A[2], B[2]};
            n_frame[23] = {A[3], B[3]};
        end else if(load_frame_cnt==9)begin
            n_frame[24] = {A[0], B[0]};
            n_frame[25] = {A[1], B[1]};
            n_frame[26] = {A[2], B[2]};
            n_frame[27] = {A[3], B[3]};
        end else if(load_frame_cnt==10)begin
            n_frame[28] = {A[0], B[0]};
            n_frame[29] = {A[1], B[1]};
            n_frame[30] = {A[2], B[2]};
            n_frame[31] = {A[3], B[3]};
        end
    end

    sram_addr = blk_base_addr;
    if(csf_state==csf_load_frame)begin
        sram_addr = blk_base_addr + load_frame_cnt;
    end
    sram_wen = 0;
    sram_strobe = 0;
    sram_wdata = 0;
end
integer i;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        csf_state <= csf_idle;
        load_frame_cnt <= 0;
        frame <= '{default: 0};
    end else begin
        csf_state <= n_csf_state;
        load_frame_cnt <= n_load_frame_cnt;
        frame <= n_frame;
    end
    if(csf_state==csf_load_frame)begin
        $display("want addr: %d and receive: %h", sram_addr, sram_dout);
    end
    if(csf_state==csf_done_frame)begin
        for(i=0;i<32;i=i+1)begin
            $display("%h", frame[i]);
        end
    end
end

endmodule

/*
6566676767676665656768676564656766666666676767676666666666666666
6666666666666666666767676565666766666666676767676666666666666666
6766666565666667666666666666666666666666676767676666666666666666
6766666666666667676665666767666567676767666666666666666666666666
*/
`include "h264_def.vh"

module consume_single_frame (
    input clk,
    input rst_n,
    input [`tc_state_width-1:0] tc_state,
    input [`QP_width-1:0] ff_QP,
    input [`index_width-1:0] ff_index,
    input [`mode_width-1:0] ff_mode,
    output reg [`sram_addr_width-1:0] sram_addr,
    output reg [`sram_addr_width-1:0] sram_wen,
    output reg [`sram_row_width-1:0] sram_strobe,
    output reg [`sram_row_width-1:0] sram_wdata,
    input [`sram_row_width-1:0] sram_dout,
    output done_consume_frame
);

reg [`csf_state_width-1:0] csf_state, n_csf_state;

reg [`step_width-1:0] max_macro_step;
reg [`step_width-1:0] macro_step, n_macro_step;

reg [`step_width-1:0] max_sub_step, n_max_sub_step;
reg [`step_width-1:0] sub_step, n_sub_step;

reg [`macro_width-1:0] macro_blk [0:`macro_height-1];
reg [`macro_width-1:0] n_macro_blk [0:`macro_height-1];
reg [`macro_width*`macro_height-1:0] one_d_macro_blk;
reg [5-1:0] cnt_macro_blk, n_cnt_macro_blk;

wire [`en_bitmap_width-1:0] en_bitmap;
wire [`TL_width_mode_0-1:0] T_mode_0;
wire [`TL_width_mode_0-1:0] L_mode_0;
wire [`TL_width_mode_1-1:0] T_mode_1;
wire [`TL_width_mode_1-1:0] L_mode_1;
wire [`step_width-1:0] macro_i, macro_j, frame_i, frame_j;
reg [`sram_addr_width-1:0] frame_water_mark, macro_water_mark, sub_water_mark;
reg [`macro_width-1:0] A [0:4-1];
reg [`macro_width-1:0] B [0:4-1];
reg [5-1:0] sub_width, sub_height;

integer i;

assign done_consume_frame = (csf_state == `csf_done);

always @(*) begin
    frame_water_mark = ff_index << 3;
    macro_water_mark = (macro_step<2)?frame_water_mark: frame_water_mark + 4;
    sub_water_mark = 0;//??
    if(max_sub_step==1)begin
        sub_width = 16*8;
        sub_height = 16;
    end else begin
        sub_width = 4*8;
        sub_height = 4;
    end
    one_d_macro_blk = {macro_blk[0], macro_blk[1], macro_blk[2], macro_blk[3], macro_blk[4], macro_blk[5], macro_blk[6], macro_blk[7], macro_blk[8], macro_blk[9], macro_blk[10], macro_blk[11], macro_blk[12], macro_blk[13], macro_blk[14], macro_blk[15]};
    // sram relate
    {A[0], B[0], A[1], B[1], A[2], B[2], A[3], B[3]} = sram_dout;
    sram_addr = macro_water_mark + cnt_macro_blk - 1;
    sram_wdata = 0;
    sram_wen = 0;
    // update regfile
    n_macro_blk = macro_blk;
    if(csf_state==`csf_set_macro_blk && cnt_macro_blk>=4)begin
        if(macro_step[0]==0)begin
            if(cnt_macro_blk==4)begin
                n_macro_blk[0] = A[0];
                n_macro_blk[1] = A[1];
                n_macro_blk[2] = A[2];
                n_macro_blk[3] = A[3];
            end else if(cnt_macro_blk==5)begin
                n_macro_blk[4] = A[0];
                n_macro_blk[5] = A[1];
                n_macro_blk[6] = A[2];
                n_macro_blk[7] = A[3];
            end else if(cnt_macro_blk==6)begin
                n_macro_blk[8] = A[0];
                n_macro_blk[9] = A[1];
                n_macro_blk[10] = A[2];
                n_macro_blk[11] = A[3];
            end else if(cnt_macro_blk==7)begin
                n_macro_blk[12] = A[0];
                n_macro_blk[13] = A[1];
                n_macro_blk[14] = A[2];
                n_macro_blk[15] = A[3];
            end
        end else begin
            if(cnt_macro_blk==4)begin
                n_macro_blk[0] = B[0];
                n_macro_blk[1] = B[1];
                n_macro_blk[2] = B[2];
                n_macro_blk[3] = B[3];
            end else if(cnt_macro_blk==5)begin
                n_macro_blk[4] = B[0];
                n_macro_blk[5] = B[1];
                n_macro_blk[6] = B[2];
                n_macro_blk[7] = B[3];
            end else if(cnt_macro_blk==6)begin
                n_macro_blk[8] = B[0];
                n_macro_blk[9] = B[1];
                n_macro_blk[10] = B[2];
                n_macro_blk[11] = B[3];
            end else if(cnt_macro_blk==7)begin
                n_macro_blk[12] = B[0];
                n_macro_blk[13] = B[1];
                n_macro_blk[14] = B[2];
                n_macro_blk[15] = B[3];
            end
        end
    end
end

always @(*) begin
    n_cnt_macro_blk = cnt_macro_blk;
    if(csf_state==`csf_set_macro_blk)begin
        n_cnt_macro_blk = cnt_macro_blk + 1;
    end else if(csf_state==`csf_determine_macro_blk) n_cnt_macro_blk = 0;
end

always @(*) begin
    n_csf_state = csf_state;
    n_macro_step = macro_step;
    n_max_sub_step = max_sub_step;
    n_sub_step = sub_step;
    case (csf_state)
        `csf_idle:begin
           if(tc_state==`tc_consume_frame) n_csf_state = `csf_load_frame; 
        end
        `csf_load_frame: n_csf_state = `csf_init_cursor;
        `csf_init_cursor: begin
            n_csf_state = `csf_determine_macro_blk;
            n_macro_step = 0;
        end
        `csf_determine_macro_blk:begin
            if(macro_step>=max_macro_step) n_csf_state = `csf_done;
            else n_csf_state = `csf_set_macro_blk;
        end
        `csf_set_macro_blk: begin
            if(cnt_macro_blk>10) n_csf_state = `csf_determine_sub_blk;

            if(macro_step==0)      n_max_sub_step = (ff_mode[4-0-1])? 16: 1;
            else if(macro_step==1) n_max_sub_step = (ff_mode[4-1-1])? 16: 1;
            else if(macro_step==2) n_max_sub_step = (ff_mode[4-2-1])? 16: 1;
            else if(macro_step==3) n_max_sub_step = (ff_mode[4-3-1])? 16: 1;
            n_sub_step = 0;
        end
        `csf_determine_sub_blk:begin
            if(sub_step>=max_sub_step) n_csf_state = `csf_update_macro_step;
            else n_csf_state = `csf_set_TL;
        end
        `csf_set_TL:begin
            n_csf_state = `csf_CAL;

        end
        `csf_CAL: n_csf_state = `csf_update_sub_step; // here
        `csf_update_sub_step: begin
            n_csf_state = `csf_determine_sub_blk;
            n_sub_step = sub_step + 1;
        end
        `csf_update_macro_step: begin
            n_csf_state = `csf_determine_macro_blk;
            n_macro_step = macro_step + 1;
        end
        `csf_done:begin
            if(tc_state!=`tc_done) n_csf_state = `csf_idle;
        end
        default: n_csf_state = csf_state;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        csf_state <= `csf_idle;
        max_macro_step <= 4;
        macro_step <= 0;
        max_sub_step <= 16; // default
        sub_step <= 0;
        
        macro_blk <= '{default: 0};
        cnt_macro_blk <= 0;
    end else begin
        csf_state <= n_csf_state;
        max_macro_step <= 4;
        macro_step <= n_macro_step;
        max_sub_step <= n_max_sub_step;
        sub_step <= n_sub_step;

        macro_blk <= n_macro_blk;
        cnt_macro_blk <= n_cnt_macro_blk;
    end

    if(csf_state==`csf_determine_sub_blk)begin
        $display("see macro %d and sub %d", macro_step, sub_step);
    end
    if(csf_state==`csf_set_macro_blk && cnt_macro_blk<=3)begin
        $display("use addr %d to form macro", sram_addr);
    end
    if(csf_state==`csf_set_macro_blk && cnt_macro_blk==9)begin
        for(i=0;i<16;i=i+1)begin
            $display("OBTAIN macro: %h", macro_blk[i]);
        end
    end
    if(csf_state==`csf_CAL)begin
        if(ff_mode[4-macro_step-1]==0)begin
            $display("SET mode0 TL T: %h", T_mode_0);
            $display("SET mode0 TL L: %h", L_mode_0);
        end else begin
            $display("SET mode0 TL T: %h", T_mode_1);
            $display("SET mode0 TL L: %h", L_mode_1);
        end
    end
    if(csf_state==`csf_determine_sub_blk)begin
        $display("[%s, %s, %s]", en_bitmap[`dc] ? "dc" : "_", en_bitmap[`h]  ? "h" : "_", en_bitmap[`v]  ? "v" : "_");
    end
end

handle_mode_0_T_L u_handle_mode_0_T_L (
    .clk(clk),
    .rst_n(rst_n),
    .sram_dout(sram_dout),
    .csf_state(csf_state),
    .macro_step(macro_step),
    .cnt_macro_blk(cnt_macro_blk),
    .T_mode_0(T_mode_0),
    .L_mode_0(L_mode_0)
);

handle_mode_1_T_L u_handle_mode_1_T_L (
    .clk(clk),
    .rst_n(rst_n),
    .csf_state(csf_state),
    .macro_step(macro_step),
    .sub_step(sub_step),
    .one_d_macro_blk(one_d_macro_blk),
    .en_bitmap(en_bitmap),
    .macro_i(macro_i),
    .macro_j(macro_j),
    .T_mode_1(T_mode_1),
    .L_mode_1(L_mode_1)
);

handle_en_bitmap u_handle_en_bitmap(
    .macro_step(macro_step),
    .sub_step(sub_step),
    .en_bitmap(en_bitmap)
);

decode_at_row_at_col u_decode_at_row_at_col (
    .macro_step(macro_step),
    .sub_step(sub_step),
    .macro_i(macro_i),
    .macro_j(macro_j),
    .frame_i(frame_i),
    .frame_j(frame_j)
);

endmodule
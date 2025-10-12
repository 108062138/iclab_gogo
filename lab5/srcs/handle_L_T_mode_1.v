`include "h264_def.vh"

module handle_mode_1_T_L (
    input clk,
    input rst_n,
    input [`csf_state_width-1:0] csf_state,
    input [`step_width-1:0] macro_step,
    input [`step_width-1:0] sub_step,
    input [`macro_width*`macro_height-1:0] one_d_macro_blk,
    input [`en_bitmap_width-1:0] en_bitmap,
    input [`step_width-1:0] macro_i,
    input [`step_width-1:0] macro_j,
    output reg [`TL_width_mode_1-1:0] T_mode_1,
    output reg [`TL_width_mode_1-1:0] L_mode_1
);

reg [`macro_width-1:0] macro_blk [0:`macro_height-1];
reg [`TL_width_mode_1-1:0] n_T_mode_1;
reg [`TL_width_mode_1-1:0] n_L_mode_1;
integer i, j;
always @(*) begin
    // fold the 1d tensor back to 2d
    {macro_blk[0], macro_blk[1], macro_blk[2], macro_blk[3],
    macro_blk[4], macro_blk[5], macro_blk[6], macro_blk[7],
    macro_blk[8], macro_blk[9], macro_blk[10], macro_blk[11],
    macro_blk[12], macro_blk[13], macro_blk[14], macro_blk[15]
    } = one_d_macro_blk;
    
    n_T_mode_1 = T_mode_1;
    n_L_mode_1 = L_mode_1;
    if(csf_state==`csf_set_TL)begin
        n_T_mode_1 = 0;
        n_L_mode_1 = 0;
        for(i=0;i<4;i=i+1)begin
            if(en_bitmap[`v])begin
                n_T_mode_1[`TL_width_mode_1 - 8*i-1 -: 8] = macro_blk[macro_i-1][macro_j+i];
            end
        end
        for(j=0;j<4;j=j+1)begin
            if(en_bitmap[`h])begin
                n_L_mode_1[`TL_width_mode_1 - 8*i-1 -: 8] = macro_blk[macro_i+j][macro_j-1];
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        T_mode_1 <= 0;
        L_mode_1 <= 0;
    end else begin
        T_mode_1 <= n_T_mode_1;
        L_mode_1 <= n_L_mode_1;
    end
end

endmodule
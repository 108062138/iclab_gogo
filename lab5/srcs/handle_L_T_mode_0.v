`include "h264_def.vh"

module handle_mode_0_T_L (
    input clk,
    input rst_n,
    input [`sram_row_width-1:0] sram_dout,
    input [`csf_state_width-1:0] csf_state,
    input [`step_width-1:0] macro_step,
    input [5-1:0] cnt_macro_blk,
    output reg [`TL_width_mode_0-1:0] T_mode_0,
    output reg [`TL_width_mode_0-1:0] L_mode_0
);

reg [`TL_width_mode_0-1:0] n_T_mode_0;
reg [`TL_width_mode_0-1:0] n_L_mode_0;
reg [`macro_width-1:0] A [0:4-1];
reg [`macro_width-1:0] B [0:4-1];

always @(*) begin
    {A[0], B[0], A[1], B[1], A[2], B[2], A[3], B[3]} = sram_dout;
    n_T_mode_0 = T_mode_0;
    n_L_mode_0 = L_mode_0;
    if(csf_state==`csf_set_macro_blk)begin
        if(cnt_macro_blk==3)begin
            if(macro_step==2)begin
                n_T_mode_0 = A[3];
            end else if(macro_step==3)begin
                n_T_mode_0 = B[3];
            end else begin
                n_T_mode_0 = 0;
            end
        end
        
        if(macro_step==1||macro_step==3)begin
            if(cnt_macro_blk==4)begin
                n_L_mode_0[`TL_width_mode_0-8*0-1 -: 8] = A[0][8-1:0];
                n_L_mode_0[`TL_width_mode_0-8*1-1 -: 8] = A[1][8-1:0];
                n_L_mode_0[`TL_width_mode_0-8*2-1 -: 8] = A[2][8-1:0];
                n_L_mode_0[`TL_width_mode_0-8*3-1 -: 8] = A[3][8-1:0];
            end else if(cnt_macro_blk==5)begin
                n_L_mode_0[`TL_width_mode_0-8*4-1 -: 8] = A[0][8-1:0];
                n_L_mode_0[`TL_width_mode_0-8*5-1 -: 8] = A[1][8-1:0];
                n_L_mode_0[`TL_width_mode_0-8*6-1 -: 8] = A[2][8-1:0];
                n_L_mode_0[`TL_width_mode_0-8*7-1 -: 8] = A[3][8-1:0];
            end else if(cnt_macro_blk==6)begin
                n_L_mode_0[`TL_width_mode_0-8*8-1 -: 8] = A[0][8-1:0];
                n_L_mode_0[`TL_width_mode_0-8*9-1 -: 8] = A[1][8-1:0];
                n_L_mode_0[`TL_width_mode_0-8*10-1 -: 8] = A[2][8-1:0];
                n_L_mode_0[`TL_width_mode_0-8*11-1 -: 8] = A[3][8-1:0];
            end else if(cnt_macro_blk==7)begin
                n_L_mode_0[`TL_width_mode_0-8*12-1 -: 8] = A[0][8-1:0];
                n_L_mode_0[`TL_width_mode_0-8*13-1 -: 8] = A[1][8-1:0];
                n_L_mode_0[`TL_width_mode_0-8*14-1 -: 8] = A[2][8-1:0];
                n_L_mode_0[`TL_width_mode_0-8*15-1 -: 8] = A[3][8-1:0];
            end
        end else n_L_mode_0 = 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        T_mode_0 <= 0;
        L_mode_0 <= 0;
    end else begin
        T_mode_0 <= n_T_mode_0;
        L_mode_0 <= n_L_mode_0;
    end
end
endmodule
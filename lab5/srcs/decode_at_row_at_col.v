`include "h264_def.vh"

module decode_at_row_at_col (
    input [`step_width-1:0] macro_step,
    input [`step_width-1:0] sub_step,
    output reg [`step_width-1:0] macro_i,
    output reg [`step_width-1:0] macro_j,
    output reg [`step_width-1:0] frame_i,
    output reg [`step_width-1:0] frame_j
);

reg [`step_width-1:0] bigger_row;
reg [`step_width-1:0] bigger_col;
reg [`step_width-1:0] smaller_row;
reg [`step_width-1:0] smaller_col;

always @(*) begin
    bigger_row = macro_step >> 1;
    bigger_col = macro_step[0];
    smaller_row = sub_step >> 2;
    smaller_col = sub_step[1:0];
    frame_i = bigger_row << 4 + smaller_row << 2;
    frame_j = bigger_col << 4 + smaller_col << 2;
    macro_i = smaller_row << 2;
    macro_j = smaller_col << 2;
end

endmodule
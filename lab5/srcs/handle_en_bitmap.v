`include "h264_def.vh"

module handle_en_bitmap (
    input [`step_width-1:0] macro_step,
    input [`step_width-1:0] sub_step,
    output reg [`en_bitmap_width-1:0] en_bitmap
);

always @(*) begin
    // handle dc
    en_bitmap = 0;
    if(macro_step==0)begin
        if(sub_step==0)begin
            en_bitmap[`dc] = 1;
            en_bitmap[`h] = 0;
            en_bitmap[`v] = 0;
        end else if(sub_step>0 && sub_step<4)begin
            en_bitmap[`dc] = 1;
            en_bitmap[`h] = 1;
            en_bitmap[`v] = 0;
        end else if(sub_step[1:0]==2'b00)begin
            en_bitmap[`dc] = 1;
            en_bitmap[`h] = 0;
            en_bitmap[`v] = 1;
        end else begin
            en_bitmap[`dc] = 1;
            en_bitmap[`h] = 1;
            en_bitmap[`v] = 1;
        end
    end else if(macro_step==1)begin
        if(sub_step<4)begin
            en_bitmap[`dc] = 1;
            en_bitmap[`h] = 1;
            en_bitmap[`v] = 0;
        end else begin
            en_bitmap[`dc] = 1;
            en_bitmap[`h] = 1;
            en_bitmap[`v] = 1;
        end
    end else if(macro_step==2)begin
        if(sub_step[1:0]==2'b00)begin
            en_bitmap[`dc] = 1;
            en_bitmap[`h] = 0;
            en_bitmap[`v] = 1;
        end else begin
            en_bitmap[`dc] = 1;
            en_bitmap[`h] = 1;
            en_bitmap[`v] = 1;
        end
    end else begin
        en_bitmap[`dc] = 1;
        en_bitmap[`h] = 1;
        en_bitmap[`v] = 1;
    end
end

endmodule
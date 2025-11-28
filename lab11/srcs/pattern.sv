module PATTERN(
    // Output signals
    clk,
    rst_n,
	
    in_valid_data,
	data,
	
    in_valid_cmd,
    cmd,    

    // Input signals
	busy
);

// ========================================
// I/O declaration
// ========================================
// Output
output reg        clk, rst_n;
output reg        in_valid_data;
output reg  [7:0] data;
output reg        in_valid_cmd;
output reg [17:0] cmd;

// Input
input busy;

// ========================================
// clock
// ========================================
real CYCLE = 20;/*`CYCLE_TIME*/
always	#(CYCLE/2.0) clk = ~clk; //clock

// ========================================
// integer & parameter
// ========================================

parameter SIZE_OF_FRAME = 8;
parameter BITS_OF_PIXEL = 8;
parameter NUM_OF_FRAME = 5;
parameter SIMPLE_PATNUM = 4;

parameter CMD_BITS = 18;
parameter OP_BITS = 2;
parameter FUNCT_BITS = 2;
parameter SRC_BITS = 7;
parameter DST_BITS = 7;

parameter MIRROR_ALONG_X_AXIS   = 4'b0000;
parameter MIRROR_ALONG_Y_AXIS   = 4'b0001;
parameter TRANSPOSE             = 4'b0010;
parameter SECONDARY_TRANSPOSE   = 4'b0011;
parameter ROTATE_90_CLOCKWISE   = 4'b0100;
parameter ROTATE_180            = 4'b0101;
parameter ROTATE_270_CLOCKWISE  = 4'b0110;
parameter RIGHT_SHIFT           = 4'b1000;
parameter LEFT_SHIFT            = 4'b1001;
parameter UP_SHIFT              = 4'b1010;
parameter DOWN_SHIFT            = 4'b1011;
parameter FOUR_BY_FOUR_ZIGZAG   = 4'b1100;
parameter EIGHT_BY_EIGHT_ZIGZAG = 4'b1101;
parameter FOUR_BY_FOUR_MORTON   = 4'b1110;
parameter EIGHT_BY_EIGHT_MORTON = 4'b1111;

// ========================================
// wire & reg
// ========================================

reg [BITS_OF_PIXEL-1:0] _input_frame [NUM_OF_FRAME-1:0] [0:SIZE_OF_FRAME-1][0:SIZE_OF_FRAME-1];
reg [BITS_OF_PIXEL-1:0] tensor       [NUM_OF_FRAME-1:0] [0:SIZE_OF_FRAME-1][0:SIZE_OF_FRAME-1];
reg [CMD_BITS-1:0] current_cmd;
reg [OP_BITS-1:0] current_opcode;
reg [FUNCT_BITS-1:0] current_funct;
reg [SRC_BITS-1:0] current_src;
reg [DST_BITS-1:0] current_dst;
reg [BITS_OF_PIXEL-1:0] golden_ans [0:SIZE_OF_FRAME-1][0:SIZE_OF_FRAME-1];

reg [4-1:0] zz4_delta_x [0:15];
reg [4-1:0] zz4_delta_y [0:15];

reg [4-1:0] zz8_delta_x [0:63];
reg [4-1:0] zz8_delta_y [0:63];

//================================================================
// design
//================================================================



/*
You should fetch the data in SRAMs first and then check answer!
Example code:
	golden_ans = u_GTE.MEM7.Memory[ 5 ];  (used in 01_RTL / 03_GATE simulation)
	golden_ans = u_CHIP.MEM7.Memory[ 5 ]; (used in 06_POST simulation)
*/


always_comb begin
    // 4x4 Zig-Zag (16 entries)
    zz4_delta_x = {0, 0, 1, 2, 1, 0, 0, 1, 2, 3, 3, 2, 1, 2, 3, 3};
    zz4_delta_y = {0, 1, 0, 0, 1, 2, 3, 2, 1, 0, 1, 2, 3, 3, 2, 3};

    // 8x8 Zig-Zag (64 entries)
    // ROWS (Vertical Index)
    zz8_delta_x = {
        0, 0, 1, 2, 1, 0, 0, 1, 
        2, 3, 4, 3, 2, 1, 0, 0, 
        1, 2, 3, 4, 5, 6, 5, 4, 
        3, 2, 1, 0, 0, 1, 2, 3, 
        4, 5, 6, 7, 7, 6, 5, 4, 
        3, 2, 3, 4, 5, 6, 7, 7, 
        6, 5, 4, 5, 6, 7, 7, 6, 
        5, 6, 7, 7, 6, 7, 7, 7
    };

    // COLS (Horizontal Index)
    zz8_delta_y = {
        0, 1, 0, 0, 1, 2, 3, 2, 
        1, 0, 0, 1, 2, 3, 4, 5, 
        4, 3, 2, 1, 0, 0, 1, 2, 
        3, 4, 5, 6, 7, 6, 5, 4, 
        3, 2, 1, 0, 1, 2, 3, 4, 
        5, 6, 7, 7, 6, 5, 4, 3, 
        2, 1, 0, 0, 1, 2, 3, 4, 
        5, 6, 7, 5, 6, 7, 6, 7
    };
end

initial begin
    rst_n = 1;
    clk = 1;
    in_valid_data = 0;
    data = 'dx;
    in_valid_cmd = 0;
    cmd = 'dx;
    // low reset
    repeat(5) @(negedge clk);
    rst_n = 0;
    repeat(3) @(negedge clk);
    rst_n = 1;
    generate_frames_task();
    input_frames_task();
    generate_job();
    generate_job();
    pass_task();
end

task generate_job; begin
    set_cmd();
    set_golden();
    snd_cmd();
    verify_task();
    udpate_tensor();
end endtask

task set_cmd; begin
    // current_opcode = $urandom() % 2;
    // current_funct = $urandom() % 2;
    {current_opcode, current_funct} = ROTATE_180;
    current_src = $urandom() % NUM_OF_FRAME;
    current_dst = $urandom() % NUM_OF_FRAME;
    cmd = {current_opcode, current_funct, current_src, current_dst};
end endtask

task snd_cmd;begin
    repeat(($urandom() % 3) + 2) @(negedge clk);
    in_valid_cmd = 1;
    @(negedge clk);
    in_valid_cmd = 0;
    // cmd = 'dx;
end endtask

task set_golden; begin
    if(cmd[17:14]==MIRROR_ALONG_X_AXIS)begin // looks good
        for(integer row=0;row<SIZE_OF_FRAME;row=row+1) begin
            for(integer col=0;col<SIZE_OF_FRAME;col=col+1) begin
                golden_ans[row][col] = tensor[current_src][SIZE_OF_FRAME-1-row][col];
            end
        end
    end else if(cmd[17:14]==MIRROR_ALONG_Y_AXIS)begin // looks good
        for(integer row=0;row<SIZE_OF_FRAME;row=row+1) begin
            for(integer col=0;col<SIZE_OF_FRAME;col=col+1) begin
                golden_ans[row][col] = tensor[current_src][row][SIZE_OF_FRAME-1-col];
            end
        end
    end else if(cmd[17:14]==TRANSPOSE)begin
        for(integer row=0;row<SIZE_OF_FRAME;row=row+1)begin
            for(integer col=0;col<SIZE_OF_FRAME;col=col+1)begin
                golden_ans[row][col] = tensor[current_src][col][row];
            end
        end
    end else if(cmd[17:14]==SECONDARY_TRANSPOSE)begin
        for(integer row=0;row<SIZE_OF_FRAME;row=row+1)begin
            for(integer col=0;col<SIZE_OF_FRAME;col=col+1)begin
                golden_ans[row][col] = tensor[current_src][SIZE_OF_FRAME-1-col][SIZE_OF_FRAME-1-row];
            end
        end
    end else if(cmd[17:14]==ROTATE_90_CLOCKWISE)begin
        for(integer row=0;row<SIZE_OF_FRAME;row=row+1)begin
            for(integer col=0;col<SIZE_OF_FRAME;col=col+1)begin
                golden_ans[col][SIZE_OF_FRAME-1-row] = tensor[current_src][row][col];
            end
        end
    end else if(cmd[17:14]==ROTATE_180)begin
        for(integer row=0;row<SIZE_OF_FRAME;row=row+1)begin
            for(integer col=0;col<SIZE_OF_FRAME;col=col+1)begin
                golden_ans[SIZE_OF_FRAME-1-row][SIZE_OF_FRAME-1-col] = tensor[current_src][row][col];
            end
        end
    end else if(cmd[17:14]==ROTATE_270_CLOCKWISE)begin
        for(integer row=0;row<SIZE_OF_FRAME;row=row+1)begin
            for(integer col=0;col<SIZE_OF_FRAME;col=col+1)begin
                golden_ans[SIZE_OF_FRAME-1-col][row] = tensor[current_src][row][col];
            end
        end
    end else if(cmd[17:14]==RIGHT_SHIFT)begin
        // shift the tensor 5 units to right
        for(integer row=0;row<SIZE_OF_FRAME;row=row+1)begin
            for(integer col=5;col<SIZE_OF_FRAME;col=col+1)begin
                golden_ans[row][col] = tensor[current_src][row][col-5];
            end
        end
        // then use mirror to make the empty space fil with values
        for(integer row=0;row<SIZE_OF_FRAME;row=row+1) begin
            for(integer col=0;col<5;col=col+1)begin
                golden_ans[row][col] = tensor[current_src][row][4-col];
            end
        end
    end else if(cmd[17:14]==LEFT_SHIFT)begin
        // shift the tensor 5 units to left
        for(integer row=0;row<SIZE_OF_FRAME;row=row+1)begin
            for(integer col=0;col<SIZE_OF_FRAME-5;col=col+1)begin
                golden_ans[row][col] = tensor[current_src][row][col+5];
            end
        end
        // then use mirror to make the empty space fil with values
        for(integer row=0;row<SIZE_OF_FRAME;row=row+1) begin
            for(integer col=SIZE_OF_FRAME-5;col<SIZE_OF_FRAME;col=col+1)begin
                golden_ans[row][col] = tensor[current_src][row][SIZE_OF_FRAME-1-(col-(SIZE_OF_FRAME-5))];
            end
        end
    end else if(cmd[17:14]==UP_SHIFT)begin
        // shift the tensor 5 units up
        for(integer row=0;row<SIZE_OF_FRAME-5;row=row+1)begin
            for(integer col=0;col<SIZE_OF_FRAME;col=col+1)begin
                golden_ans[row][col] = tensor[current_src][row+5][col];
            end
        end
        // then use mirror to make the empty space fil with values
        for(integer row=SIZE_OF_FRAME-5;row<SIZE_OF_FRAME;row=row+1) begin
            for(integer col=0;col<SIZE_OF_FRAME;col=col+1)begin
                golden_ans[row][col] = tensor[current_src][SIZE_OF_FRAME-1-(row-(SIZE_OF_FRAME-5))][col];
            end
        end
    end else if(cmd[17:14]==DOWN_SHIFT)begin
        // shift the tensor 5 units down
        for(integer row=5;row<SIZE_OF_FRAME;row=row+1)begin
            for(integer col=0;col<SIZE_OF_FRAME;col=col+1)begin
                golden_ans[row][col] = tensor[current_src][row-5][col];
            end
        end
        // then use mirror to make the empty space fil with values
        for(integer row=0;row<5;row=row+1) begin
            for(integer col=0;col<SIZE_OF_FRAME;col=col+1)begin
                golden_ans[row][col] = tensor[current_src][4-row][col];
            end
        end
    end else if(cmd[17:14]==FOUR_BY_FOUR_ZIGZAG)begin
        for(integer blk_row=0;blk_row< SIZE_OF_FRAME/4;blk_row=blk_row+1) begin
            for(integer blk_col=0;blk_col< SIZE_OF_FRAME/4;blk_col=blk_col+1) begin
                for(integer idx=0;idx<16;idx=idx+1) begin
                    integer src_row, src_col, dst_row, dst_col;
                    src_row = blk_row*4 + zz4_delta_y[idx];
                    src_col = blk_col*4 + zz4_delta_x[idx];
                    dst_row = idx / 4;
                    dst_col = idx % 4;
                    golden_ans[dst_row][dst_col] = tensor[current_src][src_row][src_col];
                end
            end
        end
    end else if(cmd[17:14]==EIGHT_BY_EIGHT_ZIGZAG)begin
        for(integer blk_row=0;blk_row< SIZE_OF_FRAME/8;blk_row=blk_row+1) begin
            for(integer blk_col=0;blk_col< SIZE_OF_FRAME/8;blk_col=blk_col+1) begin
                for(integer idx=0;idx<64;idx=idx+1) begin
                    integer src_row, src_col, dst_row, dst_col;
                    src_row = blk_row*8 + zz8_delta_y[idx];
                    src_col = blk_col*8 + zz8_delta_x[idx];
                    dst_row = idx / 8;
                    dst_col = idx % 8;
                    golden_ans[dst_row][dst_col] = tensor[current_src][src_row][src_col];
                end
            end
        end
    end else if(cmd[17:14]==FOUR_BY_FOUR_MORTON)begin
        for(integer blk_row=0;blk_row< SIZE_OF_FRAME/4;blk_row=blk_row+1) begin
            for(integer blk_col=0;blk_col< SIZE_OF_FRAME/4;blk_col=blk_col+1) begin
                for(integer idx=0;idx<16;idx=idx+1) begin
                    integer src_row, src_col, dst_row, dst_col;
                    integer interleaved_row, interleaved_col;
                    interleaved_row = {idx[3], idx[1]};
                    interleaved_col = {idx[2], idx[0]};
                    src_row = blk_row*4 + interleaved_row;
                    src_col = blk_col*4 + interleaved_col;
                    dst_row = blk_row * 4 + (idx / 4);
                    dst_col = blk_col * 4 + (idx % 4);
                    golden_ans[dst_row][dst_col] = tensor[current_src][src_row][src_col];
                end
            end
        end
    end else if(cmd[17:14]==EIGHT_BY_EIGHT_MORTON)begin
        // it may be wrong
        for(integer blk_row=0;blk_row< SIZE_OF_FRAME/8;blk_row=blk_row+1) begin
            for(integer blk_col=0;blk_col< SIZE_OF_FRAME/8;blk_col=blk_col+1) begin
                for(integer idx=0;idx<64;idx=idx+1) begin
                    integer src_row, src_col, dst_row, dst_col;
                    integer interleaved_row, interleaved_col;
                    interleaved_row = {idx[5], idx[3], idx[1]};
                    interleaved_col = {idx[4], idx[2], idx[0]};
                    src_row = blk_row*8 + interleaved_row;
                    src_col = blk_col*8 + interleaved_col;
                    dst_row = blk_row * 8 + (idx / 8);
                    dst_col = blk_col * 8 + (idx % 8);
                    golden_ans[dst_row][dst_col] = tensor[current_src][src_row][src_col];
                end
            end
        end
    end
end endtask

task verify_task; begin
    wait(busy==0);
    repeat(2) @(negedge clk);
    $display("fake Verifying...");
    case({cmd[17:14]})
        MIRROR_ALONG_X_AXIS: $display("Operation: MIRROR_ALONG_X_AXIS");
        MIRROR_ALONG_Y_AXIS: $display("Operation: MIRROR_ALONG_Y_AXIS");
        TRANSPOSE:           $display("Operation: TRANSPOSE");
        SECONDARY_TRANSPOSE: $display("Operation: SECONDARY_TRANSPOSE");
        ROTATE_90_CLOCKWISE: $display("Operation: ROTATE_90_CLOCKWISE");
        ROTATE_180:          $display("Operation: ROTATE_180");
        ROTATE_270_CLOCKWISE:$display("Operation: ROTATE_270_CLOCKWISE");
        RIGHT_SHIFT:         $display("Operation: RIGHT_SHIFT");
        LEFT_SHIFT:          $display("Operation: LEFT_SHIFT");
        UP_SHIFT:            $display("Operation: UP_SHIFT");
        DOWN_SHIFT:          $display("Operation: DOWN_SHIFT");
        FOUR_BY_FOUR_ZIGZAG: $display("Operation: FOUR_BY_FOUR_ZIGZAG");
        EIGHT_BY_EIGHT_ZIGZAG:$display("Operation: EIGHT_BY_EIGHT_ZIGZAG");
        FOUR_BY_FOUR_MORTON: $display("Operation: FOUR_BY_FOUR_MORTON");
        EIGHT_BY_EIGHT_MORTON:$display("Operation: EIGHT_BY_EIGHT_MORTON");
        default:             $display("Operation: UNKNOWN");
    endcase
    $display("Cmd: %b", cmd);
    $display("current_opcode: %b, current_funct: %b, current_src: %0d, current_dst: %0d", current_opcode, current_funct, current_src, current_dst);
    $display("src_frame  => Golden Answer:");
    for(integer row=0 ; row<SIZE_OF_FRAME ; row=row+1) begin
        for(integer col=0 ; col<SIZE_OF_FRAME ; col=col+1)
            $write("%0d ", tensor[current_src][row][col]);
        $write(" => ");
        for(integer col=0 ; col<SIZE_OF_FRAME ; col=col+1)
            $write("%0d ", golden_ans[row][col]);
        $write("\n");
    end
end endtask

task udpate_tensor; begin
    // update golden to update tensor
    for(integer row=0 ; row<SIZE_OF_FRAME ; row=row+1) begin
        for(integer col=0 ; col<SIZE_OF_FRAME ; col=col+1) begin
            tensor[current_dst][row][col] = golden_ans[row][col];
        end
    end
end endtask

task generate_frames_task;
    integer index,row,col;
begin
    for(index=0 ; index<NUM_OF_FRAME ; index=index+1) begin
        $display("Generating frame %0d", index);
        for(row=0 ; row<SIZE_OF_FRAME ; row=row+1) begin
            for(col=0 ; col<SIZE_OF_FRAME ; col=col+1) begin
                _input_frame[index][row][col] = $urandom() % (2**(BITS_OF_PIXEL-5));
                tensor[index][row][col] = _input_frame[index][row][col];
            end
        end
    end
end endtask


task input_frames_task;
    integer index,row,col;
begin
    repeat(($urandom() % 3) + 2) @(negedge clk);
    for(index=0 ; index<NUM_OF_FRAME ; index=index+1) begin
        for(row=0 ; row<SIZE_OF_FRAME ; row=row+1) begin
            for(col=0 ; col<SIZE_OF_FRAME ; col=col+1) begin
                in_valid_data = 1;
                data = _input_frame[index][row][col];
                @(negedge clk);
            end
        end
    end
    in_valid_data = 0;
    data = 'dx;
end endtask

task pass_task; begin
    $display("pass!");
    repeat(5) @(negedge clk);
    $finish;
end endtask

initial begin
    $dumpfile("tb_gte.vcd");
    $dumpvars(0, tb_gte);
end

// given a frame number, display the frame
task display_frame(input integer frame_num);
    integer row, col;
begin
    $display("Frame %0d:", frame_num);
    for(row=0 ; row<SIZE_OF_FRAME ; row=row+1) begin
        for(col=0 ; col<SIZE_OF_FRAME ; col=col+1) begin
            $write("%0d ", _input_frame[frame_num][row][col]);
        end
        $write("\n");
    end
end endtask

endmodule



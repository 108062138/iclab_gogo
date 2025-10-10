`timescale 1ns/1ps

module tb_h264();

localparam CYC = 10;
localparam max_cyc = 3000;
localparam data_width = 8;
localparam out_value_width = 32;
localparam index_width = 4;
localparam QP_width = 5;
localparam frame_width = 32*8;
localparam frame_height = 32;
localparam number_of_frame = 16;

// localparam snd_img = 2;
// localparam cd = 3;
// localparam snd_param = 4;
// localparam rcv_output = 5;


reg [3:0] tb_state, n_tb_state;
reg [16-1:0] snd_img_cnt, n_snd_img_cnt;
reg [3-1:0] cd_cnt, n_cd_cnt;
reg [5-1:0] snd_param_cnt, n_snd_param_cnt;
reg [12-1:0] rcv_output_cnt, n_rcv_output_cnt;

reg clk, rst_n;
reg in_valid_data;
reg [data_width-1:0] data;
reg in_valid_param;
reg [index_width-1:0] index;
reg mode;
reg [QP_width-1:0] QP; // fixed
reg [4-1:0] op_vec; // fixed

wire out_valid;
wire [out_value_width-1:0] out_value;

reg [frame_width-1:0] data_in_mem [0: frame_height*number_of_frame-1];
reg [frame_width-1:0] ans_mem     [0: frame_height*number_of_frame-1];

integer i;

always #(CYC/2) clk = ~clk;

// dump waveform
initial begin
    $dumpfile("tb_h264.vcd");
    $dumpvars(0, tb_h264);
end

initial begin
    mute_all();
    start_engine();
    reset_all();
    repeat(5)@(negedge clk);
    send_img();
    cd();
    set_QP_and_mode();
    send_param();
    rcv_output(0);
    $finish;
end


// input i: to indicate which frame and its ans location
task automatic rcv_output(input integer i);
    // todo: rcv output and verify [-:32]
endtask

task automatic send_param();
    snd_param_cnt = 0;
    in_valid_param = 0;

    while(snd_param_cnt < 4)begin
        @(negedge clk);
        // send mode accordingly
        in_valid_param = 1;
        case(snd_param_cnt)
            0: mode = op_vec[3];
            1: mode = op_vec[2];
            2: mode = op_vec[1];
            3: mode = op_vec[0];
            default: mode = 0;
        endcase
        snd_param_cnt = snd_param_cnt + 1;
    end
    in_valid_param = 0;
endtask

task automatic send_img();
    snd_img_cnt = 0;
    in_valid_data = 0;
    data = 0;
    while(snd_img_cnt < 16384) begin // each cycle we send 1 byte, from MSB to LSB. data_in_mem is 256bit per line
        @(negedge clk);
        in_valid_data = 1;
        data = data_in_mem[snd_img_cnt >> 5][frame_width - 1 - (snd_img_cnt & 5'h1F)*8 -: 8];
        $display("snd_img_cnt: %d, data: %h at (i: %0d, j: %0d)", snd_img_cnt, data, snd_img_cnt >> 5, snd_img_cnt & 6'h3F);
        snd_img_cnt = snd_img_cnt + 1;
    end
    in_valid_data = 0;
    data = 0;
endtask

task automatic cd();
    cd_cnt = 0;
    while(cd_cnt < 3) begin
        @(negedge clk);
        in_valid_data = 0;
        data = 0;
        cd_cnt = cd_cnt + 1;
    end
endtask

event reset_done;
task reset_all();
fork
    begin
        rst_n = 1; rst_n = 1; repeat(1)@(negedge clk);
        rst_n = 0; rst_n = 0; repeat(2)@(negedge clk);
        rst_n = 1; rst_n = 1; repeat(2)@(negedge clk);
    end
join
-> reset_done;
endtask

task automatic mute_all();
    in_valid_data = 0;
    data = 0;
    in_valid_param = 0;
    index = 0;
    mode = 0;
    QP = 0;
endtask

task automatic start_engine();
    clk = 0;
    rst_n = 1;
    $readmemh("/home/popo/Desktop/popo_train_cpu/fixing/iclab_gogo/lab5/output/big_pics/big_data_in_hexa_condensed.txt", data_in_mem);
    $readmemh("/home/popo/Desktop/popo_train_cpu/fixing/iclab_gogo/lab5/output/big_pics/big_ans_hexa_condensed.txt", ans_mem);
endtask

task automatic set_QP_and_mode();
    QP = 13;
    index = 4;
    op_vec = 4'b1000;
endtask

h264 u_h264 (
    // input
    .clk(clk),
    .rst_n(rst_n),
    .in_valid_data(in_valid_data),
    .data(data),
    .in_valid_param(in_valid_param),
    .index(index),
    .mode(mode),
    .QP(QP),
    // output
    .out_valid(out_valid),
    .out_value(out_value)
);

endmodule
module gte (
    input wire clk,
    input wire rst_n,
    input wire in_valid_data,
    input wire [7:0] data,
    input wire in_valid_cmd,
    input wire [17:0] cmd,
    output wire busy
);

reg [2:0] state, n_state;
reg [10-1:0] cnt_data, n_cnt_data;
localparam idle = 0;
localparam load_data = 1;
localparam load_cmd = 2;
localparam compute = 3;
localparam done = 4;

parameter SIZE_OF_FRAME = 4;
parameter NUM_OF_FRAME = 2;

assign busy = (state==done)? 0: 1;

always @(*) begin
    n_cnt_data = cnt_data;
    
    case (state)
        idle: begin
            n_state = load_data;
        end
        load_data: begin
            if(in_valid_data)begin
                if(cnt_data == NUM_OF_FRAME * SIZE_OF_FRAME * SIZE_OF_FRAME)begin
                    n_state = load_cmd;
                    n_cnt_data = cnt_data + 1;
                end else begin
                    n_state = load_data;
                end
            end else begin
                n_state = load_cmd;
            end
        end
        load_cmd: begin
            if(in_valid_cmd) begin
                n_state = compute;    
            end else begin
                n_state = load_cmd;
            end
        end
        compute: begin
            n_state = done;
        end
        done: begin
            n_state = load_cmd;
        end
        default: n_state = idle;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        state <= idle;
        cnt_data <= 0;
    end else begin
        state <= n_state;
        cnt_data <= n_cnt_data;
    end
end

endmodule
`ifndef H264_VH
`define H264_VH

`define dc (0)
`define h (1)
`define v (2)

`define csf_idle  (0)
`define csf_load_frame  (1)
`define csf_init_cursor  (2)
`define csf_determine_macro_blk  (3)
`define csf_set_macro_blk  (4)
`define csf_determine_sub_blk  (5)
`define csf_set_TL  (6)
`define csf_CAL  (7)
`define csf_update_sub_step  (8)
`define csf_update_macro_step  (9)
`define csf_done (10)

`define tc_idle  (0)
`define tc_rcv_in_data  (1)
`define tc_rcv_in_param  (2)
`define tc_consume_frame  (3)
`define tc_done  (4)

`define macro_width  (16*8)
`define macro_height  (16)
`define step_width  (5)
`define TL_width_mode_0  (16*8)
`define TL_width_mode_1  (4*8)
`define csf_state_width  (5)
`define tc_state_width  (4)
`define QP_width  (5)
`define index_width  (4)
`define mode_width  (4)

`define en_bitmap_width  (3)

`define sram_addr_width (7)
`define sram_row_width (1024)

`define din_width (8)
`define dout_width (32)

`endif
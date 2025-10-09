import numpy as np
from utils.check import *
def macro_block_partition(Y_tensor):
    H, W = Y_tensor.shape
    FRAME_H = 32
    FRAME_W = 32
    assert(H%FRAME_H==0 and W%FRAME_W==0)
    frames = Y_tensor.reshape(H//FRAME_H, FRAME_H, W//FRAME_W, FRAME_W).transpose(0, 2, 1, 3)
    reconstruct = frames.transpose(0, 2, 1, 3).reshape(H, W)
    print(frames.shape, reconstruct.shape)
    diff_two_tensor(Y_tensor, reconstruct)
    return frames, reconstruct
def consume_a_frame(frame, op_mode, QP):
    assert(frame.shape==(32,32) and len(op_mode)==4 and QP>=0 and QP<=32)
    H, W = frame.shape
    PREDICT_BLOCK_H = 16
    PREDICT_BLOCK_W = 16
    blocks = frame.reshape(H//PREDICT_BLOCK_H, PREDICT_BLOCK_H, W//PREDICT_BLOCK_W, PREDICT_BLOCK_W).transpose(0, 2, 1, 3)
    reconstruct = blocks.transpose(0, 2, 1, 3).reshape(H, W)
    print(blocks.shape, reconstruct.shape)
    diff_two_tensor(frame, reconstruct)

    len_i, len_j, _, _ = blocks.shape
    # iterate through each block
    for blk_idx in range(len_i*len_j):
        mode = op_mode[blk_idx]
        regs = np.zeros(blocks[blk_idx//len_j, blk_idx%len_j].shape)
        max_depth = 1 if mode==0 else 16
        predict_width = 16 if max_depth==1 else 4
        print('at blk', (blk_idx//len_j, blk_idx%len_j), 'we have op:', mode)
        # according to blk_idx and currenct step to decide prediction set
        for step in range(max_depth):
            en_bitmap = get_en_bitmap(blk_idx=blk_idx,step=step)
            L, T = get_T_L(blk_idx=blk_idx, step=step, predict_width=predict_width, en_bitmap=en_bitmap, regs=regs)
            dc_predict, h_predict, v_predict = enumerate_all_prediction(L=L, T=T, predict_width=predict_width, en_bitmap=en_bitmap)
            cut_out_ans = get_ans_block(blk_idx=blk_idx, step=step, regs=regs, predict_width=predict_width)
            SAD_res, pick = determine_predict_blk(dc_predict=dc_predict, h_predict=h_predict,v_predict=v_predict, en_bitmap=en_bitmap, cut_out_ans=cut_out_ans)
            if pick==0: predicted = dc_predict
            if pick==1: predicted = h_predict
            if pick==2: predicted = v_predict
            X = residual_computation(input=cut_out_ans, predicted=predicted)
            W = integer_transform(X=X)
            Z = quantization(W=W)
            W_bar = de_quantization(Z=Z)
            X_bar = reverse_integer_transform(W_bar=W_bar)
            reconstructed = X_bar +  predicted
            # update regs accordingly
            at_row, at_col = decode_row_col_by_blk_idx_and_step(blk_idx=blk_idx, step=step)
            for i in range(predict_width):
                for j in range(predict_width):
                    regs[i+at_row,j+at_col] = reconstructed[i,j] 
    return blocks, reconstruct

def reverse_integer_transform(W_bar):
    Y = integer_transform(X=W_bar) # chekcing~~
    X_bar = Y >> 6
    return X_bar
def integer_transform(X):
    Cf = np.array([
    [ 1,  1,  1,  1],
    [ 1,  1, -1, -1],
    [ 1, -1, -1,  1],
    [ 1, -1,  1, -1],
    ], dtype=np.int32)
    print(X.dtype)
    X = X.astype(np.int32, copy=False)
    # cut block into several 4x4 grid
    h, w = X.shape
    GRID_H = 4
    GRID_W = 4
    grids = X.reshape(h//GRID_H, GRID_H, w//GRID_W, GRID_W).transpose(0,2,1,3)
    for i in range(0, grids.shape[0]):
        for j in range(0, grids.shape[1]):
            grids[i,j] = Cf @ (grids[i, j] @ Cf.T)
    W = grids.transpose(0, 2, 1, 3).reshape(h, w)
    return W

def quantization(W,QP):
    q_bits = gen_q_bit(QP=QP)
    f = gen_offset(QP=QP)
    MF = gen_MF(QP=QP)
    h, w = W.shape
    GRID_H = 4
    GRID_W = 4
    grids = W.reshape(h//GRID_H, GRID_H, w//GRID_W, GRID_W).transpose(0,2,1,3)
    for i in range(0, grids.shape[0]):
        for j in range(0, grids.shape[1]):
            grids[i,j] = (grids[i,j] * MF + f) >> q_bits
            # for a in range(4):
            #     for b in range(4):
            #         grids[i,j,a,b] = (grids[i,j,a,b]*MF[a,b] + f) >> q_bits
    Z = grids.transpose(0, 2, 1, 3).reshape(h, w)
    return Z

def de_quantization(Z, QP):
    deq_bit = gen_deq_bit(QP)
    scale_factor = gen_scale_factor(QP=QP)
    h, w = Z.shape
    GRID_H = 4
    GRID_W = 4
    grids = Z.reshape(h//GRID_H, GRID_H, w//GRID_W, GRID_W).transpose(0,2,1,3)
    for i in range(0, grids.shape[0]):
        for j in range(0, grids.shape[1]):
            grids[i,j] = (grids[i,j] * scale_factor) << deq_bit
    W_bar = grids.transpose(0, 2, 1, 3).reshape(h, w)
    return W_bar

def gen_deq_bit(QP):
    return np.floor(QP//6)

def gen_q_bit(QP):
    return 15 + np.floor(QP//6)

def gen_offset(QP):
    if QP>=0 and QP<=5:     return  10922
    elif QP>=6 and QP<=11:  return  21845
    elif QP>=12 and QP<=17: return  43690
    elif QP>=18 and QP<=23: return  87381
    elif QP>=24 and QP<=29: return 174762
    else:
        print('fuck up')
        return -1

def gen_scale_factor(QP):
    rem = QP % 6
    scale_factor_table = np.array([
    [10,  16,  13],
    [11,  18, 14],
    [13, 20, 16],
    [14, 23,  18],
    [16, 25,  20],
    [18, 29,  23],
    ], dtype=np.int32)

    a, b, c = scale_factor_table[rem]
    scale_factor = np.array([
    [ a, c, a, c],
    [ c, b, c, b],
    [ a, c, a, c],
    [ c, b, c, b],
    ], dtype=np.int32)

    return scale_factor

def gen_MF(QP):
    rem = QP%6
    MF_table = np.array([
    [13107,  5243,  8066],
    [11916,  4660, 7490],
    [10082, 4194, 6554],
    [9362, 3647,  5825],
    [8192, 3355,  5243],
    [7282, 2893,  4559],
    ], dtype=np.int32)
    a, b, c  = MF_table[rem]
    MF = np.array([
    [ a, c, a, c],
    [ c, b, c, b],
    [ a, c, a, c],
    [ c, b, c, b],
    ], dtype=np.int32)
    return MF

def residual_computation(input, predicted):
    residual = input - predicted
    return residual

def SAD(A, B):
    assert(A.shape==B.shape)
    diff = A - B
    total = np.abs(diff).sum
    return total

def get_T_L(blk_idx, step, predict_width, en_bitmap, regs):
    T = [0] * predict_width
    L = [0] * predict_width
    # maintaion index
    at_row, at_col = decode_row_col_by_blk_idx_and_step(blk_idx=blk_idx, step=step)
    # maintain T for v
    if en_bitmap[2]:
        for i in range(len(T)):
            T[i] = regs[at_row+i][at_col]
    # maintain L for h
    if en_bitmap[1]:
        for j in range(len(L)):
            L[j] = regs[at_row][at_col+j]
    return T, L

def decode_row_col_by_blk_idx_and_step(blk_idx, step):
    bigger_row = blk_idx // 2
    bigger_col = blk_idx % 2
    smaller_row = step // 4
    smaller_col = step % 4
    at_row = bigger_row * 16 + smaller_row
    at_col = bigger_col * 16 + smaller_col
    return at_row, at_col

def enumerate_all_prediction(L, T, predict_width, en_bitmap):
    dc_predict = np.zeros((predict_width, predict_width))
    h_predict = np.zeros((predict_width, predict_width))
    v_predict = np.zeros((predict_width, predict_width))
    
    # maintain dc mode
    if en_bitmap==[1,0,0]:
        dc_val = np.u_int8(128)
    elif en_bitmap==[1,1,0]: # can do h, so use L
        dc_val = np.u_int8(np.sum(L) >> 2)
    elif en_bitmap==[1,0,1]: # can do v, so use T
        dc_val = np.u_int8(np.sum(T) >> 2)
    else:
        dc_val = np.u_int8((np.sum(L+T)) >> 3)
    for i in range(predict_width):
        for j in range(predict_width):
            dc_predict[i,j] = dc_val
    # maintain h mode
    if en_bitmap[1]:
        for i in range(predict_width):
            for j in range(predict_width):
                h_predict[i,j] = L[i]
    # maintain v mode
    if en_bitmap[2]:
        for i in range(predict_width):
            for j in range(predict_width):
                h_predict[i,j] = T[i]
    return dc_predict, h_predict, v_predict

def get_en_bitmap(blk_idx, step):
    if blk_idx==0:
        if step==0:
            prediction_set_en = {'dc'        }
        elif step>=0 and step<4:
            prediction_set_en = {'dc','h'    }
        elif step % 4==0:
            prediction_set_en = {'dc',    'v'}
        else:
            prediction_set_en = {'dc','h','v'}
    elif blk_idx==1:
        if step>=0 and step<4:
            prediction_set_en = {'dc','h'    }
        else:
            prediction_set_en = {'dc','h','v'}
    elif blk_idx==2:
        if step %4==0:
            prediction_set_en = {'dc',    'v'}
        else:
            prediction_set_en = {'dc','h','v'}
    else:
        prediction_set_en = {'dc','h','v'}
    # print(blk_prediction_set_en)
    en_bitmap = [0,0,0]
    if 'dc' in prediction_set_en: en_bitmap[0] = 1
    if 'h' in prediction_set_en: en_bitmap[1] = 1
    if 'v' in prediction_set_en: en_bitmap[2] = 1
    return en_bitmap
def get_ans_block(blk_idx, step, regs, predict_width):
    at_row, at_col = decode_row_col_by_blk_idx_and_step(blk_idx=blk_idx, step=step)
    cut_out_ans = np.zeros((predict_width, predict_width))
    for i in range(predict_width):
        for j in range(predict_width):
            cut_out_ans[i, j] = regs[i+at_row, j+at_col]
    return get_ans_block

def determine_predict_blk(dc_predict, h_predict, v_predict, en_bitmap, cut_out_ans):
    SAD_for_dc = SAD(A=dc_predict,B=cut_out_ans)
    SAD_for_h = SAD(A=h_predict,B=cut_out_ans)
    SAD_for_v = SAD(A=v_predict,B=cut_out_ans)
    
    if en_bitmap==[1,0,0]:
        SAD_res = SAD_for_dc
        pick = 0 # 0 for dc
    elif en_bitmap==[1,1,0]:
        if SAD_for_dc>SAD_for_h:
            SAD_res = SAD_for_h
            pick = 1
        else:
            SAD_res = SAD_for_dc
            pick = 0
    elif en_bitmap==[1,0,1]:
        if SAD_for_dc>SAD_for_v:
            SAD_res = SAD_for_v
            pick = 2
        else:
            SAD_res = SAD_for_dc
            pick = 0
    elif en_bitmap==[1,1,1]:
        if SAD_for_dc==SAD_for_h and SAD_for_dc!=SAD_for_v and SAD_for_h!=SAD_for_v:
            if SAD_for_dc<SAD_for_v:
                SAD_res = SAD_for_dc
                pick = 0
            else:
                SAD_res = SAD_for_v
                pick = 2
        elif SAD_for_dc!=SAD_for_h and SAD_for_dc==SAD_for_v and SAD_for_h!=SAD_for_v:
            if SAD_for_dc<SAD_for_h:
                SAD_res = SAD_for_dc
                pick = 0
            else:
                SAD_res = SAD_for_h
                pick = 1
        elif SAD_for_dc!=SAD_for_h and SAD_for_dc!=SAD_for_v and SAD_for_h==SAD_for_v:
            if SAD_for_dc<SAD_for_h:
                SAD_res = SAD_for_dc
                pick = 0
            else:
                SAD_res = SAD_for_h
                pick = 1
        elif SAD_for_dc==SAD_for_h and SAD_for_dc==SAD_for_v and SAD_for_h==SAD_for_v:
            SAD_res = SAD_for_dc
            pick = 0
        else:
            if SAD_for_dc>SAD_for_h and SAD_for_v>SAD_for_h:
                SAD_res = SAD_for_h
                pick = 1
            elif SAD_for_dc>SAD_for_v and SAD_for_h>SAD_for_v:
                SAD_res = SAD_for_v
                pick = 2
            else:
                SAD_res = SAD_for_dc
                pick = 0
    return SAD_res, pick
import numpy as np
def diff_two_tensor(A, B):
    assert(A.shape==B.shape)
    diff = A.astype(np.int32) - B.astype(np.int32)
    abs_diff = np.abs(diff)
    print("convertion diff:", abs_diff.mean())
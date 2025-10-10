import numpy as np
def diff_two_tensor(A, B):
    assert(A.shape==B.shape)
    diff = A.astype(np.int32) - B.astype(np.int32)
    abs_diff = np.abs(diff)
    print("convertion diff:", abs_diff.mean())

def check_uint_file_and_hexa_file(uint_file, hexa_file):
    # uint_file is in format: uint8 uint8 uint8 ..., where each content is in range [0, 255]
    # hexa_file is in format: AB CD..., where each content is composed by two hexa digits
    rec, uints = [], []
    with open(uint_file, 'r') as f:
        uints = f.read().strip().split()
        uints = [int(x) for x in uints]

    with open(hexa_file, 'r') as f:
        hexas = f.read().strip().split()
        for i in range(len(hexas)):
            n = len(hexas[i])
            assert(n % 2 == 0)
            for j in range(0, n, 2):
                byte = hexas[i][j:j+2]
                rec.append(int(byte, 16))
    assert(len(uints) == len(rec))
    assert(all([uints[i] == rec[i] for i in range(len(uints))]))
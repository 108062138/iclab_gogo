import numpy as np

def rgb_2_ycbcr(rgb_image):
    rbg_image = rgb_image.astype(np.float32)
    R, G, B = rbg_image[...,0], rbg_image[...,1], rbg_image[...,2]
    Y  = 0.299*R + 0.587*G + 0.114*B
    Cb = -0.168736*R - 0.331264*G + 0.5*B + 128.0
    Cr = 0.5*R - 0.418688*G - 0.081312*B + 128.0
    ycbcr = np.stack([Y, Cb, Cr], axis = -1)
    return np.clip(np.rint(ycbcr), 0, 255).astype(np.uint8)
def ycbcr_2_rgb(ycbcr_image):
    ycbcr_image = ycbcr_image.astype(np.float32)
    Y, Cb, Cr = ycbcr_image[...,0], ycbcr_image[...,1], ycbcr_image[...,2]
    r = Y + 1.402   * (Cr - 128.0)
    g = Y - 0.344136* (Cb - 128.0) - 0.714136*(Cr - 128.0)
    b = Y + 1.772   * (Cb - 128.0)
    rgb = np.stack([r, g, b], axis=-1)
    return np.clip(np.rint(rgb), 0, 255).astype(np.uint8)
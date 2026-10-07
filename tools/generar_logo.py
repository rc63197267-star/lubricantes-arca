# -*- coding: utf-8 -*-
"""Genera logo.ico (icono de Lubricantes Arca) sin dependencias externas.
Diseño simple: fondo azul marino + barril/círculo azul con franja blanca.
"""
import os
import struct

NAVY = (0x0A, 0x25, 0x40)
BLUE = (0x3B, 0x82, 0xF6)
WHITE = (0xFF, 0xFF, 0xFF)


def make_bmp(size, pixels):
    """Genera los bytes de un icono DIB (BITMAPINFOHEADER + pixeles BGRA + máscara)."""
    # BITMAPINFOHEADER (40 bytes)
    header = struct.pack(
        "<IiiHHIIiiII",
        40,          # biSize
        size,        # biWidth
        size * 2,    # biHeight (doble: XOR + AND)
        1,           # biPlanes
        32,          # biBitCount
        0,           # biCompression
        0,           # biSizeImage
        0, 0, 0, 0,  # resoluciones
    )
    xor = bytearray()
    for y in range(size):
        for x in range(size):
            r, g, b, a = pixels(size, x, y)
            xor += bytes((b, g, r, a))  # BGRA
    # Máscara AND: todo opaco (bits a 0) -> 1 byte por píxel redondeado a 4 bytes por fila
    row_bytes = ((size + 31) // 32) * 4
    mask = bytearray(b"\x00" * (row_bytes * size))
    return header + bytes(xor) + bytes(mask)


def draw(size, x, y):
    # Fondo azul marino
    r, g, b = NAVY
    cx = cy = size / 2.0
    # Círculo principal (barril)
    dist = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
    if dist <= size * 0.42:
        # franja blanca superior (tapa)
        if y < size * 0.30:
            r, g, b = WHITE
        else:
            r, g, b = BLUE
    return r, g, b, 255


def main():
    sizes = [16, 32, 48, 64, 128, 256]
    entries = []
    blobs = []
    offset = 6 + 16 * len(sizes)
    for s in sizes:
        blob = make_bmp(s, draw)
        blobs.append(blob)
        entries.append(
            struct.pack(
                "<BBBBHHII",
                (s if s < 256 else 0),  # width (0 = 256)
                (s if s < 256 else 0),  # height
                0,                      # colorCount
                0,                      # reserved
                1,                      # planes
                32,                     # bitCount
                len(blob),
                offset,
            )
        )
        offset += len(blob)

    header = struct.pack("<HHH", 0, 1, len(sizes))
    data = header + b"".join(entries) + b"".join(blobs)

    out_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "logo")
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, "logo.ico")
    with open(out, "wb") as f:
        f.write(data)
    print("Logo generado en:", out)


if __name__ == "__main__":
    main()
#!/usr/bin/env python3
"""Write deliberately malformed variants of a FABulous frame stream.

Every variant must be rejected by the loader in
verification/common/sim/tb_logic_tile_bitstream.v (run with +expect_reject).
Written here (the sibling's equivalent is not vendored); the frame layout is
read from the fixture's own files, not assumed:

  stream  = 20-byte sync header, then GRID_COLS x NFR frames of
            (4-byte frame-select word + (GRID_ROWS-2) x 4-byte data words),
            then a 4-byte desync word
  map     = "cfg_index frame_position" per line (frame_position = frame*32+bit)
  wiring  = "GRID <cols> <rows>" and "TILE <lx> <ly>" lines

usage: bitstream_corrupt.py <good.bin> <map> <wiring> <outdir>
"""
import sys
from pathlib import Path

HDR, WORD, NFR, FBITS = 20, 4, 20, 32


def grid(wiring):
    cols = rows = lx = ly = None
    for line in Path(wiring).read_text().splitlines():
        t = line.split()
        if t and t[0] == "GRID":
            cols, rows = int(t[1]), int(t[2])
        elif t and t[0] == "TILE":
            lx, ly = int(t[1]), int(t[2])
    assert None not in (cols, rows, lx, ly), "wiring manifest lacks GRID/TILE"
    return cols, rows, lx, ly


def variants(good, mapf, wiring):
    cols, rows, lx, ly = grid(wiring)
    data_words = rows - 2
    fsz = WORD * (1 + data_words)

    def off(col, frame):
        return HDR + (col * NFR + frame) * fsz

    # data word of the logic tile: interior rows are in Y-descending order
    def logic_data(col, frame):
        return off(col, frame) + WORD + (rows - 2 - ly) * WORD

    mapped = {int(p) for _, p in (ln.split() for ln in Path(mapf).read_text().split("\n") if ln.strip())}
    unmapped = next(f * FBITS + b for f in range(NFR) for b in range(FBITS) if f * FBITS + b not in mapped)
    b = bytes(good)
    v = {}
    v["empty"] = b""
    v["truncated_header"] = b[:10]
    v["truncated_mid_frame"] = b[: off(lx, 4) + WORD + 2]
    v["truncated_no_desync"] = b[:-WORD]
    bad = bytearray(b); bad[0] ^= 0xFF
    v["bad_sync"] = bytes(bad)
    dup = bytearray(b)                       # frame (lx,5) re-labelled as (lx,4)
    dup[off(lx, 5):off(lx, 5) + WORD] = b[off(lx, 4):off(lx, 4) + WORD]
    v["duplicate_frame"] = bytes(dup)
    two = bytearray(b)                       # two strobe bits set
    two[off(lx, 2) + 3] |= 0b1000
    v["two_strobes"] = bytes(two)
    col = bytearray(b)                       # column out of range
    col[off(cols - 1, 0)] = 0xFF
    v["bad_column"] = bytes(col)
    stray = bytearray(b)                     # a frame bit that is not a ConfigMem bit
    pos = unmapped
    stray[logic_data(lx, pos // FBITS) + 3 - (pos % FBITS) // 8] |= 1 << ((pos % FBITS) % 8)
    v["unmapped_bit_set"] = bytes(stray)
    v["trailing_byte"] = b + b"\x00"
    v["missing_frame"] = b[: off(lx, NFR - 1)] + b[off(lx + 1, 0):]
    return v


if __name__ == "__main__":
    good = Path(sys.argv[1]).read_bytes()
    out = Path(sys.argv[4])
    out.mkdir(parents=True, exist_ok=True)
    vs = variants(good, sys.argv[2], sys.argv[3])
    for name, data in vs.items():
        assert data != good, name
        (out / f"{name}.bin").write_bytes(data)
    print(f"wrote {len(vs)} malformed variants to {out}")

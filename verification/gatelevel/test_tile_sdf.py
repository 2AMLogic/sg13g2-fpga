"""cocotb bench for the SDF-annotated gate-level re-simulation of the routed tile
(issue #27). Run through `klt functional-verification` (layout/sdf-verify.sh) on
the post-route netlist with a post-route SDF; not an RTL bench.

Mirrors cases 1 and 2 of verification/common/sim/tb_logic_tile_routed.v (the
vendored zero-delay bench, which cannot itself run under klt: that verb takes a
cocotb module). Config bit map as in that bench: LUT n = cfg[17n+:16] init,
cfg[17n+16] registered; track mux (edge d, idx t) = cfg[68+3(4d+t)+:3]; LUT
pin (n,k) = cfg[116+2(4n+k)+:2]; SR = cfg[148+:2]; EN n = cfg[150+2n+:2].

Clock period is the 20 ns of the STA constraint (layout/timing-period.md).
Combinational outputs are sampled 10 ns after the inputs change, registered
ones 5 ns after the rising edge; a delay beyond that fails the bench.
"""

import cocotb
from cocotb.triggers import Timer

PERIOD_NS = 20
COMB_SETTLE_NS = 10
CLK_Q_NS = 5


def setf(cfg, lo, width, val):
    mask = ((1 << width) - 1) << lo
    return (cfg & ~mask) | ((val << lo) & mask)


def set_lut(cfg, n, init, reg):
    cfg = setf(cfg, 17 * n, 16, init)
    return setf(cfg, 17 * n + 16, 1, reg)


def set_lutin(cfg, n, k, d):
    return setf(cfg, 68 + 48 + 2 * (4 * n + k), 2, d)


def set_trk(cfg, d, t, code):
    return setf(cfg, 68 + 3 * (4 * d + t), 3, code)


def set_en(cfg, n, d):
    return setf(cfg, 68 + 82 + 2 * n, 2, d)


def set_sr(cfg, d):
    return setf(cfg, 68 + 80, 2, d)


def drive(dut, tin):
    dut.n_in.value, dut.e_in.value, dut.s_in.value, dut.w_in.value = tin


def outs(dut):
    return [int(dut.n_out.value), int(dut.e_out.value), int(dut.s_out.value), int(dut.w_out.value)]


async def clock_edge(dut):
    """One full period starting low: rise at +PERIOD/2, fall at +PERIOD."""
    dut.clk.value = 0
    await Timer(PERIOD_NS // 2, unit="ns")
    dut.clk.value = 1
    await Timer(CLK_Q_NS, unit="ns")


@cocotb.test()
async def routed_combinational(dut):
    """Every (BEL, pin, edge): track -> pass-through LUT -> N output track."""
    dut.clk.value = 0
    checks = 0
    for d in range(4):
        for k in range(4):
            cfg = 0
            mask = sum(1 << i for i in range(16) if (i >> k) & 1)
            for n in range(4):
                cfg = set_lut(cfg, n, mask, 0)
                for i in range(4):
                    cfg = set_lutin(cfg, n, i, (d + n) % 4)
                cfg = set_trk(cfg, 0, n, 3 + n)
            dut.cfg.value = cfg
            for v in range(8):
                pat = (1 << v) if v < 4 else (~(1 << (v - 4)) & 0xF)
                tin = []
                for e in range(4):
                    word = 0b0000 if (pat >> e) & 1 else 0b1111
                    word = (word & ~(1 << k)) | (((pat >> e) & 1) << k)
                    tin.append(word)
                drive(dut, tin)
                await Timer(COMB_SETTLE_NS, unit="ns")
                n_out = outs(dut)[0]
                for n in range(4):
                    exp = (pat >> ((d + n) % 4)) & 1
                    got = (n_out >> n) & 1
                    assert got == exp, f"d={d} k={k} v={v} BEL{n}: got {got} exp {exp}"
                    checks += 1
    dut._log.info("routed_combinational: %d checks", checks)


@cocotb.test()
async def routed_registered(dut):
    """Registered path with EN/SR from tracks: reset, capture, hold, SR priority."""
    cfg = 0
    for n in range(4):
        cfg = set_lut(cfg, n, 0xAAAA, 1)  # out = in0, registered
        cfg = set_lutin(cfg, n, 0, 0)     # pin0 <- N1END0
        cfg = set_en(cfg, n, 1)           # EN_n <- E1END<n>
        cfg = set_trk(cfg, 3, n, 3 + n)   # W1BEG<n> <- BEL n output
    cfg = set_sr(cfg, 2)                  # SR <- S1END0
    dut.cfg.value = cfg
    tin = [0b0000, 0b1111, 0b0000, 0b0000]
    drive(dut, tin)
    await Timer(COMB_SETTLE_NS, unit="ns")

    tin[2] = 0b0001                       # reset all
    drive(dut, tin)
    await clock_edge(dut)
    assert outs(dut)[3] == 0b0000, f"reset clears FF: w_out={outs(dut)[3]:04b}"

    dut.clk.value = 0
    await Timer(PERIOD_NS // 2, unit="ns")
    tin[2] = 0b0000
    tin[0] = 0b0001                       # data 1, all EN
    drive(dut, tin)
    await clock_edge(dut)
    assert outs(dut)[3] == 0b1111, f"capture 1: w_out={outs(dut)[3]:04b}"

    dut.clk.value = 0
    await Timer(PERIOD_NS // 2, unit="ns")
    tin[0] = 0b0000                       # data 0, BEL1 gated off
    tin[1] = 0b1101
    drive(dut, tin)
    await clock_edge(dut)
    assert outs(dut)[3] == 0b0010, f"EN=0 holds BEL1: w_out={outs(dut)[3]:04b}"

    dut.clk.value = 0
    await Timer(PERIOD_NS // 2, unit="ns")
    tin[2] = 0b0001                       # SR beats EN
    drive(dut, tin)
    await clock_edge(dut)
    assert outs(dut)[3] == 0b0000, f"SR priority over EN: w_out={outs(dut)[3]:04b}"

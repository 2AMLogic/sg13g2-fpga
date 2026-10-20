# sg13g2-fpga

A small open-bitstream eFPGA tile on
[IHP SG13G2](https://github.com/IHP-GmbH/IHP-Open-PDK), IHP's open-source
130 nm SiGe BiCMOS PDK — one LUT4-class logic tile and a small
demonstration fabric — designed by AI agents driving
[klayout-tools](https://github.com/2AMLogic/klayout-tools), the
[FABulous](https://github.com/FPGA-Research-Manchester/FABulous) fabric
description format, and the open-source cocotb + Icarus, Yosys, nextpnr and
OpenROAD flow.

**Status: just opened, specification phase.** Nothing is designed in this
repo yet.

**Built agent-native.** Every specification, decision record, testbench, and
line of documentation here is produced by AI agents working from a ratified
spec and an append-only evidence trail — not human-authored work that agents
merely assisted with. Verification is the product: every claim traces to a
recorded result. Where the agents hit friction with the open-source tooling —
most often [klayout-tools](https://github.com/2AMLogic/klayout-tools) — that
friction is filed as a public issue against the tool itself, so the fix
benefits everyone using SG13G2, not just this repo.

## Why this block, on this PDK

This is a **port, not a new design.** [sky130-fpga](https://github.com/2AMLogic/sky130-fpga)
carries the same tile on sky130: a ratified tile spec (4× LUT4, one output
flip-flop per LUT, no carry chain in v1, a FABulous-style switch matrix with
4 general-purpose tracks per edge, a 2×2 to 4×4 single-tile-type
demonstration fabric, an open bitstream), its framework choice, and a
physical-design and timing-characterization path. The architecture is the
constant; **the PDK is the variable.**

SG13G2 is the same 130 nm class as sky130, which makes it a clean
comparison: the architecture and the node are held, and the standard-cell
library, the metal stack and the rule deck change.

- **A different standard-cell library and supply.** The tile is placed and
  routed with the PDK's `sg13g2_stdcell` library on its 1.2 V core devices.
- **A different metal stack.** SG13G2 has five thin metals (Metal1–Metal5)
  plus two thick top metals (TopMetal1, TopMetal2). Which layers the switch
  matrix may use is a spec decision.
- **A young deck.** The klayout-tools SG13G2 DRC/LVS deck is starter-grade.
  A routing-dense digital tile exercises it very differently from the
  analog SG13G2 canaries; finding what it cannot check yet is part of the
  job.
- **Timing is re-earned.** No sky130 timing number transfers. Every timing
  claim here comes from characterized SG13G2 data at its own corners.

## Target specification (ratified — see [`spec/target-spec.md`](spec/target-spec.md), [ADR-0001](spec/decisions/0001-ratify-target-spec.md), issue #2)

Rows needing a measurement are ratified as target/fallback/stretch with the evidence that will back them, not as numbers. Port parity: the architectural rows are `sky130-fpga`'s ratified tile spec,
unchanged. The physical and timing rows are re-derived here.

| Parameter | Fallback | Target | Stretch |
|---|---|---|---|
| Logic tile | 4× LUT4 + 1 FF per LUT, no carry (inherited) | same | carry chain as a later tile revision |
| Routing (architecture) | 4 tracks/edge, FABulous-style switch matrix (inherited) | same | — |
| Bitstream | open, documented, FABulous-generated (inherited) | same | — |
| Library, supply, corners | `sg13g2_stdcell`, 1.2 V core, the three 1.2 V core liberty corners | same, plus the 1.5 V-class corners reported as information | — |
| Routing layers | Metal1–Metal5 signal, TopMetal1/TopMetal2 reserved for power | same | TopMetal signal use only by a later decision record |
| Tile area / aspect | abuts in a grid; area reported, no figure ratified | measured figure ratified by a later decision record | — |
| Demonstration fabric | 2×2 tiles | 2×2 to 4×4, single logic tile type | — |
| Timing | setup/hold-clean at a stated period at every claim corner | same, period fixed before measurement; Fmax only if derived from characterized data | SDF-annotated gate-level re-simulation |
| Signoff | DRC clean, LVS gaps attributed to filed deck issues | DRC/LVS clean on the tile and the assembled fabric | — |

Maturity ladder: framework and port plan → tile spec ratified → tile RTL
and fabric description passing bitstream-level tests → tile layout
DRC/LVS-clean → tile timing characterized → demonstration fabric assembled
and re-verified → shuttle seat → measured silicon.
**Current position: spec ratified (ADR-0001); tile RTL and fabric description stamped, not yet re-verified here.**

## Tool flow

- **Fabric description**: FABulous tile/fabric format, as in `sky130-fpga`.
- **Verification**: cocotb + Icarus, bitstream-level tests on the simulated
  fabric.
- **Synthesis and mapping**: Yosys; nextpnr for mapping user designs onto
  the fabric.
- **Physical design**: OpenROAD place-and-route; layout, DRC, LVS and STA
  through klayout-tools (`klt`).

## Repo layout

```
spec/          ratified spec + decision records + porting plan
rtl/           tile RTL + fabric description (shared material under rtl/common/)
verification/  cocotb bitstream-level testbenches + results
layout/        tile GDS, routed DEF, DRC/LVS reports (klayout-tools driven)
measurements/  silicon characterization (empty until tape-out)
```

## Reproduce

The block's `klt signoff` grade is committed in `manifests/` and re-checked
by CI on every push and pull request. To regenerate it, follow
[manifests/README.md](manifests/README.md).

## License

Apache License 2.0 — see [LICENSE](LICENSE).

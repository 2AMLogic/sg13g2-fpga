# `rtl/fabric-2x2/` — the 2×2 demonstration fabric description

The 2×2 `LOGIC4` demonstration fabric named by `spec/target-spec.md` row 4,
plus the design used to show a net crossing a tile boundary (issue #80).

## Provenance: what is new here and what is stamped

This directory holds **only** the new fabric description and the cross-tile
design. Everything the generator actually builds — the tile descriptions, the
switch-matrix lists, the BEL, the models pack, the FABulous script and the
nextpnr source overlay — is the stamped material under
`rtl/common/fabulous/`, copied from `2AMLogic/sky130-fpga` at the commit in
`reuse.lock.json` and **not edited here**. All 54 `reuse.lock.json`
destinations hash to their recorded sha256 after this work.

| File | Origin |
|---|---|
| `fabric.csv` | **New here.** The 4×4 grid with a 2×2 `LOGIC4` core inside a `CAP_*` ring. |
| `cross_tile.v` | **New here.** A six-`lut4_ff_bel` chain that cannot fit in one tile. |
| `Tile/`, `Fabric/`, `FABulous.tcl`, `nextpnr/` | **Not here.** Stamped, in `rtl/common/fabulous/`. |

`fabric.csv` differs from the stamped `rtl/common/fabulous/fabric.csv` in the
`FabricBegin`…`FabricEnd` grid alone: the `ParametersBegin`…`ParametersEnd`
block (`ConfigBitMode,frame_based`, `GenerateDelayInSwitchMatrix,80`,
`MultiplexerStyle,generic`, `SuperTileEnable,FALSE`) and the five `Tile,` lines
are carried over unchanged.

## Why a one-file overlay rather than a standalone FABulous project

The stamped description is full of **project-relative** paths — `fabric.csv`
names `./Tile/LOGIC4/LOGIC4.csv` and the four `./Tile/CAP_*/…`,
`.FABulous/.env` sets `FAB_MODELS_PACK='../Fabric/models_pack.v'`, and
`LOGIC4.csv` names `./lut4_ff_bel.v` and `./LOGIC4_switch_matrix.list`. A
standalone project here would have to duplicate `.FABulous/.env`,
`FABulous.tcl` and `Fabric/models_pack.v`, all of which are vendored, and
duplicating a vendored file needs a decision record.

So the flow copies `rtl/common/fabulous/` into the ignored `flow/build/` scratch
tree and overlays this one `fabric.csv` on top of the copy. Editing
`rtl/common/fabulous/fabric.csv` in place is not an option either — it is a
`reuse.lock.json` destination (`mode: vendored`), so it diverges only with a
decision record.

## The grid

```
        X0      X1      X2      X3
  Y0    NULL    CAP_N   CAP_N   NULL
  Y1    CAP_W   LOGIC4  LOGIC4  CAP_E
  Y2    CAP_W   LOGIC4  LOGIC4  CAP_E
  Y3    NULL    CAP_S   CAP_S   NULL
```

Logic tiles land at `X1Y1`, `X2Y1`, `X1Y2`, `X2Y2`; the generated
`Fabric/eFPGA.v` instantiates them as `Tile_X1Y1_LOGIC4` and so on. The
`CAP_*` ring is required by FABulous 2.2.0's nextpnr-model step and is
**harness-only**: `CAP_N`/`CAP_S` declare only NORTH/SOUTH wires and
`CAP_E`/`CAP_W` only EAST/WEST, so they are position-agnostic single-axis
terminators and two of the same cap tile side by side is well-formed. A
`CAP_*` cell is not a logic tile.

`LOGIC4.csv` declares span-1 wires in all four directions (`N1`/`E1`/`S1`/`W1`,
offset ±1, four wires each), so adjacent logic tiles are directly connected and
no new routing resource was added.

## `cross_tile.v`

Six `lut4_ff_bel` cells in a chain. `LOGIC4.csv` declares exactly four BELs per
tile (`LA_`, `LB_`, `LC_`, `LD_`), so five or more cells **cannot** be placed in
one tile and the chain must straddle a boundary by pigeonhole — a property of
the fabric, not of the placer's choice. Six leaves margin.

Portless and constant-free, following `rtl/common/fabulous/nextpnr/top.v`: the
generated fabric has no IO BEL and no constant driver (both are recorded G1
findings; the generated `.FABulous/template.pcf` is empty, so no pads exist).

## Running it

```sh
verification/run.sh --setup     # once: fetch the pinned toolchain into flow/build/
verification/fabric-2x2.sh      # generate, map, route, assemble, check the crossing
```

Results and the claim boundary: `measurements/g2-fabric-2x2-generation/`.

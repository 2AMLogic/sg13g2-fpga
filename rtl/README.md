# rtl

Tile RTL. `rtl/common/` holds the stamped material copied from
`2AMLogic/sky130-fpga` at the commit pinned in `reuse.lock.json`, in three
groups: the FABulous tile/fabric description (`rtl/common/fabulous/`), the
tile RTL (`rtl/common/rtl/*.v`) and the switch-matrix generator
(`rtl/common/gen/gen_switch_matrix.py`). A vendored file diverges from the
master only with a decision record (CLAUDE.md, § "Scope discipline").

`rtl/fabric-2x2/` holds the generated 2×2 demonstration fabric and its
cross-tile mapping (issue #80); see
[`measurements/g2-fabric-2x2-generation/`](../measurements/g2-fabric-2x2-generation/).

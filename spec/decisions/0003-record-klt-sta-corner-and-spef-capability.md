# ADR-0003: Record what `klt sta` can run on SG13G2 (spec row 5)

- **Status**: Proposed — takes effect on merge.
- **Date**: 2026-10-18
- **Decided by**: Builder (issue #10)
- **Related**: [`spec/target-spec.md`](../target-spec.md) "What `klt sta` can and cannot run", [`measurements/20261018-tile-timing.md`](../../measurements/20261018-tile-timing.md)

## Decision

The target spec left open which corners `klt sta` resolves and whether SPEF extraction runs on SG13G2, to be established by #10. It is now established, as recorded in the measurement above. This ADR records the answer without changing the claim, the corner set or the period.

1. `klt sta` resolves all six SG13G2 corners by name via `pdk.corners` (three claim corners, three information-only 1.5 V-class corners). No corner is unrunnable.
2. SPEF extraction runs, but annotation is incomplete for nets below bracketed generate-instance names (325 of 365 nets), tracked at 2AMLogic/klayout-tools#3900. The claim corners' slacks are reported with that caveat, not as a full real-parasitics measurement.
3. The tile clock period (20.0 ns), I/O delays and propagated-clock mode are fixed in `layout/timing-period.md`; they are a measurement stimulus, not a ratified spec figure.

`spec/target-spec.md` is not edited: its open-capability paragraph is superseded by this record.

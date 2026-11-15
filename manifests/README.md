# manifests

`klt signoff` block manifest and its committed grade.

| File | Role |
|---|---|
| `sg13g2-fpga.json` | Block manifest: block name, `kind: digital`, and the evidence it cites. `evidence` cites the `layout/records/20261030-09fa1bd/` and `layout/records/20261024-bf24d46/` envelopes, each pinned by its `provenance.input.content_hash` when the envelope carries one: item 3 (`drc.json`), item 4 (`lvs.json`), item 5 (`sta.json` from `20261030-09fa1bd` plus the SDF-annotated `functional-verification-sdf-slow.json` and `functional-verification-sdf-fast.json` from `20261024-bf24d46`) and item 11 (`erc.json`, `lvs.json`, `place-and-route.json`); item 7 by `layout/records/20261024-bf24d46/functional-verification-sdf-slow.json`; item 8 by `characterization.json` (a generic envelope over `measurements/characterization.md`; the manifest pins the report's hash, which the envelope carries as `provenance.input.content_hash`); item 1 by the `klt signoff --attest 1` envelope `item-1.attestation.json`; item 2 by the `klt signoff --attest 2` envelope `item-2.attestation.json` over the committed routed stream `layout/records/20261030-09fa1bd/logic_tile_routed.gds` (the logic tile only: the 2×2 fabric is not assembled, so no fabric layout exists to attest); item 6 by a hash-bound `not_applicable` declaration. item 9 by the `klt signoff --attest 9` envelope `item-9.attestation.json`; item 10 by the `klt signoff --attest 10` envelope `item-10.attestation.json`. Every item is cited; item 5 grades `met` (its `sta` citation and both `functional-verification` SDF citations are met); `tier` is `null`. Paths resolve from the repo root.<br><br>**Item 7 disclosure (partial SDF annotation; cited record differs from items 2/3/4/11, same layout).** The cited report is the slow-corner (`slow_1p08V_125C`) SDF-annotated gate-level re-run of the cocotb bench on `20261024-bf24d46`'s routed netlist, `environment.sdf.annotated: true`. It comes from a different record than the envelopes items 2, 3, 4 and 11 cite (`20261030-09fa1bd`); this does not break the single-layout-hash property — both records' `sta.json` carry `provenance.input.content_hash: sha256:2fc468bddfb88dc2612e5bf12565fd4de03a143bc0c216272061a64728738a64` (`role: layout`) and their `logic_tile_routed.routed.v` are byte-identical. The same envelope states `environment.sdf.partial: true`: Icarus Verilog annotates IOPATH/INTERCONNECT delays but drops every SDF `TIMINGCHECK` section (`timingcheck: 4`), so `$setup`/`$hold`/`$width` checks ran against the cell library's placeholder timing, not the characterised SDF limits; setup/hold are covered by item 5's `klt sta` citation, not by this run. Also dropped before annotation (counts in `environment.sdf.dropped`): 370 zero-delay INTERCONNECT entries whose source is a bit-selected top-level input port (`zero_delay_bus_port_source_interconnect: 370`), and 640 COND-wrapped IOPATH entries whose condition is an operator expression Icarus rejects as malformed COND (`iopath_cond_expression: 640`) — the state-dependent delay detail of those arcs is NOT represented in this run; the cells' unconditional arcs and simple `COND D`-style entries are kept. `klt signoff` item 7 takes one citation, so item 7 cites the slow-corner report only; the fast-corner report (`functional-verification-sdf-fast.json`, pass; the same 4 TIMINGCHECK, 370 zero-delay INTERCONNECT and 640 COND-wrapped IOPATH entries dropped, re-read from its envelope) is cited under item 5 from the same `20261024-bf24d46` record, and the negative control (`functional-verification-sdf-negative.json`, corrupted 50 ns IOPATH SDF, fails as intended, exit 3) sits uncited in both records; `functional-verification` envelopes carry no `provenance.input.content_hash`, so the citation has no hash pin (tracked upstream as 2AMLogic/klayout-tools#5550). These SDF reports are append-only: `layout/sdf-verify.sh` refuses to write into an existing record (exit 2, `report exists; records are append-only`), so reproducing them requires a fresh record from a new run, not a re-run against an existing record. |
| `target-spec.json`, `target-spec-na.json` | Item 6's `not_applicable` documents: the ratified spec rows (kept in step with `spec/target-spec.md`) and the statement of why none is statistical. Editing either turns item 6 `stale_evidence` until the manifest hash is updated. |
| `inventories/item-1.json` | The T1 item-1 attestation inventory: the stamped tile RTL, the committed synthesized netlist in the cited record, and `layout/check-synth-fresh.sh`, which re-hashes both against that record's `synthesize.json` (`klt synthesize --check --netlist`). |
| `item-1.attestation.json` | The envelope `klt signoff --attest 1 --inventory manifests/inventories/item-1.json -o manifests/item-1.attestation.json` wrote; cited under `evidence."1"`. CI re-runs it with `--check`. Regenerate it whenever an inventoried file changes (an RTL edit turns the freshness check, and so item 1, stale until `layout/run.sh` records a new synthesis and the inventory and manifest cite it). |
| `inventories/item-10.json` | The T1 item-10 attestation inventory: hygiene files and the audit commands `klt signoff --attest 10` runs. |
| `inventories/item-9.json` | The T1 item-9 attestation inventory: the benches behind the claimed results (including the five stream/vector benches and their vendored generators, ADR-0004), the cold-start command `verification/cold-start.sh` (`local_only`: it fetches the pinned toolchain, so the attestation runner carries the committed outcome rather than executing it — `klt signoff --attest 9 --check` skips the command, a bare `--attest 9` runs it. This scopes the skip to the attestation, not to CI as a whole: `.github/workflows/verification.yml` is a separate job that does run the cold start on every change under `rtl/` or `verification/`) and the PDK/tool pins copied from `flow/pdk.json` and `flow/toolchain.json`. Re-attest after a pin change. |
| `item-9.attestation.json` | The envelope `klt signoff --attest 9 --inventory manifests/inventories/item-9.json -o manifests/item-9.attestation.json` wrote; cited under `evidence."9"`. CI re-runs it with `--check`. Regenerate it whenever an inventoried bench or script changes. |
| `characterization.json` | The generic (`"kind": "generic"`, `status: pass`, `t1_item: 8`) envelope over the hand-assembled characterization report, hash-anchored to it. Editing the report turns item 8 `stale_evidence` until this envelope and the manifest hash are updated. |
| `item-10.attestation.json` | The envelope `klt signoff --attest 10 --inventory manifests/inventories/item-10.json -o manifests/item-10.attestation.json` wrote; cited under `evidence."10"`. CI re-runs it with `--check`. Regenerate it whenever an inventoried file (README, LICENSE, `signoff.yml`, `verification.yml`) changes. |
| `item-2.attestation.json` | The envelope `klt signoff --attest 2 --input layout/records/20261030-09fa1bd/logic_tile_routed.gds -o manifests/item-2.attestation.json` wrote (needs a klt with item-2 attest; see the pin in `signoff.yml`); cited under `evidence."2"`. CI re-runs it with `--check`. Regenerate it with a new record's stream. |
| `sg13g2-fpga.signoff.json` | Verbatim output of `klt signoff --format json` on that manifest. Exit 3 (not yet T1) is the expected verdict while any item is unmet. |

`.github/workflows/signoff.yml` re-runs the grade on every push to `main` and
every pull request and fails if the output differs byte-for-byte from the
committed report. Exit 0 and 3 pass; exit 1 and 2 fail.

`.github/workflows/verification.yml` is the other half: `signoff.yml` re-grades
the committed evidence, that workflow re-runs the benches behind it
(`verification/cold-start.sh`) on every push to `main` and every pull request
touching `rtl/`, `verification/` or `flow/toolchain.json`. It is path-filtered,
so it must not be made a required status check.

## Regenerate

From the repo root, with the klt commit pinned in `signoff.yml` (the report
embeds the grader build, so do not use a different klt):

```
SHA=<commit pinned in .github/workflows/signoff.yml>
uvx --from "klayout-tools @ git+https://github.com/2AMLogic/klayout-tools@$SHA" \
  klt signoff --manifest manifests/sg13g2-fpga.json --format json \
  > manifests/sg13g2-fpga.signoff.json   # exit 3 is expected
```

Run it from a clean checkout (or a fresh clone), not a working tree that still has
`flow/build/`: the DRC and LVS envelopes name gitignored `flow/build/...` inputs, and
when those files exist locally `input_verified` becomes `true` where CI, which does not
have them, reports `null`.

## Rules

- A klt pin bump in `signoff.yml` lands in the same change as a regenerated
  report; the report's `build.git_commit` must equal the pin.
- A pin bump also moves `flow/toolchain.json`'s `klayout-tools.release` to the
  tag naming the new commit: the tag-agreement step in `signoff.yml` checks the
  tag dereferences to the pin, so a bump that moves only one of the two files
  fails CI.
- A manifest edit lands together with a regenerated report.
- The pin lives only in `signoff.yml`; do not repeat the SHA elsewhere.

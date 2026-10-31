# manifests

`klt signoff` block manifest and its committed grade.

| File | Role |
|---|---|
| `sg13g2-fpga.json` | Block manifest: block name, `kind: digital`, and the evidence it cites. `evidence` cites the `layout/records/20261030-09fa1bd/` envelopes, each pinned by its `provenance.input.content_hash`: item 3 (`drc.json`), item 4 (`lvs.json`), item 5 (`sta.json`) and item 11 (`erc.json`, `lvs.json`, `place-and-route.json`; `unmet` / `no_pdn` on a tapless library, `2AMLogic/klayout-tools#4199`); item 7 by `layout/records/20261027-5171c5d/functional-verification-sdf-slow.json`; item 8 by `characterization.json` (a generic envelope over `measurements/characterization.md`; the manifest pins the report's hash, which the envelope carries as `provenance.input.content_hash`); item 1 by the `klt signoff --attest 1` envelope `item-1.attestation.json`; item 2 by the `klt signoff --attest 2` envelope `item-2.attestation.json` over the committed routed stream `layout/records/20261030-09fa1bd/logic_tile_routed.gds` (the logic tile only: the 2×2 fabric is not assembled, so no fabric layout exists to attest); item 6 by a hash-bound `not_applicable` declaration. item 9 by the `klt signoff --attest 9` envelope `item-9.attestation.json`; item 10 by the `klt signoff --attest 10` envelope `item-10.attestation.json`. Every item is cited; item 5 grades `unmet` / `partial_coverage` (its `sta` citation is met, no `functional-verification` envelope is cited); `tier` is `null`. Paths resolve from the repo root.<br><br>**Item 7 disclosure (partial SDF annotation).** The cited report is the slow-corner (`slow_1p08V_125C`) SDF-annotated gate-level re-run of the cocotb bench on the routed netlist of the same record, `environment.sdf.annotated: true`. The same envelope states `environment.sdf.partial: true`: Icarus Verilog annotates IOPATH/INTERCONNECT delays but drops every SDF `TIMINGCHECK` section (4 dropped), so `$setup`/`$hold`/`$width` checks ran against the cell library's placeholder timing, not the characterised SDF limits; setup/hold are covered by item 5's `klt sta` citation, not by this run. 370 zero-delay INTERCONNECT entries were also removed before annotation (also in `environment.sdf.dropped`). `klt signoff` item 7 takes one citation, so the fast-corner report (`functional-verification-sdf-fast.json`, pass) and the negative control (`functional-verification-sdf-negative.json`, corrupted 50 ns IOPATH SDF, fails as intended, exit 3) sit in the same record uncited; `functional-verification` envelopes carry no `provenance.input.content_hash`, so the citation has no hash pin. Regenerate with `layout/sdf-verify.sh 20261027-5171c5d`. |
| `target-spec.json`, `target-spec-na.json` | Item 6's `not_applicable` documents: the ratified spec rows (kept in step with `spec/target-spec.md`) and the statement of why none is statistical. Editing either turns item 6 `stale_evidence` until the manifest hash is updated. |
| `inventories/item-1.json` | The T1 item-1 attestation inventory: the stamped tile RTL, the committed synthesized netlist in the cited record, and `layout/check-synth-fresh.sh`, which re-hashes both against that record's `synthesize.json` (`klt synthesize --check --netlist`). |
| `item-1.attestation.json` | The envelope `klt signoff --attest 1 --inventory manifests/inventories/item-1.json -o manifests/item-1.attestation.json` wrote; cited under `evidence."1"`. CI re-runs it with `--check`. Regenerate it whenever an inventoried file changes (an RTL edit turns the freshness check, and so item 1, stale until `layout/run.sh` records a new synthesis and the inventory and manifest cite it). |
| `inventories/item-10.json` | The T1 item-10 attestation inventory: hygiene files and the audit commands `klt signoff --attest 10` runs. |
| `inventories/item-9.json` | The T1 item-9 attestation inventory: the benches behind the claimed results (not the `NOT-RUN` ones), the cold-start command `verification/cold-start.sh` (`local_only`: it fetches the pinned toolchain, so CI does not re-run it) and the PDK/tool pins copied from `flow/pdk.json` and `flow/toolchain.json`. Re-attest after a pin change. |
| `item-9.attestation.json` | The envelope `klt signoff --attest 9 --inventory manifests/inventories/item-9.json -o manifests/item-9.attestation.json` wrote; cited under `evidence."9"`. CI re-runs it with `--check`. Regenerate it whenever an inventoried bench or script changes. |
| `characterization.json` | The generic (`"kind": "generic"`, `status: pass`, `t1_item: 8`) envelope over the hand-assembled characterization report, hash-anchored to it. Editing the report turns item 8 `stale_evidence` until this envelope and the manifest hash are updated. |
| `item-10.attestation.json` | The envelope `klt signoff --attest 10 --inventory manifests/inventories/item-10.json -o manifests/item-10.attestation.json` wrote; cited under `evidence."10"`. CI re-runs it with `--check`. Regenerate it whenever an inventoried file (README, LICENSE, `signoff.yml`) changes. |
| `item-2.attestation.json` | The envelope `klt signoff --attest 2 --input layout/records/20261030-09fa1bd/logic_tile_routed.gds -o manifests/item-2.attestation.json` wrote (needs a klt with item-2 attest; see the pin in `signoff.yml`); cited under `evidence."2"`. CI re-runs it with `--check`. Regenerate it with a new record's stream. |
| `sg13g2-fpga.signoff.json` | Verbatim output of `klt signoff --format json` on that manifest. Exit 3 (not yet T1) is the expected verdict while any item is unmet. |

`.github/workflows/signoff.yml` re-runs the grade on every push to `main` and
every pull request and fails if the output differs byte-for-byte from the
committed report. Exit 0 and 3 pass; exit 1 and 2 fail.

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
- A manifest edit lands together with a regenerated report.
- The pin lives only in `signoff.yml`; do not repeat the SHA elsewhere.

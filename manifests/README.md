# manifests

`klt signoff` block manifest and its committed grade.

| File | Role |
|---|---|
| `sg13g2-fpga.json` | Block manifest: block name, `kind: digital`, and the evidence it cites. `evidence` cites the `layout/records/20261027-5171c5d/` envelopes, each pinned by its `provenance.input.content_hash`: item 3 (`drc.json`), item 4 (`lvs.json`), item 5 (`sta.json`) and item 11 (`erc.json`, `lvs.json`, `place-and-route.json`; `unmet` / `no_pdn` on a tapless library, `2AMLogic/klayout-tools#4199`); item 6 by a hash-bound `not_applicable` declaration. item 9 by the `klt signoff --attest 9` envelope `item-9.attestation.json`; item 10 by the `klt signoff --attest 10` envelope `item-10.attestation.json`. Items 1, 2, 7 and 8 are uncited and grade `unmet` / `no_evidence`; item 5 grades `unmet` / `partial_coverage` (its `sta` citation is met, no `functional-verification` envelope is cited); `tier` is `null`. Paths resolve from the repo root. |
| `target-spec.json`, `target-spec-na.json` | Item 6's `not_applicable` documents: the ratified spec rows (kept in step with `spec/target-spec.md`) and the statement of why none is statistical. Editing either turns item 6 `stale_evidence` until the manifest hash is updated. |
| `inventories/item-10.json` | The T1 item-10 attestation inventory: hygiene files and the audit commands `klt signoff --attest 10` runs. |
| `inventories/item-9.json` | The T1 item-9 attestation inventory: the benches behind the claimed results (not the `NOT-RUN` ones), the cold-start command `verification/cold-start.sh` (`local_only`: it fetches the pinned toolchain, so CI does not re-run it) and the PDK/tool pins copied from `flow/pdk.json` and `flow/toolchain.json`. Re-attest after a pin change. |
| `item-9.attestation.json` | The envelope `klt signoff --attest 9 --inventory manifests/inventories/item-9.json -o manifests/item-9.attestation.json` wrote; cited under `evidence."9"`. CI re-runs it with `--check`. Regenerate it whenever an inventoried bench or script changes. |
| `item-10.attestation.json` | The envelope `klt signoff --attest 10 --inventory manifests/inventories/item-10.json -o manifests/item-10.attestation.json` wrote; cited under `evidence."10"`. CI re-runs it with `--check`. Regenerate it whenever an inventoried file (README, LICENSE, `signoff.yml`) changes. |
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

## Rules

- A klt pin bump in `signoff.yml` lands in the same change as a regenerated
  report; the report's `build.git_commit` must equal the pin.
- A manifest edit lands together with a regenerated report.
- The pin lives only in `signoff.yml`; do not repeat the SHA elsewhere.

# manifests

`klt signoff` block manifest and its committed grade.

| File | Role |
|---|---|
| `sg13g2-fpga.json` | Block manifest: block name, `kind: digital`, and the evidence it cites. `evidence` cites the `layout/records/20261027-5171c5d/` envelopes, each pinned by its `provenance.input.content_hash`: item 3 (`drc.json`), item 4 (`lvs.json`), item 5 (`sta.json`) and item 11 (`erc.json`, `lvs.json`, `place-and-route.json`; `unmet` / `no_pdn` on a tapless library, `2AMLogic/klayout-tools#4199`); item 6 by a hash-bound `not_applicable` declaration. Items 1, 2, 7, 8, 9 and 10 are uncited and grade `unmet` / `no_evidence`; `tier` is `null`. Paths resolve from the repo root. |
| `target-spec.json`, `target-spec-na.json` | Item 6's `not_applicable` documents: the ratified spec rows (kept in step with `spec/target-spec.md`) and the statement of why none is statistical. Editing either turns item 6 `stale_evidence` until the manifest hash is updated. |
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

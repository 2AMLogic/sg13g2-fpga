#!/usr/bin/env bash
# verification/manifest-mask.sh -- the shared checkout-path mask rule and
# duplicate-name guard for the generation drivers (issue #122).
#
# Both drivers (verification/fabric-2x2.sh, verification/fabulous-generation.sh)
# carried byte-identical copies of the mask declaration, and the #107 drift
# class -- the same rule spelled twice, one copy edited and one missed -- is
# exactly what untyped duplication invites. This helper is the single
# declaration. It deliberately shares only the two provably identical pieces:
#
# - the mask rule (HOSTPATHS, PATHMASK, mask_paths): rewrite every
#   checkout/host-absolute path prefix to a placeholder, most specific first;
# - the duplicate-name guard (assert_no_duplicate_names): a generated-file
#   manifest must never list one file twice -- once path-dependent raw, once
#   masked -- because the drivers' sort is deliberately not `sort -u`
#   (issue #107).
#
# Each driver keeps its own masked-set declaration and its own find/hash loop:
# G2 hashes two directories ($GENDIR and $PNRDIR) and prefixes its derived
# names, G1 hashes one and its names are its paths. One emit_manifest signature
# over both would carry a parameter only one caller uses (issue #122).
#
# Usage, from a driver that has already computed its paths:
#   source "$REPO/verification/manifest-mask.sh"
#   manifest_mask_init "$REPO" "$OSS" "$VENV" "$GENDIR"
# The init is explicit -- taking the repo/suite/venv/project paths as
# arguments -- because the implicit-global form is the shape that let the two
# copies drift in the first place. $HOME is read from the environment, as in
# the drivers this replaces. Sourcing is safe under `set -euo pipefail`: the
# file only defines functions and constants.
#
# Not under verification/common/: that directory is the vendored mirror of the
# master's test tree, pinned by reuse.lock.json. This is a repo-local helper.

# Set the mask rule for one checkout. <repo> is the checkout root, <oss> the
# pinned OSS CAD Suite tree, <venv> the pinned FABulous venv and <gendir> the
# driver's generated project tree -- <gendir> is masked first (most specific:
# it lives under <repo>), then <oss>/<venv>/<repo>, then $HOME when set.
# After init, HOSTPATHS and PATHMASK are exported to the caller's scope (the
# log normalizers spread them into their own sed invocations) and mask_paths
# applies the full rule.
manifest_mask_init() {
    local repo="$1" oss="$2" venv="$3" gendir="$4"
    HOSTPATHS=(-e "s#$oss#<oss-cad-suite>#g" -e "s#$venv#<fab-venv>#g" -e "s#$repo#<repo>#g")
    if [[ -n "${HOME:-}" ]]; then
        HOSTPATHS+=(-e "s#$HOME#<home>#g")
    fi
    PATHMASK=(-e "s#$gendir#<project>#g" "${HOSTPATHS[@]}")
    return 0
}

# The path rewrites proper, shared by the log normalizers and by the masked
# hashing. Content rewrites only; never applied to a binary -- the hashed
# masked set is the explicit allowlist at each driver's hashing site.
mask_paths() { sed "${PATHMASK[@]}"; }

# Assert one written generated-file manifest lists no filename twice (a raw
# list and the masked declaration both covering a file). Names are parsed
# against sha256sum's two-space separator, so a space inside a filename does
# not misalign the extracted field.
assert_no_duplicate_names() {
    local manifest="$1" dup
    dup="$(awk -F'  ' '{print $2}' "$manifest" | LC_ALL=C sort | uniq -d)"
    if [[ -n "$dup" ]]; then
        echo "error: generated-files manifest lists a file more than once:" >&2
        while IFS= read -r line; do echo "       duplicated: $line" >&2; done <<< "$dup"
        echo "       a raw list and the masked declaration both cover it; the masked" >&2
        echo "       hash would sit beside a path-dependent raw hash (issue #107)" >&2
        return 1
    fi
    return 0
}

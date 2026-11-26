# verification/common/flow/toolchain-pins.sh -- the FABulous / nextpnr-generic
# pin gate that verification/run.sh and verification/blinky.sh share (issue
# #169). Each driver carried a private copy of the pin reader and of both
# comparisons, so the correction that landed for the demo in #146 had to be
# made again for the bench runner in #151. Source it; it only defines
# functions, resolved against the tree it sits in:
#
#   pin <key>...                      the pin at that key path in flow/toolchain.json
#   nextpnr_version_field <banner>    the complete version inside the banner's (Version ...) field
#   nextpnr_banner_is_pinned <banner>
#   fabulous_banner_is_pinned <banner>
#                                     exit 0 when the banner names the pinned tool, nonzero otherwise
#
# The predicates take the banner the caller captured and only return a
# status: a mismatch is reported by the driver, in its own context, and the
# banner a driver records is the one it passed in here.
#
# Exact matches only (issues #144, #151): a warm install whose version merely
# starts with the pin (FABulous 2.2.0rc1 vs pin 2.2.0, nextpnr ...-dirty) must
# stop before any work with the tool -- a substring match rides it through.
# FABulous is compared on its whole banner line; nextpnr on the complete
# version inside its (Version ...) field, because the banner's leading tag
# can be shorter than the field ("nextpnr-generic" vs
# nextpnr-0.11.1-54-g861c57be), so the field is the truth. A missing pin
# matches nothing.

TOOLCHAIN_MANIFEST="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/flow/toolchain.json"

pin() {  # pin <key>... -- flow/toolchain.json is the only copy of every pin (issue #88)
    python3 -I -c 'import json,sys
d = json.load(open(sys.argv[1]))
for k in sys.argv[2:]:
    if not isinstance(d, dict) or k not in d:
        sys.exit("flow/toolchain.json: no pin " + ".".join(sys.argv[2:]))
    d = d[k]
print(d)' "$TOOLCHAIN_MANIFEST" "$@"
}

nextpnr_version_field() { sed -n 's/.*(Version \([^)]*\)).*/\1/p' <<<"$1"; }

fabulous_banner_is_pinned() {
    local version
    version="$(pin fabulous version)" || return 1
    [[ -n "$version" && "$1" == "FABulous CLI $version" ]]
}

nextpnr_banner_is_pinned() {
    local version
    version="$(pin nextpnr-generic version)" || return 1
    [[ -n "$version" && "$(nextpnr_version_field "$1")" == "$version" ]]
}

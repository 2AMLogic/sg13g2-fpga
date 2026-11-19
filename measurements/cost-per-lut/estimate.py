#!/usr/bin/env python3
"""Area and cost per LUT4 for the sg13g2-fpga logic tile.

Derives die-area and cell-area per LUT4 from a committed layout record
(`place-and-route.json` + `synthesize.json`, as written by `layout/run.sh`)
and, given a cited public shuttle price (`prices.json` next to this script),
an estimate of the MPW submission fee attributable to one LUT4's design
area. The MPW rate is priced per mm2 of registered area *per submission*
(the listed standard submission includes a fixed number of bare-die samples
of the submitted design — see `ordering_unit` in `prices.json`), so the
figures labelled below are that submission fee's per-LUT4 share, not a
per-chip or per-die price. The estimate is silicon-area-only: no packaging,
test, NRE, yield, minimum-purchase or die-count rounding is included.

Only records of the logic tile are accepted: both record envelopes must
carry `hdl_toplevel: logic_tile_routed` and must agree (a counter smoke
record, or a mismatched pair, is a named-field error — exit 2).

Usage:
    estimate.py [RECORD_DIR] [--prices PRICES_JSON] [--markdown]
    estimate.py --self-test

RECORD_DIR defaults to the latest record under `layout/records/`. `--markdown`
emits the input and result tables in the form used by the dated record under
`measurements/`.
"""

import argparse
import contextlib
import io
import json
import sys
import tempfile
from datetime import date
from pathlib import Path

# spec/target-spec.md row 1: "Logic tile | 4x LUT4 + 1 FF per LUT, no carry".
LUT4_PER_TILE = 4
# The tile design this estimator's LUT4_PER_TILE divisor applies to; both
# record envelopes must identify it via `hdl_toplevel`.
EXPECTED_DESIGN = "logic_tile_routed"

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
RECORDS_DIR = REPO_ROOT / "layout" / "records"
DEFAULT_PRICES = SCRIPT_DIR / "prices.json"

MM2_PER_UM2 = 1e-6


class EstimateError(Exception):
    pass


def load_json(path):
    try:
        text = Path(path).read_text(encoding="utf-8")
    except FileNotFoundError:
        raise EstimateError(f"missing file: {path}")
    try:
        return json.loads(text)
    except json.JSONDecodeError as exc:
        raise EstimateError(f"invalid JSON in {path}: {exc}")


def require(obj, field, where):
    if not isinstance(obj, dict):
        raise EstimateError(f"{where}: expected a JSON object")
    if field not in obj or obj[field] is None:
        raise EstimateError(f"{where}: required field '{field}' missing or null")
    return obj[field]


def require_number(obj, field, where):
    value = require(obj, field, where)
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise EstimateError(f"{where}: field '{field}' must be a number, got {value!r}")
    return float(value)


def require_string(obj, field, where):
    value = require(obj, field, where)
    if not isinstance(value, str) or not value:
        raise EstimateError(f"{where}: field '{field}' must be a non-empty string, got {value!r}")
    return value


def load_prices(path):
    data = load_json(path)
    price = require_number(data, "price_per_area_unit", f"{path}")
    if price <= 0:
        raise EstimateError(f"{path}: 'price_per_area_unit' must be positive")
    currency = require_string(data, "currency", path)
    unit = require(data, "area_unit", path)
    if unit != "mm2":
        raise EstimateError(
            f"{path}: 'area_unit' must be 'mm2' (areas are converted to mm2), got {unit!r}"
        )
    basis = require_string(data, "area_basis", path)
    ordering_unit = require_string(data, "ordering_unit", path)
    source = require(data, "source", path)
    if not isinstance(source, dict):
        raise EstimateError(f"{path}: 'source' must be a JSON object")
    url = require_string(source, "url", f"{path} source")
    if not url.startswith(("http://", "https://")):
        raise EstimateError(f"{path}: 'source.url' must be an http(s) URL, got {url!r}")
    retrieved = require(source, "date_retrieved", f"{path} source")
    try:
        date.fromisoformat(retrieved)
    except (TypeError, ValueError):
        raise EstimateError(
            f"{path}: 'source.date_retrieved' must be an ISO date (YYYY-MM-DD), got {retrieved!r}"
        )
    return {
        "price_per_area_unit": price,
        "currency": currency,
        "area_unit": unit,
        "area_basis": basis,
        "ordering_unit": ordering_unit,
        "source": source,
    }


def check_design(record_dir, where, design):
    if not isinstance(design, str) or not design:
        raise EstimateError(f"{where}: field 'hdl_toplevel' must be a non-empty string, got {design!r}")
    if design != EXPECTED_DESIGN:
        raise EstimateError(
            f"{where}: field 'hdl_toplevel' is {design!r}, not {EXPECTED_DESIGN!r}: "
            f"the LUT4_PER_TILE={LUT4_PER_TILE} divisor only applies to the logic tile record"
        )


def load_record(record_dir):
    record_dir = Path(record_dir)
    pnr = load_json(record_dir / "place-and-route.json")
    synth = load_json(record_dir / "synthesize.json")
    pnr_design = require(pnr, "hdl_toplevel", f"{record_dir}/place-and-route.json")
    synth_design = require(synth, "hdl_toplevel", f"{record_dir}/synthesize.json")
    check_design(record_dir, f"{record_dir}/place-and-route.json", pnr_design)
    check_design(record_dir, f"{record_dir}/synthesize.json", synth_design)
    if pnr_design != synth_design:
        raise EstimateError(
            f"{record_dir}: field 'hdl_toplevel' mismatch: place-and-route.json says "
            f"{pnr_design!r}, synthesize.json says {synth_design!r}"
        )
    return {
        "record_dir": record_dir,
        "design": pnr_design,
        "die_area_um2": require_number(pnr, "die_area_um2", f"{record_dir}/place-and-route.json"),
        "core_area_um2": require_number(pnr, "core_area_um2", f"{record_dir}/place-and-route.json"),
        "utilization_pct": require_number(pnr, "utilization_pct", f"{record_dir}/place-and-route.json"),
        "cell_area_um2": require_number(synth, "area_um2", f"{record_dir}/synthesize.json"),
        "instance_count": require(synth, "instance_count", f"{record_dir}/synthesize.json"),
    }


def latest_record(records_dir=RECORDS_DIR):
    candidates = sorted(
        d
        for d in Path(records_dir).iterdir()
        if d.is_dir() and (d / "place-and-route.json").exists() and (d / "synthesize.json").exists()
    )
    if not candidates:
        raise EstimateError(f"no layout record found under {records_dir}")
    return candidates[-1]


def per_lut(record, lut4_per_tile=LUT4_PER_TILE):
    return {
        "die_um2": record["die_area_um2"] / lut4_per_tile,
        "core_um2": record["core_area_um2"] / lut4_per_tile,
        "cell_um2": record["cell_area_um2"] / lut4_per_tile,
    }


def cost_eur(area_mm2, prices):
    return area_mm2 * prices["price_per_area_unit"]


def format_report(record, areas, prices=None):
    lines = [
        f"record:            {record['record_dir']}",
        f"design:            {record['design']} (hdl_toplevel, both envelopes)",
        f"LUT4 per tile:     {LUT4_PER_TILE} (spec/target-spec.md row 1)",
        "",
        "area per LUT4      um2          mm2",
        f"  die              {areas['die_um2']:>12.4f}  {areas['die_um2'] * MM2_PER_UM2:.7f}",
        f"  core             {areas['core_um2']:>12.4f}  {areas['core_um2'] * MM2_PER_UM2:.7f}",
        f"  cell (synth)     {areas['cell_um2']:>12.4f}  {areas['cell_um2'] * MM2_PER_UM2:.7f}",
    ]
    if prices is not None:
        src = prices["source"]
        lines += [
            "",
            f"price:             {prices['price_per_area_unit']:g} {prices['currency']} per {prices['area_unit']}"
            f" ({prices['area_basis']})",
            f"ordering unit:     {prices['ordering_unit']}",
            f"price source:      retrieved {src['date_retrieved']}, {src['url']}",
            "",
            "estimated MPW submission fee attributable to one LUT4's design area",
            "(ESTIMATE, silicon area only):",
            f"  die area:        {cost_eur(areas['die_um2'] * MM2_PER_UM2, prices):.4f} {prices['currency']}",
            f"  core area:       {cost_eur(areas['core_um2'] * MM2_PER_UM2, prices):.4f} {prices['currency']}",
            f"  cell area:       {cost_eur(areas['cell_um2'] * MM2_PER_UM2, prices):.4f} {prices['currency']}",
            "",
            "estimate caveats: the MPW rate buys one submission (see ordering unit above;",
            "the listed standard submission includes a fixed number of bare-die samples), so",
            "each figure is that submission fee's share attributable to one LUT4's area, not",
            "a per-chip price; excludes packaging, test, NRE, yield, minimum purchase and",
            "die-count rounding; tile area excludes IO, config load, clock tree and fabric",
            "periphery; LUT count is LUT4 only (no carry).",
        ]
    return "\n".join(lines)


def format_markdown(record, areas, prices):
    src = prices["source"]
    inputs_table = [
        "| Item | Value |",
        "|---|---|",
        f"| Layout record | `{record['record_dir'].name}` |",
        f"| `hdl_toplevel` (both envelopes) | {record['design']} |",
        f"| `place-and-route.json` `die_area_um2` | {record['die_area_um2']} µm² |",
        f"| `place-and-route.json` `core_area_um2` | {record['core_area_um2']} µm² |",
        f"| `place-and-route.json` `utilization_pct` | {record['utilization_pct']} % |",
        f"| `synthesize.json` `area_um2` | {record['cell_area_um2']} µm² |",
        f"| `synthesize.json` `instance_count` | {record['instance_count']} |",
        f"| LUT4 per tile | {LUT4_PER_TILE} (`spec/target-spec.md` row 1) |",
        f"| Price rate | {prices['price_per_area_unit']:g} {prices['currency']} per {prices['area_unit']} ({prices['area_basis']}) |",
        f"| Ordering unit | {prices['ordering_unit']} |",
        f"| Price source | {src['url']} (retrieved {src['date_retrieved']}) |",
    ]
    result_table = [
        "| Quantity | Value |",
        "|---|---|",
        f"| Die area per LUT4 | {areas['die_um2']:.4f} µm² = {areas['die_um2'] * MM2_PER_UM2:.7f} mm² |",
        f"| Core area per LUT4 | {areas['core_um2']:.4f} µm² = {areas['core_um2'] * MM2_PER_UM2:.7f} mm² |",
        f"| Cell area per LUT4 (`synthesize.json` `area_um2` / {LUT4_PER_TILE}) | {areas['cell_um2']:.4f} µm² = {areas['cell_um2'] * MM2_PER_UM2:.7f} mm² |",
        f"| Submission fee attributable to one LUT4's die area (estimate) | {cost_eur(areas['die_um2'] * MM2_PER_UM2, prices):.2f} {prices['currency']} |",
        f"| Submission fee attributable to one LUT4's core area (estimate) | {cost_eur(areas['core_um2'] * MM2_PER_UM2, prices):.2f} {prices['currency']} |",
        f"| Submission fee attributable to one LUT4's cell area (estimate) | {cost_eur(areas['cell_um2'] * MM2_PER_UM2, prices):.2f} {prices['currency']} |",
    ]
    return "\n".join(inputs_table + [""] + result_table)


def self_test():
    with tempfile.TemporaryDirectory() as tmp:
        record_dir = Path(tmp) / "record"
        record_dir.mkdir()
        (record_dir / "place-and-route.json").write_text(
            json.dumps(
                {
                    "hdl_toplevel": EXPECTED_DESIGN,
                    "die_area_um2": 10468.4,
                    "core_area_um2": 8491.39,
                    "utilization_pct": 43.8462,
                }
            )
        )
        (record_dir / "synthesize.json").write_text(
            json.dumps({"hdl_toplevel": EXPECTED_DESIGN, "area_um2": 3557.4336, "instance_count": 181})
        )

        areas = per_lut(load_record(record_dir))
        assert abs(areas["die_um2"] - 2617.1) < 1e-9, areas
        assert abs(areas["cell_um2"] - 889.3584) < 1e-9, areas

        good_prices = {
            "price_per_area_unit": 2800,
            "currency": "EUR",
            "area_unit": "mm2",
            "area_basis": "registered (drawn) die area submitted to the MPW run",
            "ordering_unit": "one MPW submission (standard submission includes 40 bare-die samples)",
            "source": {
                "url": "https://example.invalid/mpw",
                "date_retrieved": "2026-11-19",
            },
        }
        prices_path = Path(tmp) / "prices.json"
        prices_path.write_text(json.dumps(good_prices))
        prices = load_prices(prices_path)
        assert abs(cost_eur(areas["die_um2"] * MM2_PER_UM2, prices) - 7.32788) < 1e-9
        assert abs(cost_eur(areas["cell_um2"] * MM2_PER_UM2, prices) - 2.49020352) < 1e-9

        def expect_error(exc_type, fn, label):
            try:
                fn()
            except exc_type:
                return
            raise AssertionError(f"expected {exc_type.__name__} for {label}")

        bad_record = Path(tmp) / "bad-record"
        bad_record.mkdir()
        (bad_record / "place-and-route.json").write_text(json.dumps({"utilization_pct": 40}))
        (bad_record / "synthesize.json").write_text(json.dumps({"area_um2": 1.0, "instance_count": 1}))
        expect_error(EstimateError, lambda: load_record(bad_record), "record without die_area_um2")

        def write_record(path, pnr, synth):
            path.mkdir()
            (path / "place-and-route.json").write_text(json.dumps(pnr))
            (path / "synthesize.json").write_text(json.dumps(synth))

        counter_dir = Path(tmp) / "counter-record"
        write_record(
            counter_dir,
            {"hdl_toplevel": "counter", "die_area_um2": 2411.9, "core_area_um2": 1931.36, "utilization_pct": 42.8572},
            {"hdl_toplevel": "counter", "area_um2": 968.5732, "instance_count": 62},
        )
        expect_error(EstimateError, lambda: load_record(counter_dir), "counter (non-tile) record")

        mismatch_dir = Path(tmp) / "mismatch-record"
        write_record(
            mismatch_dir,
            {"hdl_toplevel": EXPECTED_DESIGN, "die_area_um2": 10468.4, "core_area_um2": 8491.39, "utilization_pct": 43.8462},
            {"hdl_toplevel": "counter", "area_um2": 3557.4336, "instance_count": 181},
        )
        expect_error(EstimateError, lambda: load_record(mismatch_dir), "mismatched hdl_toplevel pair")

        err = io.StringIO()
        with contextlib.redirect_stderr(err):
            rc = main([str(counter_dir)])
        assert rc == 2, f"expected exit 2 for a counter record, got {rc}"
        assert "hdl_toplevel" in err.getvalue(), err.getvalue()

        for label, patch in [
            ("missing source", lambda d: d.pop("source")),
            ("missing date_retrieved", lambda d: d["source"].pop("date_retrieved")),
            ("bad area unit", lambda d: d.update(area_unit="um2")),
            ("non-positive price", lambda d: d.update(price_per_area_unit=0)),
            ("missing ordering_unit", lambda d: d.pop("ordering_unit")),
            ("missing area_basis", lambda d: d.pop("area_basis")),
        ]:
            broken = json.loads(json.dumps(good_prices))
            patch(broken)
            broken_path = Path(tmp) / "broken.json"
            broken_path.write_text(json.dumps(broken))
            expect_error(EstimateError, lambda p=broken_path: load_prices(p), label)

    print("self-test OK")
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("record_dir", nargs="?", default=None, help="layout record directory (default: latest under layout/records/)")
    parser.add_argument("--prices", default=str(DEFAULT_PRICES), help="cited price input JSON (default: prices.json next to this script)")
    parser.add_argument("--markdown", action="store_true", help="emit the input and result tables as markdown")
    parser.add_argument("--self-test", action="store_true", help="run the built-in arithmetic and validation checks")
    args = parser.parse_args(argv)

    if args.self_test:
        return self_test()

    try:
        record_dir = Path(args.record_dir) if args.record_dir else latest_record()
        record = load_record(record_dir)
        areas = per_lut(record)
        prices = load_prices(args.prices)
    except EstimateError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    if args.markdown:
        print(format_markdown(record, areas, prices))
    else:
        print(format_report(record, areas, prices))
    return 0


if __name__ == "__main__":
    sys.exit(main())

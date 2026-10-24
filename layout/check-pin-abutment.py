#!/usr/bin/env python3
"""Check tile-abutment pin placement from a klt place-and-route envelope's pins[].

A tile abuts a copy of itself, so the facing pairs must coincide:
  x(n_out[t]) == x(s_in[t]),  x(s_out[t]) == x(n_in[t])
  y(e_out[t]) == y(w_in[t]),  y(w_out[t]) == y(e_in[t])
and every n_*/s_*/e_*/w_* track pin must sit on the edge its name implies.
Only the 4+4 track pins per side are checked; clk, cfg[*] and the power pins
are not part of the abutment interface.

Usage: check-pin-abutment.py <place-and-route.json>   exit 0 ok, 1 violation
       check-pin-abutment.py --self-test <place-and-route.json>
"""
import copy, json, sys

EDGE = {"n": "north", "e": "east", "s": "south", "w": "west"}
TRACKS = 4
TOL = 0.005  # um


def check(env):
    pins = {p["name"]: p for p in env.get("pins") or []}
    errs = []
    for d, edge in EDGE.items():
        for io in ("in", "out"):
            for t in range(TRACKS):
                n = f"{d}_{io}[{t}]"
                if n not in pins:
                    errs.append(f"{n}: missing from pins[]")
                elif pins[n]["edge"] != edge:
                    errs.append(f"{n}: on {pins[n]['edge']} edge, expected {edge}")
    # (pin, facing pin, coordinate that must match)
    pairs = [("n_out", "s_in", "x_um"), ("s_out", "n_in", "x_um"),
             ("e_out", "w_in", "y_um"), ("w_out", "e_in", "y_um")]
    for a, b, c in pairs:
        for t in range(TRACKS):
            pa, pb = pins.get(f"{a}[{t}]"), pins.get(f"{b}[{t}]")
            if pa and pb and abs(pa[c] - pb[c]) > TOL:
                errs.append(f"{a}[{t}] {c}={pa[c]} != {b}[{t}] {c}={pb[c]}")
    return errs


def main(argv):
    self_test = argv[0] == "--self-test"
    env = json.load(open(argv[-1]))
    errs = check(env)
    if self_test:
        # Negative cases: all pins on one edge (the unconstrained run), and one
        # shifted facing pin. Both must be rejected; the real envelope must pass.
        bad = copy.deepcopy(env)
        for p in bad["pins"]:
            p["edge"], p["x_um"] = "east", 101.955
        shifted = copy.deepcopy(env)
        for p in shifted["pins"]:
            if p["name"] == "n_out[2]":
                p["x_um"] += 1.0
        for name, e in (("real envelope", env), ("all-east", bad), ("shifted n_out[2]", shifted)):
            res = check(e)
            want_bad = name != "real envelope"
            print(f"{name}: {'FAIL' if res else 'ok'} ({len(res)} findings)")
            if bool(res) != want_bad:
                print("self-test failed"); return 1
        print("self-test passed"); return 0
    for e in errs:
        print(e)
    print("abutment: " + ("NOT satisfied" if errs else "satisfied"))
    return 1 if errs else 0


sys.exit(main(sys.argv[1:]))

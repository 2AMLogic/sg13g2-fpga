"""Place the vendored harness pad model on the north and south caps of the 2×2 fabric."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "verification/common/flow"))
import nextpnr_io_overlay as overlay

if __name__ == "__main__":
    overlay.CAPS["X1Y3"] = overlay.CAPS.pop("X1Y2")
    overlay.main(*sys.argv[1:])

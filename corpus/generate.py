#!/usr/bin/env python3
"""Regenerate the deterministic, inert boundary-value corpus."""

from pathlib import Path


ROOT = Path(__file__).resolve().parent
CASES = {
    "01-short.txt": b"normal-input",
    "02-format-markers.txt": b"%08x-%08x-%08x-%n",
    "03-boundary-99.txt": b"A" * 99,
    "04-boundary-100.txt": b"B" * 100,
    "05-overflow-101.txt": b"C" * 101,
    "06-overflow-160.txt": b"D" * 160,
    "07-overflow-200.txt": b"E" * 200,
    "08-overflow-517.txt": b"F" * 517,
}


for name, payload in CASES.items():
    (ROOT / name).write_bytes(payload)

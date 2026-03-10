#!/usr/bin/env python3
"""
Execution wrapper: Train the MLB prop over/under ML model.
Run from workspace root: python execution/mlb_data/train_mlb_model.py
"""
import os
import subprocess
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
BACKEND = WORKSPACE / "nba-data-backend"
MODULE = "src.ml.mlb_train"


def main():
    if not (BACKEND / "src/ml/mlb_train.py").exists():
        print("Error: mlb_train.py not found under backend", file=sys.stderr)
        sys.exit(1)
    cmd = [sys.executable, "-m", MODULE] + sys.argv[1:]
    result = subprocess.run(
        cmd,
        cwd=str(BACKEND),
        env={**os.environ, "PYTHONPATH": str(BACKEND)},
    )
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()

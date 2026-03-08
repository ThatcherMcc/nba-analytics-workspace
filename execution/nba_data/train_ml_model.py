#!/usr/bin/env python3
"""
Execution wrapper: Train the prop over/under ML model.
Run from workspace root: python execution/nba_data/train_ml_model.py
"""
import subprocess
import sys
import os

WORKSPACE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BACKEND = os.path.join(WORKSPACE, "nba-data-backend")

def main():
    cmd = [
        sys.executable, "-m", "src.ml.train",
    ]
    result = subprocess.run(cmd, cwd=BACKEND)
    sys.exit(result.returncode)

if __name__ == "__main__":
    main()

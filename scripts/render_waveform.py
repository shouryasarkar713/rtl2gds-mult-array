#!/usr/bin/env python3
"""Generates Figure 2 (waveform_example.png) using genuine GTKWave screen capture.

This script executes scripts/make_gtkwave_screenshot.py to ensure the report
waveform screenshot always reflects the authentic GTKWave capture.
"""
import os
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
TARGET_SCRIPT = os.path.join(SCRIPT_DIR, "make_gtkwave_screenshot.py")

if __name__ == "__main__":
    ret = subprocess.run([sys.executable, TARGET_SCRIPT])
    sys.exit(ret.returncode)

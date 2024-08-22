#!/usr/bin/env python3

import os
import sys
from pathlib import Path

from pynvim import attach

# https://github.com/yyx990803/launch-editor/tree/5541bdedc254a43c47525a8e2a6923c85392c42b?tab=readme-ov-file#to-run-a-custom-launch-script
file_path = sys.argv[1].replace("$", r"\$")  # Handle $ in path
line_number = sys.argv[2]
column = sys.argv[3]

uid = os.getuid()

path = Path(f"/run/user/{uid}")
paths = path.glob("nvim*")
socket_path = next(paths)

attach("socket", path=str(socket_path)).command(f"e +{line_number} {file_path}")

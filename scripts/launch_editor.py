#!/usr/bin/env python3

import errno
import os
import sys
from pathlib import Path

from pynvim import attach

# https://github.com/yyx990803/launch-editor/tree/5541bdedc254a43c47525a8e2a6923c85392c42b?tab=readme-ov-file#to-run-a-custom-launch-script
file_path = sys.argv[1].replace("$", r"\$")  # Handle $ in path
line_number = sys.argv[2]
column = sys.argv[3]

run_dir = Path(f"/run/user/{os.getuid()}")
nvim_socket_paths = run_dir.glob("nvim*")
try:
    most_recent_socket_path = max(nvim_socket_paths, key=lambda p: p.stat().st_ctime)
except ValueError:  # Max iterable argument is empty
    print("No nvim socket found.", file=sys.stderr)
    sys.exit(errno.ESRCH)  # No such process

attach("socket", path=str(most_recent_socket_path)).command(
    f"e +{line_number} {file_path}"
)

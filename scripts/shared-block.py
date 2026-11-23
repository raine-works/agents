"""Puts the shared rules into a repository's AGENTS.md, between the markers, replacing what's there.

    python3 scripts/shared-block.py <shared AGENTS.md> <repository's AGENTS.md> <repository name>

A file without the markers gets the block at its top, above what it had; a missing file is made, with the block and a
heading for the repository's own rules.
"""

import pathlib
import sys

BEGIN = (
    "<!-- BEGIN raine-works/agents: the shared rules, synced from https://github.com/raine-works/agents. "
    "Change them there, not here: this block is replaced on every sync. -->"
)
END = "<!-- END raine-works/agents -->"

shared_path, target_path, repo = sys.argv[1:4]
block = f"{BEGIN}\n\n{pathlib.Path(shared_path).read_text().strip()}\n\n{END}"
target = pathlib.Path(target_path)

if not target.exists():
    text = f"{block}\n\n# {repo}\n\nThis repository's own rules go here.\n"
else:
    current = target.read_text()
    if BEGIN in current and END in current:
        before, rest = current.split(BEGIN, 1)
        after = rest.split(END, 1)[1]
        text = f"{before}{block}{after}"
    else:
        text = f"{block}\n\n{current.lstrip()}"

target.write_text(text)

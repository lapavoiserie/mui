#!/usr/bin/env python3
"""Turn the six backends' reports into one table.

Read on stdin, one line per backend: `<backend> <type> <type> …`.
"""
import sys

ORDER = ["pui", "cui", "sui", "aui", "qui", "wui"]

decl = {}
for line in sys.stdin:
    parts = line.split()
    if not parts:
        continue
    decl[parts[0]] = set(parts[1:])

backends = [b for b in ORDER if b in decl]
types = sorted(set().union(*decl.values())) if decl else []
width = max([len(t) for t in types] + [4])

print("%-*s  %s" % (width, "type", " ".join("%-3s" % b for b in backends)))
for t in types:
    marks = " ".join("%-3s" % ("x" if t in decl[b] else ".") for b in backends)
    print("%-*s  %s" % (width, t, marks))
print()
print("%-*s  %s" % (width, "total", " ".join("%-3d" % len(decl[b]) for b in backends)))

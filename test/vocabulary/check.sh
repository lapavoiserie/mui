#!/usr/bin/env bash
# What each backend declares, asked through the door markup itself asks.
#
# `mui.macros.Backend.types()` is what `ui()` consults, so this report cannot
# drift from what compiling would accept. The recorded table is committed:
# changing a backend's vocabulary means updating it, on purpose.
set -u
cd "$(dirname "$0")"

reports=""
for b in pui cui sui aui qui wui; do
    line=$(haxe $b.hxml 2>/dev/null | grep "^$b ")
    if [ -z "$line" ]; then
        echo "no report from $b -- run 'haxe $b.hxml' to see why" >&2
        exit 1
    fi
    reports="$reports$line"$'\n'
done

printf '%s' "$reports" | python3 matrix.py > matrix.out

if [ "${1:-}" = "--record" ]; then
    mv matrix.out matrix.txt
    echo "recorded"
    exit 0
fi

if diff -u matrix.txt matrix.out; then
    rm -f matrix.out
    echo "all good"
else
    echo "the declared vocabulary moved -- ./check.sh --record once that is intended" >&2
    rm -f matrix.out
    exit 1
fi

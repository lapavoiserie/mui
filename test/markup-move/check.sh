#!/usr/bin/env bash
# A move given in markup on the node route (`KCallbackMove`).
#
# `<ReorderList onMove={(from, to) -> …}/>` is written the same on every
# backend; the node carries it as the canon's string callback, "from,to".
# Checked against a one-tag fake vocabulary, so it says what mui does and
# nothing about any backend.
#
#   ./test/markup-move/check.sh
set -u
cd "$(dirname "$0")"
out=$(haxe -cp . -cp ../../src -lib rui -lib nui --macro "FakeVocabulary.register()" -main Moves --interp 2>&1)
if echo "$out" | grep -qxF "moves: 2->0"; then
	echo "ok   a move reaches the lambda as two indices, and a malformed one reports nothing"
	echo ""; echo "all good"; exit 0
fi
echo "FAIL expected 'moves: 2->0', got:"; echo "$out" | head -5
exit 1

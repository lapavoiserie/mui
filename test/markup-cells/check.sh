#!/usr/bin/env bash
# A cell given to a two-way value, on the node route (`Backend.Vocabulary.cellOf`).
#
# `<Toggle isOn={muted}/>` with `muted` a `rui.state.State<Bool>`: the node gets
# the cell's value, and `onToggle` becomes its `set`. A backend that builds
# nodes -- wui -- had no way to take a cell, so a bound control could not be
# written in markup there at all. Checked against a two-tag fake vocabulary, so
# it says what mui does and nothing about any backend.
#
#   ./test/markup-cells/check.sh
set -u
cd "$(dirname "$0")"
fails=0
common="-cp . -cp ../../src -lib rui -lib nui --macro FakeVocabulary.register()"

out=$(haxe $common -main Cells --interp 2>&1)
check() {
	if echo "$out" | grep -qF "$1"; then echo "ok   $2"; else echo "FAIL $2 -- expected: $1"; echo "$out" | head -5; fails=$((fails + 1)); fi
}
check "plain: PBool(true) callback=false" "a plain value stays a value, with no callback"
check "bound: PBool(true) callback=true" "a cell gives its value and its callback"
check "after: false" "and the callback writes the cell"

out=$(haxe $common -cp refused -main NotTwoWay --interp 2>&1)
if echo "$out" | grep -q 'ne lie pas "text" à une cellule'; then
	echo "ok   a cell where nothing reports back is refused by name"
else
	echo "FAIL a cell on a one-way value was not refused:"; echo "$out" | head -5; fails=$((fails + 1))
fi

echo ""
[ "$fails" -eq 0 ] && echo "all good" || echo "$fails failed"
exit "$fails"

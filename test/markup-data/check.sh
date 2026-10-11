#!/usr/bin/env bash
# Data children on the node route (`Backend.Vocabulary.dataChildren`).
#
# A picker's options, written as `Text` children or spliced from a list, used
# to be read for a backend building its own control and then dropped when the
# tag became a node: wui drew a picker with no options. Checked against a fake
# vocabulary, so it says what mui does and nothing about any backend.
#
#   ./test/markup-data/check.sh
set -u
cd "$(dirname "$0")"
fails=0
out=$(haxe -cp . -cp ../../src -lib rui -lib nui --macro "FakeVocabulary.register()" -main Data --interp 2>&1)
check() {
	if echo "$out" | grep -qxF "$1"; then echo "ok   $2"; else echo "FAIL $2 -- expected: $1"; echo "$out" | head -5; fails=$((fails + 1)); fi
}
check "written: Text:PString(A) Text:PString(B)" "written options become one Text child each"
check "spliced: Text:PString(HDMI) Text:PString(SDI)" "a spliced list becomes one Text child per value"
echo ""
[ "$fails" -eq 0 ] && echo "all good" || echo "$fails failed"
exit "$fails"

#!/usr/bin/env bash
# A `key` written in markup, on the route that builds the backend's own views.
#
# It used to be parsed and dropped there: only the node route used it. So the
# one thing that keeps a row itself when a list reorders did nothing, on every
# backend, and said nothing. It now reaches the view where views carry a key,
# and is a compile error where they do not -- knowable, so never silent.
#
#   ./test/markup-keys/check.sh
set -u
cd "$(dirname "$0")"
fails=0
common="-cp . -cp ../../src -lib rui -lib nui -D mui_views"

for b in pui sui; do
	out=$(haxe $common -lib $b -D mui_backend=$b --macro "$b.nui.Vocabulary.registerWithMui()" -main Keyed --interp 2>&1)
	if echo "$out" | grep -q "keys: a,b"; then
		echo "ok   $b: a written key reaches the view"
	else
		echo "FAIL $b: the key did not reach the view:"; echo "$out" | head -5; fails=$((fails + 1))
	fi
done

out=$(haxe $common -lib cui -D mui_backend=cui --macro "cui.nui.Vocabulary.registerWithMui()" -main Keyed --interp 2>&1)
if echo "$out" | grep -q "ne donne pas de clé"; then
	echo "ok   cui: a backend whose views carry no key refuses one, by name"
else
	echo "FAIL cui accepted a key it would have ignored:"; echo "$out" | head -5; fails=$((fails + 1))
fi

echo ""
[ "$fails" -eq 0 ] && echo "all good" || echo "$fails failed"
exit "$fails"

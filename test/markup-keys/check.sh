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

for b in pui sui cui aui; do
	# aui's State reaches a Kotlin class, so it is compiled and run on the JVM.
	run="--interp"
	[ "$b" = aui ] && run="-D jvm --jvm /tmp/mui-keys-aui.jar"
	out=$(haxe $common -lib $b -D mui_backend=$b --macro "$b.nui.Vocabulary.registerWithMui()" -main Keyed $run 2>&1)
	[ "$b" = aui ] && out=$(java -jar /tmp/mui-keys-aui.jar 2>&1)
	if echo "$out" | grep -q "keys: a,b"; then
		echo "ok   $b: a written key reaches the view"
	else
		echo "FAIL $b: the key did not reach the view:"; echo "$out" | head -5; fails=$((fails + 1))
	fi
done

# qui lives in the haxe-sailfish workspace and cannot be interpreted -- its
# components reach C++ through `untyped __cpp__`. So the proof is the generated
# code: the key has to appear in the C++ the markup produced. A missing hook
# would not have got that far anyway (markup refuses a key by name).
rm -rf /tmp/mui-keys-qui
if haxe $common -lib haxe-sailfishos -D mui_backend=qui \
		--macro "qui.nui.Vocabulary.registerWithMui()" -main Keyed -cpp /tmp/mui-keys-qui -D no-compilation 2>/dev/null \
		&& grep -rq "keyed" /tmp/mui-keys-qui/src/Keyed.cpp; then
	echo "ok   qui: a written key reaches the view (read in the generated C++)"
else
	echo "FAIL qui: the key did not reach the view"
	haxe $common -lib haxe-sailfishos -D mui_backend=qui \
		--macro "qui.nui.Vocabulary.registerWithMui()" -main Keyed -cpp /tmp/mui-keys-qui -D no-compilation 2>&1 | head -4
	fails=$((fails + 1))
fi

echo ""
[ "$fails" -eq 0 ] && echo "all good" || echo "$fails failed"
exit "$fails"

#!/usr/bin/env bash
# A `Picker`'s options: children that are DATA, not views.
#
# The canon writes them as `Text` children and the control carries an array of
# strings (`@:children("Text", "text")`). Markup had no way to ask, so it built
# them as views, `Construct` refused the whole control, and a picker written in
# markup fell back to a node -- which reaches only a backend that reads nodes.
#
#   ./test/markup-picker/check.sh
set -u
cd "$(dirname "$0")"
fails=0
common="-cp . -cp ../../src -lib rui -lib nui -D mui_views"

for b in pui cui; do
	out=$(haxe $common -lib $b -D mui_backend=$b --macro "$b.nui.Vocabulary.registerWithMui()" \
		-main Options --interp 2>&1)
	if echo "$out" | grep -q "written: HDMI,SDI | spliced: HDMI,SDI,NDI"; then
		echo "ok   $b: options written one by one, and a list spliced in"
		# And on cui they are read back off a rendered buffer: a control
		# holding the right array and showing something else would pass
		# every assertion above.
		if [ "$b" = cui ] && ! echo "$out" | grep -q "drawn: Sortie . SDI  . 2/2"; then
			echo "FAIL cui: the options did not DRAW:"; echo "$out" | head -5
			fails=$((fails + 1))
		elif [ "$b" = cui ]; then
			echo "ok   cui: and the chosen one is drawn -- read off the buffer"
		fi
	else
		echo "FAIL $b: the options did not reach the control:"; echo "$out" | head -5
		fails=$((fails + 1))
	fi
done

# One refusal per shape, each judged on the phrase it must carry: a message
# that merely fails is no better than a silent drop.
refused() {
	local main="$1" want="$2"
	local out
	out=$(haxe $common -lib pui -D mui_backend=pui --macro "pui.nui.Vocabulary.registerWithMui()" \
		-cp refused -main "$main" --interp 2>&1)
	if echo "$out" | grep -qF "$want"; then
		echo "ok   $main is refused, and the message says exactly why"
	else
		echo "FAIL $main was not refused as expected (wanted: $want)"; echo "$out" | head -4
		fails=$((fails + 1))
	fi
}

refused WrongType   'pas un "Button"'
refused MissingProp 'doit porter "text"'
refused Mixed       'pas les deux'

echo ""
[ "$fails" -eq 0 ] && echo "all good" || echo "$fails failed"
exit "$fails"

#!/usr/bin/env bash
#
# Checks `@:state(durable)`: what the shared helper refuses, and what a bound
# cell actually does across two processes.
#
# Same discipline as the surfaces runner next door. A macro whose job is to
# refuse cannot be tested by calling it, so each fixture is compiled on its
# own and judged on the exit code — and a refusal must also name what it
# refused, or an unrelated error would satisfy the check.
#
# `Durable` is the one fixture that is *run*, twice over one store, under the
# interpreter: the store is a text file and `sys.io.File` reaches it from eval
# as well as from C++, so proving persistence costs no native build. It runs
# in a temporary store, never the developer's.
#
# The fixtures bind against `cui` (the lightest real backend). What is being
# checked is `rui.macros.DurableState`, which all six share; the backend here
# is only what gives the fixtures an `App` to extend.
#
#   ./test/durable/run.sh

set -u
cd "$(dirname "$0")/fixtures"

failures=0

# EXTRA carries build flags for the one fixture built differently — the store
# library itself, whose absence is what `DurableNoStore` is about.
EXTRA="-lib kui-store"
compile() {
	haxe -cp . -cp ../../../src \
		-lib cui -lib kui -lib rui -lib nui $EXTRA \
		-D mui_backend=cui \
		--macro "mui.macros.Bind.all()" \
		--macro "cui.kui.Platform.registerWithKui()" \
		-main "$1" "${@:2}" 2>&1
}

# check <fixture> <pass|reject> [text the refusal must contain]
check() {
	local fixture="$1" expect="$2" text="${3:-}"
	local out code

	out=$(compile "$fixture" --no-output)
	code=$?

	if [ "$expect" = "pass" ]; then
		if [ $code -eq 0 ]; then
			echo "  ok   $fixture compile"
		else
			failures=$((failures + 1))
			echo "  FAIL $fixture should have compiled"
			echo "$out" | sed 's/^/         /'
		fi
		return
	fi

	if [ $code -eq 0 ]; then
		failures=$((failures + 1))
		echo "  FAIL $fixture should have been refused"
	elif ! echo "$out" | grep -qF "$text"; then
		failures=$((failures + 1))
		echo "  FAIL $fixture refused, but not for the stated reason ($text)"
		echo "$out" | sed 's/^/         /'
	else
		echo "  ok   $fixture refused ($text)"
	fi
}

echo "Durable state"

check Durable pass

# The point of the whole exercise: a value that outlives the process that
# wrote it. Two runs, a fresh store, and a non-durable cell as the control.
store=$(mktemp -d)/store
export PAVOIS_STORE="$store"

first=$(compile Durable --interp)
second=$(compile Durable --interp)
rm -rf "$(dirname "$store")"
unset PAVOIS_STORE

if [ "$first" = "read 0 none 100" ] && [ "$second" = "read 1 wrote-1 100" ]; then
	echo "  ok   Durable survives the process: 0 -> 1, volatile stays 100"
else
	failures=$((failures + 1))
	echo "  FAIL Durable round trip"
	echo "         first:  $first"
	echo "         second: $second"
	echo "         wanted: 'read 0 none 100' then 'read 1 wrote-1 100'"
fi

# What the helper refuses, in its own words.
check DurableBadType  reject "Int, Float, Bool or String"
check DurableBadParam reject "nothing else"
check DurableKeyAlone reject "only means something with"

# And the refusal that is about the build rather than the source: the platform
# is known, its store implementation is not in it.
EXTRA=""
check DurableNoStore  reject "does not exist"
EXTRA="-lib kui-store"

if [ $failures -eq 0 ]; then
	echo ""
	echo "all good"
	exit 0
else
	echo ""
	echo "$failures failed"
	exit 1
fi

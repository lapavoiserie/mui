#!/usr/bin/env bash
#
# Checks `mui.macros.Surfaces` (the `@:surface` collection) and its wiring
# into `rui.macros.ViewRule` on small fixtures.
#
# Same discipline as rui's viewrule runner: a macro whose job is to refuse
# cannot be tested by calling it — each fixture is compiled on its own and
# judged on the exit code, and a refusal must also name what it refused, or
# any unrelated error would satisfy the check.
#
# The fixtures bind against `cui` (the lightest real backend), typed only —
# `--no-output`. `Collected` additionally *runs* under the interpreter and
# must print the collected ids: compiling proves the shape, running proves
# the collection.
#
#   ./test/surfaces/run.sh

set -u
cd "$(dirname "$0")/fixtures"

failures=0

compile() {
	haxe -cp . -cp ../../../src \
		-lib cui -lib kui -lib rui -lib nui \
		-D mui_backend=cui \
		--macro "mui.macros.Bind.all()" \
		--macro "cui.kui.Platform.registerWithKui()" \
		-main "$1" "${@:2}" 2>&1
}

# check <fixture> <pass|reject> [text the refusal must contain]
#
# EXTRA carries build flags for the one fixture that needs a different build
# than the others — the cafos switch, whose whole point is that it is not on
# by default.
EXTRA=""
check() {
	local fixture="$1" expect="$2" text="${3:-}"
	local out code

	out=$(compile "$fixture" -cpp /dev/null --no-output $EXTRA)
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

echo "Surfaces"

# The happy path, compiled and then actually run.
check Collected pass
out=$(compile Collected --interp)
if [ "$out" = "body,today,pinned,shortcuts" ]; then
	echo "  ok   Collected runs: body,today,pinned,shortcuts"
else
	failures=$((failures + 1))
	echo "  FAIL Collected ids: expected body,today,pinned,shortcuts"
	echo "$out" | sed 's/^/         /'
fi

# What the macro refuses, in its own words.
check PrimaryRefused      reject "Primary is implicit"
check NotificationRefused reject "detached"
check ArgsRefused         reject "no arguments"
check DupIdRefused        reject "already declared"
check UnknownRole         reject "not a mui.surface.SurfaceRole"

# The role this backend cannot host: refused at the declaration, naming the
# backend. `Collected` covers the other half — the same declaration accepted
# on purpose with `optional`.
check UnhostedRefused     reject "cui hosts no Glance"

# The networked corner is opt-in: the same declaration is refused without the
# switch and accepted with it. Both halves, or "it compiles" would prove
# nothing about the default.
check CompanionOffRefused reject "cafos, which is off in this build"
EXTRA="-D mui_cafos"
check CompanionOptIn      pass
EXTRA=""

# What the typer refuses through the generated code: the thunk's return type.
check WrongReturn         reject "Command"

# What the view rule refuses through the metadata registration: a surface
# declaration reading a plain mutable field, named.
check StaleRead           reject '"hits"'

if [ $failures -eq 0 ]; then
	echo ""
	echo "all good"
	exit 0
else
	echo ""
	echo "$failures failed"
	exit 1
fi

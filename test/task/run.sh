#!/usr/bin/env bash
#
# Checks `mui.Task`: delivery on the calling thread, failures as values,
# cancellation, owners, and a burst larger than the worker pool.
#
# Unlike the surfaces and durable runners this one runs code rather than
# judging a compile: `mui.Task` uses only `sys.thread` and `rui.Lifetime`,
# which the interpreter has, so no backend and no native build are needed.
#
#   ./test/task/run.sh

set -u
cd "$(dirname "$0")"
haxe -cp . -cp ../../src -lib rui -main TaskTest --interp

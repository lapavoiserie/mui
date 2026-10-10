# Slow work: `mui.Task`

A view's state may only be written on the UI thread, and the UI thread must
never wait on the network. `mui.Task` is the bridge between the two: the work
runs on a worker, its result comes back to the UI thread.

```haxe
import mui.Task;

class ChoresApp extends mui.App {
	@:state var chores:ImmutableList<String> = [];
	@:state var error:String = "";
	@:state var loading:Bool = false;

	function refresh() {
		loading = true;
		Task.run(() -> api.listChores(), r -> {   // api.listChores() blocks: HTTP
			loading = false;
			switch r {
				case Done(list): chores = list;
				case Failed(e): error = e.message;
			}
		}).ownedBy(lifetime);
	}
}
```

## The contract

| | |
|---|---|
| `work` | runs on a worker thread; may block; must not touch `@:state` |
| `done` | runs on the thread that called `run`, with `Done(value)` or `Failed(exception)` |
| call `run` from | the UI thread: an action, a constructor, a `lifetime.keep` start |

Anything `work` throws arrives as `Failed`, wrapped in a `haxe.Exception` so
`e.message` is always there. Anything `done` throws is caught and traced: it
would otherwise reach the backend's event pump, and `sui` stops pumping after
the first escaped exception — no timer would fire again.

## Cancelling

```haxe
var h = Task.run(work, done);
h.cancel();                  // done will not be called
Task.run(work, done).ownedBy(lifetime);   // dropped if lifetime is released first
```

The work is never interrupted — a blocking HTTP call cannot be — only its
result is dropped. `ownedBy` registers nothing with the lifetime, it checks
`released` when the result arrives, so owning every request by the app's
lifetime leaves nothing behind.

## How it works, and why it needs no backend code

Every backend pumps the UI thread's `sys.thread.EventLoop`: `sui` and `wui`
from their host's poll timer, which they also wake the moment work is queued;
`cui` from its own loop. `Task.run` promises the calling thread's loop one
event, and the worker posts the result with `runPromised`. Same code on every
backend; a loop with nothing else to do (a CLI, a test) waits for the result
instead of exiting.

Workers come from one elastic pool of `Task.MAX_WORKERS` (4) threads: a burst
of requests queues rather than opening a thread each. On a target without
threads, `work` runs at once inside `run` and `done` is called before `run`
returns.

## Tested by

`test/task/run.sh` — delivery thread, failures, cancellation, owners, a burst
larger than the pool. It runs under the interpreter; the same file builds and
passes with hxcpp.

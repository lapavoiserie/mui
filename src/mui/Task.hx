package mui;

/**
	Run slow work off the UI thread, and get its result back on it.

	```haxe
	Task.run(() -> client.listChores(), r -> switch r {
		case Done(list): chores = list;          // a @:state write, on the UI thread
		case Failed(e): error = e.message;
	}).ownedBy(lifetime);
	```

	`work` runs on a worker thread. Whatever it returns — or throws — is posted
	back to the event loop of the thread that called `run`, and `done` receives
	it there. Call `run` from the UI thread (an action, a constructor, `body()`
	through `lifetime.keep`), and `done` is free to write `@:state`: that is the
	only thread a backend's state may be written from.

	## Why the event loop

	Every backend already pumps the UI thread's `sys.thread.EventLoop`: `sui`
	and `wui` from their host's poll, and wake that host the moment something
	is queued; `cui` from its own loop. Posting there is therefore the one way
	back that needs nothing from a backend — no new conformance, the same code
	on all of them.

	## Failures are values

	An exception escaping `work` would kill the worker silently, and the view
	would wait forever. One escaping `done` would land in the backend's event
	pump, and `sui` stops pumping after the first one: no timer would ever fire
	again. So `work`'s exception is caught and delivered as `Failed`, and one
	thrown by `done` is caught and traced.

	## Cancelling

	`cancel()` — or `ownedBy(lifetime)`, which cancels once the lifetime is
	released — means `done` will not be called. The work itself is not
	interrupted (a blocking HTTP call cannot be), its result is dropped on
	arrival. Owning the task matters when `done` writes state of something that
	may be gone by then: a window closed, a key no longer kept.

	Owning registers nothing with the lifetime: the handle checks
	`lifetime.released` when the result arrives. A task per request owned by an
	app-long lifetime therefore leaves nothing behind once delivered.

	## Workers

	Tasks share a small elastic pool of `MAX_WORKERS` threads, so a burst of
	requests queues instead of opening a thread each. A target without threads
	runs `work` at once, inside `run`, and calls `done` before `run` returns.
**/
class Task {
	/** Most worker threads alive at once. More tasks than this wait their turn. **/
	public static inline var MAX_WORKERS = 4;

	#if target.threaded
	static var pool:Null<sys.thread.ElasticThreadPool> = null;
	static final poolLock = new sys.thread.Mutex();
	#end

	/** Start `work` on a worker and deliver its outcome to `done` on this thread. **/
	public static function run<T>(work:() -> T, done:(TaskResult<T>) -> Void):TaskHandle {
		final handle = new TaskHandle();
		#if target.threaded
		final home = sys.thread.Thread.current();
		// Promised, so a loop with nothing else to do waits for this result
		// instead of returning (a CLI's main loop, a test run).
		home.events.promise();
		workers().run(() -> {
			final outcome = attempt(work);
			home.events.runPromised(() -> deliver(handle, done, outcome));
		});
		#else
		deliver(handle, done, attempt(work));
		#end
		return handle;
	}

	static function attempt<T>(work:() -> T):TaskResult<T> {
		return try Done(work()) catch (e:haxe.Exception) Failed(e) catch (e:Dynamic) Failed(new haxe.Exception(Std.string(e)));
	}

	static function deliver<T>(handle:TaskHandle, done:(TaskResult<T>) -> Void, outcome:TaskResult<T>):Void {
		if (handle.cancelled) return;
		try {
			done(outcome);
		} catch (e:Dynamic) {
			trace('[mui.Task] the done callback threw: $e');
		}
	}

	#if target.threaded
	static function workers():sys.thread.ElasticThreadPool {
		poolLock.acquire();
		var p = pool;
		if (p == null) {
			p = new sys.thread.ElasticThreadPool(MAX_WORKERS);
			pool = p;
		}
		poolLock.release();
		return p;
	}
	#end
}

/** What a task's work came to. **/
enum TaskResult<T> {
	/** `work` returned this value. **/
	Done(value:T);
	/** `work` threw. Anything thrown is wrapped, so `error.message` is always there. **/
	Failed(error:haxe.Exception);
}

/** A started task, to cancel its delivery. **/
class TaskHandle {
	/** Whether `done` has been called off, directly or by a released owner.
		Only meaningful on the calling thread. **/
	public var cancelled(get, never):Bool;

	var _cancelled = false;
	var _owner:Null<rui.Lifetime> = null;

	function get_cancelled():Bool {
		final owner = _owner;
		return _cancelled || (owner != null && owner.released);
	}

	public function new() {}

	/** `done` will not be called. Safe to call more than once, or after delivery. **/
	public function cancel():Void {
		_cancelled = true;
	}

	/** Drop the result if `lifetime` has been released by the time it arrives.
		Chainable: `Task.run(…).ownedBy(lifetime)`. **/
	public function ownedBy(lifetime:rui.Lifetime):TaskHandle {
		_owner = lifetime;
		return this;
	}
}

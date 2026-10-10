import mui.Task;
import sys.thread.Thread;

/**
	Runs under the interpreter: eval has threads and an event loop that drains
	after `main()` returns, which is all `mui.Task` uses. Each case records its
	verdict, and the last delivery prints the tally.
**/
class TaskTest {
	static var main_:Thread;
	static var checks = 0;
	static var failures = 0;
	static var pending = 0;
	static var cancelledRan = false;
	static var ownedRan = false;
	static var burst = 0;

	static function main() {
		main_ = Thread.current();

		expect("work runs off the calling thread, done runs on it", () -> Thread.current() != main_, r -> switch r {
			case Done(offMain): offMain && Thread.current() == main_;
			case Failed(_): false;
		});

		expect("an Exception from work arrives as Failed", () -> throw new haxe.Exception("boom"), r -> switch r {
			case Failed(e): e.message == "boom";
			case Done(_): false;
		});

		expect("a thrown string is wrapped, with its text as the message", () -> { throw "plain"; 0; }, r -> switch r {
			case Failed(e): e.message == "plain";
			case Done(_): false;
		});

		// Cancelled before the result can arrive: done must never run.
		Task.run(() -> 1, _ -> cancelledRan = true).cancel();

		// Owned by a lifetime released before delivery: same.
		final life = new rui.Lifetime();
		Task.run(() -> 1, _ -> ownedRan = true).ownedBy(life);
		life.release();

		// A done that throws must not stop later deliveries — nor, on eval,
		// take the process down: reaching the tally at all proves it was caught.
		pending++;
		Task.run(() -> 1, _ -> {
			settle();
			throw "callback failure (expected, traced by mui.Task)";
		});

		// More tasks than workers: all of them still arrive, in some order.
		for (i in 0...Task.MAX_WORKERS * 3) {
			pending++;
			Task.run(() -> { Sys.sleep(0.01); i; }, r -> {
				switch r { case Done(_): burst++; case Failed(_): }
				settle();
			});
		}
	}

	static function expect<T>(what:String, work:() -> T, verdict:(TaskResult<T>) -> Bool) {
		pending++;
		Task.run(work, r -> {
			record(what, verdict(r));
			settle();
		});
	}

	static function record(what:String, ok:Bool) {
		checks++;
		if (!ok) {
			failures++;
			Sys.println('  FAIL $what');
		} else {
			Sys.println('  ok   $what');
		}
	}

	/** Runs after every delivery has arrived — the cancelled and owned tasks
		finish before the last counted one is delivered, or never were going to. **/
	static function settle() {
		if (--pending > 0) return;
		record("a cancelled task's done never runs", !cancelledRan);
		record("a released owner drops the result", !ownedRan);
		record("a throwing done does not stop later deliveries", true);
		record('a burst larger than the pool is fully delivered ($burst)', burst == Task.MAX_WORKERS * 3);
		Sys.println(failures == 0 ? 'ok — $checks checks passed' : 'FAILED — $failures of $checks checks');
		Sys.exit(failures == 0 ? 0 : 1);
	}
}

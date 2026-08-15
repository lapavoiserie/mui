import sys.FileSystem;
import sys.io.File;

/**
	Generates `docs/backend-support.md` from each backend's `mui` conformance.

	## Why it is generated

	A support table copied by hand is a second statement of something the code
	already says, and the two drift the moment a backend gains a type. It drifts
	in the direction that hurts, too: the doc keeps promising what was removed.

	So the mapping is read where it is decided. That used to be the
	`#if (mui_backend == "x")` branches in `src/mui/ui/`; since the binding
	inversion there are none, and each backend declares its own conformance under
	`<backend>/mui/`. This reads those files instead.

	The *quality* of each mapping comes from `@:muiSupport` metadata on the class
	it describes, rather than from a comment above it. A comment is invisible to
	everything; metadata can be listed, checked, and one day turned into a
	warning.

	    haxe -cp tools --run BackendMatrix [extra-root …]

	Backends are found through `haxelib libpath`. A backend that is not installed
	as a library — `qui` lives inside the `haxe-sailfish` repository — can be
	named by passing the directory that holds its package:

	    haxe -cp tools --run BackendMatrix ~/new-projects/haxe-sailfish/src

	`docs/backend-support.md` is output, not source.
**/
class BackendMatrix {
	/**
		The backends to tabulate.

		A list of names, in a tool whose whole subject is a comparison *across*
		backends. It is the one place in this repository where naming them is the
		point rather than a coupling — `src/mui` names none.
	**/
	static final BACKENDS = ["sui", "aui", "wui", "cui", "qui", "pui"];

	/** Types that are in the contract but not part of the view vocabulary. **/
	static final NOT_TABULATED = [
		"View", "App", "ViewComponent",
		"State", "Binding", "Observable", "StateAction", "AnimationCurve",
		// wui's own helper, which lives in its mui package because that is who
		// needs it -- not a type mui asks any backend for.
		"FromViews",
	];

	static function main() {
		var extra = Sys.args();
		var roots = new Map<String, String>();
		for (backend in BACKENDS) {
			var dir = locate(backend, extra);
			if (dir != null) roots.set(backend, dir);
		}

		if (!roots.iterator().hasNext()) {
			Sys.println("No backend found. Install one, or pass the directory holding its package.");
			Sys.exit(1);
		}

		// The union of what the backends provide, so a type only one of them has
		// still gets a row -- and an empty cell next to it, which is the honest
		// reading.
		var types = new Map<String, Bool>();
		for (backend in BACKENDS) {
			var dir = roots.get(backend);
			if (dir == null) continue;
			for (file in FileSystem.readDirectory(dir)) {
				if (!StringTools.endsWith(file, ".hx")) continue;
				var type = file.substr(0, file.length - 3);
				if (StringTools.endsWith(type, "Binding")) continue;
				if (NOT_TABULATED.indexOf(type) >= 0) continue;
				types.set(type, true);
			}
		}

		var names = [for (t in types.keys()) t];
		names.sort(Reflect.compare);

		var extendsRe = ~/extends\s+([\w.]+)/;
		var typedefRe = ~/typedef\s+\w+\s*=\s*([\w.<>]+)/;
		var supportRe = ~/@:muiSupport\("([a-z]+)"(?:\s*,\s*"([^"]*)")?\)/;
		// What the backend actually renders. A façade that extends the backend's
		// bare `View` and sets a viewType is not "a View" -- it is that type,
		// named. Reporting the superclass would understate a faithful mapping.
		var viewTypeRe = ~/viewType\s*=\s*"(\w+)"/;

		var rows = [];
		var notes:Array<{type:String, backend:String, kind:String, note:String}> = [];

		for (type in names) {
			var cells = [];
			for (backend in BACKENDS) {
				var dir = roots.get(backend);
				var path = dir == null ? null : dir + "/" + type + ".hx";
				if (path == null || !FileSystem.exists(path)) {
					cells.push("—");
					continue;
				}

				var source = File.getContent(path);
				if (source.indexOf("#error") >= 0) {
					cells.push("**refused**");
					notes.push({type: type, backend: backend, kind: "error",
						note: "using it does not compile, with a message that says why"});
					continue;
				}

				// A façade is a subclass, an alias, or -- for `ForEach`, whose
				// shape differs on every backend -- a macro that rewrites the call
				// into that backend's own iteration.
				var target = extendsRe.match(source) ? extendsRe.matched(1)
					: (typedefRe.match(source) ? typedefRe.matched(1)
					: (source.indexOf("macro function") >= 0 ? "macro" : "?"));
				var short = target.split(".").pop();
				if (viewTypeRe.match(source)) short = viewTypeRe.matched(1);

				if (supportRe.match(source)) {
					var kind = supportRe.matched(1);
					var note = supportRe.matched(2);
					notes.push({type: type, backend: backend, kind: kind,
						note: note == null ? "" : note});
					cells.push(short + " " + badge(kind));
				} else {
					cells.push(short);
				}
			}
			rows.push({type: type, cells: cells});
		}

		var out = new StringBuf();
		out.add("# Backend support\n\n");
		out.add("> This page is **generated**: `haxe -cp tools --run BackendMatrix`.\n");
		out.add("> It reads each backend's own `<backend>/mui/` conformance, so it cannot\n");
		out.add("> promise what the code no longer does.\n\n");

		var missing = [for (b in BACKENDS) if (!roots.exists(b)) b];
		if (missing.length > 0) {
			out.add("> **Not inspected this run:** " + missing.join(", ") + " — not installed,\n");
			out.add("> and a backend that cannot be read cannot be reported on. Its column is\n");
			out.add("> blank rather than absent, so the gap is visible.\n\n");
		}

		out.add("| `mui` type | " + BACKENDS.join(" | ") + " |\n");
		out.add("|---|" + [for (_ in BACKENDS) "---"].join("|") + "|\n");
		for (row in rows) {
			out.add("| **" + row.type + "** | " + row.cells.join(" | ") + " |\n");
		}

		out.add("\n## Legend\n\n");
		out.add("Unmarked, the backend has the concept natively and `mui` binds straight to it.\n\n");
		out.add("- ⚙️ **built** — the backend composes it from its own primitives.\n");
		out.add("- ○ **not applicable** — the platform has no such concept; doing nothing is the right answer.\n");
		out.add("- ⚠️ **approximation** — what is drawn differs from what the type promises. This is the only row where your UI will not behave as it does elsewhere.\n");
		out.add("- **refused** — using it does not compile, rather than rendering something wrong.\n");
		out.add("- — **absent** — the backend provides no such type. `mui.Contract` marks the\n");
		out.add("  entry optional, and reaching for it there is a compile error at the line\n");
		out.add("  that reached.\n");

		if (notes.length > 0) {
			out.add("\n## The cases that are not native\n\n");
			out.add("| Type | Backend | | What happens |\n|---|---|---|---|\n");
			for (n in notes) {
				out.add("| " + n.type + " | " + n.backend + " | " + badge(n.kind) + " | " + n.note + " |\n");
			}
		}

		out.add("\n## What the table does not say\n\n");
		out.add("The three types that carry everything else — `View`, `App` and\n");
		out.add("`ViewComponent` — and the five reactive ones under `mui.state` are in\n");
		out.add("[the contract](https://github.com/lapavoiserie/mui/blob/main/src/mui/Contract.hx)\n");
		out.add("but not tabulated. There is nothing to compare: a backend either provides\n");
		out.add("them, or `mui.macros.Bind` names what is missing at the top of the build.\n\n");
		out.add("The `aui` column is the *mapping* — which Compose widget a type is meant to\n");
		out.add("become — not the renderer's coverage. `aui` draws through its dynamic\n");
		out.add("renderer, whose vocabulary is a subset of this table: a type outside it\n");
		out.add("**refuses to compile**, naming the type and listing what is covered. The\n");
		out.add("compile-time transpiler that covered everything listed here is\n");
		out.add("[decommissioned](https://lapavoiserie.github.io/aui/#/render-paths).\n");

		FileSystem.createDirectory("docs");
		File.saveContent("docs/backend-support.md", out.toString());
		Sys.println("docs/backend-support.md — " + rows.length + " types, "
			+ notes.length + " non-native cases, "
			+ (BACKENDS.length - missing.length) + "/" + BACKENDS.length + " backends read");
	}

	/**
		Where a backend's `mui` package lives.

		`haxelib libpath` answers with the library root for one kind of install
		and with the class path itself for another, so both are tried — and for
		the first, the `classPath` its `haxelib.json` declares. Directories given
		on the command line are searched the same way, for a backend that is not
		installed as a library.
	**/
	static function locate(backend:String, extra:Array<String>):Null<String> {
		var candidates = [];
		var root = try StringTools.trim(new sys.io.Process("haxelib",
			["libpath", backend]).stdout.readAll().toString()) catch (_:Dynamic) null;
		if (root != null && root != "" && FileSystem.exists(root)) {
			candidates.push(root + "/" + backend + "/mui");
			candidates.push(root + "/" + classPathOf(root) + "/" + backend + "/mui");
		}
		for (dir in extra) {
			candidates.push(dir + "/" + backend + "/mui");
			candidates.push(dir + "/mui");
		}
		for (c in candidates) if (FileSystem.exists(c) && FileSystem.isDirectory(c)) return c;
		return null;
	}

	static function classPathOf(root:String):String {
		var json = root + "/haxelib.json";
		if (!FileSystem.exists(json)) return "src";
		return try {
			var declared = haxe.Json.parse(File.getContent(json)).classPath;
			declared == null ? "src" : declared;
		} catch (_:Dynamic) "src";
	}

	static function badge(kind:String):String {
		return switch (kind) {
			case "built": "⚙️";
			case "none": "○";
			case "approx": "⚠️";
			case "error": "**refused**";
			case _: kind;
		};
	}
}

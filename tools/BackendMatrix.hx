import sys.FileSystem;
import sys.io.File;

/**
	Generates `docs/backend-support.md` from `src/mui/ui/*.hx`.

	## Why it is generated

	A support table copied by hand is a second statement of something the code
	already says, and the two drift the moment a backend gains a type. It drifts
	in the direction that hurts, too: the doc keeps promising what was removed.

	So the mapping is read where it is decided -- the `#if (mui_backend == "x")`
	branches -- and the *quality* of each mapping is read from `@:muiSupport`
	metadata sitting on the class it describes, rather than from a comment above
	it. A comment is invisible to everything; metadata can be listed, checked,
	and one day turned into a warning.

	    haxe -cp tools --run BackendMatrix

	Run it after touching `src/mui/ui/`; `docs/backend-support.md` is output,
	not source.
**/
class BackendMatrix {
	static final BACKENDS = ["sui", "aui", "wui", "cui"];

	/** One backend's answer for one mui type. **/
	static function branchOf(source:String, backend:String):Null<String> {
		var start = source.indexOf('mui_backend == "' + backend + '"');
		if (start < 0) return null;

		// The branch runs to the next conditional at the start of a line.
		var rest = source.substr(start);
		var end = rest.length;
		for (marker in ["\n#elseif", "\n#else", "\n#end"]) {
			var i = rest.indexOf(marker);
			if (i >= 0 && i < end) end = i;
		}
		return rest.substr(0, end);
	}

	static function main() {
		var dir = "src/mui/ui";
		if (!FileSystem.exists(dir)) {
			Sys.println('Introuvable : $dir — lancez depuis la racine de mui.');
			Sys.exit(1);
		}

		var names = FileSystem.readDirectory(dir).filter(f -> StringTools.endsWith(f, ".hx"));
		names.sort(Reflect.compare);

		var extendsRe = ~/extends\s+([\w.]+)/;
		var typedefRe = ~/typedef\s+\w+\s*=\s*([\w.]+)/;
		var supportRe = ~/@:muiSupport\("([a-z]+)"(?:\s*,\s*"([^"]*)")?\)/;
		// What the backend actually renders. A branch that extends the backend's
		// bare `View` and sets a viewType is not "a View" -- it is that type,
		// named. Reporting the superclass would understate a faithful mapping.
		var viewTypeRe = ~/viewType\s*=\s*"(\w+)"/;

		var rows = [];
		var notes:Array<{type:String, backend:String, kind:String, note:String}> = [];

		for (file in names) {
			var type = file.substr(0, file.length - 3);
			var source = File.getContent(dir + "/" + file);

			// The three *Binding types are conversion abstracts, not views.
			if (StringTools.endsWith(type, "Binding")) continue;

			var cells = [];
			for (backend in BACKENDS) {
				var branch = branchOf(source, backend);
				if (branch == null) {
					cells.push("—");
					continue;
				}

				if (branch.indexOf("#error") >= 0) {
					cells.push("**refusé**");
					notes.push({type: type, backend: backend, kind: "error",
						note: "l'usage ne compile pas, avec un message qui le dit"});
					continue;
				}

				var target = extendsRe.match(branch) ? extendsRe.matched(1)
					: (typedefRe.match(branch) ? typedefRe.matched(1) : "?");
				var short = target.split(".").pop();
				if (viewTypeRe.match(branch)) short = viewTypeRe.matched(1);

				if (supportRe.match(branch)) {
					var kind = supportRe.matched(1);
					var note = supportRe.matched(2);
					notes.push({type: type, backend: backend, kind: kind, note: note == null ? "" : note});
					cells.push(short + " " + badge(kind));
				} else {
					cells.push(short);
				}
			}

			// A type no backend answers through a branch is not unsupported: it
			// is resolved elsewhere. `ForEach` is a macro that rewrites into each
			// backend's own iteration, so an empty row would read as a hole.
			var answered = false;
			for (c in cells) if (c != "—") answered = true;
			if (!answered) cells = [for (_ in BACKENDS) "macro"];

			rows.push({type: type, cells: cells});
		}

		var out = new StringBuf();
		out.add("# Ce que chaque backend supporte\n\n");
		out.add("> Cette page est **générée** : `haxe -cp tools --run BackendMatrix`.\n");
		out.add("> Elle lit les branches `#if (mui_backend == …)` de `src/mui/ui/`,\n");
		out.add("> donc elle ne peut pas promettre ce que le code ne fait plus.\n\n");

		out.add("| Type `mui` | " + BACKENDS.join(" | ") + " |\n");
		out.add("|---|" + [for (_ in BACKENDS) "---"].join("|") + "|\n");
		for (row in rows) {
			out.add("| **" + row.type + "** | " + row.cells.join(" | ") + " |\n");
		}

		out.add("\n## Légende\n\n");
		out.add("Sans marque, le backend a nativement la notion et `mui` s'y branche.\n\n");
		out.add("- ⚙️ **construit** — `mui` le compose à partir de primitives du backend.\n");
		out.add("- ○ **sans objet** — la plateforme n'a pas cette notion ; ne rien faire est la bonne réponse.\n");
		out.add("- ⚠️ **approximation** — le rendu diffère de ce que le type promet. C'est la seule catégorie où votre interface ne se comportera pas comme ailleurs.\n");
		out.add("- **refusé** — l'usage ne compile pas, plutôt que de rendre quelque chose de faux.\n");

		if (notes.length > 0) {
			out.add("\n## Les cas qui ne sont pas natifs\n\n");
			out.add("| Type | Backend | | Ce qui se passe |\n|---|---|---|---|\n");
			for (n in notes) {
				out.add("| " + n.type + " | " + n.backend + " | " + badge(n.kind) + " | " + n.note + " |\n");
			}
		}

		out.add("\n## Ce que la table ne dit pas\n\n");
		out.add("`qui` n'y figure pas : il **n'est pas un backend `mui`**. Son `#else` l'énonce\n");
		out.add("(`mui requires -D mui_backend=sui|wui|cui|aui`), et `qui/src/qui/ui/` contient\n");
		out.add("les mêmes fichiers que `src/mui/ui/` — une copie, pas un branchement.\n\n");
		out.add("`aui` a deux chemins : le statique couvre tout ce qui est listé ici, le renderer\n");
		out.add("dynamique (`-D aui_dynamic`) en couvre un sous-ensemble et **refuse de compiler**\n");
		out.add("ce qu'il ne dessine pas.\n");

		FileSystem.createDirectory("docs");
		File.saveContent("docs/backend-support.md", out.toString());
		Sys.println("docs/backend-support.md — " + rows.length + " types, " + notes.length + " cas non natifs");
	}

	static function badge(kind:String):String {
		return switch (kind) {
			case "built": "⚙️";
			case "none": "○";
			case "approx": "⚠️";
			case "error": "**refusé**";
			case _: kind;
		};
	}
}

package tools.cli;

import sys.FileSystem;
import sys.io.File;

/**
	Scaffolds a new mui project.

	## Where the build files come from

	Not from here. This used to hold four `build-<backend>.hxml` templates
	written out by hand — four, out of six, and none of them updated when the
	binding inversion added `--macro mui.macros.Bind.all()` to every build. A
	project scaffolded from them would not have compiled, and nothing here would
	have said so.

	Each backend now ships its own, as `<backend>/mui/init.hxml` beside the rest
	of its conformance. This finds them and substitutes `$MAIN`.

	## How a backend is found

	By asking haxelib what is installed, and looking for that file. A library
	that ships one **is** a backend, as far as this is concerned — which is why
	there is no list of names here, and why a seventh appears in a scaffolded
	project the moment it is installed.
**/
class Init {
	public static function run(cwd:String, args:Array<String>) {
		var projectName = args.length > 0 ? args[0] : "MyApp";
		var projectDir = '$cwd/$projectName';

		if (FileSystem.exists(projectDir)) {
			Sys.println('Error: Directory "$projectName" already exists.');
			Sys.exit(1);
		}

		Sys.println('Creating new mui project: $projectName');

		FileSystem.createDirectory(projectDir);
		FileSystem.createDirectory('$projectDir/src');

		var written = [];
		for (backend in installedLibraries()) {
			var template = templateFor(backend);
			if (template == null) continue;
			File.saveContent('$projectDir/build-$backend.hxml',
				StringTools.replace(template, "$MAIN", projectName));
			written.push(backend);
		}

		if (written.length == 0) {
			Sys.println("Warning: no backend is installed, so no build file was written.");
			Sys.println("  haxelib install cui   # or sui, wui, aui, pui");
		}

		File.saveContent('$projectDir/mui.json', '{
    "appName": "$projectName",
    "bundleIdentifier": "com.example.${projectName.toLowerCase()}"
}
');

		File.saveContent('$projectDir/src/$projectName.hx', skeleton(projectName));
		File.saveContent('$projectDir/.gitignore', "build/\n");

		Sys.println('Project "$projectName" created.');
		Sys.println("");
		Sys.println("Next steps:");
		Sys.println('  cd $projectName');
		for (backend in written) Sys.println('  mui build $backend');
	}

	/**
		The application, with one conditional and a good reason for it.

		`mui_owns_main` is defined by `mui.macros.Bind` when the backend's own
		`App` says its engine owns the process — `cui` and `pui` today. Everywhere
		else a generator drives, and anything in `main()` would run at the wrong
		time. This used to be `#if (mui_backend == "cui" || mui_backend == "pui")`
		in every example, a list a seventh backend would have had to be added to
		by hand.

		Nothing else needs one. Every backend's `App` carries `appTitle`, and
		every backend's `State` is `rui`'s underneath, so `get()` and `set()` mean
		the same thing on all six — where this template used to branch between
		`count.get()` and `count.value`.
	**/
	static function skeleton(name:String):String {
		return 'import mui.App;
import mui.View;
import mui.ui.Button;
import mui.ui.HStack;
import mui.ui.Spacer;
import mui.ui.Text;
import mui.ui.VStack;

class $name extends App {
	@:state var count:Int = 0;

	public function new() {
		super();
		appTitle = "$name";
	}

	override function body():View {
		return new VStack([
			new Spacer(),
			new Text("Hello from $name!", Title),
			new Text("Count: " + count.get()),
			new HStack([
				new Button("-", () -> count.set(count.get() - 1)),
				new Button("+", () -> count.set(count.get() + 1)),
			], 8),
			new Spacer(),
		], 10);
	}

	static function main() {
		// Only where the engine owns the process; elsewhere a generator drives.
		#if mui_owns_main
		new $name().run();
		#end
	}
}
';
	}

	// ---- finding the backends ----

	/** Every installed library, since any of them may turn out to be a backend. **/
	static function installedLibraries():Array<String> {
		var listed = try
			new sys.io.Process("haxelib", ["list"]).stdout.readAll().toString()
		catch (_:Dynamic) "";

		var names = [];
		for (line in listed.split("\n")) {
			var colon = line.indexOf(":");
			if (colon <= 0) continue;
			var name = StringTools.trim(line.substr(0, colon));
			if (name != "" && name != "mui") names.push(name);
		}
		names.sort(Reflect.compare);
		return names;
	}

	/**
		A library's `<name>/mui/init.hxml`, if it ships one.

		`haxelib libpath` answers with the library root for one kind of install
		and with the class path itself for another, so both are tried — and for
		the first, the `classPath` its `haxelib.json` declares.
	**/
	static function templateFor(backend:String):Null<String> {
		var root = try StringTools.trim(new sys.io.Process("haxelib",
			["libpath", backend]).stdout.readAll().toString()) catch (_:Dynamic) null;
		if (root == null || root == "" || !FileSystem.exists(root)) return null;

		for (candidate in [
			'$root/$backend/mui/init.hxml',
			'$root/${classPathOf(root)}/$backend/mui/init.hxml',
		]) {
			if (FileSystem.exists(candidate)) return File.getContent(candidate);
		}
		return null;
	}

	static function classPathOf(root:String):String {
		var json = '$root/haxelib.json';
		if (!FileSystem.exists(json)) return "src";
		return try {
			var declared = haxe.Json.parse(File.getContent(json)).classPath;
			declared == null ? "src" : declared;
		} catch (_:Dynamic) "src";
	}
}

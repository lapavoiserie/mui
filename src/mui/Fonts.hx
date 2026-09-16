package mui;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import nui.FontFile;
#end

/**
	The fonts an application ships, named where they are used.

	An application keeps its font files in `assets/fonts`, beside the build file
	— the same `assets` directory pictures use, so a font needs no second
	mechanism: every backend's build already copies it where its runtime reads
	one.

	```haxe
	new Text(timecode, Body, {family: Fonts.family("Inter"), weight: 600})
	```

	**The name is checked where it is written.** `Fonts.family` is a macro: it
	reads the files at compile time and fails at that line when nothing there
	is that family, naming the families that *are* shipped. A font renamed in a
	folder is then a build error rather than a panel that quietly changed
	typeface on one platform.

	**The file describes itself.** A family name, a weight and an italic bit are
	written in a font's own `name` and `OS/2` tables, which is where every
	platform reads them. So an application does not declare that `Inter-Bold.ttf`
	is Inter, bold and upright: it would be saying again, where nothing checks,
	what the file says where everything looks.

	`-D mui_assets=<directory>` moves the assets directory, as for pictures; the
	fonts are the `fonts` subdirectory of it.
**/
class Fonts {
	/** Where a shipped font lives, inside the assets directory. **/
	public static inline var DIRECTORY = "fonts";

	/**
		A family this application ships, checked here.

		Matched without regard to case or spaces, so `Fonts.family("Inter Tight")`
		finds `InterTight-Regular.ttf`, and the name that comes back is the
		family the **file** says — which is what a platform will be asked for.
	**/
	public static macro function family(name:String):ExprOf<mui.ui.FontFamily> {
		var shipped = read();
		var wanted = flat(name);
		for (face in shipped)
			if (flat(face.family) == wanted)
				return macro mui.ui.FontFamily.fromString($v{face.family});

		var known = [];
		for (face in shipped)
			if (known.indexOf(face.family) < 0) known.push(face.family);
		known.sort(Reflect.compare);
		Context.error(known.length == 0
			? 'This application ships no fonts: put a .ttf or .otf in ${directory()}/ and name its family here.'
			: '"$name" is not a family this application ships. In ${directory()}/: ' + known.join(", ") + ".",
			Context.currentPos());
		return macro mui.ui.FontFamily.fromString($v{name});
	}

	/**
		Every face this application ships: its file, its family, its weight and
		whether it is italic.

		For a backend's build, which has to register them with the platform —
		and for a surface that rasterises its own text and needs the file.
	**/
	public static macro function faces():ExprOf<Array<ShippedFace>> {
		var out = [];
		for (face in read())
			out.push(macro {
				path: $v{face.path},
				family: $v{face.family},
				weight: $v{face.weight},
				italic: $v{face.italic}
			});
		return macro $a{out};
	}

	#if macro
	/** The assets directory's `fonts`, wherever the assets directory is. **/
	static function directory():String {
		var assets = Context.definedValue("mui_assets");
		if (assets == null || assets == "") assets = mui.Assets.DEFAULT_DIRECTORY;
		return assets + "/" + DIRECTORY;
	}

	/**
		Read what is shipped, once per compilation.

		A file that is not a font — a licence, a note, an operating system's
		hidden index — is passed over rather than reported: a directory is not
		a manifest, and refusing to compile over a `.DS_Store` would be absurd.
	**/
	static var shipped:Null<Array<{path:String, family:String, weight:Int, italic:Bool}>> = null;

	static function read():Array<{path:String, family:String, weight:Int, italic:Bool}> {
		if (shipped != null) return shipped;
		var out = [];
		var where = directory();
		if (sys.FileSystem.exists(where) && sys.FileSystem.isDirectory(where)) {
			var names = sys.FileSystem.readDirectory(where);
			names.sort(Reflect.compare);
			for (name in names) {
				var path = where + "/" + name;
				if (sys.FileSystem.isDirectory(path)) continue;
				var lower = name.toLowerCase();
				if (!StringTools.endsWith(lower, ".ttf") && !StringTools.endsWith(lower, ".otf")
					&& !StringTools.endsWith(lower, ".ttc")) continue;
				var face = FontFile.read(try sys.io.File.getBytes(path) catch (_:Dynamic) null);
				if (face == null) {
					Context.warning('$path is not a font file this can read; it is shipped but not registered.', Context.currentPos());
					continue;
				}
				out.push({path: DIRECTORY + "/" + name, family: face.family, weight: face.weight, italic: face.italic});
			}
		}
		shipped = out;
		return out;
	}

	/** A family name as it is matched: no case, no spaces. **/
	static function flat(name:String):String {
		var out = new StringBuf();
		for (i in 0...name.length) {
			var c = name.charAt(i);
			if (c != " " && c != "-" && c != "_") out.add(c.toLowerCase());
		}
		return out.toString();
	}
	#end
}

/** One font file an application ships, as its own tables describe it. **/
typedef ShippedFace = {
	/** Where it is, inside the assets directory: `fonts/Inter-Bold.ttf`. **/
	var path:String;

	var family:String;
	var weight:Int;
	var italic:Bool;
}

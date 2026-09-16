package mui;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	Files an application ships, named where they are written.

	An application keeps them in an `assets` directory beside the build file it
	is compiled from, and every backend's build copies that directory to
	wherever its runtime reads one: a bundle's `Resources/assets` on Apple
	platforms, `app/src/main/assets` on Android, an `assets` folder beside the
	executable elsewhere. What crosses in a view is the `asset:` source nui's
	node model defines, so the same tree draws the same picture on any of them.

	```haxe
	new Image(Assets.src("logo.png"), "Farceur")
	```

	**The name is checked where it is written.** `Assets.src` is a macro: it
	looks for the file at compile time and fails at that line when it is not
	there. A picture whose file was renamed is then a build error rather than an
	`alt` noticed on a device -- the rule this ecosystem keeps: what can be
	known now is not left for a screen to say later.

	`-D mui_assets=<directory>` moves the directory, for a project whose layout
	is not the default.
**/
class Assets {
	/** The directory, relative to where the compiler was run, unless moved. **/
	public static inline var DEFAULT_DIRECTORY = "assets";

	/**
		The `asset:` source for a file this application ships, checked here.

		The path is relative to the assets directory and uses `/`; it may not
		leave it.
	**/
	public static macro function src(path:String):ExprOf<String> {
		var directory = Context.definedValue("mui_assets");
		if (directory == null || directory == "") directory = DEFAULT_DIRECTORY;

		if (path == null || path == "" || path.charAt(0) == "/" || path.indexOf("..") >= 0)
			Context.error('"$path" is not a name inside $directory/', Context.currentPos());

		var full = directory + "/" + path;
		if (!sys.FileSystem.exists(full)) {
			// Name the directory as well: the usual cause is a compiler run
			// from somewhere else, not a misspelled file.
			Context.error('$full is not there. An application ships its pictures in $directory/, beside the build file it is compiled from; -D mui_assets=<directory> moves it.',
				Context.currentPos());
		}
		if (sys.FileSystem.isDirectory(full))
			Context.error('$full is a directory, not a file.', Context.currentPos());

		return macro $v{"asset:" + path};
	}
}

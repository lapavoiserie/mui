package tools.cli;

/**
    Builds a mui project for the specified backend.

    For sui/wui: delegates to the backend CLI which handles the full
    pipeline (Haxe → codegen → native build). Creates a build.hxml
    include file so the backend CLI can find our build-<backend>.hxml.

    For cui: runs haxe directly (no special pipeline needed).
**/
class Build {
    public static function run(cwd:String, args:Array<String>) {
        if (args.length == 0) {
            Sys.println("Error: specify a backend (sui, wui, or cui)");
            Sys.println("Usage: mui build <sui|wui|cui> [options]");
            Sys.exit(1);
        }

        var backend = args[0];
        var extraArgs = args.slice(1);

        var hxmlFile = 'build-$backend.hxml';
        var hxmlPath = '$cwd/$hxmlFile';
        if (!sys.FileSystem.exists(hxmlPath)) {
            Sys.println('Error: $hxmlFile not found in $cwd');
            Sys.println('Run "mui init" to create a project with build files.');
            Sys.exit(1);
        }

        Sys.println('Building for $backend...');
        Sys.setCwd(cwd);

        // Delegate, whoever the backend is.
        //
        // This used to be a switch with a case per backend, split between two
        // shapes: three that had a pipeline of their own and two that "compile
        // directly". That split was never a property of `mui` -- it was a
        // property of each backend, written down here. `cui` gained a `build`
        // command of its own so that it could be delegated to like the rest.
        ensureBuildHxml(cwd, backend);
        ensureProjectFile(cwd, backend);

        var command = ["run", backend, "build"];
        for (a in extraArgs) command.push(a);
        var code = Sys.command("haxelib", command);
        if (code != 0) Sys.exit(code);
    }

    /**
        Backend CLIs expect build.hxml in the project root.
        Create one that includes our build-<backend>.hxml.
    **/
    public static function ensureBuildHxml(cwd:String, backend:String):Void {
        var buildHxml = '$cwd/build.hxml';
        // Always overwrite to match current backend
        sys.io.File.saveContent(buildHxml, 'build-$backend.hxml\n');
    }

    /**
        sui CLI expects sui.json for app metadata.
        Create a default one if it doesn't exist.
    **/
    /**
        Write the project file a backend's CLI expects, if it wants one.

        Only `sui` does, and this used to be called `ensureSuiJson` with the name
        of one backend in it. Driving it off the backend's name instead means
        `mui` states the *convention* -- a CLI may read `<backend>.json` beside
        the build file -- rather than a fact about one of them. A backend that
        wants none simply never reads the file.
    **/
    public static function ensureProjectFile(cwd:String, backend:String):Void {
        if (backend != "sui") return;
        var suiJson = '$cwd/$backend.json';
        if (!sys.FileSystem.exists(suiJson)) {
            // Read -main from build-sui.hxml to derive app name
            var mainClass = "App";
            var hxmlPath = '$cwd/build-sui.hxml';
            if (sys.FileSystem.exists(hxmlPath)) {
                var content = sys.io.File.getContent(hxmlPath);
                for (line in content.split("\n")) {
                    var trimmed = StringTools.trim(line);
                    if (StringTools.startsWith(trimmed, "-main ")) {
                        mainClass = StringTools.trim(trimmed.substr(6));
                    }
                }
            }
            var lowerName = mainClass.toLowerCase();
            sys.io.File.saveContent(suiJson, '{\n    "appName": "$mainClass",\n    "bundleIdentifier": "com.mui.$lowerName"\n}\n');
        }
    }
}

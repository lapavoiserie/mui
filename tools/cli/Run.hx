package tools.cli;

/**
    Builds and runs a mui project for the specified backend.
**/
class Run {
    public static function run(cwd:String, args:Array<String>) {
        if (args.length == 0) {
            Sys.println("Error: specify a backend (sui, wui, or cui)");
            Sys.println("Usage: mui run <sui|wui|cui> [options]");
            Sys.exit(1);
        }

        var backend = args[0];
        var extraArgs = args.slice(1);

        var hxmlFile = 'build-$backend.hxml';
        if (!sys.FileSystem.exists('$cwd/$hxmlFile')) {
            Sys.println('Error: $hxmlFile not found in $cwd');
            Sys.exit(1);
        }

        Sys.setCwd(cwd);

        // Delegate, as `Build` does, and for the same reason.
        Build.ensureBuildHxml(cwd, backend);
        Build.ensureProjectFile(cwd, backend);

        var command = ["run", backend, "run"];
        for (a in extraArgs) command.push(a);
        Sys.exit(Sys.command("haxelib", command));
    }

    static function readMainClass(hxmlPath:String):String {
        if (!sys.FileSystem.exists(hxmlPath)) return null;
        var content = sys.io.File.getContent(hxmlPath);
        for (line in content.split("\n")) {
            var trimmed = StringTools.trim(line);
            if (StringTools.startsWith(trimmed, "-main ")) {
                return StringTools.trim(trimmed.substr(6));
            }
        }
        return null;
    }
}

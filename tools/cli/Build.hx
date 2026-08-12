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

        switch (backend) {
            case "sui":
                // sui CLI handles: Haxe → Swift codegen → Xcode → .app bundle
                ensureBuildHxml(cwd, backend);
                ensureSuiJson(cwd);
                var suiArgs = ["run", "sui", "build"];
                for (a in extraArgs) suiArgs.push(a);
                var code = Sys.command("haxelib", suiArgs);
                if (code != 0) Sys.exit(code);

            case "wui":
                // wui CLI handles: Haxe → C++/WinRT codegen → MSBuild → .exe
                ensureBuildHxml(cwd, backend);
                var wuiArgs = ["run", "wui", "build"];
                for (a in extraArgs) wuiArgs.push(a);
                var code = Sys.command("haxelib", wuiArgs);
                if (code != 0) Sys.exit(code);

            case "aui":
                // aui CLI handles: Haxe → JVM → Kotlin codegen → Gradle → APK
                ensureBuildHxml(cwd, backend);
                var auiArgs = ["run", "aui", "build"];
                for (a in extraArgs) auiArgs.push(a);
                var code = Sys.command("haxelib", auiArgs);
                if (code != 0) Sys.exit(code);

            case "cui":
                // cui compiles directly — no special pipeline
                var code = Sys.command("haxe", [hxmlFile]);
                if (code != 0) Sys.exit(code);
                Sys.println("Build complete: build/cui/");

            case "pui":
                // pui compiles directly too, and its own CLI serves the result.
                var code = Sys.command("haxe", [hxmlFile]);
                if (code != 0) Sys.exit(code);
                Sys.println("Build complete — serve it with: haxelib run pui run");

            default:
                Sys.println('Unknown backend: $backend');
                Sys.println("Available backends: sui, wui, cui, aui, qui, pui");
                Sys.exit(1);
        }
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
    public static function ensureSuiJson(cwd:String):Void {
        var suiJson = '$cwd/sui.json';
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

package tools.cli;

import sys.FileSystem;
import sys.io.File;

/**
    File watcher with CPPIA hot reload.

    For cui: compiles .cppia scripts (~0.3s) and reruns via the CPPIA host.
    For sui/wui/aui: full rebuild + restart (warm reload).
**/
class Watch {
    static var cppiaHost:String = "";
    static var cppiaScript:String = "";

    public static function run(cwd:String, args:Array<String>) {
        if (args.length == 0) {
            Sys.println("Usage: mui watch <sui|wui|aui|cui>");
            Sys.exit(1);
        }

        var backend = args[0];
        var hxmlFile = 'build-$backend.hxml';
        var hxmlPath = '$cwd/$hxmlFile';
        if (!FileSystem.exists(hxmlPath)) {
            Sys.println('Error: $hxmlFile not found');
            Sys.exit(1);
        }

        // Find source directories from hxml
        var sourceDirs = parseSourceDirs(hxmlPath, cwd);
        Sys.println('[watch] Watching ${sourceDirs.length} source directories for $backend');

        // Record initial mtimes
        var mtimes = scanMtimes(sourceDirs);
        Sys.println('[watch] Tracking ${Lambda.count(mtimes)} .hx files');

        Sys.setCwd(cwd);

        // Which reload a backend can do is the last thing here that names one,
        // and it stays named on purpose: it is not a capability a CLI can be
        // asked about, and guessing wrong means watching a host that never
        // reloads. When a backend's CLI can answer for itself, this goes too.
        switch (backend) {
            case "cui":
                // CPPIA: recompile .cppia script only (<1s), restart process
                watchCppia(cwd, hxmlFile, sourceDirs, mtimes);
            case "sui" | "aui":
                // CPPIA + dynamic renderer: recompile .cppia (<1s),
                // host stays running and re-renders view tree
                // For now, falls back to warm reload until CPPIA host mode
                // is fully integrated in the backend CLIs.
                watchCppiaWithHost(cwd, backend, hxmlFile, sourceDirs, mtimes);
            default:
                // Warm reload: full rebuild + restart
                watchWarm(cwd, backend, sourceDirs, mtimes);
        }
    }

    /**
        CPPIA hot reload loop for cui.
        Uses the pre-built CPPIA host binary; recompiles only the .cppia script.
    **/
    static function watchCppia(cwd:String, hxmlFile:String, sourceDirs:Array<String>, mtimes:Map<String, Float>) {
        cppiaHost = findCppiaHost();
        cppiaScript = '$cwd/build/watch.cppia';

        if (cppiaHost == "") {
            Sys.println("[watch] Error: CPPIA host not found. Looking in hxcpp bin/");
            Sys.exit(1);
        }

        // Initial compile
        Sys.println("[watch] Compiling .cppia script...");
        if (!compileCppia(cwd, hxmlFile)) {
            Sys.println("[watch] Initial build failed. Fix errors and save.");
        } else {
            Sys.println('[watch] Ready. Launching...');
        }

        // Main watch loop
        while (true) {
            // Launch app
            var pid = launchBackground('$cppiaHost $cppiaScript');

            // Poll for changes
            while (true) {
                Sys.sleep(0.5);
                var changed = checkChanges(sourceDirs, mtimes);
                if (changed != null) {
                    Sys.println('[watch] Changed: $changed');
                    killProcess(pid);

                    Sys.println("[watch] Recompiling...");
                    var start = Sys.time();
                    if (compileCppia(cwd, hxmlFile)) {
                        var elapsed = Std.int((Sys.time() - start) * 1000);
                        Sys.println('[watch] Ready. (${elapsed}ms)');
                    } else {
                        Sys.println("[watch] Build failed. Waiting for changes...");
                    }
                    break; // relaunch
                }
            }
        }
    }

    /**
        CPPIA with dynamic renderer for sui/aui.
        First build: full pipeline (builds host with dynamic renderer).
        Subsequent: recompile .cppia only, host detects change and re-renders.

        Until CPPIA host mode is integrated into backend CLIs, this falls
        back to warm reload but uses CPPIA for the Haxe compilation step.
    **/
    static function watchCppiaWithHost(cwd:String, backend:String, hxmlFile:String, sourceDirs:Array<String>, mtimes:Map<String, Float>) {
        // Phase 1: Build the host app with dynamic renderer (once)
        Sys.println('[watch] Building hot reload host for $backend (first time only)...');

        // `--watch` is a request, not a fact about a backend: a CLI that knows
        // the flag builds a host that can re-render, and one that does not
        // ignores it. Naming the two that know it was `mui` keeping a note about
        // someone else's CLI.
        Build.ensureBuildHxml(cwd, backend);
        Build.ensureProjectFile(cwd, backend);
        Sys.setCwd(cwd);
        var code = Sys.command("haxelib", ["run", backend, "build", "--watch"]);
        if (code != 0) {
            Sys.println("[watch] Host build failed.");
            Sys.exit(1);
        }

        // Phase 2: Now watch and do warm reloads
        // The host was built with the dynamic renderer, so subsequent
        // rebuilds only need to regenerate Swift/Kotlin from the new Haxe AST
        Sys.println("[watch] Host ready. Watching for changes...");
        watchWarm(cwd, backend, sourceDirs, mtimes);
    }

    /**
        Warm reload loop for wui (and fallback for sui/aui).
        Full rebuild + restart on each change.
    **/
    static function watchWarm(cwd:String, backend:String, sourceDirs:Array<String>, mtimes:Map<String, Float>) {
        // Initial build
        Sys.println('[watch] Building for $backend...');
        Build.run(cwd, [backend]);
        Sys.println("[watch] Ready.");

        while (true) {
            // Launch app in background
            var pid = launchBackendRun(cwd, backend);

            // Poll for changes
            while (true) {
                Sys.sleep(0.5);
                var changed = checkChanges(sourceDirs, mtimes);
                if (changed != null) {
                    Sys.println('[watch] Changed: $changed');
                    killProcess(pid);

                    Sys.println('[watch] Rebuilding for $backend...');
                    Build.run(cwd, [backend]);
                    Sys.println("[watch] Ready.");
                    break; // relaunch
                }
            }
        }
    }

    static function compileCppia(cwd:String, hxmlFile:String):Bool {
        // Parse the hxml and replace -cpp with -cppia
        var content = File.getContent('$cwd/$hxmlFile');
        var cppiaHxml = '$cwd/build/watch.hxml';
        FileSystem.createDirectory('$cwd/build');

        var lines = content.split("\n");
        var out = new StringBuf();
        for (line in lines) {
            var trimmed = StringTools.trim(line);
            if (StringTools.startsWith(trimmed, "-cpp ")) {
                // Replace -cpp with -cppia
                out.add('-cppia $cwd/build/watch.cppia\n');
            } else {
                out.add(line);
                out.add("\n");
            }
        }
        File.saveContent(cppiaHxml, out.toString());

        return Sys.command("haxe", [cppiaHxml]) == 0;
    }

    static function findCppiaHost():String {
        // Check for ARM64 first, then Mac64 (x86_64 via Rosetta)
        var hxcppDir = findHxcppDir();
        var arm64 = '$hxcppDir/bin/MacArm64/Cppia';
        if (FileSystem.exists(arm64)) return arm64;
        var mac64 = '$hxcppDir/bin/Mac64/Cppia';
        if (FileSystem.exists(mac64)) return mac64;
        return "";
    }

    static function findHxcppDir():String {
        try {
            var proc = new sys.io.Process("haxelib", ["path", "hxcpp"]);
            var lines = proc.stdout.readAll().toString().split("\n");
            proc.close();
            for (line in lines) {
                var trimmed = StringTools.trim(line);
                if (trimmed.length > 0 && !StringTools.startsWith(trimmed, "-")) {
                    if (FileSystem.exists('$trimmed/bin')) return trimmed;
                }
            }
        } catch (e:Dynamic) {}
        return "/usr/local/lib/haxe/lib/hxcpp/4,3,2";
    }

    // --- File watching ---

    static function parseSourceDirs(hxmlPath:String, cwd:String):Array<String> {
        var dirs:Array<String> = [];
        var content = File.getContent(hxmlPath);
        for (line in content.split("\n")) {
            var trimmed = StringTools.trim(line);
            if (StringTools.startsWith(trimmed, "-cp ")) {
                var dir = StringTools.trim(trimmed.substr(4));
                // Resolve relative paths
                var resolved = StringTools.startsWith(dir, "/") ? dir : '$cwd/$dir';
                if (FileSystem.exists(resolved)) dirs.push(resolved);
            }
        }
        return dirs;
    }

    static function scanMtimes(dirs:Array<String>):Map<String, Float> {
        var mtimes = new Map<String, Float>();
        for (dir in dirs) {
            scanDir(dir, mtimes);
        }
        return mtimes;
    }

    static function scanDir(dir:String, mtimes:Map<String, Float>):Void {
        if (!FileSystem.exists(dir) || !FileSystem.isDirectory(dir)) return;
        for (entry in FileSystem.readDirectory(dir)) {
            var path = '$dir/$entry';
            if (FileSystem.isDirectory(path)) {
                scanDir(path, mtimes);
            } else if (StringTools.endsWith(entry, ".hx")) {
                mtimes.set(path, FileSystem.stat(path).mtime.getTime());
            }
        }
    }

    static function checkChanges(dirs:Array<String>, mtimes:Map<String, Float>):String {
        var current = new Map<String, Float>();
        for (dir in dirs) scanDir(dir, current);

        for (path => mtime in current) {
            if (!mtimes.exists(path) || mtimes.get(path) != mtime) {
                // Update all mtimes
                for (p => m in current) mtimes.set(p, m);
                // Return just the filename
                var parts = path.split("/");
                return parts[parts.length - 1];
            }
        }
        return null;
    }

    // --- Process management ---

    static function launchBackground(cmd:String):Int {
        // Launch in background, return PID
        var pidFile = '/tmp/mui-watch-pid';
        Sys.command("/bin/sh", ["-c", '$cmd & echo $$! > $pidFile']);
        // Read PID
        try {
            return Std.parseInt(StringTools.trim(File.getContent(pidFile)));
        } catch (e:Dynamic) {
            return -1;
        }
    }

    static function launchBackendRun(cwd:String, backend:String):Int {
        var pidFile = '/tmp/mui-watch-pid';
        Build.ensureBuildHxml(cwd, backend);
        Build.ensureProjectFile(cwd, backend);
        Sys.command("/bin/sh", ["-c", 'haxelib run $backend run & echo $$! > $pidFile']);
        try {
            return Std.parseInt(StringTools.trim(File.getContent(pidFile)));
        } catch (e:Dynamic) {
            return -1;
        }
    }

    static function killProcess(pid:Int):Void {
        if (pid > 0) {
            Sys.command("kill", [Std.string(pid)]);
            Sys.sleep(0.2);
            // Force kill if still running
            Sys.command("kill", ["-9", Std.string(pid)]);
        }
    }
}

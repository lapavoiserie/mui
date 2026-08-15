# Dashboard

A system monitoring dashboard with progress indicators and stats.

```haxe
import mui.App;
import mui.View;
import mui.ui.*;

class DashboardApp extends App {
    public function new() {
        super();
        appTitle = "Dashboard";
    }

    override function body():View {
        return new VStack([
            new Text("System Dashboard"),
            new Divider(),
            new Text("Resources"),
            statusRow("CPU", 0.73),
            statusRow("Memory", 0.45),
            statusRow("Disk", 0.89),
            new Divider(),
            new Text("Stats"),
            infoRow("Uptime", "14d 3h 22m"),
            infoRow("Requests/s", "1,247"),
            infoRow("Latency p99", "142ms"),
            infoRow("Error rate", "0.03%"),
            new Spacer(),
        ], 8);
    }

    function statusRow(label:String, value:Float):View {
        return new HStack([
            new Text(label),
            new ProgressView(null, value),
            new Text('${Std.int(value * 100)}%'),
        ], 8);
    }

    function infoRow(label:String, val:String):View {
        return new HStack([
            new Text(label),
            new Spacer(),
            new Text(val),
        ], 4);
    }

    static function main() {
        #if mui_owns_main
        new DashboardApp().run();
        #end
    }
}
```

## What it demonstrates

- `ProgressView` for status bars
- View helper functions (`statusRow`, `infoRow`) — on sui, inlined by the SwiftGenerator at compile time
- `Spacer` for flexible layout
- Zero `#if` blocks in UI code

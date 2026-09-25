# Dashboard

A system monitoring dashboard with progress indicators and stats.

```haxe
import mui.macros.Markup.ui;

class DashboardApp extends mui.App {
    public function new() {
        super();
        appTitle = "Dashboard";
    }

    override function body():mui.View {
        return ui(<VStack spacing={8}>
            <Text text="System Dashboard" scale="title"/>
            <Divider/>
            <Text text="Resources" scale="caption"/>
            {[statusRow("CPU", 0.73), statusRow("Memory", 0.45), statusRow("Disk", 0.89)]}
            <Divider/>
            <Text text="Stats" scale="caption"/>
            {[
                infoRow("Uptime", "14d 3h 22m"),
                infoRow("Requests/s", "1,247"),
                infoRow("Latency p99", "142ms"),
                infoRow("Error rate", "0.03%"),
            ]}
            <Spacer/>
        </VStack>);
    }

    function statusRow(label:String, value:Float):mui.View {
        return ui(<HStack spacing={8}>
            <Text text={label}/>
            <ProgressView value={value}/>
            <Text text={Std.int(value * 100) + "%"}/>
        </HStack>);
    }

    function infoRow(label:String, said:String):mui.View {
        return ui(<HStack spacing={4}>
            <Text text={label}/>
            <Spacer/>
            <Text text={said}/>
        </HStack>);
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

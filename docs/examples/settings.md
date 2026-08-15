# Settings

A settings screen with toggles, dividers, and an app title.

```haxe
import mui.App;
import mui.View;
import mui.ui.*;

class SettingsApp extends App {
    @:state var darkMode:Bool = false;
    @:state var notifications:Bool = true;
    @:state var analytics:Bool = false;
    @:state var autoUpdate:Bool = true;

    public function new() {
        super();
        appTitle = "Settings";
    }

    override function body():View {
        return new VStack([
            new Text("Settings"),
            new Divider(),
            new Text("Appearance"),
            new Toggle("Dark Mode", darkMode),
            new Divider(),
            new Text("Notifications"),
            new Toggle("Push Notifications", notifications),
            new Divider(),
            new Text("Privacy"),
            new Toggle("Send Analytics", analytics),
            new Toggle("Auto-Update", autoUpdate),
            new Divider(),
            new Text("Version 0.1.0"),
            new Spacer(),
        ], 8);
    }

    static function main() {
        #if mui_owns_main
        new SettingsApp().run();
        #end
    }
}
```

## What it demonstrates

- Multiple `Toggle` bindings with zero `#if` blocks
- `Divider` for visual sections
- `appTitle` property

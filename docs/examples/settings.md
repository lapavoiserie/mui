# Settings

A settings screen with toggles, dividers, and an app title.

```haxe
import mui.macros.Markup.ui;

class SettingsApp extends mui.App {
    @:state var darkMode:Bool = false;
    @:state var notifications:Bool = true;
    @:state var analytics:Bool = false;
    @:state var autoUpdate:Bool = true;

    public function new() {
        super();
        appTitle = "Settings";
    }

    override function body():mui.View {
        return ui(<VStack spacing={8}>
            <Text text="Settings" scale="title"/>
            <Divider/>
            <Text text="Appearance" scale="caption"/>
            <Toggle label="Dark Mode" isOn={darkMode_}/>
            <Divider/>
            <Text text="Notifications" scale="caption"/>
            <Toggle label="Push Notifications" isOn={notifications_}/>
            <Divider/>
            <Text text="Privacy" scale="caption"/>
            <Toggle label="Send Analytics" isOn={analytics_}/>
            <Toggle label="Auto-Update" isOn={autoUpdate_}/>
            <Divider/>
            <Text text="Version 0.1.0"/>
            <Spacer/>
        </VStack>);
    }

    static function main() {
        #if mui_owns_main
        new SettingsApp().run();
        #end
    }
}
```

## What it demonstrates

- several toggles, each binding its own cell — `isOn={darkMode_}`
- `scale="caption"` to set a heading apart without a font size
- `Divider` for visual sections
- `appTitle` property

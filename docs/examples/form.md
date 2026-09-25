# Form

A registration form with text inputs, toggles, and action buttons.

```haxe
import mui.macros.Markup.ui;

class FormApp extends mui.App {
    @:state var name:String = "";
    @:state var email:String = "";
    @:state var newsletter:Bool = true;
    @:state var terms:Bool = false;

    public function new() {
        super();
        appTitle = "Form";
    }

    override function body():mui.View {
        return ui(<VStack spacing={8}>
            <Text text="Registration" scale="title"/>
            <Divider/>
            <TextInput text={name_} placeholder="Enter your name"/>
            <TextInput text={email_} placeholder="Enter your email"/>
            <Divider/>
            <Toggle label="Subscribe to newsletter" isOn={newsletter_}/>
            <Toggle label="I accept the terms" isOn={terms_}/>
            <Divider/>
            <HStack spacing={8}>
                <Button label="Submit" onClick={submit}/>
                <Button label="Clear" onClick={clear}/>
            </HStack>
            <Spacer/>
        </VStack>);
    }

    function submit() {}

    function clear() {
        name = "";
        email = "";
        newsletter = true;
        terms = false;
    }

    static function main() {
        #if mui_owns_main
        new FormApp().run();
        #end
    }
}
```

## What it demonstrates

- a two-way control binds the **cell**: `text={name_}`, `isOn={terms_}`
- an action is a closure or a method: `onClick={submit}`
- `Divider` as a visual separator
- `appTitle` for setting the window title

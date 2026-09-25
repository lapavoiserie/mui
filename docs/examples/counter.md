# Counter

The simplest example: a counter with increment, decrement, and reset buttons.

```haxe
import mui.macros.Markup.ui;

class Counter extends mui.App {
    @:state var count:Int = 0;

    override function body():mui.View {
        return ui(<VStack spacing={10}>
            <Spacer/>
            <Text text="Counter" scale="title"/>
            <Text text={"Count: " + count}/>
            <HStack spacing={8}>
                <Button label="−" onClick={() -> count -= 1}/>
                <Button label="Reset" onClick={() -> count = 0}/>
                <Button label="+" onClick={() -> count += 1}/>
            </HStack>
            <Spacer/>
        </VStack>);
    }

    static function main() {
        #if mui_owns_main
        new Counter().run();
        #end
    }
}
```

## What it demonstrates

- a view written in [markup](../markup.md), checked against the backend
- `@:state` reactive state declaration
- `count` reads and `count = …` writes: the same spelling on every backend
- `VStack` / `HStack` layout
- `Button` with closure actions
- Zero `#if` blocks in the UI code

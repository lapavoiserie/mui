import mui.macros.Markup.ui;

/**
	One source, three backends, written in `mui`'s markup.

	## Why it holds so little

	A kitchen sink is supposed to show everything, and this one shows eleven node
	types. That is not modesty: it is **every type `pui`, `sui`, `aui` and
	`cui` all declare**, and the markup is checked against the backend named by
	`-D mui_backend`, so anything else fails to compile rather than to draw.
	`mui/test/vocabulary` keeps the table of who declares what.

	The tenth is `Button`. It was absent on purpose until 2026-09-21: `aui`
	had no control that could carry a closure, so nothing declared it there,
	and the markup could not write one for that target. It was a field
	missing, not a capability -- `aui` renders by running Haxe on the JVM --
	and once the field existed the button came back here.

	## What it does show

	Every shared control, bound to state, plus the modifier canon: padding and
	a border written **whole**, a colour by role so each platform resolves it
	with its own palette, `flex`, `clip`, `opacity`, and children computed from
	data. Type in the field, drag the slider, flip the switch: the text follows,
	because the view reads the cells and the effect around it subscribed.
**/
@:keep
class KitchenSink extends mui.App {
	@:state var name:String = "Pavois";
	@:state var level:Float = 0.4;

	/** Which output: options written as data children, the canon's shape. **/
	@:state var output:Int = 1;
	@:state var lit:Bool = true;

	static function main() {
		#if mui_owns_main
		new KitchenSink().run();
		#end
	}

	public function new() {
		super();
		appTitle = "Kitchen Sink";
	}

	/**
		The screen, handed to whichever door this backend has.

		**Only `wui` has a `view():nui.Node` hook.** `pui`, `sui` and `aui` all
		expect `body()` returning their own `View` type, so the markup is
		written once -- above, in `screen()` -- and these few lines hand it
		over three different ways. That asymmetry is the honest result of
		writing this example: the markup is shared, the plumbing to accept it
		is not.

		`pui` builds views from a node in Haxe (`NodeRenderer`). `sui` and
		`aui` have no such builder -- they render a received tree natively,
		through the same door the Companion uses -- so the tree is handed to
		`readThrough` and `body()` is left empty.
	**/
	/**
		The screen. One source, three backends.

		Written straight into `body()`, not through a helper: `sui`'s generator
		reads this method at compile time and turns it into Swift, and a call
		to a method of our own is not something it can follow -- *"[SwiftGen]
		Cannot generate Swift for this factory call"*. `pui` and `aui` did not
		care, which is exactly why it was worth finding out.
	**/
	override function body():mui.View {
		return ui(<VStack spacing={12} padding={{top: 16.0, right: 16.0, bottom: 16.0, left: 16.0}}>
			<Text text="mui markup, four backends" scale="title"/>
			<Text text="every type all four declare" scale="caption"/>

			<VStack spacing={8}
				padding={{top: 12.0, right: 12.0, bottom: 12.0, left: 12.0}}
				opacity={1.0}>
				<Text text="Bound to state"/>
				<TextInput text={name_} placeholder="your name"/>
				<Toggle label="lit" isOn={lit_}/>
				<Slider value={level_} min={0.0} max={1.0}/>
				<Text text={"hello " + name + " · " + Math.round(level * 100) + "%"}/>
				<Button label="Full" onClick={() -> level = 1.0}/>
				<Picker label="Sortie" selectedIndex={output_}>
					<Text text="HDMI"/>
					<Text text="SDI"/>
				</Picker>
			</VStack>

			<HStack spacing={8}>
				<Text text="left"/>
				<Spacer/>
				<Text text="right"/>
			</HStack>

			<ZStack>
				<VStack height={44.0}/>
				<Text text="over it"/>
			</ZStack>

			<ScrollView clip={true}>
				{[for (i in 0...12) ui(<HStack spacing={8}
					padding={{top: 6.0, right: 6.0, bottom: 6.0, left: 6.0}}>
					<Text text={"row " + (i + 1)}/>
					<Spacer/>
					<Text text={i % 2 == 0 ? "even" : "odd"}/>
				</HStack>)]}
			</ScrollView>
		</VStack>);
	}

	function setName(v:String):Void name = v;

	function setLit(v:Bool):Void lit = v;

	function setLevel(v:Float):Void level = v;
}

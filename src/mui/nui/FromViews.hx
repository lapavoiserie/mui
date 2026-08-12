package mui.nui;

#if (mui_backend == "wui")
import nui.Node;
import nui.PropValue;

/**
	Describes a `mui` view tree as `nui` nodes.

	## Why this exists

	`mui` had two shapes of application, and which one you wrote depended on the
	backend you were targeting — which is the one thing a layer like this exists
	to stop being true:

	- `body():View`, built from `mui.ui.*`, on sui, aui and cui.
	- `view():nui.Node`, built from `ui()` markup, on wui alone.

	An app written the first way compiled for wui and drew an empty window: the
	push renderer asks for `nuiBody()`, and `body()` was a stub nobody called.
	The kitchen sink — one source for four backends — could not run on the
	fourth.

	So the tree is *described* rather than rewritten. A `mui.ui.Button` on wui
	already **is** a `wui.ui.Button`, carrying a type name, properties and
	children; a `nui.Node` wants exactly those. This walks one and produces the
	other, which is what `nui` is for: the shared model both halves agree on.

	Markup stays available. An app that overrides `view()` is describing nodes
	directly and this is never reached.

	## Identity

	A node's key is its **place**, unless the view carries a `nodeId`. That is
	the rule the whole ecosystem settled on — see `wui.nui.Reconciler`, which
	explains what it costs to get wrong: without a key, "the text box they are
	typing in silently becomes a different one".
**/
class FromViews {
	/** Describe a view tree, or an empty root when there is nothing to draw. **/
	public static function describe(view:wui.View):Node {
		if (view == null) return new Node("VStack");
		return node(view, 0);
	}

	static function node(view:wui.View, index:Int):Node {
		var out = new Node(typeOf(view), keyOf(view, index));

		if (view.properties != null) {
			for (key in view.properties.keys()) {
				var value = toProp(view.properties.get(key));
				if (value != null) out.prop(key, value);
			}
		}

		if (view.children != null) {
			for (i in 0...view.children.length) {
				var child = view.children[i];
				if (child != null) out.children.push(node(child, i));
			}
		}

		return out;
	}

	/**
		The node type, which is what a host switches on.

		`wui.View` sets it in its constructor — `super("Button")` — so a subclass
		reports its parent's unless it sets its own. That is the same rule the
		other backends follow, and it is why `mui.ui.TextInput` draws as the text
		box it extends.
	**/
	static function typeOf(view:wui.View):String {
		var type = view.viewType;
		return type == null || type == "" ? "VStack" : type;
	}

	static function keyOf(view:wui.View, index:Int):String {
		if (view.properties != null) {
			var declared:Dynamic = view.properties.get("nodeId");
			if (declared != null) {
				var asString = Std.string(declared);
				if (asString != "") return asString;
			}
		}
		return "#" + index;
	}

	/**
		A property, in the form the push contract carries.

		A closure crosses as a callback rather than as data: it is how a button's
		action reaches Haxe, and `PString(Std.string(fn))` would hand the sink a
		printed function. Anything else is described as a string, which is what
		the scalar accessors read.
	**/
	static function toProp(value:Dynamic):Null<PropValue> {
		if (value == null) return null;
		if (Reflect.isFunction(value)) return PCallback(value);
		if (Std.isOfType(value, Bool)) return PBool(value);
		if (Std.isOfType(value, Int)) return PInt(value);
		if (Std.isOfType(value, Float)) return PFloat(value);
		return PString(Std.string(value));
	}
}
#end

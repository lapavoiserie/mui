package mui.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	XML markup for describing a view, checked against the backend you are
	building for.

	```haxe
	ui(<VStack spacing={8}>
		<Text text={"Compteur : " + count}/>
		<Button text="Ajouter" onClick={add}/>
	</VStack>)
	```

	## Why this lives in `mui`

	Because **markup that validates has to know the target backend, and `mui` is
	the only layer that does** (`-D mui_backend`). The vocabulary is the
	backend's — `wui` has `ProgressRing`, `cui` has `Table` — so the useful error
	is "`placeholder` does not exist *here*". `nui` cannot say that: it does not
	know who you are compiling for, and giving it a common core to check against
	would make it own a vocabulary rather than a model.

	Three layers, each owning what it can actually know:

	| | owns |
	|---|---|
	| `nui` | what a node **is**, and the two renderer contracts |
	| the backend | **which** nodes exist, with which properties (its `Schema`) |
	| `mui` | **how** you write them, and against which target |

	Markup is syntax; the schema is vocabulary; `nui.Node` is structure.

	## What the schema buys over guessing

	`qui`'s existing `jsx()` infers a property's type from its **name** — a
	hardcoded list where `text` and `label` are strings, `spacing` is an int, and
	anything starting with `on` is a handler. It even special-cases `value` by
	tag, because `<Slider value=…>` is a number while `<ComboBox value=…>` is a
	string. With a schema there is nothing to infer: the kind is declared next to
	the property, per node type.

	## What is checked, and where it stops

	A tag or attribute written literally here is judged now: an unknown node
	type, an attribute the type does not accept, a required attribute missing.
	That is the same boundary the builder API has — what is written in source can
	be judged; what arrives as data at runtime cannot, and meets `?TypeName`
	instead.

	Interpolation `{expr}` is Haxe, parsed at its real source position so the
	compiler can complete inside it. Text content becomes the `text` property.
**/
class Markup {
	/**
		Build a `nui.Node` tree from markup.

		## Why this saves three statics before doing anything

		`base`, `file` and `exprs` are where the extracted `{expr}` blocks live
		while one piece of markup is being read, and they were plain statics --
		fine for one call, and one call was all there ever was.

		Computed children ended that the day they arrived, because the natural
		way to write them nests:

		```haxe
		ui(<VStack>
			<Picker …>{[for (t in types) ui(<Text text={t}/>)]}</Picker>
		</VStack>);
		```

		The inner `ui()` runs while the outer is halfway through its
		attributes, overwrites all three, and the outer then reads `exprs` that
		belong to the inner:

		    Markup.hx:175: Uncaught exception field access on null

		Found by the Farceur session, on the exact example this library's own
		documentation gives. The suite missed it because its computed list was
		the last thing in its tag, so nothing was read afterwards -- a test that
		passed for a reason unrelated to what it was checking.

		Saved and put back rather than made a parameter: the three are read from
		five places on the way down, and threading them through would be a
		parameter nobody reads, for a depth that is almost always one.
	**/
	public static macro function ui(markup:Expr):Expr {
		#if macro
		var outerBase = base;
		var outerFile = file;
		var outerExprs = exprs;

		var built = expand(markup);

		base = outerBase;
		file = outerFile;
		exprs = outerExprs;
		return built;
		#else
		return macro null;
		#end
	}

	#if macro
	static function expand(markup:Expr):Expr {
		var source:String;
		var contentPos:Position;
		var skipQuote:Bool;

		switch (markup.expr) {
			// Markup is preferred over a string: its content is verbatim source
			// with real positions, so each {expr} keeps an accurate position and
			// completion works inside it.
			case EMeta(m, {expr: EConst(CString(s, _)), pos: p}) if (m.name == ":markup"):
				source = s;
				contentPos = p;
				skipQuote = false;
			case EConst(CString(s, _)):
				source = s;
				contentPos = markup.pos;
				skipQuote = true;
			default:
				Context.error("ui() attend du markup (<Tag>...) ou une chaîne littérale", markup.pos);
				return macro null;
		}

		var info = Context.getPosInfos(contentPos);
		base = info.min + (skipQuote ? 1 : 0);
		file = info.file;
		exprs = [];

		var cleaned = extractExpressions(source, exprs);

		var xml:Xml;
		try {
			xml = Xml.parse(cleaned);
		} catch (e:Dynamic) {
			Context.error("XML invalide dans ui() : " + e, markup.pos);
			return macro null;
		}

		var root:Xml = null;
		for (child in xml) {
			if (child.nodeType == Xml.Element) {
				root = child;
				break;
			}
		}
		if (root == null) {
			Context.error("ui() n'a trouvé aucun élément", markup.pos);
			return macro null;
		}

		// A backend that declares no vocabulary cannot be checked, and compiling
		// unchecked markup would mean `<Hologramme/>` passing silently on four
		// backends out of five. Refuse, and name what is missing.
		if (!Backend.hasVocabulary()) {
			Context.error('Le backend "${Backend.name()}" ne déclare pas de vocabulaire : '
				+ "ui() ne peut rien vérifier contre lui.\n"
				+ "  Un backend expose <backend>.nui.Vocabulary — voir wui.nui.Vocabulary.\n"
				+ "  Celui de qui se dérive de ses classes typées ; wui doit le déclarer, "
				+ "son vocabulaire vivant en C++.", markup.pos);
			return macro null;
		}

		return buildNode(root, markup.pos);
	}

	static var base:Int;
	static var file:String;
	static var exprs:Array<{code:String, offset:Int}>;

	/**
		Pull `{expr}` blocks out, leaving placeholders that parse as XML.

		Each block keeps its offset in the original source, which is what lets it
		be re-parsed at its real position later.
	**/
	static function extractExpressions(input:String, out:Array<{code:String, offset:Int}>):String {
		var buf = new StringBuf();
		var i = 0;

		while (i < input.length) {
			if (StringTools.fastCodeAt(input, i) == "{".code) {
				var start = i + 1;
				var depth = 1;
				var j = start;
				while (j < input.length && depth > 0) {
					var ch = StringTools.fastCodeAt(input, j);
					if (ch == "{".code) depth++;
					else if (ch == "}".code) depth--;
					j++;
				}
				out.push({code: input.substr(start, j - start - 1), offset: start});

				// In attribute position the placeholder has to be quoted, or the
				// result is not well-formed XML.
				var quoted = i > 0 && StringTools.fastCodeAt(input, i - 1) == "=".code;
				if (quoted) buf.addChar('"'.code);
				buf.add("__EXPR_" + (out.length - 1) + "__");
				if (quoted) buf.addChar('"'.code);
				i = j;
			} else {
				buf.addChar(StringTools.fastCodeAt(input, i));
				i++;
			}
		}
		return buf.toString();
	}

	/** Re-parse an extracted block at the position it actually occupies. **/
	static function parseExpr(index:Int):Expr {
		var e = exprs[index];
		var pos = Context.makePosition({
			min: base + e.offset,
			max: base + e.offset + e.code.length,
			file: file
		});
		return Context.parseInlineString(e.code, pos);
	}

	/** An attribute value: either a literal, or one `{expr}` placeholder. **/
	static function valueExpr(raw:String, pos:Position):Expr {
		var re = ~/^__EXPR_(\d+)__$/;
		if (re.match(raw)) return parseExpr(Std.parseInt(re.matched(1)));
		return macro $v{raw};
	}

	/**
		The attributes as the object a contract's `node()` takes.

		Unwrapped: the props of a contract are ordinary Haxe fields of a
		typedef, not `nui.PropValue`, so what `wrap` put on comes straight back
		off. The kind was not wasted -- it is what refused `<LevelMeter
		channels="deux"/>` before Haxe ever saw the object.
	**/
	static function object(setters:Array<{key:String, value:Expr}>, pos:Position):Expr {
		var fields:Array<ObjectField> = [];
		for (setter in setters) fields.push({field: setter.key, expr: unwrap(setter.value)});
		return {expr: EObjectDecl(fields), pos: pos};
	}

	/** The value inside a `PropValue` constructor this markup put it in. **/
	static function unwrap(e:Expr):Expr {
		return switch (e.expr) {
			case ECall({expr: EField(_, _)}, [inner]): inner;
			case _: e;
		};
	}

	/** Append one `.prop(key, value)` to a node expression. **/
	static function applyTo(node:Expr, setter:{key:String, value:Expr}):Expr {
		var key = setter.key;
		var value = setter.value;
		return macro $node.prop($v{key}, $value);
	}

	static function buildNode(xml:Xml, pos:Position):Expr {
		var tag = xml.nodeName;

		if (!Backend.knows(tag)) {
			Context.error('Le backend cible ne sait pas construire "$tag".\n'
				+ '  Types connus : ${Backend.types().join(", ")}.', pos);
			return macro null;
		}

		var keyExpr:Expr = macro null;
		var setters:Array<{key:String, value:Expr}> = [];
		var seen = new Map<String, Bool>();

		for (attr in xml.attributes()) {
			var raw = xml.get(attr);

			if (attr == "key") {
				keyExpr = valueExpr(raw, pos);
				continue;
			}

			var kind = Backend.kindOf(tag, attr);
			if (kind == null) {
				Context.error('"$tag" n\'a pas d\'attribut "$attr".\n'
					+ '  Attributs acceptés : ${Backend.keysOf(tag).join(", ")}.', pos);
				continue;
			}

			seen.set(attr, true);
			var value = wrap(kind, valueExpr(raw, pos), tag, attr, pos);
			setters.push({key: attr, value: value});
		}

		// The children, IN THE ORDER THEY WERE WRITTEN.
		//
		// Elements and interpolations are walked together: an element becomes a
		// child node, an interpolation that resolves to nodes is spliced where
		// it stands, and anything else is text. An earlier version appended
		// every computed list after every written child, so

		//     <VStack><Text/>{rows}<Button/></VStack>

		// put `rows` after the button. The Farceur session hit it on the first
		// real panel; source order is the only order anybody can read off the
		// page, and it was not a decision, only what appending happened to do.
		var pieces:Array<{node:Null<Expr>, splice:Null<Expr>}> = [];
		var text:Null<String> = null;

		for (child in xml) {
			switch (child.nodeType) {
				case Xml.Element:
					pieces.push({node: buildNode(child, pos), splice: null});

				case Xml.PCData | Xml.CData:
					var raw = StringTools.trim(child.nodeValue);
					if (raw == "") continue;
					var nodes = spliced(raw, pos);
					if (nodes != null) pieces.push({node: null, splice: nodes});
					else text = text == null ? raw : text + raw;

				case _:
			}
		}

		// Text content is the `text` property -- `nui` settled in B2 that text is
		// an ordinary property, not a special accessor. What tells it apart from
		// children is the TYPE of the interpolation, above: a `String` is text,
		// an `Array<nui.Node>` is children, and there is no expression for which
		// both readings make sense.
		if (text != null && !seen.exists("text")) {
			if (Backend.kindOf(tag, "text") == null) {
				Context.error('"$tag" ne porte pas de texte.\n'
					+ "  Une interpolation d'enfants ({[for (x in xs) ui(<Text …/>)]}) "
					+ "serait acceptée ici ; celle-ci n'est pas une liste de nœuds.", pos);
			} else {
				seen.set("text", true);
				setters.push({key: "text", value: macro nui.PropValue.PString(${valueExpr(text, pos)})});
			}
		}

		for (req in Backend.requiredOf(tag)) {
			if (!seen.exists(req)) {
				Context.error('"$tag" exige l\'attribut "$req", absent ici.', pos);
			}
		}

		// A component contract builds its own node: `vui.meter.LevelMeter.node()`
		// fills in seven defaults and normalises the channel count, and a bare
		// `new Node("LevelMeter")` here would mean the same tag produced
		// something different depending on whether it was written in markup or
		// in Haxe. See `Backend.Vocabulary.builderOf`.
		var builder = Backend.builderOf(tag);
		var chain = builder != null
			? macro $p{builder.split(".")}.node(${object(setters, pos)})
			: macro new nui.Node($v{tag}, $keyExpr);
		if (builder == null) for (setter in setters) chain = applyTo(chain, setter);

		// A chain while every child is written, a block as soon as one is
		// computed: `prop` and `child` return the node, so both shapes build the
		// same tree, and the backend's validator reads a chain as one node with
		// its properties where statements on a local look like a bare `new`
		// carrying none.
		var anySplice = false;
		for (piece in pieces) if (piece.splice != null) anySplice = true;

		if (!anySplice) {
			for (piece in pieces) chain = macro $chain.child(${piece.node});
			return chain;
		}

		var body:Array<Expr> = [];
		body.push(macro final __parent = $chain);
		for (piece in pieces) {
			body.push(piece.splice != null
				? macro for (__child in ${piece.splice}) __parent.child(__child)
				: macro __parent.child(${piece.node}));
		}
		body.push(macro __parent);
		return {expr: EBlock(body), pos: pos};
	}

	/**
		A list of nodes written inside an element, which becomes its children.

		```haxe
		<Picker label="Type" selectedIndex={i} onSelect={choisir}>
		    {[for (t in types) ui(<Text text={t}/>)]}
		</Picker>
		```

		Children written as elements are enough for a panel whose shape is
		known, and not for one drawn from data -- a list of sources, of
		transitions, of placements. Without this the caller writes the tag, then
		a loop outside it, then uses the node again; the Farceur session measured
		its markup at 86 lines against 69 for the same panel in views, and every
		line of the difference was that loop.

		## The type says which, because nothing else honestly could

		The same position already means text: `<Text>{nom}</Text>`. Adding a
		second meaning to the same syntax needs something to tell them apart,
		and a marker (`<For>`, a second brace) would be a word invented to say
		what the expression already says. A `String` is text; an
		`Array<nui.Node>` is children; there is no expression for which both
		readings make sense.

		So this types the interpolation and answers only for a list of nodes.
		Anything else falls through to the text rule, which refuses it by name
		if the tag carries no text -- and now mentions this form, because
		"ne porte pas de texte" is a confusing thing to be told about a `for`
		comprehension.

		Null when the content is not a single interpolation at all: plain text,
		or text around one.
	**/
	static function spliced(raw:String, pos:Position):Null<Expr> {
		var re = ~/^__EXPR_(\d+)__$/;
		if (!re.match(raw)) return null;

		var e = parseExpr(Std.parseInt(re.matched(1)));
		var nodes = Context.getType("nui.Node");
		var list = Context.resolveType(macro :Array<nui.Node>, pos);

		var t = try Context.typeof(e) catch (_:Dynamic) return null;
		if (Context.unify(t, list)) return e;
		// One node on its own is a list of one: writing a conditional child as
		// `{siOuvert ? ui(<Text …/>) : null}` is the same need.
		if (Context.unify(t, nodes)) return macro [$e];
		return null;
	}

	/** Text directly inside this element, ignoring what belongs to children. **/
	static function directText(xml:Xml):Null<String> {
		var buf = new StringBuf();
		var found = false;

		for (child in xml) {
			if (child.nodeType == Xml.PCData || child.nodeType == Xml.CData) {
				var t = StringTools.trim(child.nodeValue);
				if (t != "") {
					buf.add(t);
					found = true;
				}
			}
		}
		return found ? buf.toString() : null;
	}

	/**
		Wrap a value in the `PropValue` constructor the schema declares for it.

		## An act that carries something

		`KCallback` alone was enough while the only declared callback in any
		backend was `wui.ui.Button.onClick`, a `Void->Void`. It stops being
		enough the moment a two-way control is written in markup:

		```haxe
		<Toggle isOn={muet} onToggle={v -> moteur.muet(v)}/>
		```

		`onToggle` carries a `Bool`, and wrapping it as `PCallback` builds a node
		whose action takes nothing. So a backend now says what an act carries,
		and the four `PCallbackX` of `nui.PropValue` each have a kind.

		## And an unknown kind is refused

		This ended in `case _: PString($value)`, which made an unrecognised kind
		into a string — silently, and with a cast error somewhere downstream if
		it was lucky. A schema's job is to say what a value is; a default that
		guesses undoes it. The same shape cost `wui` its numeral setters this
		morning, and `pui` its property kinds.
	**/
	static function wrap(kind:String, value:Expr, tag:String, attr:String, pos:Position):Expr {
		return switch (kind) {
			case "KString": macro nui.PropValue.PString($value);
			case "KInt": macro nui.PropValue.PInt($value);
			case "KFloat": macro nui.PropValue.PFloat($value);
			case "KBool": macro nui.PropValue.PBool($value);
			case "KCallback": macro nui.PropValue.PCallback($value);
			case "KCallbackString": macro nui.PropValue.PCallbackString($value);
			case "KCallbackFloat": macro nui.PropValue.PCallbackFloat($value);
			case "KCallbackInt": macro nui.PropValue.PCallbackInt($value);
			case "KCallbackBool": macro nui.PropValue.PCallbackBool($value);
			case _:
				Context.error('"$tag" déclare "$attr" de sorte "$kind", que ce markup '
					+ "ne sait pas écrire.\n"
					+ "  Sortes connues : KString, KInt, KFloat, KBool, KCallback, "
					+ "KCallbackString, KCallbackFloat, KCallbackInt, KCallbackBool.", pos);
				macro null;
		};
	}
	#end
}

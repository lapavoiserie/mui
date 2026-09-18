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
	/** Build a `nui.Node` tree from markup. **/
	public static macro function ui(markup:Expr):Expr {
		#if macro
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
		#else
		return macro null;
		#end
	}

	#if macro
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

		// Text content is the `text` property -- `nui` settled in B2 that text is
		// an ordinary property, not a special accessor.
		//
		// Unless what is inside is a LIST OF NODES, in which case it is the
		// children. Nothing in the syntax says which: the TYPE does, and there
		// is no expression that could sensibly be both. See `spliced`.
		var text = directText(xml);
		var computed:Null<Expr> = text == null ? null : spliced(text, pos);
		if (computed == null && text != null && !seen.exists("text")) {
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

		var childExprs:Array<Expr> = [];
		for (child in xml) {
			if (child.nodeType == Xml.Element) {
				childExprs.push(buildNode(child, pos));
			}
		}

		// A chain, not a block of statements.
		//
		// `prop` and `child` return the node, so both shapes build the same tree
		// -- but the backend's validator reads a chain as one node with its
		// properties, where statements on a local look like a bare `new` carrying
		// none, and a required property is then reported missing. Emitting the
		// idiomatic form keeps the two in agreement.
		var chain = macro new nui.Node($v{tag}, $keyExpr);
		for (setter in setters) chain = applyTo(chain, setter);
		for (child in childExprs) chain = macro $chain.child($child);

		// A computed list comes after the written children, in the order the
		// expression produced it. Evaluated ONCE, into a local, so a `for`
		// comprehension in the markup is not run per child.
		if (computed != null) {
			chain = macro {
				final __parent = $chain;
				for (__child in $computed) __parent.child(__child);
				__parent;
			};
		}

		return chain;
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

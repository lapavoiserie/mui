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
		var outerWritten = written;
		var outerAt = at;

		var built = expand(markup);

		base = outerBase;
		file = outerFile;
		exprs = outerExprs;
		written = outerWritten;
		at = outerAt;
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
		written = attributeOrder(cleaned);
		at = 0;

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

	/** Attribute names per element, in source order. See `attributeOrder`. **/
	static var written:Array<Array<String>>;

	/** Which element `buildNode` is on, walking `written` in step with it. **/
	static var at:Int;

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

	/**
		The attribute names of every element, in the order they were written.

		`Xml.attributes()` does **not** preserve document order — asked for
		`label onClick backgroundColor foregroundColor opacity` it answers
		`opacity onClick label foregroundColor backgroundColor`. That is fine
		for properties, which are a map, and wrong for decorations, which are a
		LIST because the order is the semantics: a border applied after a
		padding is not the same as one applied before it.

		So the order is read from the source, which is the only place it
		survives. One entry per element, in document order — and `buildNode`
		walks depth-first, attributes before children, which is document order
		too, so a cursor over this list stays in step with it.
	**/
	static function attributeOrder(cleaned:String):Array<Array<String>> {
		var out:Array<Array<String>> = [];
		var i = 0;
		while (i < cleaned.length) {
			if (StringTools.fastCodeAt(cleaned, i) != "<".code) { i++; continue; }
			// A closing tag, a comment or a declaration carries no attributes.
			var after = i + 1 < cleaned.length ? cleaned.charAt(i + 1) : "";
			if (after == "/" || after == "!" || after == "?") { i++; continue; }

			var names:Array<String> = [];
			var j = i + 1;
			// Past the tag name.
			while (j < cleaned.length && !isSpace(cleaned.charAt(j))
				&& cleaned.charAt(j) != ">" && cleaned.charAt(j) != "/") j++;

			while (j < cleaned.length && cleaned.charAt(j) != ">") {
				while (j < cleaned.length && isSpace(cleaned.charAt(j))) j++;
				var start = j;
				while (j < cleaned.length && cleaned.charAt(j) != "=" && cleaned.charAt(j) != ">"
					&& !isSpace(cleaned.charAt(j))) j++;
				var name = cleaned.substr(start, j - start);
				while (j < cleaned.length && isSpace(cleaned.charAt(j))) j++;
				if (j < cleaned.length && cleaned.charAt(j) == "=") {
					if (name != "" && name != "/") names.push(name);
					j++;
					while (j < cleaned.length && isSpace(cleaned.charAt(j))) j++;
					// Past the quoted value, whichever quote it used.
					if (j < cleaned.length && (cleaned.charAt(j) == '"' || cleaned.charAt(j) == "'")) {
						var quote = cleaned.charAt(j);
						j++;
						while (j < cleaned.length && cleaned.charAt(j) != quote) j++;
						j++;
					}
				} else if (name == "") {
					j++;
				}
			}
			out.push(names);
			i = j;
		}
		return out;
	}

	static inline function isSpace(c:String):Bool
		return c == " " || c == "\t" || c == "\n" || c == "\r";

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

	/**
		Append one `.modifier(...)` to a node expression.

		A modifier's shape on the wire is `{type, floats, strings}` rather than
		a `PropValue`, so what an attribute carries goes into whichever of the
		two lists its kind belongs in. `clip` carries nothing and is written as
		a flag, so `clip={true}` adds it and `clip={false}` does not -- which is
		the only way to write "not clipped" without a second name for it.
	**/
	/** One `nui.Modifier` literal, as the node path would have carried it. **/
	static function modifierOf(of:{key:String, kind:String, value:Expr}):Expr {
		var key = of.key;
		var value = of.value;
		var whole = whole(key, value);
		if (whole != null) {
			var strings = {expr: EArrayDecl(whole.strings), pos: value.pos};
			var floats = {expr: EArrayDecl(whole.floats), pos: value.pos};
			return macro {type: $v{key}, strings: $strings, floats: $floats};
		}
		return switch (of.kind) {
			case "KString": macro {type: $v{key}, strings: [$value]};
			// `clip` carries nothing, so the flag decides whether it is there
			// at all -- and in a list that means an entry or an empty one.
			case "KBool": macro($value ? {type: $v{key}} : null);
			case _: macro {type: $v{key}, floats: [$value]};
		}
	}

	static function decorate(node:Expr, of:{key:String, kind:String, value:Expr}):Expr {
		var key = of.key;
		var value = of.value;

		// Written whole, as a structure: `border={{colour: …, width: 3}}`.
		var whole = whole(key, value);
		if (whole != null) {
			var strings = {expr: EArrayDecl(whole.strings), pos: value.pos};
			var floats = {expr: EArrayDecl(whole.floats), pos: value.pos};
			return macro $node.modifier({type: $v{key}, strings: $strings, floats: $floats});
		}

		return switch (of.kind) {
			case "KString": macro $node.modifier({type: $v{key}, strings: [$value]});
			case "KBool": macro $value ? $node.modifier({type: $v{key}}) : $node;
			case _: macro $node.modifier({type: $v{key}, floats: [$value]});
		}
	}

	/**
		A modifier written as a structure rather than a single value.

		`border` carries a colour, a width and a radius -- the wire has said so
		since there was a wire -- and the markup could write only the first, so
		an application wanting a three-pixel border built the modifier by hand
		beside markup that was checked. `nui.Modifiers.partsOf` names the parts,
		and this matches the fields against them.

		Null when the attribute was not written as one, which is every other
		attribute in every existing tree: a colour on its own still means the
		colour, and this reads nothing it was not given.

		Two refusals rather than a guess, both from the canon:
		- **a field the modifier does not carry** -- `borderColour` for
		  `colour` is the same typo `backgroundColour` already is, and it is
		  caught in the same place;
		- **a part named without the part before it**, where a missing one is
		  not a zero: `{colour: …, radius: 6}` asks for a rounded border of no
		  width, which draws nothing at all. Under `fill` (that is, `padding`)
		  there is no such thing -- an unnamed edge has no padding, and that is
		  a real thing to want.
	**/
	static function whole(key:String, value:Expr):Null<{strings:Array<Expr>, floats:Array<Expr>}> {
		var fields = switch (value.expr) {
			case EObjectDecl(f): f;
			case _: return null;
		};
		var canon = nui.Modifiers.partsOf(key);
		// `clip` carries nothing, so `clip={{…}}` is not a whole modifier; it
		// falls through and Haxe refuses the structure as a condition.
		if (canon == null) return null;

		var said = new Map<String, Expr>();
		for (field in fields) {
			if (canon.strings.indexOf(field.field) < 0 && canon.floats.indexOf(field.field) < 0) {
				Context.error('"$key" ne porte pas de "${field.field}".\n'
					+ '  Parties acceptées : '
					+ canon.strings.concat(canon.floats).join(", ") + ".", value.pos);
				continue;
			}
			said.set(field.field, field.expr);
		}

		var strings = [for (name in canon.strings)
			said.exists(name) ? said.get(name) : macro ""];
		// Trailing strings are never dropped: there is one, and it is the
		// colour. An absent one is the empty string, which `nui.Color.said`
		// refuses, so the modifier carries no colour rather than black.

		var floats:Array<Expr> = [];
		var missing:Null<String> = null;
		for (name in canon.floats) {
			if (said.exists(name)) {
				if (missing != null) {
					Context.error('"$key" ne peut pas porter "$name" sans "$missing".\n'
						+ '  Une partie absente y vaut « celle du contrôle », pas zéro.', value.pos);
					return null;
				}
				floats.push(said.get(name));
			} else if (canon.fill) {
				// A real zero, leading or trailing: `{top: 8}` is a padding at
				// the top and nowhere else, not a padding of 8 everywhere --
				// which is what the positional `padding={8}` means, and the
				// reason an object must not be read as a short form.
				floats.push(macro 0.0);
			} else {
				missing = name;
			}
		}

		return {strings: strings, floats: floats};
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
		var decorations:Array<{key:String, kind:String, value:Expr}> = [];
		var seen = new Map<String, Bool>();

		// In the order they were written, which `Xml` does not keep: see
		// `attributeOrder`. A property would not care -- properties are a map
		// -- but a decoration is a list entry, and the order is the semantics.
		var order = at < written.length ? written[at] : [for (a in xml.attributes()) a];
		at++;

		for (attr in order) {
			var raw = xml.get(attr);
			if (raw == null) continue;

			if (attr == "key") {
				keyExpr = valueExpr(raw, pos);
				continue;
			}

			// A decoration, not a property. `backgroundColor` belongs to no
			// control -- it is one of `nui`'s modifiers, an ordered list with
			// its own shape on the wire -- so the backend's vocabulary is not
			// asked about it and `nui` answers instead. The names are a closed
			// set, so `backgroundColour` is refused by the same rule that
			// refuses a misspelt property.
			if (nui.Modifiers.knows(attr)) {
				seen.set(attr, true);
				decorations.push({
					key: attr,
					kind: nui.Modifiers.kindOf(attr),
					value: valueExpr(raw, pos),
				});
				continue;
			}

			var kind = Backend.kindOf(tag, attr);
			if (kind == null) {
				Context.error('"$tag" n\'a pas d\'attribut "$attr".\n'
					+ '  Attributs acceptés : ${Backend.keysOf(tag).join(", ")}.\n'
					+ '  Décorations acceptées sur n\'importe quelle balise : '
					+ nui.Modifiers.NAMES.join(", ") + ".", pos);
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
					// One text node may hold SEVERAL interpolations: `{a}{b}`,
					// or two on separate lines, are one PCData with two
					// placeholders and whitespace between them. Read as a
					// whole it matched neither "one interpolation" nor "text",
					// so `<HStack>{a}{b}</HStack>` was refused with "does not
					// carry text" -- each half compiling on its own, which is
					// the most confusing shape a refusal can take. Found by the
					// Farceur session on the first panel that needed two.
					for (part in runs(child.nodeValue)) {
						var nodes = spliced(part, pos);
						if (nodes != null) pieces.push({node: null, splice: nodes});
						else if (part != "") text = text == null ? part : text + part;
					}

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
		// The backend's own control, when it offers one: markup as a syntax
		// over its API rather than a tree it has to read back. See
		// `Backend.Vocabulary.viewOf`.
		var given = new Map<String, Expr>();
		for (setter in setters) given.set(setter.key, unwrap(setter.value));
		var own = Backend.viewOf(tag, given, childrenExpr(pieces, pos), pos);
		if (own != null) {
			if (decorations.length == 0) return own;
			// The same list, in the same order, the node path would have
			// carried -- the order IS the semantics. The backend hands it to
			// whatever already reads one, so the nine canon names are mapped
			// once per backend and not twice.
			var chain:Array<Expr> = [];
			for (decoration in decorations) chain.push(modifierOf(decoration));
			var list = {expr: EArrayDecl(chain), pos: pos};
			var dressed = Backend.decorate(own, list, pos);
			if (dressed != null) return dressed;
			Context.error('"$tag" est construit par le backend lui-même, qui ne sait pas '
				+ 'encore poser de décoration : ' + [for (d in decorations) d.key].join(", "), pos);
			return own;
		}

		var builder = Backend.builderOf(tag);
		var chain = builder != null
			? macro $p{builder.split(".")}.node(${object(setters, pos)})
			: macro new nui.Node($v{tag}, $keyExpr);
		if (builder == null) for (setter in setters) chain = applyTo(chain, setter);

		// Decorations after the properties, and among themselves in the order
		// they were written: `nui.Modifier` is a list because the order IS the
		// semantics -- a border applied after a padding is not the same as one
		// applied before it.
		for (decoration in decorations) chain = decorate(chain, decoration);

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
		The children as one `Array<View>`, for a backend building its own.

		Null when any of them is a computed list: splicing `{[for …]}` into a
		literal array needs a block, and a block is not an array literal. That
		is a real limit and not a hidden one -- the tag falls back to a node,
		which every backend still accepts.
	**/
	static function childrenExpr(pieces:Array<{node:Expr, splice:Null<Expr>}>, pos:Position):Null<Expr> {
		if (pieces.length == 0) return null;

		var anySplice = false;
		for (piece in pieces) if (piece.splice != null) anySplice = true;
		if (!anySplice) return {expr: EArrayDecl([for (piece in pieces) piece.node]), pos: pos};

		// A computed list cannot be spliced into an array literal, so the
		// children are pushed in written order instead. Typed, because an
		// empty `[]` followed by a push of one control makes an array of THAT
		// control, and the next child of another type would be refused.
		var body:Array<Expr> = [macro var __kids:Array<mui.View> = []];
		for (piece in pieces) {
			body.push(piece.splice != null
				? macro for (__child in ${piece.splice}) __kids.push(__child)
				: macro __kids.push(${piece.node}));
		}
		body.push(macro __kids);
		return {expr: EBlock(body), pos: pos};
	}

	/**
		One text node, split into its interpolations and the text between them.

		`extractExpressions` leaves `__EXPR_n__` placeholders in the source, and
		XML gives back everything between two elements as ONE text node — so two
		interpolations side by side arrive together, with whatever whitespace
		the author wrote between them. Each placeholder is its own run; what is
		left is text, trimmed, and dropped when it is only the whitespace that
		separated them.
	**/
	static function runs(said:Null<String>):Array<String> {
		if (said == null) return [];
		var out:Array<String> = [];
		var pattern = ~/__EXPR_\d+__/;
		var rest = said;
		while (pattern.match(rest)) {
			var before = StringTools.trim(pattern.matchedLeft());
			if (before != "") out.push(before);
			out.push(pattern.matched(0));
			rest = pattern.matchedRight();
		}
		var tail = StringTools.trim(rest);
		if (tail != "") out.push(tail);
		return out;
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
		var t = try Context.typeof(e) catch (_:Dynamic) return null;

		// Nodes, and -- where the backend builds its own controls -- its
		// views. Markup used to produce only nodes, so only nodes were ever
		// spliced; a computed list of `pui.ui.HStack` is the same need and
		// was being read as text, which is a confusing thing to be told.
		var wanted = [Context.getType("nui.Node")];
		// And, where the backend builds its own controls, its views.
		if (Backend.buildsViews()) wanted.push(Context.getType("mui.View"));

		for (one in wanted) {
			// One on its own is a list of one: a conditional child written as
			// `{siOuvert ? ui(<Text …/>) : null}` is the same need.
			if (Context.unify(t, one)) return macro [$e];
		}

		// A LIST of them. Not `unify(t, Array<mui.View>)`: a Haxe array is
		// invariant, so a comprehension of `pui.ui.HStack` does not unify with
		// `Array<pui.View>` however clearly it is a list of views. The element
		// type is what has to be asked.
		var element = switch (Context.follow(t)) {
			case TInst(_.get() => {name: "Array", pack: []}, [item]): item;
			case _: null;
		}
		if (element == null) return null;
		for (one in wanted) if (Context.unify(element, one)) return e;
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

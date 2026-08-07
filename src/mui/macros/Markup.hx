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

	static function buildNode(xml:Xml, pos:Position):Expr {
		var tag = xml.nodeName;

		if (!Backend.knows(tag)) {
			Context.error('Le backend cible ne sait pas construire "$tag".\n'
				+ '  Types connus : ${Backend.types().join(", ")}.', pos);
			return macro null;
		}

		var keyExpr:Expr = macro null;
		var setters:Array<Expr> = [];
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
			var value = wrap(kind, valueExpr(raw, pos));
			setters.push(macro __node.prop($v{attr}, $value));
		}

		// Text content is the `text` property -- `nui` settled in B2 that text is
		// an ordinary property, not a special accessor.
		var text = directText(xml);
		if (text != null && !seen.exists("text")) {
			if (Backend.kindOf(tag, "text") == null) {
				Context.error('"$tag" ne porte pas de texte.', pos);
			} else {
				seen.set("text", true);
				setters.push(macro __node.prop("text", nui.PropValue.PString(${valueExpr(text, pos)})));
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

		var body:Array<Expr> = [macro var __node = new nui.Node($v{tag}, $keyExpr)];
		for (s in setters) body.push(s);
		for (c in childExprs) body.push(macro __node.child($c));
		body.push(macro __node);

		return macro $b{body};
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

	/** Wrap a value in the `PropValue` constructor the schema declares for it. **/
	static function wrap(kind:String, value:Expr):Expr {
		return switch (kind) {
			case "KString": macro nui.PropValue.PString($value);
			case "KInt": macro nui.PropValue.PInt($value);
			case "KFloat": macro nui.PropValue.PFloat($value);
			case "KBool": macro nui.PropValue.PBool($value);
			case "KCallback": macro nui.PropValue.PCallback($value);
			case _: macro nui.PropValue.PString($value);
		};
	}
	#end
}

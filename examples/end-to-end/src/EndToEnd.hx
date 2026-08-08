import mui.macros.Markup.ui;

/**
	La chaîne de bout en bout : `mui` écrit, `wui` rend.

	Rien ici ne nomme WinUI. Le markup est vérifié à la compilation contre le
	vocabulaire du backend visé par `-D mui_backend`, produit un `nui.Node`, et
	le backend le rend à sa façon — `wui` par le contrat push, `cui` par son
	`NodeRenderer`. C'est ce que « write once » devait vouloir dire.

	Changer la cible change ce qui est vérifié : un `<ProgressRing/>` passerait
	sur `wui` et serait refusé sur un backend qui ne le connaît pas, à la
	compilation plutôt qu'à l'écran.
**/
@:keep
class EndToEnd extends mui.App {
	@:state var clics:Int = 0;

	static function main() {}

	public function new() {
		super();
		appTitle = "EndToEnd";
	}

	override public function view():nui.Node {
		return ui(<VStack spacing={8}>
			<Text text="Écrit en markup mui"/>
			<Text text={"clics : " + clics.value}/>
			<Button text="Compter" onClick={compter}/>
		</VStack>);
	}

	// Rien ici ne demande un re-rendu : la vue lit `clics`, donc l'effet qui
	// l'entoure s'y est abonné, et l'écriture ci-dessous suffit.
	function compter():Void {
		clics.value = clics.value + 1;
		trace('[mui] clic n°${clics.value}');
	}
}

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
	static var clics = 0;

	static function main() {}

	public function new() {
		super();
		appTitle = "EndToEnd";
	}

	override public function view():nui.Node {
		return ui(<VStack spacing={8}>
			<Text text="Écrit en markup mui"/>
			<Text text={"clics : " + clics}/>
			<Button text="Compter" onClick={compter}/>
		</VStack>);
	}

	function compter():Void {
		clics++;
		trace('[mui] clic n°$clics');
		wui.bridge.HaxeBridge.rerenderNui();
	}
}

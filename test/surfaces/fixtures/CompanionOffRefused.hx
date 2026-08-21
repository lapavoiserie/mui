import mui.App;
import mui.View;
import mui.ui.Text;

/**
	The networked corner is off unless the build asks for it.

	A Companion is served to other machines; nothing about writing an
	application implies wanting that, so declaring one without `-D mui_cafos`
	does not compile. `CompanionOptIn` is the same file with the switch on.
**/
class CompanionOffRefused extends App {
	override function body():View {
		return new Text("body");
	}

	@:surface(Companion)
	function panel():View {
		return new Text("would never be reachable");
	}

	static function main() {
		new CompanionOffRefused();
	}
}

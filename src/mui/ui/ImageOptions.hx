package mui.ui;

/**
	What an `Image` may say beyond where its picture lives and what it shows.

	Sizes are points. With one of them, the other follows the picture's own
	ratio; with neither, the picture takes its own size, never wider than the
	space offered.
**/
typedef ImageOptions = {
	@:optional var width:Float;
	@:optional var height:Float;
	@:optional var fit:ImageFit;
}

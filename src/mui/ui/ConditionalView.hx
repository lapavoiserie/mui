package mui.ui;

// Shows one view or another based on a Bool state.
// Unified constructor: (condition:State<Bool>, thenView:View, ?elseView:View)
//
// On sui: accepts State<Bool> directly (typed refs supported since PR #53)
// On wui: accepts Dynamic condition
// On aui: accepts State<Bool> directly
// On cui: evaluates condition at runtime via .get()

#if (mui_backend == "sui")
class ConditionalView extends sui.ui.ConditionalView {
    public function new(condition:sui.state.State<Bool>, thenView:sui.View, ?elseView:sui.View) {
        super(condition, thenView, elseView);
    }
}
#elseif (mui_backend == "wui")
class ConditionalView extends wui.ui.ConditionalView {
    public function new(condition:wui.state.State<Bool>, thenView:wui.View, ?elseView:wui.View) {
        super(condition, thenView, elseView);
    }
}
#elseif (mui_backend == "aui")
class ConditionalView extends aui.ui.ConditionalView {
    public function new(condition:aui.state.State<Bool>, thenView:aui.View, ?elseView:aui.View) {
        super(condition, thenView, elseView);
    }
}
#elseif (mui_backend == "cui")
// cui has no ConditionalView — implement at runtime
@:muiSupport("built", "cui has no conditional view: the branch is chosen at construction")
class ConditionalView extends cui.View {
    var condition:cui.state.State<Bool>;
    var thenView:cui.View;
    var elseView:Null<cui.View>;

    public function new(condition:cui.state.State<Bool>, thenView:cui.View, ?elseView:cui.View) {
        super();
        this.condition = condition;
        this.thenView = thenView;
        this.elseView = elseView;
        children = condition.get() ? [thenView] : (elseView != null ? [elseView] : []);
    }

    override public function measure(constraint:cui.layout.Constraint):cui.layout.Size {
        var active = condition.get() ? thenView : elseView;
        if (active != null) return active.measure(constraint);
        return new cui.layout.Size(0, 0);
    }

    override public function render(buffer:cui.render.Buffer, area:cui.layout.Rect):Void {
        var active = condition.get() ? thenView : elseView;
        if (active != null) active.render(buffer, area);
    }
}
#elseif (mui_backend == "qui")
class ConditionalView extends qui.ui.ConditionalView {
    public function new(condition:qui.state.State<Bool>, thenView:qui.View, ?elseView:qui.View) {
        super(condition, thenView, elseView);
    }
}
#elseif (mui_backend == "pui")
class ConditionalView extends pui.ui.ConditionalView {
    public function new(condition:pui.state.State<Bool>, thenView:pui.View, ?elseView:pui.View) {
        super(condition, thenView, elseView);
    }
}
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui|pui"
#end

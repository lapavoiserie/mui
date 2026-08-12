package mui.state;

#if (mui_backend == "sui")
typedef AnimationCurve = sui.state.AnimationCurve;
#elseif (mui_backend == "wui")
// AnimationCurve is defined in the StateAction module in wui
typedef AnimationCurve = wui.state.StateAction.AnimationCurve;
#elseif (mui_backend == "cui")
// TUI has no animation system -- enum is provided for API compatibility
enum AnimationCurve {
    Default;
    EaseIn;
    EaseOut;
    EaseInOut;
    Spring;
    Linear;
    Bouncy;
}
#elseif (mui_backend == "aui")
typedef AnimationCurve = aui.state.StateAction.AnimationCurve;
#elseif (mui_backend == "pui")
// pui draws its own animation, so the seven names are its own enum rather than
// a host's. Spring and Bouncy are closed-form approximations -- see
// `pui.anim.Curve`.
typedef AnimationCurve = pui.anim.Curve;
#else
#error "mui requires -D mui_backend=sui|wui|cui|aui|qui|pui"
#end

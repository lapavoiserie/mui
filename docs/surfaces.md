# Surfaces

An application is not one render root. It has a main window — and, depending on
the platform, a cover, a widget, a settings scene, a menu bar. mui calls each of
those an **app surface**, and lets an application declare them portably: the
declaration is shared, each backend maps it onto the surface its platform
actually has, and a role the backend being built has no host for is a
**compile error** — never a silence.

> **Status.** The vocabulary is implemented and checked, and hosts exist
> across the family — all validated on their platforms:
>
> | Role | Where it lives today |
> |---|---|
> | `Primary` | everywhere — it is `body()` |
> | `Glance` | Sailfish: the cover, live-mounted by `qui.mui.CoverHost`. Android: an App Widget, sampled — buttons in it run their closures. iOS: a WidgetKit widget, sampled through an App Group — its buttons run too, in the extension's own process |
> | `Preferences` | macOS: the Settings scene (⌘,), a second live root |
> | `Commands` | macOS: the menu bar (with derived shortcuts); terminal: key bindings; Windows: the MenuBar, injected as ordinary nodes |
> | `Auxiliary` | Windows (`wui`), macOS (`sui`, and `pui` since it learned to open a second `NSWindow`): real extra windows, one per declaration, on the one process and the one event loop |
> | `Companion` | another machine, or a paired watch, when the build asks for it (`-D mui_carry`) — see below |
> | `Notification` | not yet — waits for the detached subsystem |
>
> A role with no host on the backend being built stops that build, naming
> the role and the backend. Declaring stays portable — you accept the gap
> in your own source with `@:surface(Role, optional)` — but you are never
> told by an empty screen.

## Declaring a surface

Mark a method with `@:surface(Role)`. The method is the surface's content; the
method's *name* is the surface's stable id.

```haxe
class TodoApp extends mui.App {
	@:state var todos:ImmutableList<Todo> = ImmutableList.empty();

	override function body():View { … }          // Primary — implicit, required

	// The Sailfish cover, an iOS widget… "today" is the id.
	@:surface(Glance)
	function today():View {
		return ui(<VStack>
			<Text text="Todos" scale="title"/>
			<Text text={remaining() + " left"}/>
		</VStack>);
	}

	@:surface(Commands)
	function shortcuts():Array<Command> {
		return [new Command("New todo", focusNew).key("ctrl+n")];
	}
}
```

Declare as many surfaces of a role as the application wants — an iOS
application offers several widgets. Renaming a method is a compatibility event
(the id is identity); pin the id across a rename with
`@:surface(Glance, "today")`.

## Roles

| Role | Means | Examples |
|---|---|---|
| `Primary` | The main window. Implicit — it is `body()`. | everywhere |
| `Glance` | A read-at-a-glance summary. | Sailfish cover, iOS/Android widget |
| `Preferences` | The platform's settings surface. | macOS Settings scene |
| `Commands` | Named commands. | menu bar, key bindings |
| `Notification` | A system notification. *No declaration form yet.* | — |
| `Auxiliary` | Another top-level window. | desktop platforms |
| `Companion` | A companion device. *No backend maps it yet.* | — |

## What is checked, and where

- **A declaration is a view.** It runs inside its surface's own effect, so it
  reads under the same rule as `body()`: immutable or observable only, and no
  raw `rui.Signal` — `@:state` instead. Refused at compile time, naming the
  field.
- **Return types, per role.** A `Glance` method returns `View`; a `Commands`
  method returns `Array<mui.surface.Command>`. The typer refuses a mismatch at
  the method.
- **`@:surface(Primary)`** is refused: Primary is `body()`.
- **`@:surface(Notification)`** is refused until the detached-surface
  subsystem brings the contract it needs.
- **Duplicate role/id pairs** are refused, including against superclasses.

## Under the sugar

The framework consumes one thing: `surfaces():Array<SurfaceDecl>` — a list of
`Tree(role, id, () -> View)` and `CommandSet(id, () -> Array<Command>)`.
`@:surface` methods are collected into it by `mui.macros.Surfaces` (each
backend's `mui.App` carries the `@:autoBuild`). Declaring past the sugar is
overriding the list:

```haxe
override function surfaces():Array<SurfaceDecl> {
	return super.surfaces().concat([
		Tree(Auxiliary, "inspector", () -> inspectorWindow()),
	]);
}
```

`mui.Contract` requires `surfaces` of every backend, next to `lifetime`.

## Several windows, one process

A control room is two windows: the desk you press things on, and the wall of
monitors beside it. Both are this application, on this machine, showing this
state — and before anything was written down, the only way to get the second
one was `dui`: a second process, a serialiser, a socket and a receiving end,
for two windows six inches apart.

**The vocabulary already had the answer, and it is `Auxiliary`.** A second
window on the same machine is not a new concept next to `Glance`, `Companion`
and the rest; it is the role that says "another top-level window, where the
platform has windows", and `sui` and `wui` have hosted it since the surfaces
chantier. What was missing was a third host and this page.

So nothing new is declared:

```haxe
class Regie extends mui.App {
	@:state var takes:Int = 0;

	override function body():View {              // the desk
		return ui(<VStack>
			<Text text={"takes: " + takes}/>
			<Button label="New take" onClick={() -> takes += 1}/>
		</VStack>);
	}

	@:surface(Auxiliary)                          // the monitor wall
	function monitors():View {
		return ui(<VStack>
			<Text text={"takes: " + takes}/>
		</VStack>);
	}
}
```

Cardinality is `Many`: every declaration gets a window, in declaration order.
The id is the window's identity and, for want of anywhere else to put it, its
title — `monitors` opens a window called "Monitors". That is a degradation and
is named as one: the vocabulary has no place for a window title yet, and
inventing one that only two backends could honour is how a `case _:` gets
written.

### The same tree twice

A declaration is a method, so the second window may simply be the first:

```haxe
@:surface(Auxiliary)
function mirror():View return body();
```

Nothing special happens. Each window builds its own tree from the same thunk,
and gets its own everything below — which is the next section, and the only
part of this that is subtle.

### What is shared, and what is not

| | shared | why |
|---|---|---|
| `@:state` cells | **yes** | state is the application's. One application seen twice is the whole point, and it is what makes the second window worth having instead of a screenshot. |
| the view tree | no | each window builds its own from its own thunk. Two windows of the same thunk are two trees. |
| focus, and the caret | no | there is one focus ring per window. A field focused on the desk must not draw a ring on the wall. |
| hover, and the cursor | no | the pointer is over one window at a time. |
| an open drop-down | no | `pui.Overlay` is per host — and it was per *process* until a press in one window was answered by the other one's open list. |
| scroll offsets, press highlights, animation phases | no | all of it is the interaction store, and the store belongs to a pane of glass. |
| the clock | no | a window that is animating asks for frames; an idle one costs nothing. |
| `lifetime.keep` keys | **see below** | the one question with three answers in this family. |

### Where a `keep` lands, and the one hole

`rui.Lifetime.keep` is declared from inside a body and swept at the end of the
pass that stopped asking for it. With one window that is unambiguous. With two
it is a design decision, and the family has made it twice, differently:

- **`sui` brackets every root in one pass of the application's one lifetime**
  (`ViewNodeBridge.rebuild`: "the roots share the app's one Lifetime, so the
  pass opens once before the first root and closes once after the last"). A
  `keep` declared anywhere works. The cost is that every root rebuilds
  together.
- **`pui` does the same**, and it costs nothing there: a state write already
  marks a rebuild on *every* live host, because the sink has no host in hand
  and broadcasts — so the windows were going to rebuild together regardless.
- **`wui` gives each Auxiliary surface its own fresh `rui.Lifetime`**, which
  buys genuinely finer rebuilds: each surface reconciles on its own state and
  nobody else's, which is something the other two do not do.

The third answer has a hole, and it is **measured**, not deduced. A `keep`
written inside an `@:surface(Auxiliary)` body names `lifetime` — the
application's, because that is the only one an application can see — while the
application's lifetime is *between* passes. So the key is registered, and the
Primary's very next rebuild sweeps it:

```
after first render:        started=1 stopped=0 keeping=true
after a primary rebuild:   started=1 stopped=1 keeping=false
```

(`KeepProbe` against `wui.bridge.HaxeBridge` under `--interp`, 2026-09-29. The
same shape was reproduced in `pui` on purpose, by putting a lifetime back per
window, before the one-pass answer was settled: the wall's key started twice
and was swept once.)

It is a hole in one backend and not in the model, and the general fix is not a
backend's: `rui.Lifetime` has no notion of *which* surface a key was declared
by, and giving it one would let every backend keep per-surface rebuilds and
correct sweeping at once. Until then, **a `keep` in an Auxiliary body is
reliable on sui and pui and is swept on wui**, which is written here rather
than discovered by a subscription that starts and stops for ever.

### What a backend has to do

Very little, and none of it new:

1. **State that you host it.** `Auxiliary` in `@:hostedRoles` on your
   `mui.App`. A backend that cannot is not behind: it is telling the truth,
   and a declaration aimed at it stops that build by name.
2. **Ask `mui` for the declarations**, rather than walking `surfaces()`
   yourself: `mui.surface.SurfaceDeclTools.treesOf(surfaces(), Auxiliary)`
   gives them in declaration order. Three backends were each writing that walk
   with a `switch` whose `case _:` silently dropped what it did not know.
   `pickOne(decls, role, defaultId)` is the cardinality-One rule beside it —
   the role's default id if declared, else the first.
3. **Give each window its own interaction state.** Focus, hover, overlays,
   scroll offsets and the clock are per pane of glass. This is where the bugs
   are: `pui` had one overlay for the process, and a press in one window was
   tested against the other window's open drop-down.
4. **Do not give it a loop.** Every desktop system has one event queue per
   process, so the extra windows are pumped and painted by the loop that
   already exists. `pui.Platform.openWindow` hands back a whole platform whose
   `run` records its frame callback and returns — a shape the interface already
   allowed, because the browser needs it.
5. **Answer the closing of one window without ending the application.** One
   window going is not the process going; the loop's own window going is.

### Hosting is a property of the build, not only of the backend

`pui` is one library over seven surfaces, and AppKit puts N windows on one
process while iOS has exactly one pane of glass. So its `@:hostedRoles` is
written per build:

```haxe
#if (cpp && !pui_surface)
@:hostedRoles(Auxiliary, Companion)   // macOS
#else
@:hostedRoles(Companion)              // browser, iOS, Android, Qt, Direct2D
#end
```

That is the same rule one level down, not a way round it: which surface is
being built is as knowable at compile time as which backend is, so it is a
compile error and not a silence. Each refusal is written where the surface
lives — see `openWindow` in each of `pui`'s platforms, which says, per
platform, whether this is a port nobody has written (Qt, Direct2D) or an
answer that will not change (iOS, Android, the browser, where the second
surface is a scene, a widget or a blocked pop-up, and those are other roles).

### The three that do not host it, and what each would need

Stated rather than left blank, because "not listed" and "cannot" are different
facts and only one of them is worth waiting for.

| Backend | What a second window would be | What it would take |
|---|---|---|
| `cui` | a terminal has one screen | nothing to host. A second panel in a terminal is a layout an application already writes with the views it has; calling it a window would put a role somewhere the reader cannot find it. This is an answer, not a gap. |
| `aui` | another Activity, or a launcher widget | the Activity is the system's, started by an intent and owned by the back stack, and the widget is `Glance`, which `aui` already hosts. Neither is a window this process opens and keeps. |
| `qui` | SailfishOS gives an application one page stack | the cover is `Glance` and `qui` mounts it live. A floating second top-level surface is something the platform does not have. (`qui` is not checked out on the machine this was written on; this is read from `pui`'s own Qt/Sailfish surface, which refuses for the same reason — **deduced**, not measured.) |

### When it is still `dui`

`Auxiliary` is the same machine and the same process. The moment the second
surface is on another machine, another device or another process, it is
`Companion` and it is carried by `dui` — with the define, the explicit serve
call and the pairing. Nothing here weakens that: what it removes is paying for
a network to put a window beside another window.

## Following, rather than being told

A live surface needs nothing: it is an effect, and it reconciles when the state
it read changes. **A snapshot surface is the same, and used not to be.**

The system samples it when it decides — on a home screen, "when it bound the
widget, and then never again on its own" — so something has to say *now*. That
something is the surface's own effect: the declaration is evaluated inside one,
`rui` records every cell the thunk read, and a write to any of them re-samples
and republishes. You write no call:

```haxe
<Button label="−" onClick={() -> count -= 1}/>   // the widget follows
```

Every host answers that under a different name — Android pushes a fresh picture
into the widget's state, WidgetKit calls `reloadTimelines`, a self-drawn painter
repaints — and none of them is the application's business.

### Why there used to be a call, and why it is gone

`mui.surface.Resample.request(Glance)` was a macro an application called after
changing state. A snapshot surface has no host reactivity — there is no SwiftUI
and no Compose on our side of a widget's boundary to hand a value to — and
lacking a reactive host, the only thing left that could say *now* was the
developer.

That is a guarantee which depends on remembering, which is not a guarantee. The
`Counter` example proved it: `+` called `request`, `-` did not, and subtracting
left the widget showing a number nobody had. Nothing said so.

The framework knows when the content changed: it is what the thunk read. And
`rui.macros.ViewRule` already **refuses** a declaration that reads anything but
an immutable or an observable, so there was never anything a manual call could
serve that a cell does not.

`cafos` had been doing it this way for the Companion surface all along —
`NuiProjector` samples inside an effect and re-projects on a write. Glance was
the one snapshot corner still asking to be reminded.

The register outlived the macro by a few days. `Resample.impl` was meant to
stay — the backend's own sampler, called by the effect instead of by the
application — but once each follower took a callback saying what to do with
its picture, nothing ever called it: three backends signed a hook with no
caller, and one of them signed an empty one to silence a warning that could
no longer fire. A per-surface callback is better typed than a register keyed
by role and id, so the module is gone as well.

### What still needs saying out loud

A surface whose content depends on something no cell can see — a clock ticking
on its own, a file changed underneath you — has nothing to follow. Give it a
cell: an `@:state` the timer writes is observable, and the surface follows it
like anything else. That is the discipline `ViewRule` already imposes on every
view, applied to the one corner that had an exemption.

### Naming one surface among several

A role can be declared more than once — several widgets, several covers — and
each follows its own state independently: a write to a cell only `today()`
reads re-samples `today` and nothing else. That falls out of the mechanism
rather than being arranged: one follower per declaration, one effect per
follower, and `rui` subscribes each effect to exactly the cells its own thunk
read.

### Implementing it, as a backend

Follow each snapshot declaration you host, and say what to do with the picture:

```haxe
class App extends yourbackend.App {
    public function new() {
        super();
        mui.surface.Describe.impl = v -> yourbackend.nui.Describe.describe(v);
    }

    // ...once the instance is whole — never in the constructor, where the
    // subclass has not initialised its @:state fields and the thunk would
    // read a null cell:
    function startFollowing() {
        var decl = pickGlance(surfaces());
        if (decl != null)
            follower = mui.surface.Follow.surface(decl, json -> yourHost.show(json));
    }
}
```

`Follow.surface` returns a `Follower` — `sampleNow()` for a host that pulls,
`invoke(id, arg)` for a tap coming back, `dispose()` to stop. The effect, the
action table, and the question of whether the first run publishes are decided
inside it, once for every backend; see [nui's snapshot
contract](https://lapavoiserie.github.io/nui/#/snapshot) for what those three answers are.

The callback is the whole of a backend's freedom here, and the three that
exist use it differently: `aui` throws the JSON away and nudges its host to
pull for itself, because Android's widget asks rather than being handed;
`cafos` wraps it in a generation number and sends it over a socket; `sui`
writes it into the App Group container a separate binary reads.

Two shapes are worth copying rather than inventing:

- **A snapshot host answers by sampling and delivering.** `aui` reaches a
  Kotlin object in a *fixed* package (`aui.glance.GlanceHost`) because Haxe
  must be able to name it, while the code that knows how to push the picture
  is generated into the application's own package — it names the app class
  and the widget class, which vary — and registers itself with that object
  when the process boots. Every entry point that can start the process
  registers, since any of them may be the one that did.
- **A live host follows nothing, on purpose**, and says so in a comment.
  `qui` mounts the Sailfish cover as an effect over the signal graph: the
  picture was never stale, so there is no snapshot to keep current. That is a
  difference of kind, not a hole — and the only one who can tell those apart
  is the backend.

## What a detached surface reaches

A snapshot surface is a picture, and for a long time that was the whole of it:
the host kept the tree of text, the application kept the state, and the two
only met when the application took a new sample. A surface sampled by a
process that had just started — the launcher waking us for a tap, an extension
that never ran before — sampled an application at its *initial* state and drew
a number nobody had ever seen.

A cell declared `@:state(durable)` closes that. Its value lives in a
device-local store, a file with one line per key, that the application and its
own detached surfaces both open, so the fresh process reads what the
application last wrote instead of the default in the source. The picture
already outlived the process that drew it; now the value in it does too.

On iOS it is also what makes the tap work. A WidgetKit tap runs in the
extension's process, where the application's closures do not exist, so the
extension boots its own instance of the application and invokes the action
there — and durable cells are what let that instance agree with the
application about what the count is. Everything *not* declared durable is at
its initial value in that instance: a draft that never existed anywhere. A
closure that reads three cells and writes one is wrong there with nothing on
screen to say so, which is the reason to keep a `Glance` closure to what it
can honestly reach.

Nothing about this crosses a machine. The store is per device; what may be
durable, where it lives per platform, and what happens when two processes
write the same key at once are on [Durable state](state/durable.md).

## Companion: a surface on another machine

**Off unless the build asks.** A Companion leaves this device — to a machine
merely met on a network, or to a paired watch — and nothing about writing an
application implies wanting either, so the off-device corner is opt-in:
without `-D mui_carry` the declaration below does not compile, and the refusal
says what to add. Turning it on is one line in the build file, where it is
reviewable.

**Three deliberate acts, none of them a default.** The define, then the
explicit `dui.mui.CompanionServe.serve` call, and then a **pairing**: even
served, a surface goes only where somebody named. See
[dui](https://github.com/lapavoiserie/dui).

*(`-D mui_cafos` still works and means the same thing. It was the spelling when
CAFOS was the only way a surface could leave; the concept was renamed, not the
switch.)*

A `@:surface(Companion)` declaration is not rendered by this process at all:
it is *carried* — by `dui`, over whichever transport the application chose —
onto the target somebody paired, and rendered there by that machine's own
renderer. The remote taps come back as action ids and run your closures; ids
are stable by place, so a tap racing a re-render does what the unchanged
button says.

```hxml
# in the build file — the switch, once
-D mui_carry
```

```haxe
@:surface(Companion)
function panel():View {
	return ui(<VStack>
		<Text text={"count: " + count}/>
		<Button label="Add" onClick={() -> count += 10}/>
	</VStack>);
}

// once, after construction (the app opts into the transport):
var projector = cafos.mui.CompanionServe.serve(app);
app.lifetime.own(() -> projector.stop());
```

Reading state inside the method keeps the remote surface live — the same rule
as every other surface. The machinery underneath: the backend's **describer**
(`mui.surface.Describe`, installed by each backend's `mui.App`) turns views
into canonical `nui.Node`s; `nui.Snapshot` ships them as pure data with
closures replaced by table ids; the far side inflates and renders with any
backend's `NodeRenderer`. See nui's *Snapshot* page and cafos's *nui-wire*
page for the contracts.

## The describer

Serving detached surfaces (Companion today, widget snapshots in P4a) needs
the backend's views as `nui.Node` data. Each backend installs its describer
on `mui.surface.Describe.impl` at `mui.App` construction, emitting the
**canonical prop names** (`text`, `label`/`onClick`, `isOn`/`onToggle`,
`value`/`min`/`max`/`onValue`, `text`/`placeholder`/`onText`) so a tree
served from any backend looks the same on the wire. A backend without a
describer degrades with a word: the declaration never projects.

## Degradation, and who declares it

The house rule first: **what is knowable at compile time is a compile error,
never a silence.** Which roles a backend hosts is knowable — each backend
states them as `@:hostedRoles` on its `mui.App`, where
`mui.macros.Surfaces` reads them — so a terminal build that meets a `Glance`
declaration stops, naming both:

```
Counter.hx:16: cui hosts no Glance: surface "glance" would fly nowhere here
  (it hosts Commands, Companion). Accept that with @:surface(Glance, optional),
  or build for a backend that hosts it.
```

An application built for several platforms says so once, in its own source:

```haxe
@:surface(Glance, optional)      // the Sailfish cover; nothing on the others,
function today():View { … }      // and this app accepts that
```

That is what "degradation is declared, not accidental" has to mean to be
worth anything: declared by the application, for this build, where the next
reader sees it — not asserted in a doc comment while a `case _:` drops it on
the floor.

| | today |
|---|---|
| `Primary` | every backend |
| `Glance` | qui, aui, sui (iOS) |
| `Preferences` | sui |
| `Commands` | sui, wui, cui |
| `Auxiliary` | sui, wui, pui (macOS builds only — see below) |
| `Companion` | every backend that installs a describer — all but qui — **and only when the build sets `-D mui_cafos`** |

Cardinality is still the host's answer: when a platform mounts only one
surface of a role (the Sailfish cover) and several are declared, the host
takes the role's default id (`"glance"`) if declared, else the first. Roles
with `Many` cardinality (auxiliary windows, companions) mount every
declaration, in declaration order.

`mui.surface.SurfaceHost.capabilities()` describes a host's shape at
runtime; it is not what the check reads, and nothing consumes it yet.

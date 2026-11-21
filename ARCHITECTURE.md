# Architecture map

Package version: **0.0.1**.

The package is split in layers (Clean Architecture) and the screens follow MVVM.
**Rule: a layer only knows the layers inside it.**

```
Dart                                              Native (C++ / Win32)
----                                              --------------------
presentation  (views + view models)               presentation   (method-channel adapter)
      |                                                 |
   domain     (entities, contracts, use cases)    application   (use cases)
      |                                                 |
    data      (channel, mappers, repository)        domain        (models, contracts)
                                                        ^
composition   (wires everything, Dart)            infrastructure (Win32)
                                                  composition    (window_frame_plugin.cpp)
```

MVVM, in Dart: **View** = widgets (`WindowTitleBar`, `WindowCaptionButtons`,
`WindowFrameScope`, `WindowDragArea`), **ViewModel** = `WindowFrameViewModel`,
`TitleBarViewModel`, `WindowMenuViewModel`, `WindowMenuSession`, `DoubleClickDetector`,
`TitleBarController`, **Model** = the domain entities and the presentation models
(`TitleBarContent`, `WindowMenu`).

**The rule for the views:** a view only translates what the framework gives it (pointer
events, hit tests, render boxes) into plain values, asks a view model what to do, and does
it (pop a route, start a drag, replay a click). The decisions themselves (is this a
double-click? is this release a drag from the icon? what happens after the menu closes?) live
in view models that import no widget: `view_models/` only knows `dart:ui` types (`Offset`,
`Rect`), `VoidCallback` and the pointer constants (`kPrimaryButton`...). The standard menu
entries are the one thing that needs widgets (their icons), so they are built by the view
(`widgets/title_bar/window_menu_entries.dart`), from the state and commands the view model
exposes.

## How the files are grouped

One file holds **one concept group**: classes that change together and are small
(for example the nine one-line use cases, or the six window-message handlers). A class
that is public, or grows past a few hundred lines, gets its own file. The layers
are folders, so the dependency rule is still visible in the paths.

Dart: 34 files in `lib/`. C++: 18 files in `windows/src/` (+ the plugin entry files).

```
lib/
  window_frame.dart                         what apps can import
  src/
    domain/
      entities/window_entities.dart         WindowEvent, WindowFrameOptions, WindowInitializationResult
      repositories/window_platform_repository.dart   the contract the app needs from the window
      use_cases/window_use_cases.dart       the nine use cases (one small class each)
    data/
      constants/window_channel_contract.dart  names shared with C++ (twin of channel_contract.h)
      datasources/window_method_channel_data_source.dart   the only MethodChannel user
      mappers/window_channel_mappers.dart   options -> native, native -> events/results
      repositories/window_platform_repositories.dart   Windows + no-op repositories, retry policy
    composition/window_frame_composition_root.dart   the one place that wires the layers
    presentation/
      facade/window_frame.dart              the public WindowFrame.xxx() calls
      models/title_bar_content.dart         what a title bar shows (all fields optional)
      models/window_menu.dart               WindowMenu, WindowMenuItem (activator), WindowMenuDivider
      models/shortcut_label.dart            the hint text made from an activator (Ctrl+,)
      resolvers/title_bar_appearance_resolver.dart   active / inactive colors
      view_models/title_bar_controller.dart          the "remote control" of the bar (public)
      view_models/title_bar_view_model.dart          registry (which page wins) + merging
      view_models/window_frame_view_model.dart       window state + commands for the views
      view_models/window_menu_view_model.dart        regions of the bar, window state/commands for menus, creates sessions
      view_models/window_menu_session.dart           the decisions of ONE open menu (press, move, release, after close)
      view_models/double_click_detector.dart         counts a double-click from two clicks
      coordinators/window_close_coordinator.dart     onCloseRequested
      widgets/scope/window_frame_scope.dart          the widget apps add in MaterialApp.builder
      widgets/scope/window_frame_scope_shell.dart    the page inside the scope's Navigator
      widgets/scope/window_frame_services.dart       shares the view models with the widgets
      widgets/title_bar/window_title_bar.dart        the bar layout
      widgets/title_bar/window_drag_area.dart        drag, double-click, right-click, WindowNoDragArea
      widgets/title_bar/window_menu_presenter.dart   shows a window menu (route, surface, keyboard); the icon trigger
      widgets/title_bar/window_menu_entries.dart     the standard entries with their glyph icons
      widgets/title_bar/window_menu_shortcuts.dart   runs the entry whose activator was pressed (above the Navigator)
      widgets/title_bar/pointer_replay.dart          replayLeftClick: sends a click again after a menu swallowed it
      widgets/title_bar/title_bar_controller_binding.dart   a page selects its bar
      widgets/caption_buttons/window_caption_buttons.dart   the three buttons + style + colors
      widgets/caption_buttons/window_caption_button.dart    one button (hover / pressed)
      widgets/caption_buttons/window_caption_glyph_painter.dart   the drawn glyphs

windows/
  window_frame_plugin.h / .cpp              composition root (creates and connects everything)
  window_frame_plugin_c_api.cpp             Flutter's entry point
  src/
    common/disallow_copy_and_assign.h
    domain/window_models.h                  WindowOptions, WindowSession, WindowStatus
    domain/window_ports.h                   WindowGateway + WindowEventPublisher (contracts)
    application/window_use_cases.h / .cpp   Initialize, SetMinimumSize, Commands, Synchronize, StartMaximized
    infrastructure/win32/win32_window_gateway.*       the Win32 implementation of the gateway
    infrastructure/win32/win32_frame.*                frame sizes + the top-edge hit-test subclass
    infrastructure/win32/win32_message_pipeline.*     message, handler interface, dispatcher
    infrastructure/win32/win32_message_handlers.*     the six message handlers
    presentation/channel_contract.h         names shared with Dart (twin of the Dart contract)
    presentation/channel_codec.*            read Dart's arguments, encode the answers
    presentation/window_channel.*           events to Dart + calls from Dart
```

## Which file do I open to change X?

Open only the file(s) of the row.

| I want to change... | Open |
|---|---|
| What the title bar can show (a new slot, a new color option) | `presentation/models/title_bar_content.dart` + `widgets/title_bar/window_title_bar.dart` |
| The layout of the title bar | `widgets/title_bar/window_title_bar.dart` |
| The look of the inactive (unfocused) window | `presentation/resolvers/title_bar_appearance_resolver.dart` |
| Dragging, right-click, what counts as "interactive" (the hit test) | `widgets/title_bar/window_drag_area.dart` |
| How the window menu looks, its animation, where it opens, right-click-elsewhere, double-click-to-close | `widgets/title_bar/window_menu_presenter.dart` |
| What the window menu contains (the standard entries, their icons) | `widgets/title_bar/window_menu_entries.dart` (state and commands: `view_models/window_menu_view_model.dart`) |
| What a press, move or release means while a menu is open (close, hand over, drag, run an entry, reopen) | `view_models/window_menu_session.dart` (+ its test) |
| What counts as a double-click | `view_models/double_click_detector.dart` (+ its test) |
| Keyboard shortcut of a menu entry (`activator`): the field, the hint text, the key handler, which entries are collected | `models/window_menu.dart`, `models/shortcut_label.dart`, `widgets/title_bar/window_menu_shortcuts.dart`, `widgets/scope/window_frame_scope.dart` (`_collectShortcutEntries`, `_areShortcutsBlocked`) |
| A click that must reach a widget after a menu closed | `widgets/title_bar/pointer_replay.dart`, `window_menu_presenter.dart` (end of `showWindowMenu`), `window_drag_area.dart` (`noteDismissingClick`) |
| The menu types an app can use | `presentation/models/window_menu.dart` |
| The caption button glyphs | `widgets/caption_buttons/window_caption_glyph_painter.dart` |
| Caption button style options / colors | `widgets/caption_buttons/window_caption_buttons.dart` |
| One caption button (hover / pressed behavior) | `widgets/caption_buttons/window_caption_button.dart` |
| How a page selects its title bar | `widgets/title_bar/title_bar_controller_binding.dart` |
| Which page's title bar wins / how bars are merged | `view_models/title_bar_view_model.dart` |
| What a controller can do (`update`, `setTitle`...) | `view_models/title_bar_controller.dart` |
| The window state shown to the views | `view_models/window_frame_view_model.dart` |
| The application name | Dart: `window_frame_view_model.dart`, `facade/window_frame.dart`, `window_title_bar.dart` (`_buildTitle`). Native: `win32_window_gateway.cpp` (`ApplicationTitle`) |
| The close handler (`onCloseRequested`) | `presentation/coordinators/window_close_coordinator.dart` |
| The root Navigator / page layout of the scope | `widgets/scope/window_frame_scope.dart`, `window_frame_scope_shell.dart` |
| The public `WindowFrame.xxx()` calls | `presentation/facade/window_frame.dart` |
| What is exported to apps | `lib/window_frame.dart` |
| A new window command (Dart side) | `domain/repositories/window_platform_repository.dart`, `domain/use_cases/window_use_cases.dart`, `data/repositories/window_platform_repositories.dart`, `data/constants/window_channel_contract.dart`, the view model, the facade |
| Names shared with the native side | `data/constants/window_channel_contract.dart` **and** `windows/src/presentation/channel_contract.h` (twins) |
| Retry / timeout when starting | `data/repositories/window_platform_repositories.dart` (`NativeInitializationRetryPolicy`) |
| Startup options (Dart) | `domain/entities/window_entities.dart`, `data/mappers/window_channel_mappers.dart` |
| Native: the frame (title bar removal) | `win32_message_handlers.cpp` (`NonClientAreaHandler`), `win32_window_gateway.cpp` (`ApplyCustomFrame`) |
| Native: resize from the top edge | `win32_message_handlers.cpp` (`ResizeHitTestHandler`), `win32_frame.cpp` |
| Native: minimum size | `win32_message_handlers.cpp` (`MinimumSizeHandler`) |
| Native: focus (active/inactive) detection | `win32_message_handlers.cpp` (`ActivationChangeHandler`) |
| Native: start maximized | `win32_message_handlers.cpp` (`StartMaximizedHandler`), `application/window_use_cases.cpp` (`StartMaximizedPolicy`) |
| Native: a new window command | `domain/window_ports.h`, `win32_window_gateway.*`, `application/window_use_cases.*`, `presentation/window_channel.cpp`, `presentation/channel_contract.h` |
| Native: a new Windows message | a new handler in `win32_message_handlers.*` + `window_frame_plugin.cpp` (`RegisterMessageHandlers`) |
| Native: a new event for Dart | `domain/window_ports.h`, `presentation/window_channel.*`, `application/window_use_cases.*` (`SynchronizeWindowStateUseCase`), `presentation/channel_contract.h` |

All native paths above are relative to `windows/src/infrastructure/win32/` (for the
`win32_*` files) or `windows/src/` (for the others). A new `.cpp` file must also be added
to `windows/CMakeLists.txt`.

## Flow of one action (the user clicks "minimize")

1. `WindowCaptionButton` (view) calls `WindowFrameViewModel.minimize()`.
2. The view model runs `MinimizeWindowUseCase`.
3. The use case calls `WindowPlatformRepository.minimize()` (a contract).
4. `WindowPlatformRepositoryImpl` sends `minimizeWindow` through the data source.
5. Native `WindowChannelController` receives it, calls `WindowCommandsUseCase::Minimize()`.
6. The use case calls `WindowGateway::Minimize()` (a contract).
7. `Win32WindowGateway` calls `ShowWindow(..., SW_MINIMIZE)`.

## Flow of one event (the window loses the focus)

1. Windows sends `WM_ACTIVATE`; `ActivationChangeHandler` sees it.
2. `SynchronizeWindowStateUseCase` publishes the change (only if it changed).
3. `ChannelEventPublisher` sends `onActivationStateChanged` to Dart.
4. `WindowEventMapper` turns it into an `ActivationStateChangedEvent`.
5. `WindowFrameViewModel.isWindowActive` changes; the title bar and the caption buttons
   repaint with the inactive look.

## Flow of a click on the bar (double-click, right-click, icon menu)

`WindowDragArea` reads the mouse in two ways, each for what it does best:

1. **A raw `Listener`** sees every press at once. It runs a hit test at that position and
   asks what is under the pointer (`_inspectTargetAt`). The walk goes from the deepest widget
   up and **stops at the boundary** (`_RenderDragAreaContent`) that wraps the child, so only
   the app's widgets count, not the drag area's own gesture detector or the Navigator's
   listener. A widget is a **control** when the path holds a `RenderPointerListener` with
   `onPointerDown` (every `GestureDetector`, `InkWell`, button and text field has one), a
   `RenderSemanticsGestureHandler` with `onTap`, a `RenderMouseRegion` with a special cursor,
   or a `WindowNoDragArea`.
2. **`onTapUp` through the gesture arena.** The arena gives the tap to the deepest
   recognizer, so a button or a tab wins its own tap without any heuristic. The
   double-click is counted by hand (`DoubleClickDetector`) from two such taps within 300 ms and 8 px.

Then:
- Empty space + double-click -> `toggleMaximize()`.
- Empty space + right click -> `onContextMenuRequested` -> `showWindowMenu(barMenu)`.
- Empty space + drag -> `startDrag()`. A control under the pointer: nothing.
- Clicking the leading widget is a tap on `WindowMenuTrigger` (left or right button) ->
  `showWindowMenu(leadingMenu)`.

`showWindowMenu` builds the entries (`buildWindowMenuEntries`: the standard entries from the window
state of `WindowMenuViewModel`, passed through the app's `itemsBuilder`), asks the view model for a
`WindowMenuSession` and pushes `_WindowMenuRoute`: a `PopupRoute`
with a 90 ms fade, positioned by a layout delegate that keeps it inside the window. While it
is open, a **global pointer route** watches the mouse (the barrier swallows the clicks). The route
only feeds every press, move and release to the session and does what it answers
(`MenuPressOutcome`, `MenuReleaseOutcome`, `MenuClosedOutcome`); the rules below are the
session's:
- a right-click elsewhere is remembered; when the menu closes, `WindowMenuViewModel.openMenuAt`
  asks the registered `WindowMenuRegion`s (the leading trigger, then the bar) which one owns
  that point, and its menu opens: one click replaces the old menu with the new one;
- a second left-click on the leading icon, within 300 ms, closes the window; with the menu
  already open, the first click is remembered by the icon (`noteDismissingClick`) and the
  second closes the window instead of reopening the menu;
- a left-click that closed the menu is also handed to the bar (`noteDismissingClick`), so it
  counts as the first click of a double-click (maximize / restore) when it was on an empty
  part of the bar;
- **a left-click on a widget while a menu is open reaches the widget.** The barrier swallowed
  the press, so once the menu is completely gone (`route.completed` + the end of the frame)
  the click is sent again with `replayLeftClick` (`pointer_replay.dart`): a `PointerDownEvent` +
  `PointerUpEvent` of the same mouse, with a fresh pointer id, through
  `GestureBinding.handlePointerEvent`, so the normal hit test finds the button, the tab or the
  text field (which takes the focus). Who replays it: the drag area, when the point is on one of
  its controls (`_inspectTargetAt` says it is interactive); `showWindowMenu`, when the point is
  outside every region (`WindowMenuViewModel.isInsideRegion`: the action buttons, the caption
  buttons, the page below the bar). An empty part of the bar is never replayed: there the click
  is the first click of a double-click, and replaying it would maximize the window;
- pressing the empty bar and moving more than 6 px closes the menu and calls `startDrag()`
  (`canDragWindowAt` says which region is a drag handle: the bar yes, the icon no);
- the left button opens the icon menu on the PRESS (`openedByPress`, from a `Listener`), and
  the release of the button runs the entry under the mouse (`_WindowMenuRoute.itemAt`), keeps
  the menu open over the icon or the menu, and closes it anywhere else. It must be the press:
  `Navigator.push` calls `_cancelActivePointers()`, and Flutter drops the rest of a cancelled
  pointer's events (no moves, no release). From the press handler (deeper than the Navigator's
  own `Listener`) the pointer is not yet in the Navigator's list, so nothing is cancelled;
- a press on the icon while another menu is open is handed over: the route page has a
  translucent `Listener` over the whole window that sees the press BEFORE the barrier and the
  Navigator (so the new menu can be pushed without cancelling the pointer); it asks
  `WindowMenuViewModel.openMenuOnPress`, and the icon's region closes the open menu and opens
  its own. The icon of the menu that is open is left alone: a second click just closes it;
- the menu closes when `isWindowActive` or `isMaximized` changes.
- keyboard: `_WindowMenuSurfaceState` owns the focus. It keeps ONE highlighted index (the
  mouse sets it through `InkWell.onHover`, the arrow keys move it), runs the highlighted
  entry on `Enter` / `Space`, and finds an entry by mnemonic (`_mnemonicOf`). Escape is left to
  the route (`CallbackShortcuts`).
The chosen entry's `onPressed` runs after the menu closes.

## Flow of a keyboard shortcut of a menu entry (the user presses Ctrl+,)

1. `WindowFrameScope` wraps its Navigator in `WindowMenuShortcuts`: a `Focus` with
   `canRequestFocus: false` that only listens. It sits ABOVE the Navigator on purpose: the focus
   tree follows the widget tree, so a key pressed anywhere (a page, a dialog, a text field)
   bubbles up to it after the focused widget had its chance. A text field keeps `Ctrl+C`.
2. A key-down (or repeat) arrives. Cheap exits first: a pure modifier key; a key that types a
   character without Ctrl/Alt/Win (so ordinary typing never builds any entry).
3. `isBlocked` (`_areShortcutsBlocked` in the scope): a window menu is open
   (`WindowMenuViewModel.isMenuOpen`, counted by `showWindowMenu`), or the window page is not
   the current route (a dialog covers it).
4. `entriesProvider` (`_collectShortcutEntries`): the resolved bar's `leadingMenu` and
   `barMenu`; for each one that is enabled and has an `itemsBuilder`, the entries are built
   right now (`buildWindowMenuEntries`) with a context inside the Navigator. Nothing is cached,
   so `isEnabled` and `onPressed` are the current ones.
5. The first enabled `WindowMenuItem` whose `activator.accepts(event, keyboard)` runs its
   `onPressed` (once: repeats of a held key are swallowed) and the key is marked handled.

The hint text in the menu comes from `WindowMenuItem.shortcutLabel`: the `shortcut` string when
given, otherwise `describeShortcutActivator(activator)`.

## Adding a value to the "initialize" answer (example: the application name)

Native, from the inside out:
1. `windows/src/domain/window_models.h`: a new field in `WindowStatus`.
2. `windows/src/domain/window_ports.h`: a new question on `WindowGateway` (only if the value
   comes from the OS window).
3. `infrastructure/win32/win32_window_gateway.*`: the Win32 implementation.
4. `application/window_use_cases.cpp`: fill the field (`InitializeWindowUseCase`).
5. `presentation/channel_contract.h` + `channel_codec.cpp`: a new key, and put the field in
   the answer.

Dart, from the outside in:
1. `data/constants/window_channel_contract.dart`: the same key (twin).
2. `data/mappers/window_channel_mappers.dart`: read it (with a fallback).
3. `domain/entities/window_entities.dart`: a new field (and its value in `.unavailable()`).
4. `presentation/view_models/window_frame_view_model.dart`: keep it.
5. `presentation/facade/window_frame.dart`: expose it. Update README + CHANGELOG.

## Design decisions (why it is built this way)

| Decision | Reason |
|---|---|
| The scope hosts the app in its **own root `Navigator`** | Widgets in the bar need a `Navigator` and an `Overlay` above them (`showDialog`, `Tooltip`, `PopupMenuButton`, the window menus). Without it they throw. |
| Title bar slots are **builders** (`WidgetBuilder`) | The default controller is created before `MaterialApp` exists. A builder receives a context inside the Navigator when the bar is drawn, so a closure like `onPressed: () => showDialog(context: context, ...)` uses the right context. |
| A controller holds **nullable** fields that **merge** over the default | A page only says what differs; the rest is inherited. `[]` for actions, `''` for the title and `WindowMenu.disabled()` for a menu are the explicit "remove" values. |
| The double-click is counted from two **`onTapUp`** events, not from `onDoubleTap` | A `DoubleTapGestureRecognizer` on the drag area holds the gesture arena: it delays every tap inside the bar by about 300 ms and wins over the buttons and tabs. A plain tap recognizer holds nothing, and the arena gives the tap to the deepest recognizer, so a control wins its own tap and the drag area never sees it. |
| "Is this a control?" is answered by a **hit test that stops at a boundary** | Dragging cannot use the arena (a pan always beats a tap), so a hit test finds what is under the pointer. The walk stops at the boundary around the drag area's child: the Navigator above has a pointer listener too and would make everything look like a control. Widgets that only draw (a progress bar) count as empty space; `WindowNoDragArea` opts them out. |
| Window menus are **Flutter menus**, not the native system menu | Fully customizable (entries, icons, language, theme) and no extra native code. The standard entries call the same commands as the caption buttons. |
| The window menu is **its own `PopupRoute`**, not `showMenu` | `showMenu` animates for about 300 ms, and its barrier swallows a right-click, so the new menu needed a second click. The own route fades in 90 ms, exposes its bounds, and lets the presenter watch the mouse while it is open. |
| `onCloseRequested` uses **`AppLifecycleListener.onExitRequested`** | Flutter's Windows embedder routes the close of the last window through it, so one hook covers the close button, Alt+F4 and the taskbar. |
| The app below the bar is wrapped in **`ClipRect`** | Nothing in the app, not even a page transition, may paint over the bar. |
| The frame is **not** extended into the client area (`DwmExtendFrameIntoClientArea` with zero margins) | A one-pixel extension made the window border look thicker (checked on a real machine). |
| The session flags are set **before** `ApplyCustomFrame()` | Removing the title bar makes Windows send messages immediately, and the handlers must already be active to answer them. |
| `applicationTitle` is read from the **native window title** | `pubspec.yaml` is not shipped inside a built app, so Dart cannot read the project name at run time. `flutter create` writes it as the window title in `main.cpp`, which is compiled code and works in release builds. |
| Dart and C++ **share names through two twin files** | One agreed list of channel, method and key names; change both files together. |
| **Dependency rule**: a layer only knows the layers inside it | Keeps the Win32 code replaceable (a new platform) and the widgets free of channels. |
| **Grouped files** | Small related classes live together so a change touches few files; the layers stay visible as folders. |
| Mouse decisions live in **view models**, not in the views | A view that holds the state of a press / drag / double-click cannot be tested without a window. `WindowMenuSession` and `DoubleClickDetector` are plain Dart with an injectable clock, so `test/` covers them; the views only translate events and act. |
| A swallowed click is **replayed**, not let through | The menu's barrier must stay: it closes the menu and keeps the app from reacting to a click meant only to close it. Replaying one full click after the menu is gone gives the widget a normal press (focus, tap) and keeps the double-click logic of the bar intact. |
| Shortcuts belong to the **menu entries** (`WindowMenuItem.activator`), not to `WindowFrameOptions` | `WindowFrameOptions` are native start-up settings, given before `runApp`: they cannot hold callbacks that need a `BuildContext` (opening a dialog) and cannot change at run time. The entry already owns the label and the action, so it owns the keys too, and the shown hint and the behavior cannot disagree (like Flutter's `MenuBar`). A general shortcut registry is app logic: Flutter's `Shortcuts` / `Actions` already do it. |
| The shortcut handler asks for the entries **when a key is pressed** | `itemsBuilder` runs only when a menu opens, and an entry's `isEnabled` / `onPressed` depend on the app's state. Asking at key time keeps them current with no listener or cache to invalidate; typing stays cheap because characters without Ctrl/Alt/Win never reach the builder. |

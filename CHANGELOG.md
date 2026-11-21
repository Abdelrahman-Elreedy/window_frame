## 0.0.1

First release. Windows desktop only.

**Title bar**
- Replace the grey Windows title bar with your own Flutter widgets:
  `[leading] [title] [content] [actions] [caption buttons]`. Every slot is a builder, so
  it gets a context inside the window's Navigator (`showDialog`, `Tooltip` and
  `PopupMenuButton` work in the bar).
- Controller-based bar: `TitleBarController` (the default one goes to `WindowFrameScope`,
  other ones per page with `page.withTitleBarController(...)`). Every field of
  `TitleBarContent` is optional and inherited from the default; `reset()` goes back to
  inheriting everything.
- `TitleBarContent`: `title`, `titleBuilder`, `titleStyle`, `padding`, `spacing`, colors,
  `isDraggable`, `doubleClickMaximizes`, `leadingMenu`, `barMenu`. The height of the bar is
  `WindowFrameScope(titleBarHeight: ...)`.
- Application name: `WindowFrame.applicationTitle` is the project name from `pubspec.yaml`
  (read from the title the native runner gives to the window, so it works in release
  builds, non-Latin names included). A bar with no `title` shows it; `''` hides the title.
- Inactive window look: the bar and the caption buttons fade when the window loses the
  focus (`inactiveBackgroundColor`, `inactiveForegroundColor`, `dimWhenInactive`,
  `appearanceTransitionDuration`, `inactiveIconColor`); `WindowFrame.isWindowActive`.
- Right-to-left friendly: the app's widgets keep the app's direction, the caption buttons
  stay on the right.

**Caption buttons**
- Drawn with `CustomPaint`; the glyphs are public and reusable (`WindowCaptionGlyphIcon`,
  `WindowCaptionGlyph`, `WindowCaptionGlyphPainter`).
- Custom colors, custom glyphs, a whole custom set built from `WindowCaptionButton`, and
  `WindowCaptionButtons(showMinimize:, showMaximize:, showClose:)` to hide single buttons.

**Window frame**
- `WindowFrame.init(WindowFrameOptions(...))`: `minimumSize` (takes effect at once),
  `startMaximized`, `customFrame`, and `frameBorderWidth` (default `0`: how many pixels of
  the native frame are extended into the app area on every side).
- Native resize borders, Aero Snap, the window shadow and the minimize / maximize
  animations stay the real Windows behavior.
- Window commands: `WindowFrame.minimize`, `maximize`, `restore`, `toggleMaximize`, `close`,
  `startDrag`, `setMinimumSize`; state: `isMaximized`, `isWindowActive`, `frameActive`,
  `isSupported`.
- `onCloseRequested` runs for every way of closing (the close button, Alt+F4, the taskbar).
- On other platforms the calls do nothing and the app runs normally.

**Mouse behavior of the bar**
- Dragging an empty part (or a text) moves the window; a double-click on it maximizes /
  restores. Buttons, tabs, text fields and every widget that listens to the mouse are left
  alone: they never move or maximize the window and are not delayed.
- A widget that only draws something (a progress bar, an image) counts as empty space; wrap
  it in `WindowNoDragArea` to keep it out. `WindowDragArea` makes a drag area in your own
  page.

**Window menus**
- Click the leading widget (left or right button) or right-click an empty part of the bar:
  the standard Restore / Minimize / Maximize / Close menu opens. Customize it with
  `WindowMenu(itemsBuilder: ...)` (`WindowMenuItem`, `WindowMenuDivider`, `icon`,
  `iconBuilder`, `shortcut`, `mnemonic`, `isEnabled`) or turn it off with
  `WindowMenu.disabled()`.
- Double-click on the icon closes the window (`WindowMenu.closeOnDoubleClick`).
- Keyboard shortcuts for entries: `WindowMenuItem.activator` (any `SingleActivator`, e.g.
  `Ctrl+,`) makes the keys run the entry from anywhere in the app, with the menu closed, and
  the hint shown at the right of the entry is made from it. `WindowMenuItem.shortcut` stays a
  plain hint text (display only, binds nothing) and wins over the generated text. Entries are
  asked for at the moment of the key press; the focused widget gets the key first; nothing
  runs while a menu is open or a dialog covers the window; plain characters are ignored.
- Behaves like a native menu: it opens on the PRESS of the left button and follows the
  mouse (releasing over an entry runs it), a right-click elsewhere closes it and opens the
  menu of the new place in one click, pressing the icon switches menus at once, pressing
  the bar and dragging moves the window, and it closes by itself when the window loses the
  focus or is maximized / restored.
- A left-click on a widget while a menu is open closes the menu and reaches the widget
  (focus, press).
- Keyboard: `↓` `↑` `Home` `End` move the highlight (shared with the mouse), `Enter` /
  `Space` run the entry, a letter runs the entry with that mnemonic (the letter is
  underlined), `Esc` closes.
- Own `PopupRoute` with a 90 ms fade, kept inside the window near the edges.

**Architecture, example and documentation**
- Clean Architecture + MVVM (see `ARCHITECTURE.md`): Dart `domain` / `data` /
  `presentation` / `composition`, and the same layers in the C++ code of `windows/`. The
  mouse decisions live in view models that know no widget (`WindowMenuSession`,
  `DoubleClickDetector`); the views only feed them events.
- Example app: a home page with a **Minimal example** and a **Guided tour** (colors, tabs,
  search box, updates from a service, the unfocused look, caption buttons, height / padding
  / spacing, drag areas, window menus, right-to-left).
- README: quick start, concepts, recipes, the full table of title bar behaviors, known
  limits and troubleshooting.
- Contains native code (`windows/`): after adding the package, close the app completely
  and run it again (hot reload is not enough).

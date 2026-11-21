#ifndef WINDOW_FRAME_SRC_INFRASTRUCTURE_WIN32_WIN32_FRAME_H_
#define WINDOW_FRAME_SRC_INFRASTRUCTURE_WIN32_WIN32_FRAME_H_

// Win32 helpers for the custom frame: the sizes of the native window frame, and
// the subclass that lets the top edge of the Flutter view resize the window.

#include <windows.h>

namespace window_frame::infrastructure {

// Sizes of the native window frame, adjusted to the monitor's DPI.
class Win32FrameMetrics {
 public:
  // 1.0 at 100% display scaling, 1.5 at 150%...
  static double DpiScaleFactor(HWND window);

  // Height of the invisible band at the very top that resizes the window.
  static int TopResizeBandHeight(HWND window);

  // Full thickness of the native sizing frame. Windows adds it around a
  // maximized window so that it extends past the monitor edges.
  static int SizingFrameThickness(HWND window);
};

// The Flutter view covers the whole client area, so it would swallow the mouse
// on the top edge. This subclass lets that thin band fall through to the
// runner window, which answers "resize from the top".
class FlutterViewHitTestSubclass {
 public:
  // Returns true when the subclass is installed.
  static bool Install(HWND flutter_view_window);
  static void Remove(HWND flutter_view_window);
};

}  // namespace window_frame::infrastructure

#endif  // WINDOW_FRAME_SRC_INFRASTRUCTURE_WIN32_WIN32_FRAME_H_

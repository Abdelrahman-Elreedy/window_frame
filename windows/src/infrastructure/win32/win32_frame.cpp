#include "src/infrastructure/win32/win32_frame.h"

#include <windowsx.h>
#include <commctrl.h>

namespace window_frame::infrastructure {

namespace {
constexpr double kBaseDpi = 96.0;
}  // namespace

double Win32FrameMetrics::DpiScaleFactor(HWND window) {
  return static_cast<double>(GetDpiForWindow(window)) / kBaseDpi;
}

int Win32FrameMetrics::TopResizeBandHeight(HWND window) {
  const UINT dpi = GetDpiForWindow(window);
  return GetSystemMetricsForDpi(SM_CYSIZEFRAME, dpi);
}

int Win32FrameMetrics::SizingFrameThickness(HWND window) {
  const UINT dpi = GetDpiForWindow(window);
  return GetSystemMetricsForDpi(SM_CYSIZEFRAME, dpi) +
         GetSystemMetricsForDpi(SM_CXPADDEDBORDER, dpi);
}

namespace {

constexpr UINT_PTR kSubclassIdentifier = 0x57465631;

bool IsInTopResizeBand(HWND runner_window, LPARAM screen_position) {
  RECT window_rectangle;
  GetWindowRect(runner_window, &window_rectangle);
  const int vertical_position = GET_Y_LPARAM(screen_position);
  const int band_height = Win32FrameMetrics::TopResizeBandHeight(runner_window);
  return vertical_position >= window_rectangle.top &&
         vertical_position < window_rectangle.top + band_height;
}

LRESULT CALLBACK HitTestSubclassProcedure(HWND view_window, UINT message,
                                          WPARAM wparam, LPARAM lparam,
                                          UINT_PTR /*subclass_identifier*/,
                                          DWORD_PTR /*reference_data*/) {
  if (message == WM_NCHITTEST) {
    HWND runner_window = GetParent(view_window);
    if (runner_window != nullptr && !IsZoomed(runner_window) &&
        IsInTopResizeBand(runner_window, lparam)) {
      return HTTRANSPARENT;
    }
  }
  return DefSubclassProc(view_window, message, wparam, lparam);
}

}  // namespace

bool FlutterViewHitTestSubclass::Install(HWND flutter_view_window) {
  return SetWindowSubclass(flutter_view_window, HitTestSubclassProcedure,
                           kSubclassIdentifier, 0) != FALSE;
}

void FlutterViewHitTestSubclass::Remove(HWND flutter_view_window) {
  if (IsWindow(flutter_view_window)) {
    RemoveWindowSubclass(flutter_view_window, HitTestSubclassProcedure,
                         kSubclassIdentifier);
  }
}

}  // namespace window_frame::infrastructure

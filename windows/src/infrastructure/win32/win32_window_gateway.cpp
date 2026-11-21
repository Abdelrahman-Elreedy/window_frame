#include "src/infrastructure/win32/win32_window_gateway.h"

#include <dwmapi.h>

#include "src/infrastructure/win32/win32_frame.h"

namespace window_frame::infrastructure {

Win32WindowGateway::Win32WindowGateway(HWND flutter_view_window)
    : flutter_view_window_(flutter_view_window) {}

Win32WindowGateway::~Win32WindowGateway() {
  if (is_view_subclassed_) {
    FlutterViewHitTestSubclass::Remove(flutter_view_window_);
  }
}

HWND Win32WindowGateway::FindRunnerWindow() const {
  if (flutter_view_window_ == nullptr) return nullptr;
  HWND root_window = GetAncestor(flutter_view_window_, GA_ROOT);
  return root_window == flutter_view_window_ ? nullptr : root_window;
}

bool Win32WindowGateway::IsReady() const {
  return FindRunnerWindow() != nullptr;
}

bool Win32WindowGateway::IsVisible() const {
  HWND window = FindRunnerWindow();
  return window != nullptr && IsWindowVisible(window) != 0;
}

bool Win32WindowGateway::IsMaximized() const {
  HWND window = FindRunnerWindow();
  return window != nullptr && IsZoomed(window) != 0;
}

bool Win32WindowGateway::IsActive() const {
  HWND window = FindRunnerWindow();
  // A window that is not shown yet is treated as active, so the title bar does
  // not flash in its "inactive" look when the app starts.
  if (window == nullptr || !IsWindowVisible(window)) return true;
  return GetActiveWindow() == window;
}

std::string Win32WindowGateway::ApplicationTitle() const {
  HWND window = FindRunnerWindow();
  if (window == nullptr) return std::string();

  const int title_length = GetWindowTextLengthW(window);
  if (title_length <= 0) return std::string();

  std::wstring wide_title(static_cast<size_t>(title_length) + 1, L'\0');
  const int copied_length =
      GetWindowTextW(window, &wide_title[0], title_length + 1);
  if (copied_length <= 0) return std::string();
  wide_title.resize(static_cast<size_t>(copied_length));

  // Flutter's method channel carries UTF-8 strings, so non-Latin names (for
  // example Arabic) must be converted, not truncated.
  const int utf8_length =
      WideCharToMultiByte(CP_UTF8, 0, wide_title.c_str(), copied_length,
                          nullptr, 0, nullptr, nullptr);
  if (utf8_length <= 0) return std::string();

  std::string utf8_title(static_cast<size_t>(utf8_length), '\0');
  WideCharToMultiByte(CP_UTF8, 0, wide_title.c_str(), copied_length,
                      &utf8_title[0], utf8_length, nullptr, nullptr);
  return utf8_title;
}

void Win32WindowGateway::Minimize() {
  HWND window = FindRunnerWindow();
  if (window != nullptr) ShowWindow(window, SW_MINIMIZE);
}

void Win32WindowGateway::Maximize() {
  HWND window = FindRunnerWindow();
  if (window != nullptr) ShowWindow(window, SW_MAXIMIZE);
}

void Win32WindowGateway::Restore() {
  HWND window = FindRunnerWindow();
  if (window != nullptr) ShowWindow(window, SW_RESTORE);
}

void Win32WindowGateway::ToggleMaximize() {
  HWND window = FindRunnerWindow();
  if (window == nullptr) return;
  ShowWindow(window, IsZoomed(window) ? SW_RESTORE : SW_MAXIMIZE);
}

void Win32WindowGateway::RequestClose() {
  HWND window = FindRunnerWindow();
  if (window != nullptr) PostMessage(window, WM_CLOSE, 0, 0);
}

void Win32WindowGateway::BeginDrag() {
  HWND window = FindRunnerWindow();
  if (window == nullptr) return;
  ReleaseCapture();
  SendMessage(window, WM_SYSCOMMAND, SC_MOVE | HTCAPTION, 0);
}

void Win32WindowGateway::ApplyCustomFrame(int frame_border_width) {
  HWND window = FindRunnerWindow();
  if (window == nullptr) return;

  if (!is_view_subclassed_) {
    is_view_subclassed_ =
        FlutterViewHitTestSubclass::Install(flutter_view_window_);
  }

  // By default the frame is NOT extended into the client area: a one-pixel
  // extension made the window border look thicker (checked on a real machine).
  // A developer can ask for more with WindowFrameOptions.frameBorderWidth.
  constexpr int kMaximumFrameBorderWidth = 16;
  int width = frame_border_width;
  if (width < 0) width = 0;
  if (width > kMaximumFrameBorderWidth) width = kMaximumFrameBorderWidth;
  const MARGINS frame_extension = {width, width, width, width};
  DwmExtendFrameIntoClientArea(window, &frame_extension);

  // Makes Windows re-run WM_NCCALCSIZE so the title bar disappears.
  SetWindowPos(window, nullptr, 0, 0, 0, 0,
               SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER |
                   SWP_NOACTIVATE);
}

void Win32WindowGateway::EnlargeToMinimumSize(double minimum_width,
                                              double minimum_height) {
  HWND window = FindRunnerWindow();
  if (window == nullptr) return;
  if (minimum_width <= 0.0 || minimum_height <= 0.0) return;
  // A maximized or minimized window is not constrained.
  if (IsZoomed(window) || IsIconic(window)) return;

  const double scale = Win32FrameMetrics::DpiScaleFactor(window);
  const int minimum_width_in_pixels = static_cast<int>(minimum_width * scale);
  const int minimum_height_in_pixels = static_cast<int>(minimum_height * scale);

  RECT window_rectangle;
  if (!GetWindowRect(window, &window_rectangle)) return;
  const int current_width = window_rectangle.right - window_rectangle.left;
  const int current_height = window_rectangle.bottom - window_rectangle.top;
  if (current_width >= minimum_width_in_pixels &&
      current_height >= minimum_height_in_pixels) {
    return;
  }

  SetWindowPos(window, nullptr, 0, 0,
               current_width < minimum_width_in_pixels ? minimum_width_in_pixels
                                                       : current_width,
               current_height < minimum_height_in_pixels
                   ? minimum_height_in_pixels
                   : current_height,
               SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
}

}  // namespace window_frame::infrastructure

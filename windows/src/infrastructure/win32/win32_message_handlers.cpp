#include "src/infrastructure/win32/win32_message_handlers.h"

#include <windowsx.h>

#include "src/infrastructure/win32/win32_frame.h"

namespace window_frame::infrastructure {

NonClientAreaHandler::NonClientAreaHandler(const domain::WindowSession& session)
    : session_(session) {}

bool NonClientAreaHandler::TryHandle(const WindowMessage& message,
                                     LRESULT* result) {
  if (message.identifier != WM_NCCALCSIZE) return false;
  if (!session_.is_custom_frame_active || message.wparam == 0) return false;

  auto* parameters = reinterpret_cast<NCCALCSIZE_PARAMS*>(message.lparam);
  const LONG original_top = parameters->rgrc[0].top;

  // 1. Let Windows compute the normal client rectangle. This keeps the native
  //    (invisible) resize borders on the left, right and bottom.
  const LRESULT default_result = DefWindowProc(
      message.window, message.identifier, message.wparam, message.lparam);
  if (default_result != 0) {
    *result = default_result;
    return true;
  }

  // 2. Give the title-bar strip back to the app.
  parameters->rgrc[0].top = original_top;

  // 3. A maximized window is positioned past the monitor by the frame
  //    thickness: push the content back inside the visible area.
  if (IsZoomed(message.window)) {
    parameters->rgrc[0].top +=
        Win32FrameMetrics::SizingFrameThickness(message.window);
  }

  *result = 0;
  return true;
}

ResizeHitTestHandler::ResizeHitTestHandler(const domain::WindowSession& session)
    : session_(session) {}

bool ResizeHitTestHandler::TryHandle(const WindowMessage& message,
                                     LRESULT* result) {
  if (message.identifier != WM_NCHITTEST) return false;
  if (!session_.is_custom_frame_active || IsZoomed(message.window)) {
    return false;
  }

  const int horizontal_position = GET_X_LPARAM(message.lparam);
  const int vertical_position = GET_Y_LPARAM(message.lparam);
  RECT window_rectangle;
  GetWindowRect(message.window, &window_rectangle);

  const int band_height = Win32FrameMetrics::TopResizeBandHeight(message.window);
  const bool is_in_top_band = vertical_position >= window_rectangle.top &&
                              vertical_position < window_rectangle.top + band_height;
  if (!is_in_top_band) return false;

  const int corner_width = Win32FrameMetrics::SizingFrameThickness(message.window);
  if (horizontal_position < window_rectangle.left + corner_width) {
    *result = HTTOPLEFT;
  } else if (horizontal_position >= window_rectangle.right - corner_width) {
    *result = HTTOPRIGHT;
  } else {
    *result = HTTOP;
  }
  return true;
}

MinimumSizeHandler::MinimumSizeHandler(const domain::WindowSession& session)
    : session_(session) {}

bool MinimumSizeHandler::TryHandle(const WindowMessage& message,
                                   LRESULT* result) {
  if (message.identifier != WM_GETMINMAXINFO) return false;

  const double minimum_width = session_.options.minimum_width;
  const double minimum_height = session_.options.minimum_height;
  if (minimum_width <= 0.0 || minimum_height <= 0.0) return false;

  auto* size_limits = reinterpret_cast<MINMAXINFO*>(message.lparam);
  const double scale = Win32FrameMetrics::DpiScaleFactor(message.window);
  size_limits->ptMinTrackSize.x = static_cast<LONG>(minimum_width * scale);
  size_limits->ptMinTrackSize.y = static_cast<LONG>(minimum_height * scale);

  *result = 0;
  return true;
}

SizeChangeHandler::SizeChangeHandler(
    application::SynchronizeWindowStateUseCase& synchronize_state)
    : synchronize_state_(synchronize_state) {}

bool SizeChangeHandler::TryHandle(const WindowMessage& message,
                                  LRESULT* /*result*/) {
  if (message.identifier != WM_SIZE) return false;

  // A minimized window keeps its previous maximized state.
  if (message.wparam != static_cast<WPARAM>(SIZE_MINIMIZED)) {
    synchronize_state_.OnWindowSizeChanged(IsZoomed(message.window) != 0);
  }
  return false;
}

ActivationChangeHandler::ActivationChangeHandler(
    application::SynchronizeWindowStateUseCase& synchronize_state)
    : synchronize_state_(synchronize_state) {}

bool ActivationChangeHandler::TryHandle(const WindowMessage& message,
                                        LRESULT* /*result*/) {
  if (message.identifier != WM_ACTIVATE) return false;

  const bool is_active = LOWORD(message.wparam) != WA_INACTIVE;
  synchronize_state_.OnWindowActivationChanged(is_active);
  return false;
}

StartMaximizedHandler::StartMaximizedHandler(
    application::StartMaximizedPolicy& policy)
    : policy_(policy),
      maximize_request_message_(
          RegisterWindowMessageW(L"window_frame.maximize_request")) {}

bool StartMaximizedHandler::TryHandle(const WindowMessage& message,
                                      LRESULT* result) {
  if (message.identifier == maximize_request_message_) {
    ShowWindow(message.window, SW_MAXIMIZE);
    *result = 0;
    return true;
  }

  // wparam != 0: the window is being shown. lparam == 0: because of a
  // ShowWindow call (not because an owner or parent window changed).
  const bool is_window_being_shown =
      message.identifier == WM_SHOWWINDOW && message.wparam != 0 &&
      message.lparam == 0;
  if (is_window_being_shown && policy_.ShouldMaximizeOnFirstShow()) {
    PostMessage(message.window, maximize_request_message_, 0, 0);
  }
  return false;
}

}  // namespace window_frame::infrastructure

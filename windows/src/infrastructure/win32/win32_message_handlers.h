#ifndef WINDOW_FRAME_SRC_INFRASTRUCTURE_WIN32_WIN32_MESSAGE_HANDLERS_H_
#define WINDOW_FRAME_SRC_INFRASTRUCTURE_WIN32_WIN32_MESSAGE_HANDLERS_H_

// One handler per kind of window message. They are registered, in this order,
// by the plugin (window_frame_plugin.cpp).

#include "src/application/window_use_cases.h"
#include "src/common/disallow_copy_and_assign.h"
#include "src/domain/window_models.h"
#include "src/infrastructure/win32/win32_message_pipeline.h"

namespace window_frame::infrastructure {

// WM_NCCALCSIZE: gives the title-bar strip back to the app, so the native
// title bar disappears. The resize borders on the left, right and bottom stay.
class NonClientAreaHandler : public WindowMessageHandler {
 public:
  explicit NonClientAreaHandler(const domain::WindowSession& session);

  bool TryHandle(const WindowMessage& message, LRESULT* result) override;

 private:
  const domain::WindowSession& session_;

  WINDOW_FRAME_DISALLOW_COPY_AND_ASSIGN(NonClientAreaHandler);
};

// WM_NCHITTEST: answers "resize" for the thin band at the top edge and the two
// top corners (the other edges are resized by the native frame itself).
class ResizeHitTestHandler : public WindowMessageHandler {
 public:
  explicit ResizeHitTestHandler(const domain::WindowSession& session);

  bool TryHandle(const WindowMessage& message, LRESULT* result) override;

 private:
  const domain::WindowSession& session_;

  WINDOW_FRAME_DISALLOW_COPY_AND_ASSIGN(ResizeHitTestHandler);
};

// WM_GETMINMAXINFO: stops the user from resizing below the minimum size.
class MinimumSizeHandler : public WindowMessageHandler {
 public:
  explicit MinimumSizeHandler(const domain::WindowSession& session);

  bool TryHandle(const WindowMessage& message, LRESULT* result) override;

 private:
  const domain::WindowSession& session_;

  WINDOW_FRAME_DISALLOW_COPY_AND_ASSIGN(MinimumSizeHandler);
};

// WM_SIZE: tells Dart when the window is maximized or restored. The message
// is only observed, so the runner still handles it.
class SizeChangeHandler : public WindowMessageHandler {
 public:
  explicit SizeChangeHandler(
      application::SynchronizeWindowStateUseCase& synchronize_state);

  bool TryHandle(const WindowMessage& message, LRESULT* result) override;

 private:
  application::SynchronizeWindowStateUseCase& synchronize_state_;

  WINDOW_FRAME_DISALLOW_COPY_AND_ASSIGN(SizeChangeHandler);
};

// WM_ACTIVATE: tells Dart when the window gains or loses the focus. The
// message is only observed, so the runner still handles it.
class ActivationChangeHandler : public WindowMessageHandler {
 public:
  explicit ActivationChangeHandler(
      application::SynchronizeWindowStateUseCase& synchronize_state);

  bool TryHandle(const WindowMessage& message, LRESULT* result) override;

 private:
  application::SynchronizeWindowStateUseCase& synchronize_state_;

  WINDOW_FRAME_DISALLOW_COPY_AND_ASSIGN(ActivationChangeHandler);
};

// Maximizes the window when it is shown for the first time.
//
// Windows ignores the show command of the very first ShowWindow call when the
// app was launched with startup information (for example by double-clicking
// the .exe). So the maximize is requested as a SECOND step: at the first show
// a private message is posted, and the maximize happens when it arrives.
class StartMaximizedHandler : public WindowMessageHandler {
 public:
  explicit StartMaximizedHandler(application::StartMaximizedPolicy& policy);

  bool TryHandle(const WindowMessage& message, LRESULT* result) override;

 private:
  application::StartMaximizedPolicy& policy_;
  // A unique message identifier: it cannot clash with other plugins.
  UINT maximize_request_message_;

  WINDOW_FRAME_DISALLOW_COPY_AND_ASSIGN(StartMaximizedHandler);
};

}  // namespace window_frame::infrastructure

#endif  // WINDOW_FRAME_SRC_INFRASTRUCTURE_WIN32_WIN32_MESSAGE_HANDLERS_H_

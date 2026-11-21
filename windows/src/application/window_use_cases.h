#ifndef WINDOW_FRAME_SRC_APPLICATION_WINDOW_USE_CASES_H_
#define WINDOW_FRAME_SRC_APPLICATION_WINDOW_USE_CASES_H_

// The use cases of the plugin: one small class per thing the plugin does.
// They only know the domain contracts, never Win32 or Flutter.

#include "src/common/disallow_copy_and_assign.h"
#include "src/domain/window_models.h"
#include "src/domain/window_ports.h"

namespace window_frame::application {

// Applies the startup options once and reports the resulting window status.
class InitializeWindowUseCase {
 public:
  InitializeWindowUseCase(domain::WindowGateway& gateway,
                          domain::WindowSession& session);

  // Calling it again changes nothing and returns the current status.
  domain::WindowStatus Execute(const domain::WindowOptions& options);

 private:
  domain::WindowStatus ReadCurrentStatus() const;

  domain::WindowGateway& gateway_;
  domain::WindowSession& session_;

  WINDOW_FRAME_DISALLOW_COPY_AND_ASSIGN(InitializeWindowUseCase);
};

// Changes the minimum window size while the app runs.
class SetMinimumSizeUseCase {
 public:
  SetMinimumSizeUseCase(domain::WindowGateway& gateway,
                        domain::WindowSession& session);

  // The new limit applies to the next resize; a smaller window grows now.
  void Execute(double minimum_width, double minimum_height);

 private:
  domain::WindowGateway& gateway_;
  domain::WindowSession& session_;

  WINDOW_FRAME_DISALLOW_COPY_AND_ASSIGN(SetMinimumSizeUseCase);
};

// The simple window commands the title bar buttons send.
class WindowCommandsUseCase {
 public:
  explicit WindowCommandsUseCase(domain::WindowGateway& gateway);

  void Minimize();
  void Maximize();
  void Restore();
  void ToggleMaximize();
  void RequestClose();
  void BeginDrag();

 private:
  domain::WindowGateway& gateway_;

  WINDOW_FRAME_DISALLOW_COPY_AND_ASSIGN(WindowCommandsUseCase);
};

// Keeps Dart informed: publishes the window state, but only when it changed.
class SynchronizeWindowStateUseCase {
 public:
  SynchronizeWindowStateUseCase(domain::WindowSession& session,
                                domain::WindowEventPublisher& publisher);

  void OnWindowSizeChanged(bool is_maximized);
  void OnWindowActivationChanged(bool is_active);

 private:
  domain::WindowSession& session_;
  domain::WindowEventPublisher& publisher_;

  WINDOW_FRAME_DISALLOW_COPY_AND_ASSIGN(SynchronizeWindowStateUseCase);
};

// Decides whether the window must be maximized when it is shown.
class StartMaximizedPolicy {
 public:
  explicit StartMaximizedPolicy(domain::WindowSession& session);

  // True exactly once: at the first show, if "start maximized" was requested.
  bool ShouldMaximizeOnFirstShow();

 private:
  domain::WindowSession& session_;

  WINDOW_FRAME_DISALLOW_COPY_AND_ASSIGN(StartMaximizedPolicy);
};

}  // namespace window_frame::application

#endif  // WINDOW_FRAME_SRC_APPLICATION_WINDOW_USE_CASES_H_

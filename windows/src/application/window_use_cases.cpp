#include "src/application/window_use_cases.h"

namespace window_frame::application {

InitializeWindowUseCase::InitializeWindowUseCase(
    domain::WindowGateway& gateway, domain::WindowSession& session)
    : gateway_(gateway), session_(session) {}

domain::WindowStatus InitializeWindowUseCase::Execute(
    const domain::WindowOptions& options) {
  if (session_.is_initialized) {
    return ReadCurrentStatus();
  }

  session_.options = options;
  // If the window is already visible the first show was missed, so a "start
  // maximized" request can no longer be honored.
  session_.has_handled_first_show = gateway_.IsVisible();
  session_.last_known_maximized = gateway_.IsMaximized();
  session_.last_known_active = gateway_.IsActive();
  session_.is_custom_frame_active = options.use_custom_frame;

  // The flags come first: removing the title bar makes Windows send messages
  // right away, and the message handlers must already be active to answer.
  session_.is_initialized = true;
  if (options.use_custom_frame) {
    gateway_.ApplyCustomFrame(options.frame_border_width);
  }
  return ReadCurrentStatus();
}

domain::WindowStatus InitializeWindowUseCase::ReadCurrentStatus() const {
  domain::WindowStatus status;
  status.is_custom_frame_active = session_.is_custom_frame_active;
  status.is_maximized = gateway_.IsMaximized();
  status.is_window_active = gateway_.IsActive();
  status.application_title = gateway_.ApplicationTitle();
  return status;
}

SetMinimumSizeUseCase::SetMinimumSizeUseCase(domain::WindowGateway& gateway,
                                             domain::WindowSession& session)
    : gateway_(gateway), session_(session) {}

void SetMinimumSizeUseCase::Execute(double minimum_width,
                                    double minimum_height) {
  session_.options.minimum_width = minimum_width;
  session_.options.minimum_height = minimum_height;
  gateway_.EnlargeToMinimumSize(minimum_width, minimum_height);
}

WindowCommandsUseCase::WindowCommandsUseCase(domain::WindowGateway& gateway)
    : gateway_(gateway) {}

void WindowCommandsUseCase::Minimize() { gateway_.Minimize(); }

void WindowCommandsUseCase::Maximize() { gateway_.Maximize(); }

void WindowCommandsUseCase::Restore() { gateway_.Restore(); }

void WindowCommandsUseCase::ToggleMaximize() { gateway_.ToggleMaximize(); }

void WindowCommandsUseCase::RequestClose() { gateway_.RequestClose(); }

void WindowCommandsUseCase::BeginDrag() { gateway_.BeginDrag(); }

SynchronizeWindowStateUseCase::SynchronizeWindowStateUseCase(
    domain::WindowSession& session, domain::WindowEventPublisher& publisher)
    : session_(session), publisher_(publisher) {}

void SynchronizeWindowStateUseCase::OnWindowSizeChanged(bool is_maximized) {
  if (session_.last_known_maximized == is_maximized) return;
  session_.last_known_maximized = is_maximized;
  publisher_.PublishMaximizedStateChanged(is_maximized);
}

void SynchronizeWindowStateUseCase::OnWindowActivationChanged(bool is_active) {
  if (session_.last_known_active == is_active) return;
  session_.last_known_active = is_active;
  publisher_.PublishActivationStateChanged(is_active);
}

StartMaximizedPolicy::StartMaximizedPolicy(domain::WindowSession& session)
    : session_(session) {}

bool StartMaximizedPolicy::ShouldMaximizeOnFirstShow() {
  if (!session_.is_initialized || session_.has_handled_first_show) {
    return false;
  }
  session_.has_handled_first_show = true;
  return session_.options.start_maximized;
}

}  // namespace window_frame::application

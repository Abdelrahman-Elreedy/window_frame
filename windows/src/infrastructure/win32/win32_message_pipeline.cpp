#include "src/infrastructure/win32/win32_message_pipeline.h"

#include <utility>

namespace window_frame::infrastructure {

Win32MessageDispatcher::Win32MessageDispatcher(
    const domain::WindowSession& session)
    : session_(session) {}

void Win32MessageDispatcher::AddHandler(
    std::unique_ptr<WindowMessageHandler> handler) {
  handlers_.push_back(std::move(handler));
}

std::optional<LRESULT> Win32MessageDispatcher::Dispatch(HWND window,
                                                        UINT identifier,
                                                        WPARAM wparam,
                                                        LPARAM lparam) {
  if (!session_.is_initialized) return std::nullopt;

  const WindowMessage message = {window, identifier, wparam, lparam};
  for (const std::unique_ptr<WindowMessageHandler>& handler : handlers_) {
    LRESULT result = 0;
    if (handler->TryHandle(message, &result)) {
      return result;
    }
  }
  return std::nullopt;
}

}  // namespace window_frame::infrastructure

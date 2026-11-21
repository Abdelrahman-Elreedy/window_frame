#ifndef WINDOW_FRAME_SRC_INFRASTRUCTURE_WIN32_WIN32_MESSAGE_PIPELINE_H_
#define WINDOW_FRAME_SRC_INFRASTRUCTURE_WIN32_WIN32_MESSAGE_PIPELINE_H_

// How window messages travel: one message, the interface of a handler, and the
// dispatcher that offers every message to the handlers in order.

#include <windows.h>

#include <memory>
#include <optional>
#include <vector>

#include "src/common/disallow_copy_and_assign.h"
#include "src/domain/window_models.h"

namespace window_frame::infrastructure {

// One Win32 window message, with readable field names.
struct WindowMessage {
  HWND window;
  UINT identifier;
  WPARAM wparam;
  LPARAM lparam;
};

// One handler per kind of window message.
class WindowMessageHandler {
 public:
  virtual ~WindowMessageHandler() = default;

  // Returns true when the message is fully handled: [result] is then the
  // answer for Windows and nobody else sees the message. Returns false to let
  // the message continue to the rest of the app.
  virtual bool TryHandle(const WindowMessage& message, LRESULT* result) = 0;
};

// Gives every window message to the handlers, in the order they were added.
class Win32MessageDispatcher {
 public:
  explicit Win32MessageDispatcher(const domain::WindowSession& session);

  void AddHandler(std::unique_ptr<WindowMessageHandler> handler);

  // Returns the answer for Windows when a handler consumed the message, or
  // std::nullopt to let the message continue. Does nothing until Dart has
  // initialized the plugin.
  std::optional<LRESULT> Dispatch(HWND window, UINT identifier, WPARAM wparam,
                                  LPARAM lparam);

 private:
  const domain::WindowSession& session_;
  std::vector<std::unique_ptr<WindowMessageHandler>> handlers_;

  WINDOW_FRAME_DISALLOW_COPY_AND_ASSIGN(Win32MessageDispatcher);
};

}  // namespace window_frame::infrastructure

#endif  // WINDOW_FRAME_SRC_INFRASTRUCTURE_WIN32_WIN32_MESSAGE_PIPELINE_H_

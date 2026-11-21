#ifndef FLUTTER_PLUGIN_WINDOW_FRAME_PLUGIN_H_
#define FLUTTER_PLUGIN_WINDOW_FRAME_PLUGIN_H_

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "src/application/window_use_cases.h"
#include "src/common/disallow_copy_and_assign.h"
#include "src/domain/window_models.h"
#include "src/infrastructure/win32/win32_message_pipeline.h"
#include "src/infrastructure/win32/win32_window_gateway.h"
#include "src/presentation/window_channel.h"

namespace window_frame {

// The composition root of the native side: it creates every object, connects
// them, and links the result to Flutter (method channel + window messages).
//
//   Dart  <->  presentation  ->  application  ->  domain  <-  infrastructure
//   (channel)   (controller)     (use cases)    (contracts)    (Win32)
class WindowFramePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit WindowFramePlugin(flutter::PluginRegistrarWindows* registrar);
  ~WindowFramePlugin() override;

 private:
  void RegisterMessageHandlers();

  // The order of these members is the order of construction: every member only
  // depends on the ones declared above it.
  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  domain::WindowSession session_;
  infrastructure::Win32WindowGateway gateway_;
  presentation::ChannelEventPublisher event_publisher_;
  application::InitializeWindowUseCase initialize_window_;
  application::WindowCommandsUseCase window_commands_;
  application::SetMinimumSizeUseCase set_minimum_size_;
  application::SynchronizeWindowStateUseCase synchronize_window_state_;
  application::StartMaximizedPolicy start_maximized_policy_;
  presentation::WindowChannelController channel_controller_;
  infrastructure::Win32MessageDispatcher message_dispatcher_;
  int message_delegate_identifier_ = -1;

  WINDOW_FRAME_DISALLOW_COPY_AND_ASSIGN(WindowFramePlugin);
};

}  // namespace window_frame

#endif  // FLUTTER_PLUGIN_WINDOW_FRAME_PLUGIN_H_

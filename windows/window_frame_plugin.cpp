// NOT compiled on Windows by the author (no Windows toolchain available): the
// sources were only syntax-checked against hand-written stubs. The Flutter
// Windows build treats warnings as errors (/W4 /WX): if the build fails, send
// the exact message.

#include "window_frame_plugin.h"

#include <flutter/standard_method_codec.h>

#include <utility>

#include "src/infrastructure/win32/win32_message_handlers.h"
#include "src/presentation/channel_contract.h"

namespace window_frame {

namespace {

// The window that shows the Flutter content.
//
// GetView() is documented as deprecated in newer Flutter (GetViewById is the
// replacement). It still works, so it is used here; the pragma keeps a
// possible deprecation warning from failing the build (/WX).
HWND FindFlutterViewWindow(flutter::PluginRegistrarWindows* registrar) {
#pragma warning(push)
#pragma warning(disable : 4996)
  flutter::FlutterView* flutter_view = registrar->GetView();
#pragma warning(pop)
  return flutter_view != nullptr ? flutter_view->GetNativeWindow() : nullptr;
}

}  // namespace

// static
void WindowFramePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  registrar->AddPlugin(std::make_unique<WindowFramePlugin>(registrar));
}

WindowFramePlugin::WindowFramePlugin(flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar),
      channel_(
          std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
              registrar->messenger(), presentation::channel_contract::kChannelName,
              &flutter::StandardMethodCodec::GetInstance())),
      gateway_(FindFlutterViewWindow(registrar)),
      event_publisher_(channel_.get()),
      initialize_window_(gateway_, session_),
      window_commands_(gateway_),
      set_minimum_size_(gateway_, session_),
      synchronize_window_state_(session_, event_publisher_),
      start_maximized_policy_(session_),
      channel_controller_(gateway_, initialize_window_, window_commands_,
                          set_minimum_size_),
      message_dispatcher_(session_) {
  // First thing: Dart may call the channel as soon as main() starts.
  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& method_call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        channel_controller_.HandleMethodCall(method_call, std::move(result));
      });

  RegisterMessageHandlers();

  message_delegate_identifier_ = registrar_->RegisterTopLevelWindowProcDelegate(
      [this](HWND window, UINT identifier, WPARAM wparam, LPARAM lparam) {
        return message_dispatcher_.Dispatch(window, identifier, wparam, lparam);
      });
}

WindowFramePlugin::~WindowFramePlugin() {
  registrar_->UnregisterTopLevelWindowProcDelegate(message_delegate_identifier_);
}

void WindowFramePlugin::RegisterMessageHandlers() {
  message_dispatcher_.AddHandler(
      std::make_unique<infrastructure::NonClientAreaHandler>(session_));
  message_dispatcher_.AddHandler(
      std::make_unique<infrastructure::ResizeHitTestHandler>(session_));
  message_dispatcher_.AddHandler(
      std::make_unique<infrastructure::MinimumSizeHandler>(session_));
  message_dispatcher_.AddHandler(
      std::make_unique<infrastructure::SizeChangeHandler>(
          synchronize_window_state_));
  message_dispatcher_.AddHandler(
      std::make_unique<infrastructure::ActivationChangeHandler>(
          synchronize_window_state_));
  message_dispatcher_.AddHandler(
      std::make_unique<infrastructure::StartMaximizedHandler>(
          start_maximized_policy_));
}

}  // namespace window_frame

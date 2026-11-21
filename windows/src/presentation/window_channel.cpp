#include "src/presentation/window_channel.h"

#include <memory>
#include <string>
#include <utility>

#include "src/domain/window_models.h"
#include "src/presentation/channel_codec.h"
#include "src/presentation/channel_contract.h"

namespace window_frame::presentation {

ChannelEventPublisher::ChannelEventPublisher(
    flutter::MethodChannel<flutter::EncodableValue>* channel)
    : channel_(channel) {}

void ChannelEventPublisher::PublishMaximizedStateChanged(bool is_maximized) {
  PublishBoolean(channel_contract::kMaximizedStateChangedEvent, is_maximized);
}

void ChannelEventPublisher::PublishActivationStateChanged(bool is_active) {
  PublishBoolean(channel_contract::kActivationStateChangedEvent, is_active);
}

void ChannelEventPublisher::PublishBoolean(const char* event_name, bool value) {
  if (channel_ == nullptr) return;
  channel_->InvokeMethod(event_name,
                         std::make_unique<flutter::EncodableValue>(value));
}

WindowChannelController::WindowChannelController(
    domain::WindowGateway& gateway,
    application::InitializeWindowUseCase& initialize_window,
    application::WindowCommandsUseCase& window_commands,
    application::SetMinimumSizeUseCase& set_minimum_size)
    : gateway_(gateway),
      initialize_window_(initialize_window),
      window_commands_(window_commands),
      set_minimum_size_(set_minimum_size) {}

void WindowChannelController::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    MethodResultPointer result) {
  if (!gateway_.IsReady()) {
    result->Error(channel_contract::kWindowNotReadyErrorCode,
                  "The Flutter window is not ready yet.");
    return;
  }

  const std::string& method_name = method_call.method_name();
  const auto* arguments =
      std::get_if<flutter::EncodableMap>(method_call.arguments());

  if (method_name == channel_contract::kInitializeMethod) {
    InitializeWindow(arguments, std::move(result));
  } else if (method_name == channel_contract::kSetMinimumSizeMethod) {
    SetMinimumSize(arguments, std::move(result));
  } else if (method_name == channel_contract::kMinimizeMethod) {
    window_commands_.Minimize();
    result->Success();
  } else if (method_name == channel_contract::kMaximizeMethod) {
    window_commands_.Maximize();
    result->Success();
  } else if (method_name == channel_contract::kRestoreMethod) {
    window_commands_.Restore();
    result->Success();
  } else if (method_name == channel_contract::kToggleMaximizeMethod) {
    window_commands_.ToggleMaximize();
    result->Success();
  } else if (method_name == channel_contract::kRequestCloseMethod) {
    window_commands_.RequestClose();
    result->Success();
  } else if (method_name == channel_contract::kStartDragMethod) {
    window_commands_.BeginDrag();
    result->Success();
  } else {
    result->NotImplemented();
  }
}

void WindowChannelController::InitializeWindow(
    const flutter::EncodableMap* arguments, MethodResultPointer result) {
  const domain::WindowOptions options = ChannelArgumentReader::ReadWindowOptions(
      arguments, domain::WindowOptions());
  const domain::WindowStatus status = initialize_window_.Execute(options);
  result->Success(WindowStatusEncoder::Encode(status));
}

void WindowChannelController::SetMinimumSize(
    const flutter::EncodableMap* arguments, MethodResultPointer result) {
  double minimum_width = 0.0;
  double minimum_height = 0.0;
  if (ChannelArgumentReader::TryReadMinimumSize(arguments, &minimum_width,
                                                &minimum_height)) {
    set_minimum_size_.Execute(minimum_width, minimum_height);
  }
  result->Success();
}

}  // namespace window_frame::presentation

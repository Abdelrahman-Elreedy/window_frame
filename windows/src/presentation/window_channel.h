#ifndef WINDOW_FRAME_SRC_PRESENTATION_WINDOW_CHANNEL_H_
#define WINDOW_FRAME_SRC_PRESENTATION_WINDOW_CHANNEL_H_

// The method channel, both directions: events from the plugin to Dart (event
// publisher) and calls from Dart to the use cases (channel controller).

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <memory>

#include "src/application/window_use_cases.h"
#include "src/common/disallow_copy_and_assign.h"
#include "src/domain/window_ports.h"

namespace window_frame::presentation {

// Sends window events to Dart through the method channel.
class ChannelEventPublisher : public domain::WindowEventPublisher {
 public:
  // [channel] is owned by the plugin and outlives this publisher.
  explicit ChannelEventPublisher(
      flutter::MethodChannel<flutter::EncodableValue>* channel);

  void PublishMaximizedStateChanged(bool is_maximized) override;
  void PublishActivationStateChanged(bool is_active) override;

 private:
  void PublishBoolean(const char* event_name, bool value);

  flutter::MethodChannel<flutter::EncodableValue>* channel_;

  WINDOW_FRAME_DISALLOW_COPY_AND_ASSIGN(ChannelEventPublisher);
};

// Receives the calls from Dart, runs the matching use case and answers. It
// holds no window logic itself: it only translates between the channel and
// the application layer.
class WindowChannelController {
 public:
  using MethodResultPointer =
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>;

  WindowChannelController(
      domain::WindowGateway& gateway,
      application::InitializeWindowUseCase& initialize_window,
      application::WindowCommandsUseCase& window_commands,
      application::SetMinimumSizeUseCase& set_minimum_size);

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      MethodResultPointer result);

 private:
  void InitializeWindow(const flutter::EncodableMap* arguments,
                        MethodResultPointer result);
  void SetMinimumSize(const flutter::EncodableMap* arguments,
                      MethodResultPointer result);

  domain::WindowGateway& gateway_;
  application::InitializeWindowUseCase& initialize_window_;
  application::WindowCommandsUseCase& window_commands_;
  application::SetMinimumSizeUseCase& set_minimum_size_;

  WINDOW_FRAME_DISALLOW_COPY_AND_ASSIGN(WindowChannelController);
};

}  // namespace window_frame::presentation

#endif  // WINDOW_FRAME_SRC_PRESENTATION_WINDOW_CHANNEL_H_

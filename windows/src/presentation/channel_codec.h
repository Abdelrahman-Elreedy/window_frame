#ifndef WINDOW_FRAME_SRC_PRESENTATION_CHANNEL_CODEC_H_
#define WINDOW_FRAME_SRC_PRESENTATION_CHANNEL_CODEC_H_

// Translation between Flutter's channel values and the plugin's own types:
// reading what Dart sends, and encoding what the plugin answers.

#include <flutter/encodable_value.h>

#include "src/domain/window_models.h"

namespace window_frame::presentation {

// Reads the arguments Dart sends (a map of names to values).
class ChannelArgumentReader {
 public:
  // Fields missing from [arguments] keep the value from [defaults].
  static domain::WindowOptions ReadWindowOptions(
      const flutter::EncodableMap* arguments,
      const domain::WindowOptions& defaults);

  // Returns false when [arguments] holds no minimum size.
  static bool TryReadMinimumSize(const flutter::EncodableMap* arguments,
                                 double* minimum_width,
                                 double* minimum_height);
};

// Turns a window status into the map Dart expects as the "initialize" answer.
class WindowStatusEncoder {
 public:
  static flutter::EncodableValue Encode(const domain::WindowStatus& status);
};

}  // namespace window_frame::presentation

#endif  // WINDOW_FRAME_SRC_PRESENTATION_CHANNEL_CODEC_H_

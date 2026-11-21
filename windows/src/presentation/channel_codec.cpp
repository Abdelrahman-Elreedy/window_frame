#include "src/presentation/channel_codec.h"

#include <cstdint>
#include <string>

#include "src/presentation/channel_contract.h"

namespace window_frame::presentation {

namespace {

const flutter::EncodableValue* FindValue(const flutter::EncodableMap& arguments,
                                         const char* key) {
  const auto found = arguments.find(flutter::EncodableValue(std::string(key)));
  return found == arguments.end() ? nullptr : &found->second;
}

// Dart numbers arrive as double, int32 or int64 depending on their value.
bool TryReadNumber(const flutter::EncodableMap& arguments, const char* key,
                   double* number) {
  const flutter::EncodableValue* value = FindValue(arguments, key);
  if (value == nullptr) return false;
  if (const auto* as_double = std::get_if<double>(value)) {
    *number = *as_double;
    return true;
  }
  if (const auto* as_int32 = std::get_if<int32_t>(value)) {
    *number = static_cast<double>(*as_int32);
    return true;
  }
  if (const auto* as_int64 = std::get_if<int64_t>(value)) {
    *number = static_cast<double>(*as_int64);
    return true;
  }
  return false;
}

bool ReadBoolean(const flutter::EncodableMap& arguments, const char* key,
                 bool fallback) {
  const flutter::EncodableValue* value = FindValue(arguments, key);
  if (value == nullptr) return fallback;
  if (const auto* as_bool = std::get_if<bool>(value)) return *as_bool;
  return fallback;
}

}  // namespace

domain::WindowOptions ChannelArgumentReader::ReadWindowOptions(
    const flutter::EncodableMap* arguments,
    const domain::WindowOptions& defaults) {
  domain::WindowOptions options = defaults;
  if (arguments == nullptr) return options;

  TryReadMinimumSize(arguments, &options.minimum_width, &options.minimum_height);
  options.start_maximized = ReadBoolean(
      *arguments, channel_contract::kStartMaximizedKey, defaults.start_maximized);
  options.use_custom_frame = ReadBoolean(
      *arguments, channel_contract::kCustomFrameKey, defaults.use_custom_frame);
  double frame_border_width = defaults.frame_border_width;
  TryReadNumber(*arguments, channel_contract::kFrameBorderWidthKey,
                &frame_border_width);
  options.frame_border_width = static_cast<int>(frame_border_width);
  return options;
}

bool ChannelArgumentReader::TryReadMinimumSize(
    const flutter::EncodableMap* arguments, double* minimum_width,
    double* minimum_height) {
  if (arguments == nullptr) return false;

  double width = 0.0;
  double height = 0.0;
  const bool has_width =
      TryReadNumber(*arguments, channel_contract::kMinimumWidthKey, &width);
  const bool has_height =
      TryReadNumber(*arguments, channel_contract::kMinimumHeightKey, &height);
  if (!has_width || !has_height) return false;

  *minimum_width = width;
  *minimum_height = height;
  return true;
}

flutter::EncodableValue WindowStatusEncoder::Encode(
    const domain::WindowStatus& status) {
  flutter::EncodableMap encoded_status;
  encoded_status[flutter::EncodableValue(
      std::string(channel_contract::kCustomFrameActiveKey))] =
      flutter::EncodableValue(status.is_custom_frame_active);
  encoded_status[flutter::EncodableValue(
      std::string(channel_contract::kIsMaximizedKey))] =
      flutter::EncodableValue(status.is_maximized);
  encoded_status[flutter::EncodableValue(
      std::string(channel_contract::kIsWindowActiveKey))] =
      flutter::EncodableValue(status.is_window_active);
  encoded_status[flutter::EncodableValue(
      std::string(channel_contract::kApplicationTitleKey))] =
      flutter::EncodableValue(status.application_title);
  return flutter::EncodableValue(encoded_status);
}

}  // namespace window_frame::presentation

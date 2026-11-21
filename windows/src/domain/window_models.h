#ifndef WINDOW_FRAME_SRC_DOMAIN_WINDOW_MODELS_H_
#define WINDOW_FRAME_SRC_DOMAIN_WINDOW_MODELS_H_

// The plain data of the window domain: what Dart asked for at start-up (options),
// what the plugin remembers while the app runs (session), and what it reports
// back to Dart (status).

#include <string>

namespace window_frame::domain {

// Startup configuration chosen by the Dart side. Sizes are in logical pixels.
struct WindowOptions {
  double minimum_width = 800.0;
  double minimum_height = 600.0;
  bool start_maximized = false;
  bool use_custom_frame = true;
  // Pixels of the native frame extended into the client area on every side.
  int frame_border_width = 0;
};

// What the plugin remembers about the window while the app runs. Use cases
// write it, the message handlers read it.
struct WindowSession {
  WindowOptions options;

  // False until Dart calls "initialize": until then the plugin is inert.
  bool is_initialized = false;

  // True once the native title bar is removed.
  bool is_custom_frame_active = false;

  // True once the first show of the window was seen (or missed).
  bool has_handled_first_show = false;

  // The last values published to Dart, to publish changes only.
  bool last_known_maximized = false;
  bool last_known_active = true;
};

// A snapshot of the window, reported to Dart after initialization.
struct WindowStatus {
  bool is_custom_frame_active = false;
  bool is_maximized = false;
  bool is_window_active = true;
  // The title the runner gave to the window (UTF-8). By default Flutter uses
  // the project name from pubspec.yaml; empty when it cannot be read.
  std::string application_title;
};

}  // namespace window_frame::domain

#endif  // WINDOW_FRAME_SRC_DOMAIN_WINDOW_MODELS_H_

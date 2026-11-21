# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "window_frame")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "window_frame_plugin")

# Any new source file must be added here.
list(APPEND PLUGIN_SOURCES
  # Composition root (links the native code to Flutter).
  "window_frame_plugin.cpp"
  "window_frame_plugin.h"

  # Application layer: the use cases.
  "src/application/window_use_cases.cpp"

  # Infrastructure layer: Win32.
  "src/infrastructure/win32/win32_frame.cpp"
  "src/infrastructure/win32/win32_message_handlers.cpp"
  "src/infrastructure/win32/win32_message_pipeline.cpp"
  "src/infrastructure/win32/win32_window_gateway.cpp"

  # Presentation layer: the Flutter method channel.
  "src/presentation/channel_codec.cpp"
  "src/presentation/window_channel.cpp"
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
  "include/window_frame/window_frame_plugin_c_api.h"
  "window_frame_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. (Warnings are treated as errors there.)
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies.
# The plugin folder is a private include root: sources say
# #include "src/domain/window_gateway.h".
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  flutter_wrapper_plugin
  "dwmapi.lib"
  "comctl32.lib"
)

# List of absolute paths to libraries that should be bundled with the plugin.
set(window_frame_bundled_libraries
  ""
  PARENT_SCOPE
)

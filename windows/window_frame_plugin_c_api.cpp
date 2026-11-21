#include "include/window_frame/window_frame_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "window_frame_plugin.h"

void WindowFramePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  window_frame::WindowFramePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

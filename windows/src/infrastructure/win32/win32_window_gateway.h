#ifndef WINDOW_FRAME_SRC_INFRASTRUCTURE_WIN32_WIN32_WINDOW_GATEWAY_H_
#define WINDOW_FRAME_SRC_INFRASTRUCTURE_WIN32_WIN32_WINDOW_GATEWAY_H_

#include <windows.h>

#include <string>

#include "src/common/disallow_copy_and_assign.h"
#include "src/domain/window_ports.h"

namespace window_frame::infrastructure {

// Win32 implementation of the window gateway.
//
// It is built from the Flutter view window; the runner window that hosts the
// view is looked up lazily, because the view is only placed inside it a moment
// after the plugin is registered.
class Win32WindowGateway : public domain::WindowGateway {
 public:
  explicit Win32WindowGateway(HWND flutter_view_window);
  ~Win32WindowGateway() override;

  bool IsReady() const override;
  bool IsVisible() const override;
  bool IsMaximized() const override;
  bool IsActive() const override;
  std::string ApplicationTitle() const override;

  void Minimize() override;
  void Maximize() override;
  void Restore() override;
  void ToggleMaximize() override;
  void RequestClose() override;
  void BeginDrag() override;

  void ApplyCustomFrame(int frame_border_width) override;
  void EnlargeToMinimumSize(double minimum_width,
                            double minimum_height) override;

 private:
  // The runner window, or nullptr while the view has no parent yet.
  HWND FindRunnerWindow() const;

  HWND flutter_view_window_;
  bool is_view_subclassed_ = false;

  WINDOW_FRAME_DISALLOW_COPY_AND_ASSIGN(Win32WindowGateway);
};

}  // namespace window_frame::infrastructure

#endif  // WINDOW_FRAME_SRC_INFRASTRUCTURE_WIN32_WIN32_WINDOW_GATEWAY_H_

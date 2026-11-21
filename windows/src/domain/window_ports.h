#ifndef WINDOW_FRAME_SRC_DOMAIN_WINDOW_PORTS_H_
#define WINDOW_FRAME_SRC_DOMAIN_WINDOW_PORTS_H_

// The two contracts the domain defines and the outer layers implement:
// the operating-system window (gateway) and the channel to Dart (event publisher).

#include <string>

namespace window_frame::domain {

// Everything the application layer can ask of the operating-system window.
// The Win32 implementation lives in the infrastructure layer.
class WindowGateway {
 public:
  virtual ~WindowGateway() = default;

  // False until the Flutter view is placed inside the runner window.
  virtual bool IsReady() const = 0;
  virtual bool IsVisible() const = 0;
  virtual bool IsMaximized() const = 0;
  virtual bool IsActive() const = 0;

  // The title of the runner window as UTF-8, or an empty string when the
  // window is not ready or has no title.
  virtual std::string ApplicationTitle() const = 0;

  virtual void Minimize() = 0;
  virtual void Maximize() = 0;
  virtual void Restore() = 0;
  virtual void ToggleMaximize() = 0;
  virtual void RequestClose() = 0;
  virtual void BeginDrag() = 0;

  // Removes the native title bar and keeps the resize borders and the shadow.
  // [frame_border_width] pixels of the native frame are extended into the
  // client area on every side (0 = none).
  virtual void ApplyCustomFrame(int frame_border_width) = 0;

  // Grows a normal-sized window that is smaller than the given minimum.
  virtual void EnlargeToMinimumSize(double minimum_width,
                                    double minimum_height) = 0;
};

// How the application layer tells Dart that something happened to the window.
class WindowEventPublisher {
 public:
  virtual ~WindowEventPublisher() = default;

  virtual void PublishMaximizedStateChanged(bool is_maximized) = 0;
  virtual void PublishActivationStateChanged(bool is_active) = 0;
};

}  // namespace window_frame::domain

#endif  // WINDOW_FRAME_SRC_DOMAIN_WINDOW_PORTS_H_

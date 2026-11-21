// The one place where the layers are wired together:
// data source -> repository -> use cases -> view model.
//
// Nothing else in the package creates repositories or use cases.

import 'package:flutter/foundation.dart';

import 'package:window_frame/src/data/datasources/window_method_channel_data_source.dart';
import 'package:window_frame/src/data/repositories/window_platform_repositories.dart';
import 'package:window_frame/src/domain/repositories/window_platform_repository.dart';
import 'package:window_frame/src/domain/use_cases/window_use_cases.dart';
import 'package:window_frame/src/presentation/view_models/window_frame_view_model.dart';

abstract final class WindowFrameCompositionRoot {
  static WindowFrameViewModel? _windowFrameViewModel;

  /// True where a native implementation exists (Windows only for now).
  static bool get isPlatformSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// The single view model shared by the facade and every widget.
  static WindowFrameViewModel get windowFrameViewModel =>
      _windowFrameViewModel ??= _createWindowFrameViewModel();

  static WindowFrameViewModel _createWindowFrameViewModel() {
    final WindowPlatformRepository repository = _createRepository();
    return WindowFrameViewModel(
      initializeWindowFrame: InitializeWindowFrameUseCase(repository),
      minimizeWindow: MinimizeWindowUseCase(repository),
      maximizeWindow: MaximizeWindowUseCase(repository),
      restoreWindow: RestoreWindowUseCase(repository),
      toggleMaximizeWindow: ToggleMaximizeWindowUseCase(repository),
      requestWindowClose: RequestWindowCloseUseCase(repository),
      startWindowDrag: StartWindowDragUseCase(repository),
      setMinimumWindowSize: SetMinimumWindowSizeUseCase(repository),
      observeWindowEvents: ObserveWindowEventsUseCase(repository),
    );
  }

  static WindowPlatformRepository _createRepository() {
    if (!isPlatformSupported) {
      return const UnsupportedWindowPlatformRepository();
    }
    return WindowPlatformRepositoryImpl(
      dataSource: WindowMethodChannelDataSource(),
    );
  }
}

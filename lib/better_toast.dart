/// Highly customizable toasts for Flutter.
///
/// Add a host once with [BetterToast.init] or [BetterToastScope], then show
/// toasts from anywhere:
///
/// ```dart
/// MaterialApp(builder: BetterToast.init(), home: const HomePage());
///
/// BetterToast.success('Saved');
/// ```
///
/// Customize in layers, each optional: [BetterToastThemeData] for the whole
/// app, `typeStyles` per [ToastType], a [ToastStyle] per call, or a fully
/// custom [ToastBuilder].
library;

export 'src/better_toast.dart' show BetterToast;
export 'src/enums.dart'
    show ToastAnimation, ToastPosition, ToastStackMode, ToastType;
export 'src/scope.dart' show BetterToastScope;
export 'src/theme.dart' show BetterToastTheme, BetterToastThemeData;
export 'src/toast_action.dart' show ToastAction;
export 'src/toast_handle.dart'
    show ToastBuilder, ToastHandle, ToastTransitionBuilder;
export 'src/toast_style.dart' show ToastStyle;

import 'package:flutter/material.dart';

import 'entry.dart';
import 'enums.dart';
import 'scope.dart';
import 'theme.dart';
import 'toast_action.dart';
import 'toast_handle.dart';
import 'toast_style.dart';

/// Shows toasts from anywhere, with or without a [BuildContext].
///
/// Add a host once, then call the static methods:
///
/// ```dart
/// MaterialApp(builder: BetterToast.init(), home: const HomePage());
///
/// // Anywhere, even outside the widget tree:
/// BetterToast.success('Saved');
/// final handle = BetterToast.loading('Uploading…');
/// handle.update(text: 'Uploaded', type: ToastType.success);
/// ```
///
/// Every `show*` method returns a [ToastHandle] to update or close the
/// toast. They throw a [FlutterError] when no [BetterToastScope] is mounted.
///
/// ## Shared arguments
///
/// * `text`: the message as plain text. Use `message` for a widget instead.
/// * `title` and `description`: optional lines above and below the message.
/// * `duration`: how long the toast stays. `null` uses the theme
///   ([BetterToastThemeData.duration]); [Duration.zero] makes it sticky.
///   Loading toasts are sticky unless a duration is given.
/// * `position`, `animation`, `transitionBuilder`: placement and motion.
///   `null` uses the theme.
/// * `style`: [ToastStyle] overrides, merged over the theme.
/// * `action`: an optional [ToastAction] button.
/// * `dismissible`: whether the toast can be swiped away.
/// * `pauseOnHover`, `pauseOnTouch`: whether the timer pauses while the
///   toast is hovered or pressed.
/// * `showProgressBar`: whether to show the remaining time.
/// * `onTap`, `onDismissed`: callbacks. `onDismissed` runs once, after the
///   toast is removed.
/// * `id`: when a toast with the same id is active, it is updated in place
///   instead of adding a duplicate.
/// * `context`: picks the [BetterToastScope] that contains this context.
///   Without it, the most recently mounted scope is used.
abstract final class BetterToast {
  /// Returns a [MaterialApp.builder] (or [WidgetsApp.builder]) that adds a
  /// [BetterToastScope] above the navigator.
  ///
  /// Pass your own [builder] to chain it. It wraps the scope: its `child`
  /// argument is the [BetterToastScope] (which contains the navigator), so
  /// whatever it adds above `child`, such as a [Directionality], a
  /// [MediaQuery] text scale, a [Theme] or [Localizations], applies to the
  /// toasts as well as to the app.
  ///
  /// ```dart
  /// MaterialApp(
  ///   builder: BetterToast.init(
  ///     theme: const BetterToastThemeData(maxVisible: 5),
  ///     builder: (context, child) => Directionality(
  ///       textDirection: TextDirection.rtl,
  ///       child: child!,
  ///     ),
  ///   ),
  ///   home: const HomePage(),
  /// );
  /// ```
  static TransitionBuilder init({
    BetterToastThemeData? theme,
    TransitionBuilder? builder,
  }) {
    return (BuildContext context, Widget? child) {
      final Widget scope = BetterToastScope(
        theme: theme,
        child: child ?? const SizedBox.shrink(),
      );
      return builder == null ? scope : builder(context, scope);
    };
  }

  /// Shows a toast.
  ///
  /// ```dart
  /// final handle = BetterToast.show(
  ///   'Saved',
  ///   type: ToastType.success,
  ///   title: 'Done',
  ///   position: ToastPosition.bottom,
  ///   action: ToastAction(label: 'Undo', onPressed: undo),
  /// );
  /// ```
  ///
  /// See [BetterToast] for the meaning of each argument.
  static ToastHandle show(
    String? text, {
    Widget? message,
    ToastType type = ToastType.info,
    String? title,
    String? description,
    Duration? duration,
    ToastPosition? position,
    ToastAnimation? animation,
    ToastTransitionBuilder? transitionBuilder,
    ToastStyle? style,
    ToastAction? action,
    bool? dismissible,
    bool? pauseOnHover,
    bool? pauseOnTouch,
    bool? showProgressBar,
    VoidCallback? onTap,
    VoidCallback? onDismissed,
    Object? id,
    BuildContext? context,
  }) {
    assert(
      text != null || message != null || title != null || description != null,
      'A BetterToast needs content: pass text, message, title or '
      'description. Use BetterToast.custom() for a fully custom toast.',
    );
    return _show(
      ToastConfig(
        type: type,
        text: text,
        message: message,
        title: title,
        description: description,
        duration: duration,
        position: position,
        animation: animation,
        transitionBuilder: transitionBuilder,
        style: style,
        action: action,
        dismissible: dismissible,
        pauseOnHover: pauseOnHover,
        pauseOnTouch: pauseOnTouch,
        showProgressBar: showProgressBar,
        onTap: onTap,
        onDismissed: onDismissed,
      ),
      id: id,
      context: context,
      method: 'show',
    );
  }

  /// Shows a [ToastType.success] toast. Same arguments as [show].
  ///
  /// ```dart
  /// BetterToast.success('Profile updated');
  /// ```
  static ToastHandle success(
    String? text, {
    Widget? message,
    String? title,
    String? description,
    Duration? duration,
    ToastPosition? position,
    ToastAnimation? animation,
    ToastTransitionBuilder? transitionBuilder,
    ToastStyle? style,
    ToastAction? action,
    bool? dismissible,
    bool? pauseOnHover,
    bool? pauseOnTouch,
    bool? showProgressBar,
    VoidCallback? onTap,
    VoidCallback? onDismissed,
    Object? id,
    BuildContext? context,
  }) {
    return show(
      text,
      type: ToastType.success,
      message: message,
      title: title,
      description: description,
      duration: duration,
      position: position,
      animation: animation,
      transitionBuilder: transitionBuilder,
      style: style,
      action: action,
      dismissible: dismissible,
      pauseOnHover: pauseOnHover,
      pauseOnTouch: pauseOnTouch,
      showProgressBar: showProgressBar,
      onTap: onTap,
      onDismissed: onDismissed,
      id: id,
      context: context,
    );
  }

  /// Shows a [ToastType.error] toast. Same arguments as [show].
  ///
  /// ```dart
  /// BetterToast.error('Could not connect', description: 'Check your network');
  /// ```
  static ToastHandle error(
    String? text, {
    Widget? message,
    String? title,
    String? description,
    Duration? duration,
    ToastPosition? position,
    ToastAnimation? animation,
    ToastTransitionBuilder? transitionBuilder,
    ToastStyle? style,
    ToastAction? action,
    bool? dismissible,
    bool? pauseOnHover,
    bool? pauseOnTouch,
    bool? showProgressBar,
    VoidCallback? onTap,
    VoidCallback? onDismissed,
    Object? id,
    BuildContext? context,
  }) {
    return show(
      text,
      type: ToastType.error,
      message: message,
      title: title,
      description: description,
      duration: duration,
      position: position,
      animation: animation,
      transitionBuilder: transitionBuilder,
      style: style,
      action: action,
      dismissible: dismissible,
      pauseOnHover: pauseOnHover,
      pauseOnTouch: pauseOnTouch,
      showProgressBar: showProgressBar,
      onTap: onTap,
      onDismissed: onDismissed,
      id: id,
      context: context,
    );
  }

  /// Shows a [ToastType.warning] toast. Same arguments as [show].
  ///
  /// ```dart
  /// BetterToast.warning('Battery low');
  /// ```
  static ToastHandle warning(
    String? text, {
    Widget? message,
    String? title,
    String? description,
    Duration? duration,
    ToastPosition? position,
    ToastAnimation? animation,
    ToastTransitionBuilder? transitionBuilder,
    ToastStyle? style,
    ToastAction? action,
    bool? dismissible,
    bool? pauseOnHover,
    bool? pauseOnTouch,
    bool? showProgressBar,
    VoidCallback? onTap,
    VoidCallback? onDismissed,
    Object? id,
    BuildContext? context,
  }) {
    return show(
      text,
      type: ToastType.warning,
      message: message,
      title: title,
      description: description,
      duration: duration,
      position: position,
      animation: animation,
      transitionBuilder: transitionBuilder,
      style: style,
      action: action,
      dismissible: dismissible,
      pauseOnHover: pauseOnHover,
      pauseOnTouch: pauseOnTouch,
      showProgressBar: showProgressBar,
      onTap: onTap,
      onDismissed: onDismissed,
      id: id,
      context: context,
    );
  }

  /// Shows a [ToastType.info] toast. Same arguments as [show].
  ///
  /// ```dart
  /// BetterToast.info('A new version is available');
  /// ```
  static ToastHandle info(
    String? text, {
    Widget? message,
    String? title,
    String? description,
    Duration? duration,
    ToastPosition? position,
    ToastAnimation? animation,
    ToastTransitionBuilder? transitionBuilder,
    ToastStyle? style,
    ToastAction? action,
    bool? dismissible,
    bool? pauseOnHover,
    bool? pauseOnTouch,
    bool? showProgressBar,
    VoidCallback? onTap,
    VoidCallback? onDismissed,
    Object? id,
    BuildContext? context,
  }) {
    return show(
      text,
      type: ToastType.info,
      message: message,
      title: title,
      description: description,
      duration: duration,
      position: position,
      animation: animation,
      transitionBuilder: transitionBuilder,
      style: style,
      action: action,
      dismissible: dismissible,
      pauseOnHover: pauseOnHover,
      pauseOnTouch: pauseOnTouch,
      showProgressBar: showProgressBar,
      onTap: onTap,
      onDismissed: onDismissed,
      id: id,
      context: context,
    );
  }

  /// Shows a [ToastType.loading] toast with a spinner. Same arguments as
  /// [show].
  ///
  /// Loading toasts are sticky unless [duration] is given. Change the toast
  /// when the work is done, or use [promise]:
  ///
  /// ```dart
  /// final handle = BetterToast.loading('Uploading…');
  /// await upload();
  /// handle.update(text: 'Uploaded', type: ToastType.success);
  /// ```
  static ToastHandle loading(
    String? text, {
    Widget? message,
    String? title,
    String? description,
    Duration? duration,
    ToastPosition? position,
    ToastAnimation? animation,
    ToastTransitionBuilder? transitionBuilder,
    ToastStyle? style,
    ToastAction? action,
    bool? dismissible,
    bool? pauseOnHover,
    bool? pauseOnTouch,
    bool? showProgressBar,
    VoidCallback? onTap,
    VoidCallback? onDismissed,
    Object? id,
    BuildContext? context,
  }) {
    return show(
      text,
      type: ToastType.loading,
      message: message,
      title: title,
      description: description,
      duration: duration,
      position: position,
      animation: animation,
      transitionBuilder: transitionBuilder,
      style: style,
      action: action,
      dismissible: dismissible,
      pauseOnHover: pauseOnHover,
      pauseOnTouch: pauseOnTouch,
      showProgressBar: showProgressBar,
      onTap: onTap,
      onDismissed: onDismissed,
      id: id,
      context: context,
    );
  }

  /// Shows a toast whose whole visual comes from [builder].
  ///
  /// The host still places, animates, times and announces the toast. The
  /// other arguments work as in [show].
  ///
  /// ```dart
  /// BetterToast.custom(
  ///   builder: (context, handle) => Chip(
  ///     avatar: const Icon(Icons.wifi_off),
  ///     label: const Text('Offline'),
  ///     onDeleted: handle.dismiss,
  ///   ),
  /// );
  /// ```
  static ToastHandle custom({
    required ToastBuilder builder,
    Duration? duration,
    ToastPosition? position,
    ToastAnimation? animation,
    ToastTransitionBuilder? transitionBuilder,
    bool? dismissible,
    bool? pauseOnHover,
    bool? pauseOnTouch,
    VoidCallback? onTap,
    VoidCallback? onDismissed,
    Object? id,
    BuildContext? context,
  }) {
    return _show(
      ToastConfig(
        type: ToastType.custom,
        builder: builder,
        duration: duration,
        position: position,
        animation: animation,
        transitionBuilder: transitionBuilder,
        dismissible: dismissible,
        pauseOnHover: pauseOnHover,
        pauseOnTouch: pauseOnTouch,
        onTap: onTap,
        onDismissed: onDismissed,
      ),
      id: id,
      context: context,
      method: 'custom',
    );
  }

  /// Shows a loading toast while [future] runs, then turns it into a
  /// success or error toast.
  ///
  /// Returns a future that completes like [future]: with its value, or with
  /// its error. If you do not await the result, handle its error, for
  /// example with `.ignore()`.
  ///
  /// [duration] applies to the success or error toast. Other arguments work
  /// as in [show]. If the toast was dismissed before [future] completes, no
  /// new toast is shown.
  ///
  /// [success] and [error] should not throw. If [success] throws, the
  /// loading toast is closed and the returned future completes with that
  /// exception; it is not shown as an error toast. If [error] throws, the
  /// loading toast is closed, the callback exception is reported to
  /// [FlutterError.onError], and the returned future completes with the
  /// error of [future].
  ///
  /// ```dart
  /// final user = await BetterToast.promise(
  ///   api.fetchUser(),
  ///   loading: 'Loading profile…',
  ///   success: (user) => 'Welcome back, ${user.name}',
  ///   error: (error) => 'Could not load profile',
  /// );
  /// ```
  static Future<T> promise<T>(
    Future<T> future, {
    required String loading,
    required String Function(T value) success,
    required String Function(Object error) error,
    String? title,
    String? description,
    Duration? duration,
    ToastPosition? position,
    ToastAnimation? animation,
    ToastStyle? style,
    bool? showProgressBar,
    Object? id,
    BuildContext? context,
  }) async {
    final ToastHandle handle = BetterToast.loading(
      loading,
      title: title,
      description: description,
      position: position,
      animation: animation,
      style: style,
      showProgressBar: showProgressBar,
      id: id,
      context: context,
    );
    final T value;
    try {
      value = await future;
    } catch (e, stackTrace) {
      final String text;
      try {
        text = error(e);
      } catch (callbackError, stack) {
        // A bug in the callback must not hide the original error.
        handle.dismiss();
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: callbackError,
            stack: stack,
            library: 'better_toast',
            context: ErrorDescription('while running the error callback of '
                'BetterToast.promise'),
          ),
        );
        Error.throwWithStackTrace(e, stackTrace);
      }
      handle.update(text: text, type: ToastType.error, duration: duration);
      rethrow;
    }
    final String text;
    try {
      text = success(value);
    } catch (_) {
      // Not an error of [future]: close the loading toast and let the
      // exception of the callback complete the returned future.
      handle.dismiss();
      rethrow;
    }
    handle.update(text: text, type: ToastType.success, duration: duration);
    return value;
  }

  /// Closes the active toast with [id], in every scope.
  ///
  /// ```dart
  /// BetterToast.loading('Syncing…', id: 'sync');
  /// // later
  /// BetterToast.dismiss('sync');
  /// ```
  static void dismiss(Object id) {
    for (final ToastHost host in List<ToastHost>.of(ToastHost.active)) {
      host.findActive(id)?.dismiss();
    }
  }

  /// Closes every toast in every scope, including queued toasts.
  static void dismissAll() {
    for (final ToastHost host in List<ToastHost>.of(ToastHost.active)) {
      host.dismissAll();
    }
  }

  /// Whether a toast with [id] is shown or queued in any scope.
  static bool isActive(Object id) {
    return ToastHost.active
        .any((ToastHost host) => host.findActive(id) != null);
  }

  static ToastHandle _show(
    ToastConfig config, {
    required Object? id,
    required BuildContext? context,
    required String method,
  }) {
    final ToastHost? host =
        (context == null ? null : ToastHost.maybeOf(context)) ??
            (ToastHost.active.isEmpty ? null : ToastHost.active.last);
    if (host == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
          'BetterToast.$method() was called, but no BetterToastScope is '
          'mounted.',
        ),
        ErrorDescription(
          'Toasts are drawn by a BetterToastScope host. None is in the '
          'widget tree yet, so the toast has nowhere to appear.',
        ),
        ErrorHint(
          'Add the host once, near the root of your app:\n'
          '\n'
          '  MaterialApp(\n'
          '    builder: BetterToast.init(),\n'
          '    home: const HomePage(),\n'
          '  )\n'
          '\n'
          'or wrap your app in BetterToastScope(child: ...).',
        ),
        ErrorHint(
          'If you show a toast during app start-up, wait until the first '
          'frame is built, for example with '
          'WidgetsBinding.instance.addPostFrameCallback.',
        ),
      ]);
    }
    return host.show(config, id: id);
  }
}

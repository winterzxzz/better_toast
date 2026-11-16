import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'better_toast.dart';
import 'enums.dart';
import 'theme.dart';
import 'toast_action.dart';
import 'toast_style.dart';

/// Builds the whole visual of a toast.
///
/// Used by [BetterToast.custom] and [BetterToastThemeData.builder]. The
/// returned widget is still placed, animated, made swipeable and announced
/// to screen readers by the toast host. Read the toast content from
/// [handle], and close it with [ToastHandle.dismiss].
///
/// ```dart
/// BetterToast.custom(
///   builder: (context, handle) => Card(
///     child: ListTile(
///       title: const Text('New message'),
///       trailing: IconButton(
///         icon: const Icon(Icons.close),
///         onPressed: handle.dismiss,
///       ),
///     ),
///   ),
/// );
/// ```
typedef ToastBuilder = Widget Function(
  BuildContext context,
  ToastHandle handle,
);

/// Builds a custom enter and exit transition for a toast.
///
/// [animation] runs from `0` (hidden) to `1` (shown) on enter, and back on
/// exit. [position] tells where the toast is placed.
///
/// ```dart
/// BetterToastThemeData(
///   animation: ToastAnimation.custom,
///   transitionBuilder: (context, animation, position, child) =>
///       RotationTransition(turns: animation, child: child),
/// )
/// ```
typedef ToastTransitionBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  ToastPosition position,
  Widget child,
);

/// A reference to one shown toast.
///
/// Every `BetterToast.show*` method returns a handle. Use it to change or
/// close the toast later:
///
/// ```dart
/// final handle = BetterToast.loading('Uploading…');
/// // ...
/// handle.update(text: 'Uploaded', type: ToastType.success);
/// await handle.closed;
/// ```
///
/// The getters return the current content, which is useful in a
/// [ToastBuilder].
abstract class ToastHandle {
  /// The id of the toast. Showing a toast with the same id updates this
  /// toast instead of adding a new one.
  ///
  /// When no id was given, this is a unique generated object.
  Object get id;

  /// The current type of the toast.
  ToastType get type;

  /// The current plain-text message, if any.
  String? get text;

  /// The current widget message, if any.
  Widget? get message;

  /// The current title, if any.
  String? get title;

  /// The current description, if any.
  String? get description;

  /// The current action, if any.
  ToastAction? get action;

  /// The per-call style overrides, if any.
  ///
  /// To get the fully resolved style, use [BetterToastTheme.resolveStyle].
  ToastStyle? get style;

  /// Whether the toast is shown or waiting in the queue.
  ///
  /// Becomes `false` as soon as the toast starts to close.
  bool get isActive;

  /// Completes after the toast is closed and removed from the screen.
  Future<void> get closed;

  /// The remaining display time, from `1.0` (full) to `0.0` (about to close).
  ///
  /// Stays at `1.0` for sticky toasts and while the toast is queued.
  ValueListenable<double> get progress;

  /// Closes the toast with its exit animation. Does nothing if the toast is
  /// already closing.
  void dismiss();

  /// Changes the content of the toast in place and restarts its timer.
  ///
  /// Only the given arguments change. [duration] follows the same rules as
  /// in [BetterToast.show]. Does nothing if the toast is no longer
  /// [isActive].
  void update({
    String? text,
    Widget? message,
    ToastType? type,
    String? title,
    String? description,
    Duration? duration,
    ToastStyle? style,
    ToastAction? action,
    bool? showProgressBar,
    ToastBuilder? builder,
  });

  /// Stops the auto-dismiss timer until [resume] is called.
  void pause();

  /// Restarts the auto-dismiss timer after [pause].
  void resume();
}

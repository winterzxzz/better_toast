import 'package:flutter/widgets.dart';

import 'theme.dart';

/// The semantic kind of a toast.
///
/// The type picks the default icon, accent color and auto-dismiss behavior.
/// Restyle a type for the whole app with [BetterToastThemeData.typeStyles]:
///
/// ```dart
/// BetterToastThemeData(
///   typeStyles: {
///     ToastType.error: ToastStyle(backgroundColor: Colors.red.shade900),
///   },
/// )
/// ```
enum ToastType {
  /// Neutral information. Uses the primary color as accent.
  info,

  /// A successful operation. Uses a green accent.
  success,

  /// Something that needs attention. Uses an amber accent.
  warning,

  /// A failed operation. Uses the error color of the color scheme as accent.
  error,

  /// A long-running operation.
  ///
  /// Loading toasts show a spinner and are sticky unless a duration is given.
  loading,

  /// A toast rendered by a user-supplied builder, for example with
  /// `BetterToast.custom`. The default look shows no icon for this type.
  custom,
}

/// Where a toast appears on the screen.
///
/// The `Left`/`Right` values are physical. The `Start`/`End` values follow
/// the ambient [TextDirection], so they flip in right-to-left locales.
enum ToastPosition {
  /// Top edge, horizontally centered.
  top,

  /// Center of the screen.
  center,

  /// Bottom edge, horizontally centered.
  bottom,

  /// Top-left corner, in every text direction.
  topLeft,

  /// Top-right corner, in every text direction.
  topRight,

  /// Bottom-left corner, in every text direction.
  bottomLeft,

  /// Bottom-right corner, in every text direction.
  bottomRight,

  /// Top corner at the start side (left in LTR, right in RTL).
  topStart,

  /// Top corner at the end side (right in LTR, left in RTL).
  topEnd,

  /// Bottom corner at the start side (left in LTR, right in RTL).
  bottomStart,

  /// Bottom corner at the end side (right in LTR, left in RTL).
  bottomEnd;

  /// The alignment of the toast stack for this position.
  AlignmentGeometry get alignment => switch (this) {
        ToastPosition.top => Alignment.topCenter,
        ToastPosition.center => Alignment.center,
        ToastPosition.bottom => Alignment.bottomCenter,
        ToastPosition.topLeft => Alignment.topLeft,
        ToastPosition.topRight => Alignment.topRight,
        ToastPosition.bottomLeft => Alignment.bottomLeft,
        ToastPosition.bottomRight => Alignment.bottomRight,
        ToastPosition.topStart => AlignmentDirectional.topStart,
        ToastPosition.topEnd => AlignmentDirectional.topEnd,
        ToastPosition.bottomStart => AlignmentDirectional.bottomStart,
        ToastPosition.bottomEnd => AlignmentDirectional.bottomEnd,
      };

  /// Whether toasts at this position are attached to the top edge.
  bool get isTop => switch (this) {
        ToastPosition.top ||
        ToastPosition.topLeft ||
        ToastPosition.topRight ||
        ToastPosition.topStart ||
        ToastPosition.topEnd =>
          true,
        _ => false,
      };

  /// Whether toasts at this position are attached to the bottom edge.
  bool get isBottom => !isTop && this != ToastPosition.center;
}

/// The built-in enter and exit animations of a toast.
///
/// Durations and the curve come from [BetterToastThemeData]. When the
/// platform asks for reduced motion (`MediaQuery.disableAnimations`), every
/// animation is skipped.
enum ToastAnimation {
  /// Fade in and out.
  fade,

  /// Slide in from the nearest screen edge.
  slide,

  /// Grow from a slightly smaller size while fading in.
  scale,

  /// A short slide combined with a fade. This is the default.
  slideFade,

  /// Appear and disappear without animation.
  none,

  /// Use a `ToastTransitionBuilder` given per call or in the theme.
  custom,
}

/// How a toast host handles more than one toast at a time.
enum ToastStackMode {
  /// Show up to `maxVisible` toasts at once. Extra toasts wait in a queue and
  /// appear as visible ones close. This is the default.
  stack,

  /// Show one toast at a time. Other toasts wait in a queue.
  queue,

  /// A new toast closes every visible and queued toast and takes their place.
  replace,
}

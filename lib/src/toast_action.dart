import 'package:flutter/foundation.dart';

/// A button shown at the end of a toast, such as "Undo" or "Retry".
///
/// ```dart
/// BetterToast.show(
///   'Message archived',
///   action: ToastAction(label: 'Undo', onPressed: restoreMessage),
/// );
/// ```
@immutable
class ToastAction {
  /// Creates a toast action.
  const ToastAction({
    required this.label,
    required this.onPressed,
    this.dismissOnPressed = true,
  });

  /// The text of the button.
  final String label;

  /// Called when the button is pressed.
  final VoidCallback onPressed;

  /// Whether pressing the button also dismisses the toast. Defaults to
  /// `true`.
  final bool dismissOnPressed;
}

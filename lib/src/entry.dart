import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'enums.dart';
import 'scope.dart';
import 'toast_action.dart';
import 'toast_handle.dart';
import 'toast_style.dart';

/// Runs [callback] now, or after the current frame when called during a
/// build, layout or paint phase. Marking other widgets dirty in those
/// phases is not allowed.
void runOutsideBuild(VoidCallback callback) {
  final SchedulerBinding binding = SchedulerBinding.instance;
  if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
    binding.addPostFrameCallback((_) => callback());
  } else {
    callback();
  }
}

/// The content and options of one toast, as given by the caller.
///
/// `null` options inherit from the theme. Internal; not exported.
@immutable
class ToastConfig {
  /// Creates a toast config.
  const ToastConfig({
    required this.type,
    this.text,
    this.message,
    this.title,
    this.description,
    this.duration,
    this.position,
    this.animation,
    this.transitionBuilder,
    this.style,
    this.action,
    this.dismissible,
    this.pauseOnHover,
    this.pauseOnTouch,
    this.showProgressBar,
    this.onTap,
    this.onDismissed,
    this.builder,
  });

  /// See [ToastHandle.type].
  final ToastType type;

  /// See [ToastHandle.text].
  final String? text;

  /// See [ToastHandle.message].
  final Widget? message;

  /// See [ToastHandle.title].
  final String? title;

  /// See [ToastHandle.description].
  final String? description;

  /// The display time. `null` inherits, [Duration.zero] is sticky.
  final Duration? duration;

  /// Where the toast appears.
  final ToastPosition? position;

  /// The enter and exit animation.
  final ToastAnimation? animation;

  /// The transition for [ToastAnimation.custom].
  final ToastTransitionBuilder? transitionBuilder;

  /// See [ToastHandle.style].
  final ToastStyle? style;

  /// See [ToastHandle.action].
  final ToastAction? action;

  /// Whether the toast can be swiped away.
  final bool? dismissible;

  /// Whether hovering pauses the timer.
  final bool? pauseOnHover;

  /// Whether pressing pauses the timer.
  final bool? pauseOnTouch;

  /// Whether to show the remaining-time bar.
  final bool? showProgressBar;

  /// Called when the toast is tapped.
  final VoidCallback? onTap;

  /// Called once after the toast is closed and removed.
  final VoidCallback? onDismissed;

  /// Replaces the default visual.
  final ToastBuilder? builder;

  /// Returns a copy with the given fields replaced.
  ToastConfig copyWith({
    ToastType? type,
    String? text,
    Widget? message,
    String? title,
    String? description,
    Duration? duration,
    ToastStyle? style,
    ToastAction? action,
    bool? showProgressBar,
    ToastBuilder? builder,
    bool clearTitle = false,
    bool clearDescription = false,
    bool clearAction = false,
    bool clearStyle = false,
  }) {
    return ToastConfig(
      type: type ?? this.type,
      text: text ?? this.text,
      message: message ?? this.message,
      title: title ?? (clearTitle ? null : this.title),
      description: description ?? (clearDescription ? null : this.description),
      duration: duration ?? this.duration,
      position: position,
      animation: animation,
      transitionBuilder: transitionBuilder,
      style: style ?? (clearStyle ? null : this.style),
      action: action ?? (clearAction ? null : this.action),
      dismissible: dismissible,
      pauseOnHover: pauseOnHover,
      pauseOnTouch: pauseOnTouch,
      showProgressBar: showProgressBar ?? this.showProgressBar,
      onTap: onTap,
      onDismissed: onDismissed,
      builder: builder ?? this.builder,
    );
  }
}

/// The life cycle of a [ToastEntry].
enum ToastEntryStatus {
  /// Waiting for a free slot.
  queued,

  /// On screen.
  visible,

  /// Playing its exit animation.
  exiting,

  /// Gone.
  removed,
}

/// The id given to toasts shown without an explicit id.
class AutoToastId {
  /// Creates an id with a debug [index].
  const AutoToastId(this.index);

  /// A per-host counter, only for debugging.
  final int index;

  @override
  String toString() => 'AutoToastId#$index';
}

/// The mutable model of one toast. Implements the public [ToastHandle].
///
/// Internal; not exported.
class ToastEntry extends ChangeNotifier implements ToastHandle {
  /// Creates an entry owned by [host].
  ToastEntry({
    required this.host,
    required this.id,
    required ToastConfig config,
  }) : _config = config;

  /// The host that shows this toast.
  final ToastHost host;

  @override
  final Object id;

  ToastConfig _config;

  /// The current content and options.
  ToastConfig get config => _config;

  /// Where this entry is in its life cycle.
  ToastEntryStatus status = ToastEntryStatus.queued;

  /// Increments whenever the content changes. A change restarts the timer.
  int version = 0;

  /// The toast widget state that currently shows this entry, if any.
  ///
  /// When a toast moves to another position, the new widget is created
  /// before the old one is disposed, so ownership is tracked by object
  /// rather than by a flag.
  Object? owner;

  /// Whether a toast widget currently shows this entry.
  bool get attached => owner != null;

  bool _manuallyPaused = false;

  /// Whether [pause] is in effect.
  bool get manuallyPaused => _manuallyPaused;

  final Completer<void> _closed = Completer<void>();
  final ValueNotifier<double> _progress = ValueNotifier<double>(1);

  /// The writable [progress].
  ValueNotifier<double> get progressNotifier => _progress;

  @override
  ToastType get type => _config.type;

  @override
  String? get text => _config.text;

  @override
  Widget? get message => _config.message;

  @override
  String? get title => _config.title;

  @override
  String? get description => _config.description;

  @override
  ToastAction? get action => _config.action;

  @override
  ToastStyle? get style => _config.style;

  @override
  bool get isActive =>
      status == ToastEntryStatus.queued || status == ToastEntryStatus.visible;

  @override
  Future<void> get closed => _closed.future;

  @override
  ValueListenable<double> get progress => _progress;

  @override
  void dismiss() => host.dismissEntry(this);

  @override
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
    bool clearTitle = false,
    bool clearDescription = false,
    bool clearAction = false,
    bool clearStyle = false,
  }) {
    if (!isActive) {
      return;
    }
    _config = _config.copyWith(
      text: text,
      message: message,
      type: type,
      title: title,
      description: description,
      duration: duration,
      style: style,
      action: action,
      showProgressBar: showProgressBar,
      builder: builder,
      clearTitle: clearTitle,
      clearDescription: clearDescription,
      clearAction: clearAction,
      clearStyle: clearStyle,
    );
    version++;
    changed();
  }

  /// Replaces the whole config, as `show` with an existing id does.
  void replaceConfig(ToastConfig config) {
    _config = config;
    version++;
    changed();
  }

  @override
  void pause() {
    if (_manuallyPaused) {
      return;
    }
    _manuallyPaused = true;
    changed();
  }

  @override
  void resume() {
    if (!_manuallyPaused) {
      return;
    }
    _manuallyPaused = false;
    changed();
  }

  /// Notifies the toast widget, deferring when called during a build.
  void changed() {
    runOutsideBuild(() {
      if (status != ToastEntryStatus.removed) {
        notifyListeners();
      }
    });
  }

  /// Marks the entry removed, then calls `onDismissed` and completes
  /// [closed].
  ///
  /// The callback runs in a microtask, never synchronously: [finish] can be
  /// called while the widget tree is locked (for example when the host is
  /// unmounted), where a `setState` in the callback would throw. An
  /// exception thrown by the callback is reported to [FlutterError.onError]
  /// and [closed] still completes.
  void finish() {
    if (status == ToastEntryStatus.removed) {
      return;
    }
    status = ToastEntryStatus.removed;
    _progress.value = 0;
    final VoidCallback? onDismissed = _config.onDismissed;
    scheduleMicrotask(() {
      try {
        onDismissed?.call();
      } catch (exception, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'better_toast',
            context: ErrorDescription('while calling onDismissed of a toast'),
          ),
        );
      } finally {
        _closed.complete();
      }
    });
  }

  @override
  String toString() => 'ToastEntry($id, ${status.name})';
}

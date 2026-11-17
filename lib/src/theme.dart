import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'better_toast.dart';
import 'enums.dart';
import 'scope.dart';
import 'toast_handle.dart';
import 'toast_style.dart';

/// App-wide defaults for toasts.
///
/// Give it to [BetterToast.init] or [BetterToastScope], or add it to
/// [ThemeData.extensions]. Every field is optional; `null` means "use the
/// layer below". The layers are, later wins:
///
/// 1. [BetterToastThemeData.fallback].
/// 2. The [ThemeExtension] on the nearest [Theme].
/// 3. The `theme` of the [BetterToastScope].
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: const [
///       BetterToastThemeData(
///         position: ToastPosition.bottom,
///         maxVisible: 4,
///         defaultStyle: ToastStyle(showCloseButton: true),
///       ),
///     ],
///   ),
///   builder: BetterToast.init(),
/// );
/// ```
@immutable
class BetterToastThemeData extends ThemeExtension<BetterToastThemeData>
    with Diagnosticable {
  /// Creates a toast theme. Every argument is optional.
  const BetterToastThemeData({
    this.defaultStyle,
    this.typeStyles,
    this.position,
    this.animation,
    this.transitionBuilder,
    this.animationDuration,
    this.reverseAnimationDuration,
    this.animationCurve,
    this.duration,
    this.maxVisible,
    this.stackMode,
    this.spacing,
    this.margin,
    this.respectSafeArea,
    this.dismissible,
    this.pauseOnHover,
    this.pauseOnTouch,
    this.showProgressBar,
    this.builder,
  }) : assert(maxVisible == null || maxVisible > 0);

  /// The built-in defaults. Every field except [defaultStyle], [typeStyles],
  /// [transitionBuilder] and [builder] is set.
  static const BetterToastThemeData fallback = BetterToastThemeData(
    position: ToastPosition.top,
    animation: ToastAnimation.slideFade,
    animationDuration: Duration(milliseconds: 350),
    reverseAnimationDuration: Duration(milliseconds: 250),
    animationCurve: Curves.easeOutCubic,
    duration: Duration(seconds: 4),
    maxVisible: 3,
    stackMode: ToastStackMode.stack,
    spacing: 8,
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    respectSafeArea: true,
    dismissible: true,
    pauseOnHover: true,
    pauseOnTouch: true,
    showProgressBar: false,
  );

  /// Style overrides for every toast.
  final ToastStyle? defaultStyle;

  /// Style overrides for one [ToastType]. Merged over [defaultStyle].
  final Map<ToastType, ToastStyle>? typeStyles;

  /// Where toasts appear when the call does not say.
  final ToastPosition? position;

  /// The enter and exit animation when the call does not say.
  final ToastAnimation? animation;

  /// The transition used for [ToastAnimation.custom].
  final ToastTransitionBuilder? transitionBuilder;

  /// How long the enter animation takes.
  final Duration? animationDuration;

  /// How long the exit animation takes.
  final Duration? reverseAnimationDuration;

  /// The curve of the enter animation and of the stack reflow.
  final Curve? animationCurve;

  /// How long a toast stays visible when the call does not say.
  ///
  /// [Duration.zero] makes toasts sticky: they stay until dismissed.
  /// Loading toasts are always sticky unless the call gives a duration.
  final Duration? duration;

  /// The most toasts shown at the same time in [ToastStackMode.stack].
  /// Extra toasts wait in a queue. Counted per host, across positions.
  final int? maxVisible;

  /// How the host handles several toasts. See [ToastStackMode].
  final ToastStackMode? stackMode;

  /// The vertical gap between stacked toasts.
  final double? spacing;

  /// The space between the toasts and the screen edges.
  final EdgeInsetsGeometry? margin;

  /// Whether to keep toasts out of system UI such as the status bar and
  /// the notch.
  final bool? respectSafeArea;

  /// Whether toasts can be swiped away by default.
  final bool? dismissible;

  /// Whether the timer pauses while a mouse pointer hovers a toast.
  final bool? pauseOnHover;

  /// Whether the timer pauses while a toast is pressed.
  final bool? pauseOnTouch;

  /// Whether toasts show a bar with their remaining time.
  final bool? showProgressBar;

  /// Replaces the default toast visual for every toast that has no builder
  /// of its own. See [ToastBuilder].
  final ToastBuilder? builder;

  /// The resolved style for a toast of [type] with the per-call [style].
  ///
  /// Merges [ToastStyle.fallback], [defaultStyle], `typeStyles[type]` and
  /// [style], in this order.
  ToastStyle styleFor(ThemeData theme, ToastType type, [ToastStyle? style]) {
    return ToastStyle.fallback(theme, type)
        .merge(defaultStyle)
        .merge(typeStyles?[type])
        .merge(style);
  }

  /// Returns a copy of this theme where every non-null field of [other]
  /// wins. Styles are merged with [ToastStyle.merge].
  BetterToastThemeData merge(BetterToastThemeData? other) {
    if (other == null) {
      return this;
    }
    Map<ToastType, ToastStyle>? mergedTypeStyles = typeStyles;
    if (other.typeStyles != null) {
      mergedTypeStyles = <ToastType, ToastStyle>{...?typeStyles};
      other.typeStyles!.forEach((ToastType type, ToastStyle style) {
        mergedTypeStyles![type] = mergedTypeStyles[type]?.merge(style) ?? style;
      });
    }
    return BetterToastThemeData(
      defaultStyle:
          defaultStyle?.merge(other.defaultStyle) ?? other.defaultStyle,
      typeStyles: mergedTypeStyles,
      position: other.position ?? position,
      animation: other.animation ?? animation,
      transitionBuilder: other.transitionBuilder ?? transitionBuilder,
      animationDuration: other.animationDuration ?? animationDuration,
      reverseAnimationDuration:
          other.reverseAnimationDuration ?? reverseAnimationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
      duration: other.duration ?? duration,
      maxVisible: other.maxVisible ?? maxVisible,
      stackMode: other.stackMode ?? stackMode,
      spacing: other.spacing ?? spacing,
      margin: other.margin ?? margin,
      respectSafeArea: other.respectSafeArea ?? respectSafeArea,
      dismissible: other.dismissible ?? dismissible,
      pauseOnHover: other.pauseOnHover ?? pauseOnHover,
      pauseOnTouch: other.pauseOnTouch ?? pauseOnTouch,
      showProgressBar: other.showProgressBar ?? showProgressBar,
      builder: other.builder ?? builder,
    );
  }

  @override
  BetterToastThemeData copyWith({
    ToastStyle? defaultStyle,
    Map<ToastType, ToastStyle>? typeStyles,
    ToastPosition? position,
    ToastAnimation? animation,
    ToastTransitionBuilder? transitionBuilder,
    Duration? animationDuration,
    Duration? reverseAnimationDuration,
    Curve? animationCurve,
    Duration? duration,
    int? maxVisible,
    ToastStackMode? stackMode,
    double? spacing,
    EdgeInsetsGeometry? margin,
    bool? respectSafeArea,
    bool? dismissible,
    bool? pauseOnHover,
    bool? pauseOnTouch,
    bool? showProgressBar,
    ToastBuilder? builder,
  }) {
    return BetterToastThemeData(
      defaultStyle: defaultStyle ?? this.defaultStyle,
      typeStyles: typeStyles ?? this.typeStyles,
      position: position ?? this.position,
      animation: animation ?? this.animation,
      transitionBuilder: transitionBuilder ?? this.transitionBuilder,
      animationDuration: animationDuration ?? this.animationDuration,
      reverseAnimationDuration:
          reverseAnimationDuration ?? this.reverseAnimationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      duration: duration ?? this.duration,
      maxVisible: maxVisible ?? this.maxVisible,
      stackMode: stackMode ?? this.stackMode,
      spacing: spacing ?? this.spacing,
      margin: margin ?? this.margin,
      respectSafeArea: respectSafeArea ?? this.respectSafeArea,
      dismissible: dismissible ?? this.dismissible,
      pauseOnHover: pauseOnHover ?? this.pauseOnHover,
      pauseOnTouch: pauseOnTouch ?? this.pauseOnTouch,
      showProgressBar: showProgressBar ?? this.showProgressBar,
      builder: builder ?? this.builder,
    );
  }

  @override
  BetterToastThemeData lerp(
    covariant ThemeExtension<BetterToastThemeData>? other,
    double t,
  ) {
    if (other is! BetterToastThemeData) {
      return this;
    }
    T? pick<T>(T? a, T? b) => t < 0.5 ? a : b;
    Map<ToastType, ToastStyle>? styles;
    if (typeStyles != null || other.typeStyles != null) {
      styles = <ToastType, ToastStyle>{
        for (final ToastType type in ToastType.values)
          if (typeStyles?[type] != null || other.typeStyles?[type] != null)
            type: ToastStyle.lerp(
              typeStyles?[type],
              other.typeStyles?[type],
              t,
            )!,
      };
    }
    return BetterToastThemeData(
      defaultStyle: ToastStyle.lerp(defaultStyle, other.defaultStyle, t),
      typeStyles: styles,
      position: pick(position, other.position),
      animation: pick(animation, other.animation),
      transitionBuilder: pick(transitionBuilder, other.transitionBuilder),
      animationDuration: pick(animationDuration, other.animationDuration),
      reverseAnimationDuration:
          pick(reverseAnimationDuration, other.reverseAnimationDuration),
      animationCurve: pick(animationCurve, other.animationCurve),
      duration: pick(duration, other.duration),
      maxVisible: pick(maxVisible, other.maxVisible),
      stackMode: pick(stackMode, other.stackMode),
      spacing: lerpDouble(spacing, other.spacing, t),
      margin: EdgeInsetsGeometry.lerp(margin, other.margin, t),
      respectSafeArea: pick(respectSafeArea, other.respectSafeArea),
      dismissible: pick(dismissible, other.dismissible),
      pauseOnHover: pick(pauseOnHover, other.pauseOnHover),
      pauseOnTouch: pick(pauseOnTouch, other.pauseOnTouch),
      showProgressBar: pick(showProgressBar, other.showProgressBar),
      builder: pick(builder, other.builder),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is BetterToastThemeData &&
        other.runtimeType == runtimeType &&
        other.defaultStyle == defaultStyle &&
        mapEquals(other.typeStyles, typeStyles) &&
        other.position == position &&
        other.animation == animation &&
        other.transitionBuilder == transitionBuilder &&
        other.animationDuration == animationDuration &&
        other.reverseAnimationDuration == reverseAnimationDuration &&
        other.animationCurve == animationCurve &&
        other.duration == duration &&
        other.maxVisible == maxVisible &&
        other.stackMode == stackMode &&
        other.spacing == spacing &&
        other.margin == margin &&
        other.respectSafeArea == respectSafeArea &&
        other.dismissible == dismissible &&
        other.pauseOnHover == pauseOnHover &&
        other.pauseOnTouch == pauseOnTouch &&
        other.showProgressBar == showProgressBar &&
        other.builder == builder;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
        defaultStyle,
        typeStyles == null
            ? null
            : Object.hashAllUnordered(
                typeStyles!.entries.map(
                  (MapEntry<ToastType, ToastStyle> e) =>
                      Object.hash(e.key, e.value),
                ),
              ),
        position,
        animation,
        transitionBuilder,
        animationDuration,
        reverseAnimationDuration,
        animationCurve,
        duration,
        maxVisible,
        stackMode,
        spacing,
        margin,
        respectSafeArea,
        dismissible,
        pauseOnHover,
        pauseOnTouch,
        showProgressBar,
        builder,
      ]);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
          EnumProperty<ToastPosition>('position', position, defaultValue: null))
      ..add(EnumProperty<ToastAnimation>('animation', animation,
          defaultValue: null))
      ..add(DiagnosticsProperty<Duration>('duration', duration,
          defaultValue: null))
      ..add(IntProperty('maxVisible', maxVisible, defaultValue: null))
      ..add(EnumProperty<ToastStackMode>('stackMode', stackMode,
          defaultValue: null))
      ..add(DoubleProperty('spacing', spacing, defaultValue: null))
      ..add(DiagnosticsProperty<ToastStyle>('defaultStyle', defaultStyle,
          defaultValue: null));
  }
}

/// Looks up the effective [BetterToastThemeData].
///
/// ```dart
/// final theme = BetterToastTheme.of(context);
/// final style = BetterToastTheme.resolveStyle(context, handle.type);
/// ```
abstract final class BetterToastTheme {
  /// The effective toast theme for [context].
  ///
  /// Combines [BetterToastThemeData.fallback], the [ThemeExtension] on the
  /// nearest [Theme], and the theme of the nearest [BetterToastScope]. All
  /// fields that [BetterToastThemeData.fallback] sets are non-null in the
  /// result.
  static BetterToastThemeData of(BuildContext context) {
    final BetterToastThemeData? scopeTheme =
        context.dependOnInheritedWidgetOfExactType<ToastScopeMarker>()?.theme;
    return resolveToastTheme(context, scopeTheme);
  }

  /// The fully resolved style for a toast of [type] with the per-call
  /// [style], as the default toast visual would use it.
  ///
  /// Handy in a [ToastBuilder] that wants to reuse the theme colors.
  static ToastStyle resolveStyle(
    BuildContext context,
    ToastType type, [
    ToastStyle? style,
  ]) {
    return of(context).styleFor(Theme.of(context), type, style);
  }
}

/// Combines the fallback theme, the [ThemeExtension] and [scopeTheme].
BetterToastThemeData resolveToastTheme(
  BuildContext context,
  BetterToastThemeData? scopeTheme,
) {
  return BetterToastThemeData.fallback
      .merge(Theme.of(context).extension<BetterToastThemeData>())
      .merge(scopeTheme);
}

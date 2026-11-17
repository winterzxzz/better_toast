import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'enums.dart';
import 'theme.dart';

/// Visual overrides for a toast.
///
/// Every field is optional. A `null` field means "inherit from the layer
/// below". Styles are resolved in this order, later layers win:
///
/// 1. [ToastStyle.fallback], the built-in look derived from the app's
///    [ColorScheme] (light and dark).
/// 2. [BetterToastThemeData.defaultStyle], for every toast.
/// 3. [BetterToastThemeData.typeStyles], for one [ToastType].
/// 4. The `style` argument of a single `BetterToast.show` call.
///
/// ```dart
/// BetterToast.success(
///   'Saved',
///   style: const ToastStyle(
///     backgroundColor: Color(0xFF0F172A),
///     foregroundColor: Colors.white,
///     borderRadius: BorderRadius.all(Radius.circular(24)),
///   ),
/// );
/// ```
@immutable
class ToastStyle with Diagnosticable {
  /// Creates a toast style. Every argument is optional.
  const ToastStyle({
    this.backgroundColor,
    this.gradient,
    this.foregroundColor,
    this.iconColor,
    this.icon,
    this.showIcon,
    this.iconSize,
    this.titleStyle,
    this.messageStyle,
    this.descriptionStyle,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border,
    this.shadows,
    this.blur,
    this.elevation,
    this.width,
    this.maxWidth,
    this.contentAlignment,
    this.progressBarColor,
    this.progressBarBackgroundColor,
    this.progressBarHeight,
    this.showCloseButton,
    this.closeIcon,
    this.actionStyle,
  });

  /// The fill color of the toast card.
  ///
  /// When a layer sets [backgroundColor] but not [gradient], the gradient of
  /// lower layers is dropped, so the more specific color is visible.
  final Color? backgroundColor;

  /// A gradient fill for the toast card. Wins over [backgroundColor].
  final Gradient? gradient;

  /// The default color for text and the close button.
  final Color? foregroundColor;

  /// The color of the leading icon. Defaults to the accent of the type.
  final Color? iconColor;

  /// Replaces the default leading icon of the type.
  final Widget? icon;

  /// Whether to show the leading icon.
  final bool? showIcon;

  /// The size of the leading icon.
  final double? iconSize;

  /// The style of the title. Merged over lower layers with [TextStyle.merge].
  final TextStyle? titleStyle;

  /// The style of the message. Merged over lower layers with
  /// [TextStyle.merge].
  final TextStyle? messageStyle;

  /// The style of the description. Merged over lower layers with
  /// [TextStyle.merge].
  final TextStyle? descriptionStyle;

  /// The space between the card edge and its content.
  final EdgeInsetsGeometry? padding;

  /// The space around the card.
  final EdgeInsetsGeometry? margin;

  /// The corner radius of the card.
  final BorderRadiusGeometry? borderRadius;

  /// The border of the card.
  final BoxBorder? border;

  /// The shadows of the card. When set, [elevation] is ignored.
  final List<BoxShadow>? shadows;

  /// The sigma of a backdrop blur behind the card, for a glass look.
  ///
  /// Use it with a translucent [backgroundColor]. `0` turns the blur off.
  final double? blur;

  /// A simple way to get a soft shadow. Ignored when [shadows] is set.
  final double? elevation;

  /// A fixed width for the card. When `null`, the card fills the available
  /// width up to [maxWidth].
  final double? width;

  /// The maximum width of the card.
  final double? maxWidth;

  /// The horizontal alignment of the title, message and description.
  final CrossAxisAlignment? contentAlignment;

  /// The color of the progress bar.
  final Color? progressBarColor;

  /// The color of the track behind the progress bar.
  final Color? progressBarBackgroundColor;

  /// The height of the progress bar.
  final double? progressBarHeight;

  /// Whether to show a close button.
  final bool? showCloseButton;

  /// Replaces the default close icon.
  final Widget? closeIcon;

  /// The style of the action button. Merged over lower layers with
  /// [ButtonStyle.merge].
  final ButtonStyle? actionStyle;

  /// The built-in look for [type], derived from [theme].
  ///
  /// Every field of the result is set, except [gradient], [icon], [width],
  /// [shadows], [closeIcon] and [actionStyle]. The colors follow
  /// [ThemeData.colorScheme], so light and dark themes both work.
  static ToastStyle fallback(ThemeData theme, ToastType type) {
    final ColorScheme scheme = theme.colorScheme;
    final bool dark = scheme.brightness == Brightness.dark;
    final Color accent = accentColor(scheme, type);
    return ToastStyle(
      backgroundColor:
          dark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
      foregroundColor: scheme.onSurface,
      iconColor: accent,
      showIcon: type != ToastType.custom,
      iconSize: 22,
      titleStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      messageStyle: const TextStyle(fontSize: 14, height: 1.35),
      descriptionStyle: const TextStyle(fontSize: 13, height: 1.35),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: EdgeInsets.zero,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      border: Border.all(
        color: scheme.outlineVariant.withValues(alpha: dark ? 0.6 : 0.5),
      ),
      blur: 0,
      elevation: 6,
      maxWidth: 420,
      contentAlignment: CrossAxisAlignment.start,
      progressBarColor: accent,
      progressBarBackgroundColor: accent.withValues(alpha: 0.15),
      progressBarHeight: 3,
      showCloseButton: false,
    );
  }

  /// The accent color the built-in look uses for [type] in [scheme].
  static Color accentColor(ColorScheme scheme, ToastType type) {
    final bool dark = scheme.brightness == Brightness.dark;
    return switch (type) {
      ToastType.info => scheme.primary,
      ToastType.success =>
        dark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
      ToastType.warning =>
        dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
      ToastType.error => scheme.error,
      ToastType.loading => scheme.onSurfaceVariant,
      ToastType.custom => scheme.primary,
    };
  }

  /// Returns a copy of this style where every non-null field of [other]
  /// wins.
  ///
  /// Text styles and [actionStyle] are merged field by field instead of
  /// replaced. If [other] sets [backgroundColor] without [gradient], the
  /// result has no gradient.
  ToastStyle merge(ToastStyle? other) {
    if (other == null) {
      return this;
    }
    final bool dropGradient =
        other.backgroundColor != null && other.gradient == null;
    return ToastStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      gradient: dropGradient ? null : (other.gradient ?? gradient),
      foregroundColor: other.foregroundColor ?? foregroundColor,
      iconColor: other.iconColor ?? iconColor,
      icon: other.icon ?? icon,
      showIcon: other.showIcon ?? showIcon,
      iconSize: other.iconSize ?? iconSize,
      titleStyle: titleStyle?.merge(other.titleStyle) ?? other.titleStyle,
      messageStyle:
          messageStyle?.merge(other.messageStyle) ?? other.messageStyle,
      descriptionStyle: descriptionStyle?.merge(other.descriptionStyle) ??
          other.descriptionStyle,
      padding: other.padding ?? padding,
      margin: other.margin ?? margin,
      borderRadius: other.borderRadius ?? borderRadius,
      border: other.border ?? border,
      shadows: other.shadows ?? shadows,
      blur: other.blur ?? blur,
      elevation: other.elevation ?? elevation,
      width: other.width ?? width,
      maxWidth: other.maxWidth ?? maxWidth,
      contentAlignment: other.contentAlignment ?? contentAlignment,
      progressBarColor: other.progressBarColor ?? progressBarColor,
      progressBarBackgroundColor:
          other.progressBarBackgroundColor ?? progressBarBackgroundColor,
      progressBarHeight: other.progressBarHeight ?? progressBarHeight,
      showCloseButton: other.showCloseButton ?? showCloseButton,
      closeIcon: other.closeIcon ?? closeIcon,
      actionStyle: other.actionStyle?.merge(actionStyle) ?? actionStyle,
    );
  }

  /// Returns a copy of this style with the given fields replaced.
  ToastStyle copyWith({
    Color? backgroundColor,
    Gradient? gradient,
    Color? foregroundColor,
    Color? iconColor,
    Widget? icon,
    bool? showIcon,
    double? iconSize,
    TextStyle? titleStyle,
    TextStyle? messageStyle,
    TextStyle? descriptionStyle,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadiusGeometry? borderRadius,
    BoxBorder? border,
    List<BoxShadow>? shadows,
    double? blur,
    double? elevation,
    double? width,
    double? maxWidth,
    CrossAxisAlignment? contentAlignment,
    Color? progressBarColor,
    Color? progressBarBackgroundColor,
    double? progressBarHeight,
    bool? showCloseButton,
    Widget? closeIcon,
    ButtonStyle? actionStyle,
  }) {
    return ToastStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gradient: gradient ?? this.gradient,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      iconColor: iconColor ?? this.iconColor,
      icon: icon ?? this.icon,
      showIcon: showIcon ?? this.showIcon,
      iconSize: iconSize ?? this.iconSize,
      titleStyle: titleStyle ?? this.titleStyle,
      messageStyle: messageStyle ?? this.messageStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      padding: padding ?? this.padding,
      margin: margin ?? this.margin,
      borderRadius: borderRadius ?? this.borderRadius,
      border: border ?? this.border,
      shadows: shadows ?? this.shadows,
      blur: blur ?? this.blur,
      elevation: elevation ?? this.elevation,
      width: width ?? this.width,
      maxWidth: maxWidth ?? this.maxWidth,
      contentAlignment: contentAlignment ?? this.contentAlignment,
      progressBarColor: progressBarColor ?? this.progressBarColor,
      progressBarBackgroundColor:
          progressBarBackgroundColor ?? this.progressBarBackgroundColor,
      progressBarHeight: progressBarHeight ?? this.progressBarHeight,
      showCloseButton: showCloseButton ?? this.showCloseButton,
      closeIcon: closeIcon ?? this.closeIcon,
      actionStyle: actionStyle ?? this.actionStyle,
    );
  }

  /// Linearly interpolates between two styles.
  ///
  /// Fields that cannot be interpolated, such as [icon] or [showIcon],
  /// switch from [a] to [b] at `t == 0.5`. A size, such as [maxWidth],
  /// [padding] or [borderRadius], that is set on one side only keeps that
  /// value instead of shrinking toward zero.
  static ToastStyle? lerp(ToastStyle? a, ToastStyle? b, double t) {
    if (identical(a, b)) {
      return a;
    }
    a ??= const ToastStyle();
    b ??= const ToastStyle();
    T? pick<T>(T? x, T? y) => t < 0.5 ? x : y;
    return ToastStyle(
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      gradient: Gradient.lerp(a.gradient, b.gradient, t),
      foregroundColor: Color.lerp(a.foregroundColor, b.foregroundColor, t),
      iconColor: Color.lerp(a.iconColor, b.iconColor, t),
      icon: pick(a.icon, b.icon),
      showIcon: pick(a.showIcon, b.showIcon),
      iconSize: lerpSize(a.iconSize, b.iconSize, t, lerpDouble),
      titleStyle: TextStyle.lerp(a.titleStyle, b.titleStyle, t),
      messageStyle: TextStyle.lerp(a.messageStyle, b.messageStyle, t),
      descriptionStyle:
          TextStyle.lerp(a.descriptionStyle, b.descriptionStyle, t),
      padding: lerpSize(a.padding, b.padding, t, EdgeInsetsGeometry.lerp),
      margin: lerpSize(a.margin, b.margin, t, EdgeInsetsGeometry.lerp),
      borderRadius: lerpSize(
          a.borderRadius, b.borderRadius, t, BorderRadiusGeometry.lerp),
      border: BoxBorder.lerp(a.border, b.border, t),
      shadows: BoxShadow.lerpList(a.shadows, b.shadows, t),
      blur: lerpSize(a.blur, b.blur, t, lerpDouble),
      elevation: lerpSize(a.elevation, b.elevation, t, lerpDouble),
      width: lerpSize(a.width, b.width, t, lerpDouble),
      maxWidth: lerpSize(a.maxWidth, b.maxWidth, t, lerpDouble),
      contentAlignment: pick(a.contentAlignment, b.contentAlignment),
      progressBarColor: Color.lerp(a.progressBarColor, b.progressBarColor, t),
      progressBarBackgroundColor: Color.lerp(
        a.progressBarBackgroundColor,
        b.progressBarBackgroundColor,
        t,
      ),
      progressBarHeight:
          lerpSize(a.progressBarHeight, b.progressBarHeight, t, lerpDouble),
      showCloseButton: pick(a.showCloseButton, b.showCloseButton),
      closeIcon: pick(a.closeIcon, b.closeIcon),
      actionStyle: ButtonStyle.lerp(a.actionStyle, b.actionStyle, t),
    );
  }

  List<Object?> get _props => <Object?>[
        backgroundColor,
        gradient,
        foregroundColor,
        iconColor,
        icon,
        showIcon,
        iconSize,
        titleStyle,
        messageStyle,
        descriptionStyle,
        padding,
        margin,
        borderRadius,
        border,
        shadows == null ? null : Object.hashAll(shadows!),
        blur,
        elevation,
        width,
        maxWidth,
        contentAlignment,
        progressBarColor,
        progressBarBackgroundColor,
        progressBarHeight,
        showCloseButton,
        closeIcon,
        actionStyle,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ToastStyle &&
        other.runtimeType == runtimeType &&
        listEquals(other.shadows, shadows) &&
        listEquals(other._props, _props);
  }

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
          ColorProperty('backgroundColor', backgroundColor, defaultValue: null))
      ..add(DiagnosticsProperty<Gradient>('gradient', gradient,
          defaultValue: null))
      ..add(
          ColorProperty('foregroundColor', foregroundColor, defaultValue: null))
      ..add(ColorProperty('iconColor', iconColor, defaultValue: null))
      ..add(DoubleProperty('blur', blur, defaultValue: null))
      ..add(DoubleProperty('elevation', elevation, defaultValue: null))
      ..add(DoubleProperty('width', width, defaultValue: null))
      ..add(DoubleProperty('maxWidth', maxWidth, defaultValue: null))
      ..add(DiagnosticsProperty<BorderRadiusGeometry>(
          'borderRadius', borderRadius,
          defaultValue: null))
      ..add(FlagProperty('showCloseButton',
          value: showCloseButton, ifTrue: 'close button'));
  }
}

/// Interpolates a size field with [lerp], but when only one side is set,
/// returns that side unchanged instead of shrinking it toward zero.
///
/// A `null` size means "inherit", not zero. Internal; not exported.
T? lerpSize<T extends Object>(
  T? a,
  T? b,
  double t,
  T? Function(T? a, T? b, double t) lerp,
) {
  if (a == null || b == null) {
    return a ?? b;
  }
  return lerp(a, b, t);
}

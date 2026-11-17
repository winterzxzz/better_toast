import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'entry.dart';
import 'enums.dart';
import 'theme.dart';
import 'toast_action.dart';
import 'toast_handle.dart';
import 'toast_style.dart';

/// One toast on screen: animation, timer, gestures and semantics around
/// the toast visual.
///
/// Internal; not exported.
class ToastItem extends StatefulWidget {
  /// Creates the widget for [entry].
  const ToastItem({
    super.key,
    required this.entry,
    required this.theme,
    required this.position,
  });

  /// The toast to show.
  final ToastEntry entry;

  /// The resolved theme of the host.
  final BetterToastThemeData theme;

  /// The resolved position.
  final ToastPosition position;

  @override
  State<ToastItem> createState() => _ToastItemState();
}

class _ToastItemState extends State<ToastItem> with TickerProviderStateMixin {
  late final AnimationController _visibility;
  late CurvedAnimation _curved;
  AnimationController? _timer;
  int _version = -1;
  bool _started = false;
  bool _exiting = false;
  bool _hovered = false;
  bool _pressed = false;
  bool _dragging = false;
  bool _accessibleNavigation = false;

  ToastEntry get _entry => widget.entry;
  ToastConfig get _config => _entry.config;
  BetterToastThemeData get _theme => widget.theme;

  @override
  void initState() {
    super.initState();
    // A toast moved to another position gets a new widget, created before
    // the old one is disposed. Claim the entry; the old state only releases
    // it if it still owns it. The new widget plays the enter animation at
    // its new position.
    _entry
      ..owner = this
      ..addListener(_handleEntryChanged);
    _entry.host.appResumed.addListener(_syncTimer);
    _visibility = AnimationController(vsync: this);
    _curved = _createCurve();
  }

  CurvedAnimation _createCurve() {
    return CurvedAnimation(
      parent: _visibility,
      curve: _theme.animationCurve!,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDurations();
    final bool accessibleNavigation =
        MediaQuery.accessibleNavigationOf(context);
    if (accessibleNavigation != _accessibleNavigation) {
      _accessibleNavigation = accessibleNavigation;
      if (_started && _config.action != null && !_exiting) {
        _restartTimer();
      }
    }
    if (!_started) {
      _started = true;
      _version = _entry.version;
      _restartTimer();
      if (_entry.status == ToastEntryStatus.exiting) {
        _startExit();
      } else {
        _visibility.forward();
      }
    }
  }

  @override
  void didUpdateWidget(ToastItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme.animationCurve != _theme.animationCurve) {
      _curved.dispose();
      _curved = _createCurve();
    }
    _updateDurations();
    _syncTimer();
  }

  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _updateDurations() {
    final bool off = _reduceMotion || _resolvedAnimation == ToastAnimation.none;
    _visibility
      ..duration = off ? Duration.zero : _theme.animationDuration
      ..reverseDuration = off ? Duration.zero : _theme.reverseAnimationDuration;
  }

  ToastAnimation get _resolvedAnimation =>
      _config.animation ?? _theme.animation!;

  Duration? get _resolvedDuration {
    // Like SnackBar: a toast with an action stays until closed while an
    // accessibility service navigates the screen, so the action stays
    // reachable.
    if (_accessibleNavigation && _config.action != null) {
      return null;
    }
    final Duration? duration = _config.duration ??
        (_config.type == ToastType.loading ? null : _theme.duration);
    if (duration == null || duration <= Duration.zero) {
      return null;
    }
    return duration;
  }

  bool get _shouldPause {
    final bool pauseOnHover = _config.pauseOnHover ?? _theme.pauseOnHover!;
    final bool pauseOnTouch = _config.pauseOnTouch ?? _theme.pauseOnTouch!;
    return _entry.manuallyPaused ||
        !_entry.host.appResumed.value ||
        _dragging ||
        (pauseOnHover && _hovered) ||
        (pauseOnTouch && _pressed);
  }

  void _restartTimer() {
    _timer?.dispose();
    _timer = null;
    _entry.progressNotifier.value = 1;
    final Duration? duration = _resolvedDuration;
    if (duration == null) {
      return;
    }
    // `preserve` keeps the real display time even when the platform asks
    // to shorten animations for accessibility.
    final AnimationController timer = AnimationController(
      vsync: this,
      duration: duration,
      animationBehavior: AnimationBehavior.preserve,
    );
    timer
      ..addListener(() {
        _entry.progressNotifier.value = 1 - timer.value;
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          _entry.dismiss();
        }
      });
    _timer = timer;
    _syncTimer();
  }

  void _syncTimer() {
    final AnimationController? timer = _timer;
    if (timer == null) {
      return;
    }
    if (_exiting || _shouldPause) {
      timer.stop();
    } else if (!timer.isAnimating && timer.value < 1) {
      timer.forward();
    }
  }

  void _handleEntryChanged() {
    if (!mounted) {
      return;
    }
    if (_entry.status == ToastEntryStatus.exiting) {
      _startExit();
    } else if (_entry.version != _version) {
      _version = _entry.version;
      _updateDurations();
      _restartTimer();
    } else {
      _syncTimer();
    }
    setState(() {});
  }

  void _startExit() {
    if (_exiting) {
      return;
    }
    _exiting = true;
    _timer?.stop();
    _visibility.reverse().whenCompleteOrCancel(() {
      _entry.host.removeEntry(_entry);
    });
  }

  void _setHovered(bool value) {
    if (!mounted) {
      return;
    }
    _hovered = value;
    _syncTimer();
  }

  void _setPressed(bool value) {
    if (!mounted) {
      return;
    }
    _pressed = value;
    _syncTimer();
  }

  @override
  void dispose() {
    _entry.removeListener(_handleEntryChanged);
    _entry.host.appResumed.removeListener(_syncTimer);
    if (identical(_entry.owner, this)) {
      _entry.owner = null;
    }
    _timer?.dispose();
    _curved.dispose();
    _visibility.dispose();
    super.dispose();
  }

  DismissDirection get _swipeDirection {
    if (widget.position.isTop) {
      return DismissDirection.up;
    }
    if (widget.position.isBottom) {
      return DismissDirection.down;
    }
    return DismissDirection.horizontal;
  }

  bool get _isCorner =>
      widget.position != ToastPosition.top &&
      widget.position != ToastPosition.bottom &&
      widget.position != ToastPosition.center;

  @override
  Widget build(BuildContext context) {
    final ToastBuilder? builder = _config.builder ??
        (_config.type == ToastType.custom ? null : _theme.builder);
    Widget toast;
    if (builder != null) {
      toast = Builder(
        builder: (BuildContext context) => builder(context, _entry),
      );
    } else {
      toast = DefaultToastView(
        entry: _entry,
        style: _theme.styleFor(Theme.of(context), _config.type, _config.style),
        showProgressBar: (_config.showProgressBar ?? _theme.showProgressBar!) &&
            _resolvedDuration != null,
      );
    }

    toast = Semantics(container: true, liveRegion: true, child: toast);
    toast = Material(type: MaterialType.transparency, child: toast);

    if (_config.onTap != null) {
      toast = GestureDetector(onTap: _config.onTap, child: toast);
    }

    toast = MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: toast,
      ),
    );

    // Keep the Dismissible in the tree while exiting, so the widgets below
    // keep their state; only turn swiping off.
    if (_config.dismissible ?? _theme.dismissible!) {
      toast = Dismissible(
        key: ObjectKey(_entry),
        direction: _exiting
            ? DismissDirection.none
            : _isCorner
                ? DismissDirection.horizontal
                : _swipeDirection,
        onUpdate: (DismissUpdateDetails details) {
          final bool dragging = details.progress > 0;
          if (dragging != _dragging) {
            _dragging = dragging;
            _syncTimer();
          }
        },
        onDismissed: (_) {
          _exiting = true;
          _entry.status = ToastEntryStatus.exiting;
          _entry.host.removeEntry(_entry);
        },
        child: toast,
      );
    }

    toast = _transition(context, toast);

    final double spacing = _theme.spacing!;
    final bool top = widget.position.isTop;
    toast = Padding(
      padding: top
          ? EdgeInsets.only(bottom: spacing)
          : EdgeInsets.only(top: spacing),
      child: toast,
    );

    // Grows and shrinks the slot, so neighbors reflow smoothly. No clip,
    // so shadows stay visible.
    return AnimatedBuilder(
      animation: _curved,
      builder: (BuildContext context, Widget? child) {
        return Align(
          alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
          widthFactor: 1,
          heightFactor: _curved.value.clamp(0.0, 1.0),
          child: child,
        );
      },
      child: toast,
    );
  }

  Widget _transition(BuildContext context, Widget child) {
    final Animation<double> animation = _curved;
    final Offset from = widget.position.isTop
        ? const Offset(0, -1)
        : widget.position.isBottom
            ? const Offset(0, 1)
            : const Offset(0, 0.5);
    switch (_reduceMotion ? ToastAnimation.none : _resolvedAnimation) {
      case ToastAnimation.none:
        return child;
      case ToastAnimation.fade:
        return FadeTransition(opacity: animation, child: child);
      case ToastAnimation.slide:
        return SlideTransition(
          position:
              Tween<Offset>(begin: from, end: Offset.zero).animate(animation),
          child: child,
        );
      case ToastAnimation.scale:
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1).animate(animation),
            child: child,
          ),
        );
      case ToastAnimation.slideFade:
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: from * 0.5, end: Offset.zero)
                .animate(animation),
            child: child,
          ),
        );
      case ToastAnimation.custom:
        final ToastTransitionBuilder? builder =
            _config.transitionBuilder ?? _theme.transitionBuilder;
        if (builder == null) {
          return FadeTransition(opacity: animation, child: child);
        }
        return builder(context, animation, widget.position, child);
    }
  }
}

/// The built-in toast visual: icon, texts, action, close button and
/// progress bar on a card.
///
/// Internal; not exported.
class DefaultToastView extends StatelessWidget {
  /// Creates the default visual for [entry] with a fully resolved [style].
  const DefaultToastView({
    super.key,
    required this.entry,
    required this.style,
    required this.showProgressBar,
  });

  /// The toast to show.
  final ToastEntry entry;

  /// The resolved style. Fields set by [ToastStyle.fallback] are non-null.
  final ToastStyle style;

  /// Whether to draw the remaining-time bar.
  final bool showProgressBar;

  @override
  Widget build(BuildContext context) {
    final ToastStyle s = style;
    final Color foreground = s.foregroundColor!;
    final CrossAxisAlignment alignment = s.contentAlignment!;
    final TextAlign textAlign = switch (alignment) {
      CrossAxisAlignment.center => TextAlign.center,
      CrossAxisAlignment.end => TextAlign.end,
      _ => TextAlign.start,
    };
    final TextStyle titleStyle =
        TextStyle(color: foreground).merge(s.titleStyle);
    final TextStyle messageStyle =
        TextStyle(color: foreground).merge(s.messageStyle);
    final TextStyle descriptionStyle =
        TextStyle(color: foreground.withValues(alpha: foreground.a * 0.75))
            .merge(s.descriptionStyle);

    final List<Widget> texts = <Widget>[
      if (entry.title != null)
        Text(entry.title!, style: titleStyle, textAlign: textAlign),
      if (entry.text != null)
        Text(entry.text!, style: messageStyle, textAlign: textAlign),
      if (entry.message != null)
        DefaultTextStyle.merge(
          style: messageStyle,
          textAlign: textAlign,
          child: entry.message!,
        ),
      if (entry.description != null)
        Text(entry.description!, style: descriptionStyle, textAlign: textAlign),
    ];

    final Widget? icon = s.showIcon! ? _icon(s) : null;
    final _TapTargetLink closeLink = _TapTargetLink();
    final ToastAction? action = entry.action;
    final List<Widget> row = <Widget>[
      if (icon != null) ...<Widget>[icon, const SizedBox(width: 12)],
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alignment == CrossAxisAlignment.stretch ||
                  alignment == CrossAxisAlignment.baseline
              ? CrossAxisAlignment.start
              : alignment,
          children: _spaced(texts),
        ),
      ),
      if (action != null) ...<Widget>[
        const SizedBox(width: 8),
        TextButton(
          style: s.actionStyle?.merge(_actionBaseStyle(context, s)) ??
              _actionBaseStyle(context, s),
          onPressed: () {
            action.onPressed();
            if (action.dismissOnPressed) {
              entry.dismiss();
            }
          },
          child: Text(action.label),
        ),
      ],
      if (s.showCloseButton!) ...<Widget>[
        const SizedBox(width: 4),
        _CloseButton(
          color: foreground.withValues(alpha: foreground.a * 0.7),
          icon: s.closeIcon,
          onPressed: entry.dismiss,
          link: closeLink,
        ),
      ],
    ];

    final bool multiline = texts.length > 1;
    Widget content = Padding(
      padding: s.padding!,
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: row,
      ),
    );
    if (s.showCloseButton!) {
      content = _TapTargetArea(link: closeLink, child: content);
    }

    if (showProgressBar) {
      content = Stack(
        children: <Widget>[
          content,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: s.progressBarHeight,
            child: ColoredBox(
              color: s.progressBarBackgroundColor!,
              child: ValueListenableBuilder<double>(
                valueListenable: entry.progress,
                builder: (BuildContext context, double value, Widget? _) {
                  return FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: value.clamp(0.0, 1.0),
                    child: ColoredBox(color: s.progressBarColor!),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    final double blur = s.blur!;
    if (blur > 0) {
      content = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      );
    }

    final double elevation = s.elevation!;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final List<BoxShadow>? shadows = s.shadows ??
        (elevation <= 0
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.36 : 0.10),
                  blurRadius: elevation * 4,
                  spreadRadius: -elevation / 2,
                  offset: Offset(0, elevation * 0.75),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
                  blurRadius: elevation / 2,
                  offset: Offset(0, elevation / 6),
                ),
              ]);

    return Padding(
      padding: s.margin!,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: s.maxWidth!),
        child: SizedBox(
          width: s.width ?? double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: s.backgroundColor,
              gradient: s.gradient,
              borderRadius: s.borderRadius,
              border: s.border,
              boxShadow: shadows,
            ),
            child: ClipRRect(
              borderRadius: s.borderRadius!,
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  static ButtonStyle _actionBaseStyle(BuildContext context, ToastStyle s) {
    // Extend the theme's button text style, so the app font is kept.
    final TextStyle label =
        Theme.of(context).textTheme.labelLarge ?? const TextStyle();
    return TextButton.styleFrom(
      foregroundColor: s.iconColor,
      visualDensity: VisualDensity.compact,
      textStyle: label.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _icon(ToastStyle s) {
    final double size = s.iconSize!;
    final Widget icon;
    if (s.icon != null) {
      icon = s.icon!;
    } else if (entry.type == ToastType.loading) {
      icon = SizedBox.square(
        dimension: size * 0.82,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: s.iconColor),
      );
    } else {
      icon = Icon(switch (entry.type) {
        ToastType.success => Icons.check_circle_rounded,
        ToastType.warning => Icons.warning_rounded,
        ToastType.error => Icons.error_rounded,
        ToastType.info ||
        ToastType.loading ||
        ToastType.custom =>
          Icons.info_rounded,
      });
    }
    return IconTheme.merge(
      data: IconThemeData(color: s.iconColor, size: size),
      child: SizedBox.square(dimension: size, child: Center(child: icon)),
    );
  }

  static List<Widget> _spaced(List<Widget> children) {
    return <Widget>[
      for (int i = 0; i < children.length; i++) ...<Widget>[
        if (i > 0) const SizedBox(height: 2),
        children[i],
      ],
    ];
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({
    required this.color,
    required this.icon,
    required this.onPressed,
    required this.link,
  });

  final Color color;
  final Widget? icon;
  final VoidCallback onPressed;
  final _TapTargetLink link;

  @override
  Widget build(BuildContext context) {
    final String label = Localizations.of<MaterialLocalizations>(
          context,
          MaterialLocalizations,
        )?.closeButtonTooltip ??
        'Close';
    return _TapTarget(
      link: link,
      label: label,
      textDirection: Directionality.of(context),
      onTap: onPressed,
      child: InkResponse(
        onTap: onPressed,
        radius: 18,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: IconTheme.merge(
            data: IconThemeData(color: color, size: 18),
            child: icon ?? const Icon(Icons.close_rounded),
          ),
        ),
      ),
    );
  }
}

/// The minimum tap target of the close button, as in Material.
const double _kMinTapTarget = kMinInteractiveDimension;

/// Connects a [_TapTarget] to the [_TapTargetArea] around it.
class _TapTargetLink {
  _RenderTapTarget? target;
}

/// Lets taps near the close button reach it, without changing layout.
///
/// Wraps the padded toast content. A tap that hits nothing else inside this
/// area, but falls within the enlarged rectangle of the linked target, is
/// sent to the center of the target.
class _TapTargetArea extends SingleChildRenderObjectWidget {
  const _TapTargetArea({required this.link, required super.child});

  final _TapTargetLink link;

  @override
  _RenderTapTargetArea createRenderObject(BuildContext context) =>
      _RenderTapTargetArea(link);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTapTargetArea renderObject,
  ) {
    renderObject.link = link;
  }
}

class _RenderTapTargetArea extends RenderProxyBox {
  _RenderTapTargetArea(this.link);

  _TapTargetLink link;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) {
      return true;
    }
    final _RenderTapTarget? target = link.target;
    if (target == null || !target.attached || !size.contains(position)) {
      return false;
    }
    final Matrix4 transform = target.getTransformTo(this);
    final Rect area =
        MatrixUtils.transformRect(transform, target.semanticBounds);
    if (!area.contains(position)) {
      return false;
    }
    return result.addWithPaintTransform(
      transform: transform,
      position: position,
      hitTest: (BoxHitTestResult result, Offset _) => target.hitTest(
        result,
        position: target.size.center(Offset.zero),
      ),
    );
  }
}

/// A button whose semantics and tap area are at least [_kMinTapTarget]
/// square, while it lays out and paints at the size of [child].
class _TapTarget extends SingleChildRenderObjectWidget {
  const _TapTarget({
    required this.link,
    required this.label,
    required this.textDirection,
    required this.onTap,
    required super.child,
  });

  final _TapTargetLink link;
  final String label;
  final TextDirection textDirection;
  final VoidCallback onTap;

  @override
  _RenderTapTarget createRenderObject(BuildContext context) {
    return _RenderTapTarget(
      link: link,
      label: label,
      textDirection: textDirection,
      onTap: onTap,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderTapTarget renderObject) {
    renderObject
      ..link = link
      ..label = label
      ..textDirection = textDirection
      ..onTap = onTap;
  }
}

class _RenderTapTarget extends RenderProxyBox {
  _RenderTapTarget({
    required _TapTargetLink link,
    required String label,
    required TextDirection textDirection,
    required this.onTap,
  })  : _link = link,
        _label = label,
        _textDirection = textDirection;

  _TapTargetLink _link;
  set link(_TapTargetLink value) {
    if (identical(value, _link)) {
      return;
    }
    if (identical(_link.target, this)) {
      _link.target = null;
    }
    _link = value;
    if (attached) {
      _link.target = this;
    }
  }

  String _label;
  set label(String value) {
    if (value == _label) {
      return;
    }
    _label = value;
    markNeedsSemanticsUpdate();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) {
      return;
    }
    _textDirection = value;
    markNeedsSemanticsUpdate();
  }

  VoidCallback onTap;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _link.target = this;
  }

  @override
  void detach() {
    if (identical(_link.target, this)) {
      _link.target = null;
    }
    super.detach();
  }

  @override
  Rect get semanticBounds => Rect.fromCenter(
        center: size.center(Offset.zero),
        width: math.max(size.width, _kMinTapTarget),
        height: math.max(size.height, _kMinTapTarget),
      );

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    // The label describes the button; the icon adds nothing.
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isButton = true
      ..label = _label
      ..textDirection = _textDirection
      ..onTap = () => onTap();
  }
}

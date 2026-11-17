import 'package:flutter/material.dart';

import 'better_toast.dart';
import 'entry.dart';
import 'enums.dart';
import 'theme.dart';
import 'toast_item.dart';

/// Hosts toasts for the widgets below it.
///
/// The scope puts an [Overlay] above [child], so toasts float over every
/// route and survive navigation. Most apps add it through
/// [BetterToast.init] instead:
///
/// ```dart
/// MaterialApp(builder: BetterToast.init(), home: const HomePage());
/// ```
///
/// Use the widget directly for an explicit host, for example around one
/// part of the screen or above a `WidgetsApp`:
///
/// ```dart
/// BetterToastScope(
///   theme: const BetterToastThemeData(position: ToastPosition.bottom),
///   child: MaterialApp(home: const HomePage()),
/// );
/// ```
///
/// A scope placed above [MaterialApp] cannot see the app's [Theme], so the
/// toasts use the default light theme. Prefer [BetterToast.init] or a scope
/// inside the app.
///
/// When several scopes are mounted, `BetterToast.show` uses the scope that
/// contains its `context` argument, or else the most recently mounted scope.
class BetterToastScope extends StatefulWidget {
  /// Creates a toast host around [child].
  const BetterToastScope({super.key, required this.child, this.theme});

  /// The widget below this scope, usually the app or its navigator.
  final Widget child;

  /// Toast theme overrides for this scope. Merged over the
  /// [BetterToastThemeData] extension of the ambient [Theme].
  final BetterToastThemeData? theme;

  @override
  State<BetterToastScope> createState() => ToastHost();
}

/// Marks the subtree of a [ToastHost], so `context` lookups find it.
///
/// Internal; not exported.
class ToastScopeMarker extends InheritedWidget {
  /// Creates a marker for [host].
  const ToastScopeMarker({
    super.key,
    required this.host,
    required this.theme,
    required super.child,
  });

  /// The host state.
  final ToastHost host;

  /// The theme given to the scope widget.
  final BetterToastThemeData? theme;

  @override
  bool updateShouldNotify(ToastScopeMarker oldWidget) =>
      host != oldWidget.host || theme != oldWidget.theme;
}

/// The state of [BetterToastScope]. Owns the toast list and the queue.
///
/// Internal; not exported.
class ToastHost extends State<BetterToastScope> {
  /// Every mounted host, oldest first.
  static final List<ToastHost> active = <ToastHost>[];

  /// The host that contains [context], if any.
  static ToastHost? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<ToastScopeMarker>()?.host;
  }

  final List<ToastEntry> _visible = <ToastEntry>[];
  final List<ToastEntry> _queue = <ToastEntry>[];
  late BetterToastThemeData _theme;
  bool _disposed = false;
  int _nextId = 0;

  late final OverlayEntry _childEntry = OverlayEntry(
    builder: (BuildContext context) => widget.child,
  );
  late final OverlayEntry _layerEntry = OverlayEntry(
    builder: (BuildContext context) => ToastLayer(host: this),
  );

  /// The entries on screen, including the ones playing their exit animation.
  List<ToastEntry> get visibleEntries =>
      List<ToastEntry>.unmodifiable(_visible);

  /// The entries waiting for a free slot.
  List<ToastEntry> get queuedEntries => List<ToastEntry>.unmodifiable(_queue);

  int get _limit => switch (_theme.stackMode!) {
        ToastStackMode.stack => _theme.maxVisible!,
        ToastStackMode.queue || ToastStackMode.replace => 1,
      };

  int get _activeVisibleCount => _visible
      .where((ToastEntry e) => e.status == ToastEntryStatus.visible)
      .length;

  @override
  void initState() {
    super.initState();
    _theme = BetterToastThemeData.fallback.merge(widget.theme);
    active.add(this);
  }

  @override
  void didUpdateWidget(BetterToastScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    _childEntry.markNeedsBuild();
    _layerEntry.markNeedsBuild();
  }

  @override
  void dispose() {
    _disposed = true;
    active.remove(this);
    final List<ToastEntry> entries = <ToastEntry>[..._visible, ..._queue];
    _visible.clear();
    _queue.clear();
    for (final ToastEntry entry in entries) {
      entry.finish();
    }
    _childEntry
      ..remove()
      ..dispose();
    _layerEntry
      ..remove()
      ..dispose();
    super.dispose();
  }

  /// Finds an active toast by [id].
  ToastEntry? findActive(Object id) {
    for (final ToastEntry entry in <ToastEntry>[..._visible, ..._queue]) {
      if (entry.isActive && entry.id == id) {
        return entry;
      }
    }
    return null;
  }

  /// Shows a toast, or updates the active toast with the same [id].
  ToastEntry show(ToastConfig config, {Object? id}) {
    if (id != null) {
      final ToastEntry? existing = findActive(id);
      if (existing != null) {
        existing.replaceConfig(config);
        _changed();
        return existing;
      }
    }
    final ToastEntry entry = ToastEntry(
      host: this,
      id: id ?? AutoToastId(_nextId++),
      config: config,
    );
    if (_theme.stackMode == ToastStackMode.replace) {
      for (final ToastEntry other in <ToastEntry>[..._queue, ..._visible]) {
        _dismiss(other);
      }
    }
    _queue.add(entry);
    _promote();
    _changed();
    return entry;
  }

  /// Starts closing [entry]. Queued entries are dropped at once.
  void dismissEntry(ToastEntry entry) {
    if (_disposed) {
      return;
    }
    _dismiss(entry);
    _promote();
    _changed();
  }

  /// Closes every toast, including queued ones.
  void dismissAll() {
    if (_disposed) {
      return;
    }
    for (final ToastEntry entry in <ToastEntry>[..._queue, ..._visible]) {
      _dismiss(entry);
    }
    _changed();
  }

  /// Removes [entry] at once, after its exit animation or a swipe.
  void removeEntry(ToastEntry entry) {
    if (_disposed) {
      return;
    }
    _visible.remove(entry);
    _queue.remove(entry);
    entry.finish();
    _promote();
    _changed();
  }

  void _dismiss(ToastEntry entry) {
    switch (entry.status) {
      case ToastEntryStatus.queued:
        _queue.remove(entry);
        entry.finish();
      case ToastEntryStatus.visible:
        if (entry.attached) {
          entry.status = ToastEntryStatus.exiting;
          entry.changed();
        } else {
          _visible.remove(entry);
          entry.finish();
        }
      case ToastEntryStatus.exiting:
      case ToastEntryStatus.removed:
        break;
    }
  }

  void _promote() {
    while (_queue.isNotEmpty && _activeVisibleCount < _limit) {
      final ToastEntry entry = _queue.removeAt(0);
      entry.status = ToastEntryStatus.visible;
      _visible.add(entry);
    }
  }

  void _changed() {
    runOutsideBuild(() {
      if (!_disposed) {
        _layerEntry.markNeedsBuild();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _theme = resolveToastTheme(context, widget.theme);
    Widget result = Overlay(
      initialEntries: <OverlayEntry>[_childEntry, _layerEntry],
    );
    if (Directionality.maybeOf(context) == null) {
      result = Directionality(textDirection: TextDirection.ltr, child: result);
    }
    if (MediaQuery.maybeOf(context) == null) {
      result = MediaQuery.fromView(view: View.of(context), child: result);
    }
    return ToastScopeMarker(host: this, theme: widget.theme, child: result);
  }
}

/// Lays out the visible toasts of a [ToastHost], grouped by position.
///
/// Internal; not exported.
class ToastLayer extends StatelessWidget {
  /// Creates the layer for [host].
  const ToastLayer({super.key, required this.host});

  /// The host whose toasts to show.
  final ToastHost host;

  @override
  Widget build(BuildContext context) {
    final BetterToastThemeData theme = BetterToastTheme.of(context);
    final TextDirection textDirection = Directionality.of(context);
    final Map<ToastPosition, List<ToastEntry>> groups =
        <ToastPosition, List<ToastEntry>>{};
    for (final ToastEntry entry in host.visibleEntries) {
      final ToastPosition position = entry.config.position ?? theme.position!;
      (groups[position] ??= <ToastEntry>[]).add(entry);
    }
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Stack(
      children: <Widget>[
        for (final MapEntry<ToastPosition, List<ToastEntry>> group
            in groups.entries)
          Positioned.fill(
            key: ValueKey<ToastPosition>(group.key),
            child: _buildGroup(
              theme,
              textDirection,
              keyboard,
              group.key,
              group.value,
            ),
          ),
      ],
    );
  }

  Widget _buildGroup(
    BetterToastThemeData theme,
    TextDirection textDirection,
    double keyboard,
    ToastPosition position,
    List<ToastEntry> entries,
  ) {
    // Newest toast sits closest to the screen edge it is attached to.
    final List<ToastEntry> ordered =
        position.isTop ? entries.reversed.toList() : entries;
    Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _crossAxisAlignment(position, textDirection),
      children: <Widget>[
        for (final ToastEntry entry in ordered)
          ToastItem(
            key: ObjectKey(entry),
            entry: entry,
            theme: theme,
            position: position,
          ),
      ],
    );
    column = OverflowBox(
      alignment: position.alignment,
      minHeight: 0,
      maxHeight: double.infinity,
      child: column,
    );
    column = Padding(padding: theme.margin!, child: column);
    if (theme.respectSafeArea!) {
      column = SafeArea(child: column);
    }
    if (position.isBottom && keyboard > 0) {
      column = Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: column,
      );
    }
    return column;
  }

  static CrossAxisAlignment _crossAxisAlignment(
    ToastPosition position,
    TextDirection textDirection,
  ) {
    final bool ltr = textDirection == TextDirection.ltr;
    return switch (position) {
      ToastPosition.top ||
      ToastPosition.center ||
      ToastPosition.bottom =>
        CrossAxisAlignment.center,
      ToastPosition.topStart ||
      ToastPosition.bottomStart =>
        CrossAxisAlignment.start,
      ToastPosition.topEnd || ToastPosition.bottomEnd => CrossAxisAlignment.end,
      ToastPosition.topLeft ||
      ToastPosition.bottomLeft =>
        ltr ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      ToastPosition.topRight ||
      ToastPosition.bottomRight =>
        ltr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    };
  }
}

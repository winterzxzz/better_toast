# better_toast — design contract (v0.1.0)

Owner: SLP Lead. The public API shape below is a Lead decision. Internal
structure is the Engineer's call. Raise REOPEN_REQUEST with evidence to change
anything public.

## Goals

1. Show toasts from anywhere — with or without a `BuildContext`.
2. Maximum customization in layers: global theme → per-type style → per-call
   overrides → fully custom builder. Each layer is optional.
3. Pure Dart/Flutter. No platform channels, no runtime dependencies beyond
   the Flutter SDK. Works on Android, iOS, web, macOS, Windows, Linux.
4. pub.dev ready: 160/160 pana points target, full dartdoc on public API,
   example app, tests, MIT/BSD license, CHANGELOG.

## Public API (required shape)

```dart
// 1. Setup — one of:
MaterialApp(builder: BetterToast.init(), ...)             // context-free usage
BetterToastScope(child: ..., theme: BetterToastThemeData(...))  // explicit host

// 2. Show
final ToastHandle h = BetterToast.show(
  'Saved',                          // or `message: Widget`
  type: ToastType.success,          // info | success | warning | error | loading | custom
  title: 'Done',
  description: 'Your file was saved',
  duration: Duration(seconds: 3),   // null/Duration.zero = sticky
  position: ToastPosition.top,      // top | center | bottom (+ topLeft/topRight/bottomLeft/bottomRight)
  animation: ToastAnimation.slide,  // fade | slide | scale | slideFade | none | custom
  style: ToastStyle(...),           // per-call overrides, merged over theme
  action: ToastAction(label: 'Undo', onPressed: ...),
  dismissible: true,                // swipe to dismiss
  pauseOnHover/ pauseOnTouch: true,
  showProgressBar: false,
  onTap:, onDismissed:,
  id: 'upload',                     // same id => update in place, no duplicate
  context: context,                 // optional
);
BetterToast.success(...); .error(...); .warning(...); .info(...); .loading(...);
BetterToast.custom(builder: (context, ToastHandle h) => Widget, ...);
Future<T> BetterToast.promise<T>(future, loading:, success: (T)=>, error: (Object)=>);

h.dismiss(); h.update(...); h.isActive; await h.closed;
BetterToast.dismiss(id); BetterToast.dismissAll();

// 3. Theme
BetterToastThemeData(
  defaultStyle: ToastStyle, typeStyles: Map<ToastType, ToastStyle>,
  position, animation, duration, maxVisible (queue overflow), stackMode
  (stack | queue | replace), spacing, margin, respect SafeArea,
  builder: global custom toast builder,
)
// Also usable as ThemeExtension<BetterToastThemeData> on ThemeData.

ToastStyle(  // every field nullable; merge() / copyWith() / lerp()
  backgroundColor, gradient, foregroundColor, iconColor, icon, iconSize,
  titleStyle, messageStyle, padding, margin, borderRadius, border, shadows,
  blur (glassmorphism), elevation, width, maxWidth, alignment of content,
  progressBarColor, progressBarHeight, closeButton (bool + widget),
)
```

## Behavioral requirements

- Multiple toasts stack with smooth reflow; respects `maxVisible`, excess queued.
- Timer pauses on hover (desktop/web) and while touched; resumes after.
- Swipe-to-dismiss in a direction appropriate to position.
- Accessibility: `Semantics(liveRegion: true)` announcing the message;
  respects `MediaQuery.disableAnimations` (reduce motion); text scales.
- RTL aware (Directional positions/padding).
- Light/dark defaults derived from `Theme.of(context).colorScheme`.
- No leaks: timers/controllers disposed; safe to call show() before host is
  mounted (throws a clear `FlutterError` with setup instructions).
- Works with Navigator route changes (lives in an Overlay above Navigator).

## 0.1.0

Initial release.

* Show toasts from anywhere, with or without a `BuildContext`, through
  `BetterToast.init()` (one line in `MaterialApp.builder`) or an explicit
  `BetterToastScope`.
* Types: `info`, `success`, `warning`, `error`, `loading` and `custom`, with
  `BetterToast.success/error/warning/info/loading/custom` helpers.
* Eleven positions: `top`, `center`, `bottom`, four physical corners and four
  RTL-aware `Start`/`End` corners.
* Animations: `fade`, `slide`, `scale`, `slideFade`, `none` and `custom` (your
  own `ToastTransitionBuilder`). Smooth reflow when toasts stack.
* Stack modes: `stack` (up to `maxVisible`, the rest queued), `queue` (one at
  a time) and `replace`.
* `ToastHandle`: `update()`, `dismiss()`, `pause()`, `resume()`, `isActive`,
  `closed` and a `progress` listenable. Showing a toast with an existing `id`
  replaces its content in place; `update()` merges, and its `clearTitle`,
  `clearDescription`, `clearAction` and `clearStyle` flags remove a field.
* The `builder` passed to `BetterToast.init()` wraps the toast host, so its
  `Directionality`, `MediaQuery`, `Theme` or `Localizations` reach toasts.
* `onDismissed` runs in a microtask, never while the widget tree is locked;
  an exception it throws is reported and `closed` still completes.
* `BetterToast.promise()` turns a loading toast into a success or error toast.
* Layered customization: `BetterToastThemeData` (also a `ThemeExtension`),
  per-type `typeStyles`, per-call `ToastStyle` and fully custom builders.
  `ToastStyle` supports gradients, borders, shadows, glass blur, widths,
  progress bar, close button and more.
* Swipe to dismiss, pause on hover and on touch, optional progress bar,
  action button, close button.
* Timers pause while the app is not in the foreground (any
  `AppLifecycleState` other than `resumed`) and continue where they left off;
  a toast paused with `handle.pause()` stays paused.
* Accessibility: live-region announcements, reduce-motion support, text
  scaling and RTL. Toasts with an action stay until closed while
  `accessibleNavigation` is on, and the close button has a 48x48 tap target. Light and dark defaults from the app's `ColorScheme`.

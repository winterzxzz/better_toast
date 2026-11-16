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
  updates it in place.
* `BetterToast.promise()` turns a loading toast into a success or error toast.
* Layered customization: `BetterToastThemeData` (also a `ThemeExtension`),
  per-type `typeStyles`, per-call `ToastStyle` and fully custom builders.
  `ToastStyle` supports gradients, borders, shadows, glass blur, widths,
  progress bar, close button and more.
* Swipe to dismiss, pause on hover and on touch, optional progress bar,
  action button, close button.
* Accessibility: live-region announcements, reduce-motion support, text
  scaling and RTL. Light and dark defaults from the app's `ColorScheme`.

// Renders the README and pub.dev screenshots and the demo animation with
// real fonts, from the real package.
//
// Run from the example directory:
//   ./tool/make_screenshots.sh
//
// The script runs this file. Stills are written to
// example/build/screenshots/ and demo frames to example/build/demo/. The
// script then converts them to WebP in doc/screenshots/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:better_toast/better_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable)
          .parent
          .parent
          .parent
          .parent
          .parent
          .parent
          .path;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String name) async =>
      ByteData.sublistView(await File('$dir/$name').readAsBytes());
  final roboto = FontLoader('Roboto')
    ..addFont(read('Roboto-Regular.ttf'))
    ..addFont(read('Roboto-Medium.ttf'))
    ..addFont(read('Roboto-Bold.ttf'))
    ..addFont(read('Roboto-Black.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(read('MaterialIcons-Regular.otf'));
  await Future.wait([roboto.load(), icons.load()]);
}

/// The logical size of a phone still, before the status bar and home
/// indicator insets.
const _phone = Size(390, 700);

/// The logical size of the phone used for the demo animation.
const _tallPhone = Size(390, 844);

/// The logical size of the tablet used for the positions still.
const _tablet = Size(1024, 640);

const _statusBar = 47.0;
const _homeIndicator = 34.0;

const _glassGradient = LinearGradient(
  colors: [Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFFF59E0B)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Sets the test view to a device of [size] logical pixels.
void _device(WidgetTester tester, Size size,
    {double dpr = 3, bool insets = true}) {
  tester.view.physicalSize = size * dpr;
  tester.view.devicePixelRatio = dpr;
  final padding = insets
      ? FakeViewPadding(top: _statusBar * dpr, bottom: _homeIndicator * dpr)
      : FakeViewPadding.zero;
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
  addTearDown(tester.view.reset);
}

/// A fake status bar and home indicator, drawn above the toasts.
class _SystemChrome extends StatelessWidget {
  const _SystemChrome({required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final textStyle = TextStyle(
      color: color,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      fontFamily: 'Roboto',
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          Positioned.fill(child: child),
          if (padding.top > 0)
            Positioned(
              top: 0,
              left: 28,
              right: 22,
              height: padding.top,
              child: Row(
                children: [
                  DefaultTextStyle(
                    style: textStyle,
                    child: const Text('9:41'),
                  ),
                  const Spacer(),
                  Icon(Icons.signal_cellular_alt, size: 17, color: color),
                  const SizedBox(width: 4),
                  Icon(Icons.wifi, size: 17, color: color),
                  const SizedBox(width: 4),
                  Icon(Icons.battery_full, size: 18, color: color),
                ],
              ),
            ),
          if (padding.bottom > 0)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 134,
                  height: 5,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A decorative card without text. The phone screens put it under the toast
/// stack, so the gaps between toasts show a clean surface instead of
/// half-covered text.
class _Hero extends StatelessWidget {
  const _Hero({this.glass = false});

  final bool glass;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = glass
        ? [
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.05),
          ]
        : [scheme.primaryContainer, scheme.tertiaryContainer];
    final blob = glass
        ? Colors.white.withValues(alpha: 0.35)
        : scheme.primary.withValues(alpha: 0.18);
    Widget circle(double size, Color color) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -40, right: -30, child: circle(180, blob)),
            Positioned(
              bottom: -60,
              left: -20,
              child: circle(200, blob.withValues(alpha: blob.a * 0.7)),
            ),
            Positioned(
              top: 90,
              left: 120,
              child: circle(70, blob.withValues(alpha: blob.a * 1.4)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A plain inbox screen. [toastsAtTop] decides whether the [_Hero] card
/// sits at the top (under top toasts) or at the bottom.
class _Home extends StatelessWidget {
  const _Home({this.toastsAtTop = true, this.glass = false, this.items = 3});

  final bool toastsAtTop;
  final bool glass;
  final int items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // No trailing punctuation: the RTL still mirrors this screen too.
    final names = [
      'Jane Cooper',
      'Leo Martin',
      'Ava Chen',
      'Sam Patel',
      'Mia Wong',
    ];
    final previews = [
      'The slides look great',
      'Lunch on Friday',
      'Photos from the trip',
      'Can you review my PR',
      'Meeting moved to 3 PM',
    ];
    final list = [
      for (var i = 0; i < items; i++)
        Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: glass
                ? Colors.white.withValues(alpha: 0.18)
                : scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            textColor: glass ? Colors.white : null,
            leading: CircleAvatar(
              backgroundColor:
                  glass ? Colors.white.withValues(alpha: 0.9) : null,
              child: Text(names[i % names.length][0]),
            ),
            title: Text(names[i % names.length]),
            subtitle: Text(previews[i % names.length]),
          ),
        ),
    ];
    final hero = Expanded(child: _Hero(glass: glass));
    return Scaffold(
      backgroundColor: glass ? Colors.transparent : null,
      appBar: AppBar(
        centerTitle: true,
        // The glass toasts blur what is behind them; a title there would
        // show as a smudge (and, left-aligned, leak past the round corners).
        title: glass ? null : const Text('Inbox'),
        backgroundColor: glass ? Colors.transparent : null,
        foregroundColor: glass ? Colors.white : null,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: toastsAtTop
                ? [hero, const SizedBox(height: 4), ...list]
                : [...list, const SizedBox(height: 12), hero],
          ),
        ),
      ),
    );
  }
}

/// A tablet dashboard whose body is one decorative card, so toasts in every
/// corner sit on a clean surface.
class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(padding: EdgeInsets.all(12), child: _Hero()),
    );
  }
}

Widget _app({
  required Widget home,
  BetterToastThemeData? theme,
  Brightness brightness = Brightness.light,
  bool glass = false,
  TextDirection? textDirection,
}) {
  final chrome = glass || brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF1B1B1F);
  final toastHost = BetterToast.init(theme: theme);
  Widget app = MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      fontFamily: 'Roboto',
      colorSchemeSeed: Colors.indigo,
      brightness: brightness,
    ),
    builder: (context, child) {
      Widget result = toastHost(context, child);
      if (textDirection != null) {
        result = Directionality(textDirection: textDirection, child: result);
      }
      return _SystemChrome(color: chrome, child: result);
    },
    home: home,
  );
  if (glass) {
    app = DecoratedBox(
      decoration: const BoxDecoration(gradient: _glassGradient),
      child: app,
    );
  }
  return RepaintBoundary(key: _screen, child: app);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The repaint boundary around the whole app, captured by [_save].
final _screen = GlobalKey();

/// Writes the current frame of [_screen] to [path] as a PNG, at
/// [pixelRatio] physical pixels per logical pixel.
Future<void> _save(WidgetTester tester, String path, double pixelRatio) async {
  final boundary =
      _screen.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File(path)..parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Future<void> _snap(WidgetTester tester, String name, {double dpr = 3}) =>
    _save(tester, 'build/screenshots/$name.png', dpr);

Future<void> _cleanUp(WidgetTester tester) async {
  BetterToast.dismissAll();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _still(
  WidgetTester tester,
  String name, {
  required void Function() show,
  required Widget home,
  BetterToastThemeData? theme,
  Brightness brightness = Brightness.light,
  bool glass = false,
}) async {
  _device(tester, _phone);
  await tester.pumpWidget(
    _app(home: home, theme: theme, brightness: brightness, glass: glass),
  );
  show();
  await _settle(tester);
  await _snap(tester, name);
  await _cleanUp(tester);
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('types', (tester) async {
    await _still(
      tester,
      'types',
      home: const _Home(items: 3),
      theme: const BetterToastThemeData(
        duration: Duration.zero,
        maxVisible: 4,
      ),
      show: () {
        BetterToast.info('A new version is available');
        BetterToast.warning('Battery below 15%');
        BetterToast.error(
          'Upload failed',
          description: 'The server did not respond.',
          action: ToastAction(label: 'Retry', onPressed: () {}),
        );
        BetterToast.success('Your changes were saved.', title: 'Saved');
      },
    );
  });

  testWidgets('dark', (tester) async {
    await _still(
      tester,
      'dark_bottom',
      home: const _Home(toastsAtTop: false, items: 3),
      brightness: Brightness.dark,
      theme: const BetterToastThemeData(
        position: ToastPosition.bottom,
        showProgressBar: true,
        duration: Duration(seconds: 10),
        defaultStyle: ToastStyle(showCloseButton: true),
      ),
      show: () {
        BetterToast.loading('Uploading photo.jpg… 60%', title: 'Uploading');
        BetterToast.success(
          'Message moved to Archive.',
          title: 'Archived',
          action: ToastAction(label: 'Undo', onPressed: () {}),
        );
      },
    );
  });

  testWidgets('glass', (tester) async {
    await _still(
      tester,
      'glass',
      home: const _Home(glass: true, items: 3),
      glass: true,
      theme: BetterToastThemeData(
        duration: Duration.zero,
        defaultStyle: ToastStyle(
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          foregroundColor: Colors.white,
          iconColor: Colors.white,
          blur: 16,
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          borderRadius: const BorderRadius.all(Radius.circular(22)),
        ),
      ),
      show: () {
        BetterToast.info('Glassmorphism with one ToastStyle');
        BetterToast.success('Payment received', title: r'+ $42.00');
      },
    );
  });

  testWidgets('custom', (tester) async {
    await _still(
      tester,
      'custom',
      home: const _Home(toastsAtTop: false, items: 2),
      theme: const BetterToastThemeData(
        duration: Duration.zero,
        position: ToastPosition.bottom,
        typeStyles: {
          ToastType.success: ToastStyle(
            backgroundColor: Color(0xFF15803D),
            foregroundColor: Colors.white,
            iconColor: Colors.white,
            border: Border(),
          ),
          ToastType.error: ToastStyle(
            backgroundColor: Color(0xFFB91C1C),
            foregroundColor: Colors.white,
            iconColor: Colors.white,
            border: Border(),
          ),
        },
      ),
      show: () {
        BetterToast.custom(
          builder: (context, handle) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(blurRadius: 16, color: Color(0x33000000)),
              ],
            ),
            child: const Row(
              children: [
                CircleAvatar(child: Text('JD')),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Jane Doe sent you a message',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        );
        BetterToast.error('Card declined');
        BetterToast.success('Order placed');
      },
    );
  });

  testWidgets('promise', (tester) async {
    _device(tester, _phone);
    await tester.pumpWidget(
      _app(
        home: const _Home(items: 3),
        theme: const BetterToastThemeData(showProgressBar: true),
      ),
    );
    final handle = BetterToast.loading(
      'Uploading photo.jpg…',
      title: 'Uploading',
    );
    await _settle(tester);
    await _snap(tester, 'promise_1');
    handle.update(
      title: 'Almost there',
      text: 'Processing on the server…',
    );
    await _settle(tester);
    await _snap(tester, 'promise_2');
    handle.update(
      type: ToastType.success,
      title: 'Uploaded',
      text: 'photo.jpg is in your library.',
      duration: const Duration(seconds: 4),
      action: ToastAction(label: 'View', onPressed: () {}),
    );
    await _settle(tester);
    await _snap(tester, 'promise_3');
    await _cleanUp(tester);
  });

  testWidgets('positions', (tester) async {
    _device(tester, _tablet, dpr: 2, insets: false);
    await tester.pumpWidget(
      _app(
        home: const _Dashboard(),
        theme: const BetterToastThemeData(
          duration: Duration.zero,
          maxVisible: 8,
          margin: EdgeInsets.all(28),
          defaultStyle: ToastStyle(maxWidth: 290),
        ),
      ),
    );
    const shown = {
      ToastPosition.topLeft: ToastType.info,
      ToastPosition.top: ToastType.success,
      ToastPosition.topRight: ToastType.warning,
      ToastPosition.center: ToastType.loading,
      ToastPosition.bottomLeft: ToastType.error,
      ToastPosition.bottom: ToastType.info,
      ToastPosition.bottomRight: ToastType.success,
    };
    shown.forEach((position, type) {
      BetterToast.show(
        'ToastPosition.${position.name}',
        type: type,
        position: position,
      );
    });
    await _settle(tester);
    await _snap(tester, 'positions_ltr', dpr: 2);
    await _cleanUp(tester);
  });

  testWidgets('rtl', (tester) async {
    _device(tester, _phone);
    await tester.pumpWidget(
      _app(
        // Only the hero card, so the bottom toast covers no text.
        home: const _Home(items: 0),
        textDirection: TextDirection.rtl,
        theme: const BetterToastThemeData(
          duration: Duration.zero,
          defaultStyle: ToastStyle(maxWidth: 300),
        ),
      ),
    );
    BetterToast.info(
      'topStart is on the right',
      title: 'Right-to-left',
      position: ToastPosition.topStart,
    );
    BetterToast.success(
      'Layout mirrors too',
      position: ToastPosition.topStart,
      action: ToastAction(label: 'Undo', onPressed: () {}),
    );
    BetterToast.warning(
      'bottomEnd is on the left',
      position: ToastPosition.bottomEnd,
    );
    await _settle(tester);
    await _snap(tester, 'positions_rtl');
    await _cleanUp(tester);
  });

  testWidgets('demo', (tester) async {
    // 25 fps. Each step pumps one frame interval and saves the frame.
    const frame = Duration(milliseconds: 40);
    const pixelRatio = 1.5;
    final dir = Directory('build/demo');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);

    _device(tester, _tallPhone);
    await tester.pumpWidget(
      _app(
        home: const _Home(items: 5),
        theme: const BetterToastThemeData(
          maxVisible: 4,
          showProgressBar: true,
          duration: Duration(milliseconds: 2600),
        ),
      ),
    );

    late ToastHandle upload;
    TestGesture? swipe;
    final script = <int, Future<void> Function()>{
      8: () async => BetterToast.success(
            'Your changes were saved.',
            title: 'Saved',
            duration: const Duration(milliseconds: 4400),
          ),
      24: () async => BetterToast.info(
            'Version 2.1 is ready to install',
            duration: Duration.zero,
            action: ToastAction(label: 'Update', onPressed: () {}),
          ),
      42: () async => upload = BetterToast.loading(
            'Uploading photo.jpg…',
            title: 'Uploading',
          ),
      66: () async => upload.update(
            title: 'Almost there',
            text: 'Processing on the server…',
          ),
      90: () async => upload.update(
            type: ToastType.success,
            title: 'Uploaded',
            text: 'photo.jpg is in your library.',
            duration: const Duration(milliseconds: 2400),
          ),
      108: () async => BetterToast.error(
            'Card declined',
            description: 'Try another payment method.',
            duration: const Duration(milliseconds: 2000),
            action: ToastAction(label: 'Retry', onPressed: () {}),
          ),
      // The sticky toast is left alone; swipe it up to close it.
      164: () async {
        swipe = await tester.startGesture(
          tester.getCenter(find.text('Version 2.1 is ready to install')),
        );
      },
    };
    for (var i = 165; i < 173; i++) {
      script[i] = () async => swipe!.moveBy(const Offset(0, -12));
    }
    script[173] = () async => swipe!.up();

    const frames = 196;
    for (var i = 0; i < frames; i++) {
      await script[i]?.call();
      await tester.pump(frame);
      final name = i.toString().padLeft(3, '0');
      await _save(tester, '${dir.path}/frame_$name.png', pixelRatio);
    }
    await _cleanUp(tester);
  });
}

// Renders the README and pub.dev screenshots with real fonts.
//
// Run from the example directory:
//   flutter test tool/screenshots_test.dart --update-goldens
//   ./tool/make_screenshots.sh
//
// The first command writes PNGs to example/build/screenshots/. The script
// converts them to WebP in doc/screenshots/ and builds the banner.
import 'dart:io';

import 'package:better_toast/better_toast.dart';
import 'package:flutter/material.dart';
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

class _Backdrop extends StatelessWidget {
  const _Backdrop({this.gradient = false});

  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < 8; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: gradient
                  ? Colors.white.withValues(alpha: 0.2)
                  : scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Text('${i + 1}'),
              ),
              title: Text('Conversation ${i + 1}'),
              subtitle: const Text('Tap to open the thread'),
            ),
          ),
      ],
    );
    final scaffold = Scaffold(
      backgroundColor: gradient ? Colors.transparent : null,
      appBar: AppBar(
        title: const Text('Inbox'),
        backgroundColor: gradient ? Colors.transparent : null,
      ),
      body: body,
    );
    if (!gradient) return scaffold;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: scaffold,
    );
  }
}

Future<void> _scene(
  WidgetTester tester,
  String name, {
  required void Function() show,
  BetterToastThemeData? theme,
  Brightness brightness = Brightness.light,
  bool gradient = false,
}) async {
  tester.view.physicalSize = const Size(1170, 2100);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorSchemeSeed: Colors.indigo,
        brightness: brightness,
      ),
      builder: BetterToast.init(theme: theme),
      home: _Backdrop(gradient: gradient),
    ),
  );
  show();
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../build/screenshots/$name.png'),
  );
  BetterToast.dismissAll();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('types', (tester) async {
    await _scene(
      tester,
      'types',
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
        BetterToast.success(
          'Your changes were saved.',
          title: 'Saved',
        );
      },
    );
  });

  testWidgets('dark', (tester) async {
    await _scene(
      tester,
      'dark_bottom',
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
    await _scene(
      tester,
      'glass',
      gradient: true,
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
        BetterToast.success('Payment received', title: r'+ $42.00');
        BetterToast.info('Glassmorphism with one ToastStyle');
      },
    );
  });

  testWidgets('custom', (tester) async {
    await _scene(
      tester,
      'custom',
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
            width: 360,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(18),
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
}

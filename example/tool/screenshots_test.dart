// Renders the README and pub.dev marketing images and the demo animation
// with real fonts, from the real package.
//
// Run from the example directory:
//   sh tool/make_screenshots.sh
//
// Every frame is drawn by Flutter: the gradient background, the headline,
// the device frame and the app screen are plain widgets, and every toast is
// a genuine better_toast toast shown through a BetterToastScope. Stills are
// written to example/build/screenshots/ and demo frames to
// example/build/demo/; the script converts them to WebP.
import 'dart:io';
import 'dart:math' as math;
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

// ---------------------------------------------------------------------------
// Geometry and palette
// ---------------------------------------------------------------------------

/// A marketing still, in logical pixels. Rendered at 3x: 1290 x 2796.
const _canvas = Size(430, 932);

/// The banner, in logical pixels. Rendered at 2x: 1600 x 700.
const _bannerSize = Size(800, 350);

/// The phone screen, in logical pixels (an iPhone 15-sized display).
const _screen = Size(390, 844);

/// The device frame around [_screen]: a 3 px rim and a 9 px bezel.
const _rim = 3.0;
const _bezel = 9.0;
const _device = Size(
  390 + 2 * (_rim + _bezel),
  844 + 2 * (_rim + _bezel),
);

const _statusBar = 54.0;
const _homeIndicator = 34.0;

const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);

const _seed = Color(0xFF4F46E5);

/// The background gradients, one per frame.
const _hero = [Color(0xFF4338CA), Color(0xFF7C3AED), Color(0xFFDB2777)];
const _sky = [Color(0xFF0284C7), Color(0xFF4F46E5), Color(0xFF7C3AED)];
const _sunset = [Color(0xFFEA580C), Color(0xFFDB2777), Color(0xFF7C3AED)];
const _night = [Color(0xFF020617), Color(0xFF1E1B4B), Color(0xFF581C87)];
const _ocean = [Color(0xFF047857), Color(0xFF0E7490), Color(0xFF4338CA)];
const _berry = [Color(0xFF6D28D9), Color(0xFFC026D3), Color(0xFFE11D48)];

TextStyle _text(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = _ink,
  double? height,
  double? spacing,
}) =>
    TextStyle(
      fontFamily: 'Roboto',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
      decoration: TextDecoration.none,
    );

// ---------------------------------------------------------------------------
// Marketing frame
// ---------------------------------------------------------------------------

/// A soft radial glow used to give the flat gradients some depth.
class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// The brand background: a diagonal gradient with two glows.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.colors, required this.child});

  final List<Color> colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1, -1),
          end: const Alignment(1, 1),
          colors: colors,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -220,
            right: -200,
            child: _Glow(
              size: 560,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            bottom: -260,
            left: -240,
            child: _Glow(
              size: 640,
              color: colors.last.withValues(alpha: 0.7),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// The brand wordmark: a small toast glyph and "better_toast".
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  static const double size = 15;

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: 0.85);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size * 1.45,
          height: size * 1.45,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size * 0.42),
          ),
          child: Center(
            child: Container(
              width: size * 0.85,
              height: size * 0.32,
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
        ),
        const SizedBox(width: size * 0.5),
        Text(
          'better_toast',
          style: _text(size, weight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

/// A pill that names the API shown in the frame.
class _ApiPill extends StatelessWidget {
  const _ApiPill(this.code);

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.code_rounded, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            code,
            style: _text(
              15,
              weight: FontWeight.w500,
              color: Colors.white,
              spacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// One marketing still: wordmark, headline, API pill and [child] below.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.colors,
    required this.headline,
    required this.api,
    required this.child,
  });

  final List<Color> colors;
  final String headline;
  final String api;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: _canvas,
      child: _Backdrop(
        colors: colors,
        child: Column(
          children: [
            const SizedBox(height: 44),
            const _Wordmark(),
            const SizedBox(height: 18),
            Text.rich(
              TextSpan(
                children: [
                  for (final (i, part) in headline.split('→').indexed) ...[
                    if (i > 0)
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 42,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    TextSpan(text: part.trim()),
                  ],
                ],
              ),
              textAlign: TextAlign.center,
              style: _text(
                46,
                weight: FontWeight.w900,
                color: Colors.white,
                height: 1.04,
                spacing: -1.6,
              ),
            ),
            const SizedBox(height: 18),
            _ApiPill(api),
            const SizedBox(height: 30),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Device frame and phone screen
// ---------------------------------------------------------------------------

/// A modern phone: titanium rim, black bezel, dynamic island, side buttons
/// and a soft shadow. [width] is the outer width in the frame; the phone is
/// drawn at its real size and scaled, so everything stays vector-sharp.
class _Phone extends StatelessWidget {
  const _Phone({required this.width, required this.screen});

  final double width;
  final Widget screen;

  @override
  Widget build(BuildContext context) {
    Widget button(double top, double height, {bool right = false}) =>
        Positioned(
          top: top,
          left: right ? null : -2.5,
          right: right ? -2.5 : null,
          child: Container(
            width: 4,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFF3F3F4A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
    final device = SizedBox.fromSize(
      size: _device,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // A soft drop shadow. BoxShadow blur is not rendered by the test
          // renderer, so blur a dark shape instead.
          Positioned(
            left: 20,
            right: 20,
            top: 40,
            bottom: -30,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x66120826),
                  borderRadius: BorderRadius.circular(64),
                ),
              ),
            ),
          ),
          button(150, 32),
          button(210, 62),
          button(286, 62),
          button(240, 98, right: true),
          Container(
            padding: const EdgeInsets.all(_rim),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(64),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6B6B78),
                  Color(0xFF26262E),
                  Color(0xFF55555F),
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(_bezel),
              decoration: BoxDecoration(
                color: const Color(0xFF08080B),
                borderRadius: BorderRadius.circular(61),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(52),
                child: SizedBox.fromSize(
                  size: _screen,
                  child: Stack(
                    children: [
                      Positioned.fill(child: screen),
                      Positioned(
                        top: 11,
                        left: (_screen.width - 122) / 2,
                        child: Container(
                          width: 122,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return SizedBox(
      width: width,
      height: width * _device.height / _device.width,
      child: FittedBox(child: device),
    );
  }
}

/// The status bar and home indicator, drawn above the toasts.
class _SystemChrome extends StatelessWidget {
  const _SystemChrome({required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            top: 0,
            left: 40,
            right: 30,
            height: _statusBar,
            child: Row(
              children: [
                Text('9:41',
                    style: _text(16, weight: FontWeight.w600)
                        .copyWith(color: color)),
                const Spacer(),
                Icon(Icons.signal_cellular_alt, size: 17, color: color),
                const SizedBox(width: 4),
                Icon(Icons.wifi, size: 17, color: color),
                const SizedBox(width: 4),
                Icon(Icons.battery_full, size: 18, color: color),
              ],
            ),
          ),
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

ThemeData _theme(Brightness brightness) => ThemeData(
      fontFamily: 'Roboto',
      colorSchemeSeed: _seed,
      brightness: brightness,
    );

/// A complete app running inside the phone: a MaterialApp whose builder is
/// [BetterToast.init], so its toasts are drawn by the real package. Show
/// toasts with `context: anchor.currentContext` to target this host.
class _App extends StatelessWidget {
  const _App({
    required this.anchor,
    required this.home,
    this.theme,
    this.brightness = Brightness.light,
    this.chrome = _ink,
    this.textDirection,
  });

  final GlobalKey anchor;
  final Widget home;
  final BetterToastThemeData? theme;
  final Brightness brightness;
  final Color chrome;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final toastHost = BetterToast.init(theme: theme);
    return MediaQuery(
      data: MediaQueryData(
        size: _screen,
        devicePixelRatio: 3,
        platformBrightness: brightness,
        padding: const EdgeInsets.only(
          top: _statusBar,
          bottom: _homeIndicator,
        ),
        viewPadding: const EdgeInsets.only(
          top: _statusBar,
          bottom: _homeIndicator,
        ),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _theme(brightness),
        builder: (context, child) {
          Widget result = toastHost(context, child);
          if (textDirection != null) {
            result = Directionality(
              textDirection: textDirection!,
              child: result,
            );
          }
          return _SystemChrome(color: chrome, child: result);
        },
        home: KeyedSubtree(key: anchor, child: home),
      ),
    );
  }
}

const _floatingTheme = BetterToastThemeData(
  duration: Duration.zero,
  maxVisible: 1,
  // Room for the toast shadow inside the host's clip.
  margin: EdgeInsets.all(14),
);

/// A transparent toast host of [size], used for toasts that float on the
/// marketing background. The toasts are still real better_toast toasts.
class _Floating extends StatelessWidget {
  const _Floating({
    required this.anchor,
    required this.size,
  });

  final GlobalKey anchor;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: size,
      child: MediaQuery(
        data: MediaQueryData(size: size, devicePixelRatio: 3),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _theme(Brightness.light),
          builder: BetterToast.init(theme: _floatingTheme),
          home: SizedBox.expand(key: anchor),
        ),
      ),
    );
  }
}

/// Places a phone at the top of the frame's content area, running off the
/// bottom edge like a store screenshot.
class _CroppedPhone extends StatelessWidget {
  const _CroppedPhone({required this.screen, this.width = 370});

  final Widget screen;
  final double width;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      alignment: Alignment.topCenter,
      maxHeight: double.infinity,
      child: _Phone(width: width, screen: screen),
    );
  }
}

// ---------------------------------------------------------------------------
// Artwork: painted "photos" for the app screens
// ---------------------------------------------------------------------------

class _ArtPalette {
  const _ArtPalette({
    required this.sky,
    required this.sun,
    required this.far,
    required this.near,
  });

  final List<Color> sky;
  final Color sun;
  final Color far;
  final Color near;
}

const _goldenHour = _ArtPalette(
  sky: [Color(0xFF4C1D95), Color(0xFFDB2777), Color(0xFFFBBF24)],
  sun: Color(0xFFFEF3C7),
  far: Color(0xFF9D174D),
  near: Color(0xFF3B0764),
);

const _morning = _ArtPalette(
  sky: [Color(0xFF38BDF8), Color(0xFFBAE6FD), Color(0xFFFEF9C3)],
  sun: Color(0xFFFFFBEB),
  far: Color(0xFF34D399),
  near: Color(0xFF065F46),
);

const _neon = _ArtPalette(
  sky: [Color(0xFF0EA5E9), Color(0xFF8B5CF6), Color(0xFFF472B6)],
  sun: Color(0xFFFFF1F2),
  far: Color(0xFF6D28D9),
  near: Color(0xFF1E1B4B),
);

/// A landscape: a gradient sky, a glowing sun and two mountain ridges.
class _Art extends StatelessWidget {
  const _Art(this.palette);

  final _ArtPalette palette;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ArtPainter(palette),
      child: const SizedBox.expand(),
    );
  }
}

class _ArtPainter extends CustomPainter {
  _ArtPainter(this.palette);

  final _ArtPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.sky,
        ).createShader(rect),
    );
    final sun = Offset(w * 0.66, h * 0.44);
    final r = w * 0.12;
    final glow = Rect.fromCircle(center: sun, radius: r * 3);
    canvas.drawCircle(
      sun,
      r * 3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.sun.withValues(alpha: 0.55),
            palette.sun.withValues(alpha: 0),
          ],
        ).createShader(glow),
    );
    canvas.drawCircle(sun, r, Paint()..color = palette.sun);

    Path ridge(List<double> ys) {
      final path = Path()..moveTo(0, h * ys.first);
      for (var i = 1; i < ys.length; i++) {
        path.lineTo(w * i / (ys.length - 1), h * ys[i]);
      }
      return path
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
    }

    canvas.drawPath(
      ridge([0.62, 0.48, 0.58, 0.42, 0.56, 0.5, 0.6]),
      Paint()..color = palette.far.withValues(alpha: 0.85),
    );
    canvas.drawPath(
      ridge([0.78, 0.66, 0.74, 0.62, 0.72, 0.64, 0.76]),
      Paint()..color = palette.near,
    );
  }

  @override
  bool shouldRepaint(_ArtPainter oldDelegate) => oldDelegate.palette != palette;
}

/// A city map for the positions frame: blocks, parks, a river and roads.
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFF1EFE9));
    final park = Paint()..color = const Color(0xFFC7EBC9);
    canvas
      ..drawRRect(
        RRect.fromLTRBR(
            w * 0.08, h * 0.2, w * 0.46, h * 0.36, const Radius.circular(18)),
        park,
      )
      ..drawRRect(
        RRect.fromLTRBR(
            w * 0.58, h * 0.6, w * 0.94, h * 0.78, const Radius.circular(18)),
        park,
      );
    final river = Path()
      ..moveTo(-20, h * 0.5)
      ..cubicTo(w * 0.3, h * 0.42, w * 0.55, h * 0.62, w + 20, h * 0.48);
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFFA5D8F3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 34,
    );
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 12;
    final minor = Paint()
      ..color = Colors.white
      ..strokeWidth = 6;
    for (final x in [0.28, 0.72]) {
      canvas.drawLine(Offset(w * x, 0), Offset(w * x, h), road);
    }
    for (final y in [0.14, 0.42, 0.86]) {
      canvas.drawLine(Offset(0, h * y), Offset(w, h * y), road);
    }
    for (final x in [0.5, 0.88, 0.1]) {
      canvas.drawLine(Offset(w * x, 0), Offset(w * x, h), minor);
    }
    for (final y in [0.28, 0.66, 0.74]) {
      canvas.drawLine(Offset(0, h * y), Offset(w, h * y), minor);
    }
    canvas.drawLine(
      Offset(0, h * 0.95),
      Offset(w, h * 0.55),
      Paint()
        ..color = const Color(0xFFFDE68A)
        ..strokeWidth = 14,
    );
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// App screens
// ---------------------------------------------------------------------------

class _Avatar extends StatelessWidget {
  const _Avatar(this.initials, this.color, {this.size = 40});

  final String initials;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.25)!],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: _text(size * 0.36, weight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text, {this.color = _ink, this.trailing = const []});

  final String text;
  final Color color;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style:
              _text(30, weight: FontWeight.w900, color: color, spacing: -0.8),
        ),
        const Spacer(),
        ...trailing,
      ],
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsetsDirectional.only(start: 10),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Icon(icon, size: 21, color: _ink),
    );
  }
}

/// A photo feed: two posts with painted photos.
class _FeedScreen extends StatelessWidget {
  const _FeedScreen();

  @override
  Widget build(BuildContext context) {
    final actions = Row(
      children: [
        const Icon(Icons.favorite, color: Color(0xFFF43F5E), size: 24),
        const SizedBox(width: 6),
        Text('1.2k', style: _text(14, weight: FontWeight.w600)),
        const SizedBox(width: 18),
        const Icon(Icons.chat_bubble_outline, size: 22),
        const SizedBox(width: 6),
        Text('84', style: _text(14, weight: FontWeight.w600)),
        const SizedBox(width: 18),
        const Icon(Icons.send_outlined, size: 22),
        const Spacer(),
        const Icon(Icons.bookmark_border, size: 24),
      ],
    );
    Widget post(String name, String meta, Color color, _ArtPalette art) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(name.split(' ').map((s) => s[0]).join(), color),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: _text(15, weight: FontWeight.w700)),
                    Text(meta, style: _text(13, color: _muted)),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.more_horiz, color: _muted),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: SizedBox(height: 330, child: _Art(art)),
            ),
            const SizedBox(height: 12),
            actions,
          ],
        );
    return ColoredBox(
      color: Colors.white,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 480,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _Art(_goldenHour),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.55, 1],
                        colors: [Color(0x00000000), Color(0x99000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Row(
                      children: [
                        const _Avatar('ML', Color(0xFFF97316)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Maya Lin',
                                style: _text(15,
                                    weight: FontWeight.w700,
                                    color: Colors.white)),
                            Text('Golden hour in Lisbon',
                                style:
                                    _text(13, color: const Color(0xCCFFFFFF))),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Follow',
                              style: _text(13, weight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  actions,
                  const SizedBox(height: 22),
                  post('Leo Martin', 'Kyoto · 5h', const Color(0xFF0EA5E9),
                      _morning),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A cloud drive: storage card and recent files.
class _FilesScreen extends StatelessWidget {
  const _FilesScreen();

  @override
  Widget build(BuildContext context) {
    Widget file(IconData icon, Color color, String name, String meta) =>
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: _text(15, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(meta, style: _text(13, color: _muted)),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: _muted),
            ],
          ),
        );
    return ColoredBox(
      color: const Color(0xFFF3F4F9),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 70, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Title(
              'My Files',
              trailing: [
                _IconBubble(Icons.search_rounded),
                _IconBubble(Icons.cloud_upload_outlined),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_done_rounded, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        'Cloud storage',
                        style: _text(15,
                            weight: FontWeight.w600, color: Colors.white),
                      ),
                      const Spacer(),
                      Text(
                        '68%',
                        style: _text(15,
                            weight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const LinearProgressIndicator(
                      value: 0.68,
                      minHeight: 8,
                      color: Colors.white,
                      backgroundColor: Color(0x40FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '87 GB of 128 GB used',
                    style: _text(13, color: const Color(0xCCFFFFFF)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Recent', style: _text(18, weight: FontWeight.w800)),
            const SizedBox(height: 12),
            file(Icons.movie_rounded, const Color(0xFFDB2777), 'beach_trip.mp4',
                '248 MB · Just now'),
            file(Icons.picture_as_pdf_rounded, const Color(0xFFDC2626),
                'Q3 report.pdf', '2.4 MB · Yesterday'),
            file(Icons.table_chart_rounded, const Color(0xFF16A34A),
                'Budget 2026.xlsx', '540 KB · Mon'),
            file(Icons.image_rounded, const Color(0xFFD97706), 'IMG_2041.heic',
                '3.1 MB · Sun'),
            file(Icons.palette_rounded, const Color(0xFF7C3AED),
                'Moodboard.fig', '12 MB · Sat'),
          ],
        ),
      ),
    );
  }
}

/// A music player with full-bleed album art.
class _MusicScreen extends StatelessWidget {
  const _MusicScreen();

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0B12);
    final controls = [
      Icons.shuffle_rounded,
      Icons.skip_previous_rounded,
      null,
      Icons.skip_next_rounded,
      Icons.repeat_rounded,
    ];
    return ColoredBox(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 500,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _Art(_neon),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.6, 1],
                      colors: [bg.withValues(alpha: 0), bg],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Golden Hour',
                          style: _text(28,
                              weight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nova Lights · Neon Coast',
                          style: _text(15, color: const Color(0x99FFFFFF)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.favorite,
                        color: Color(0xFFF472B6), size: 28),
                  ],
                ),
                const SizedBox(height: 26),
                Stack(
                  children: [
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: 0.37,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('1:24',
                        style: _text(12, color: const Color(0x99FFFFFF))),
                    const Spacer(),
                    Text('3:52',
                        style: _text(12, color: const Color(0x99FFFFFF))),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final icon in controls)
                      icon == null
                          ? Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.pause_rounded,
                                  size: 40, color: bg),
                            )
                          : Icon(icon, size: 30, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A dark messaging inbox.
class _InboxScreen extends StatelessWidget {
  const _InboxScreen();

  @override
  Widget build(BuildContext context) {
    const chats = [
      ('Design Team', 'Ava: New mockups are up', '9:40', 3, Color(0xFF8B5CF6)),
      ('Jane Cooper', 'The slides look great', '9:12', 1, Color(0xFFF97316)),
      ('Leo Martin', 'Lunch on Friday?', '8:55', 0, Color(0xFF0EA5E9)),
      ('Mia Wong', 'Photos from the trip', 'Tue', 0, Color(0xFF22C55E)),
      ('Sam Patel', 'Can you review my PR', 'Mon', 0, Color(0xFFEC4899)),
      ('Noah Kim', 'Meeting moved to 3 PM', 'Sun', 0, Color(0xFFEAB308)),
      ('Ella Ruiz', 'Thanks for the help', 'Sat', 0, Color(0xFF14B8A6)),
    ];
    return ColoredBox(
      color: const Color(0xFF0E0E14),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 70, 20, 0),
        child: Column(
          children: [
            const _Title('Inbox', color: Colors.white),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final (i, (name, art)) in const [
                  ('Ava', _neon),
                  ('Leo', _goldenHour),
                  ('Mia', _morning),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 210,
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF818CF8), Color(0xFFF472B6)],
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _Art(art),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(name,
                            style: _text(13,
                                weight: FontWeight.w600,
                                color: const Color(0xCCFFFFFF))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C26),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0x80FFFFFF)),
                  const SizedBox(width: 8),
                  Text('Search',
                      style: _text(15, color: const Color(0x80FFFFFF))),
                ],
              ),
            ),
            const SizedBox(height: 10),
            for (final (name, preview, time, unread, color) in chats)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    _Avatar(name.split(' ').map((s) => s[0]).join(), color,
                        size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: _text(16,
                                  weight: FontWeight.w700,
                                  color: Colors.white)),
                          const SizedBox(height: 3),
                          Text(preview,
                              style: _text(14, color: const Color(0x99FFFFFF))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(time,
                            style: _text(12, color: const Color(0x80FFFFFF))),
                        const SizedBox(height: 6),
                        if (unread > 0)
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFF818CF8),
                              shape: BoxShape.circle,
                            ),
                            child: Text('$unread',
                                style: _text(11,
                                    weight: FontWeight.w700,
                                    color: Colors.white)),
                          )
                        else
                          const SizedBox(height: 20),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A full-screen map with a location pin.
class _MapScreen extends StatelessWidget {
  const _MapScreen();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _MapPainter()),
        Align(
          alignment: const Alignment(0.1, -0.22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _ink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('12 min',
                    textDirection: TextDirection.ltr,
                    style: _text(13,
                        weight: FontWeight.w700, color: Colors.white)),
              ),
              const Icon(Icons.location_on_rounded,
                  size: 44, color: Color(0xFFE11D48)),
            ],
          ),
        ),
        Align(
          alignment: const Alignment(-0.3, 0.3),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x552563EB), blurRadius: 0, spreadRadius: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A shop: categories and a product grid.
class _ShopScreen extends StatelessWidget {
  const _ShopScreen();

  @override
  Widget build(BuildContext context) {
    const products = [
      (
        'Studio Headphones',
        r'$249',
        Icons.headphones_rounded,
        Color(0xFFE0E7FF),
        Color(0xFF4F46E5)
      ),
      (
        'Smart Watch',
        r'$199',
        Icons.watch_rounded,
        Color(0xFFFCE7F3),
        Color(0xFFDB2777)
      ),
      (
        'Travel Backpack',
        r'$89',
        Icons.backpack_rounded,
        Color(0xFFDCFCE7),
        Color(0xFF16A34A)
      ),
      (
        'Instant Camera',
        r'$129',
        Icons.photo_camera_rounded,
        Color(0xFFFEF3C7),
        Color(0xFFD97706)
      ),
    ];
    return ColoredBox(
      color: const Color(0xFFF6F6FA),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 70, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Title('Shop'),
            const SizedBox(height: 16),
            Container(
              height: 300,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF312E81),
                    Color(0xFF7C3AED),
                    Color(0xFFEC4899)
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -40,
                    top: 20,
                    child: Icon(Icons.headphones_rounded,
                        size: 240, color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  Positioned(
                    left: 22,
                    bottom: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Summer Sale',
                            style: _text(26,
                                weight: FontWeight.w900, color: Colors.white)),
                        Text('Up to 30% off audio',
                            style: _text(15, color: const Color(0xD9FFFFFF))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final (i, label)
                    in ['All', 'Audio', 'Wearables', 'Travel'].indexed)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: i == 0 ? _ink : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(label,
                        style: _text(14,
                            weight: FontWeight.w600,
                            color: i == 0 ? Colors.white : _ink)),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final (name, price, icon, tint, color) in products)
                  Container(
                    width: 168,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: tint,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child:
                              Center(child: Icon(icon, size: 72, color: color)),
                        ),
                        const SizedBox(height: 10),
                        Text(name, style: _text(14, weight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(price,
                            style: _text(15,
                                weight: FontWeight.w800, color: color)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom toasts for the custom-builder frame
// ---------------------------------------------------------------------------

/// Gives a custom toast a soft drop shadow. The test renderer draws
/// BoxShadow and elevation shadows with hard edges, so blur a shape instead.
class _Lifted extends StatelessWidget {
  const _Lifted({required this.color, required this.child});

  /// The shadow tint.
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 10,
          right: 10,
          top: 10,
          bottom: -6,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

Widget _cartToast(BuildContext context, ToastHandle handle) => _Lifted(
      color: const Color(0xFF111827),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.headphones_rounded,
                  color: Color(0xFF4F46E5), size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Added to bag',
                      style: _text(15,
                          weight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(r'Studio Headphones · $249',
                      style: _text(13, color: const Color(0xB3FFFFFF))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child:
                  Text('View bag', style: _text(13, weight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

Widget _messageToast(BuildContext context, ToastHandle handle) => _Lifted(
      color: const Color(0xFF1E1B4B),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const _Avatar('JC', Color(0xFFF97316), size: 46),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jane Cooper',
                      style: _text(15, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Is the watch still available?',
                      style: _text(13, color: _muted)),
                ],
              ),
            ),
            const Icon(Icons.reply_rounded, color: _seed),
          ],
        ),
      ),
    );

Widget _rewardToast(BuildContext context, ToastHandle handle) => _Lifted(
      color: const Color(0xFFEF4444),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFFDB2777)],
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: 0.75,
                    strokeWidth: 4,
                    color: Colors.white,
                    backgroundColor: Color(0x40FFFFFF),
                  ),
                  Icon(Icons.emoji_events_rounded,
                      color: Colors.white, size: 26),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Level up!',
                      style: _text(16,
                          weight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('+200 points · Gold member',
                      style: _text(13, color: const Color(0xE6FFFFFF))),
                ],
              ),
            ),
          ],
        ),
      ),
    );

// ---------------------------------------------------------------------------
// Toast styles for the styles frame
// ---------------------------------------------------------------------------

final _glassStyle = ToastStyle(
  backgroundColor: Colors.white.withValues(alpha: 0.18),
  foregroundColor: Colors.white,
  iconColor: Colors.white,
  blur: 18,
  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
  borderRadius: const BorderRadius.all(Radius.circular(22)),
  elevation: 0,
);

const _gradientStyle = ToastStyle(
  gradient: LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
  ),
  foregroundColor: Colors.white,
  iconColor: Colors.white,
  border: Border(),
  borderRadius: BorderRadius.all(Radius.circular(22)),
  actionStyle: ButtonStyle(
    foregroundColor: WidgetStatePropertyAll(Colors.white),
  ),
);

const _pillStyle = ToastStyle(
  backgroundColor: Colors.black,
  foregroundColor: Colors.white,
  iconColor: Color(0xFF4ADE80),
  border: Border(),
  borderRadius: BorderRadius.all(Radius.circular(40)),
  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
);

const _softStyle = ToastStyle(
  backgroundColor: Color(0xFFFEF3C7),
  foregroundColor: Color(0xFF78350F),
  iconColor: Color(0xFFD97706),
  border: Border.fromBorderSide(BorderSide(color: Color(0xFFFCD34D))),
  borderRadius: BorderRadius.all(Radius.circular(16)),
);

// ---------------------------------------------------------------------------
// Rendering helpers
// ---------------------------------------------------------------------------

/// The repaint boundary around the whole canvas, captured by [_save].
final _shot = GlobalKey();

/// Sets the test view to [size] logical pixels at [dpr].
void _view(WidgetTester tester, Size size, {double dpr = 3}) {
  tester.view.physicalSize = size * dpr;
  tester.view.devicePixelRatio = dpr;
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  addTearDown(tester.view.reset);
}

Future<void> _pump(WidgetTester tester, Widget canvas) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(key: _shot, child: canvas),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Writes the current frame of [_shot] to [path] as a PNG, at [pixelRatio]
/// physical pixels per logical pixel.
Future<void> _save(WidgetTester tester, String path, double pixelRatio) async {
  final boundary =
      _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
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

void main() {
  setUpAll(_loadFonts);

  testWidgets('01 types', (tester) async {
    final phone = GlobalKey();
    _view(tester, _canvas);
    await _pump(
      tester,
      _Frame(
        colors: _hero,
        headline: 'Toasts,\nbeautifully.',
        api: 'BetterToast.success(…)',
        child: _CroppedPhone(
          screen: _App(
            anchor: phone,
            home: const _FeedScreen(),
            chrome: Colors.white,
            theme: const BetterToastThemeData(
              duration: Duration.zero,
              maxVisible: 4,
            ),
          ),
        ),
      ),
    );
    BetterToast.info('Maya Lin started following you',
        context: phone.currentContext);
    BetterToast.warning(
      'Storage almost full',
      description: '1.2 GB left on this device.',
      context: phone.currentContext,
    );
    BetterToast.error(
      'Upload failed',
      description: 'Check your connection.',
      action: ToastAction(label: 'Retry', onPressed: () {}),
      context: phone.currentContext,
    );
    BetterToast.success(
      'Your photo is live.',
      title: 'Post published',
      context: phone.currentContext,
    );
    await _settle(tester);
    await _snap(tester, '01_types');
    await _cleanUp(tester);
  });

  testWidgets('02 promise', (tester) async {
    final phone = GlobalKey();
    final step1 = GlobalKey();
    final step2 = GlobalKey();
    _view(tester, _canvas);
    Widget label(String number, String text) => Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(number,
                    style: _text(12, weight: FontWeight.w900, color: _sky[1])),
              ),
              const SizedBox(width: 8),
              Text(text,
                  style: _text(14,
                      weight: FontWeight.w600, color: const Color(0xE6FFFFFF))),
            ],
          ),
        );
    const toastBox = Size(380, 96);
    await _pump(
      tester,
      _Frame(
        colors: _sky,
        headline: 'Loading → Done',
        api: 'BetterToast.promise(…)',
        child: Column(
          children: [
            label('1', 'Loading'),
            _Floating(anchor: step1, size: toastBox),
            label('2', 'Updated in place'),
            _Floating(anchor: step2, size: toastBox),
            label('3', 'Success, with an action'),
            const SizedBox(height: 14),
            Expanded(
              child: _CroppedPhone(
                width: 360,
                screen: _App(
                  anchor: phone,
                  home: const _FilesScreen(),
                  theme: const BetterToastThemeData(showProgressBar: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    BetterToast.loading(
      'beach_trip.mp4 · 248 MB',
      title: 'Uploading…',
      context: step1.currentContext,
    );
    BetterToast.loading(
      'beach_trip.mp4 · 248 MB',
      title: 'Uploading…',
      context: step2.currentContext,
    ).update(title: 'Almost there', text: 'Processing on the server…');
    final handle = BetterToast.loading(
      'beach_trip.mp4 · 248 MB',
      title: 'Uploading…',
      context: phone.currentContext,
    );
    await _settle(tester);
    handle.update(
      type: ToastType.success,
      title: 'Uploaded',
      text: 'beach_trip.mp4 is in your library.',
      duration: const Duration(seconds: 6),
      action: ToastAction(label: 'View', onPressed: () {}),
    );
    await _settle(tester);
    await _snap(tester, '02_promise');
    await _cleanUp(tester);
  });

  testWidgets('03 styles', (tester) async {
    final phone = GlobalKey();
    _view(tester, _canvas);
    await _pump(
      tester,
      _Frame(
        colors: _sunset,
        headline: 'Your style.\nAny style.',
        api: 'ToastStyle(gradient: …, blur: 18)',
        child: _CroppedPhone(
          screen: _App(
            anchor: phone,
            home: const _MusicScreen(),
            chrome: Colors.white,
            theme: const BetterToastThemeData(
              duration: Duration.zero,
              maxVisible: 4,
              spacing: 12,
            ),
          ),
        ),
      ),
    );
    BetterToast.warning(
      'Offline mode is on',
      style: _softStyle,
      context: phone.currentContext,
    );
    BetterToast.success(
      'Downloaded · 12 songs',
      style: _pillStyle,
      context: phone.currentContext,
    );
    BetterToast.info(
      'Ad-free, offline, lossless.',
      title: 'Try Premium free',
      style: _gradientStyle.copyWith(
        icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
      ),
      action: ToastAction(label: 'Start', onPressed: () {}),
      context: phone.currentContext,
    );
    BetterToast.success(
      'Added to Liked Songs',
      style: _glassStyle.copyWith(
        icon: const Icon(Icons.favorite_rounded, color: Colors.white),
      ),
      context: phone.currentContext,
    );
    await _settle(tester);
    await _snap(tester, '03_styles');
    await _cleanUp(tester);
  });

  testWidgets('04 dark', (tester) async {
    final phone = GlobalKey();
    _view(tester, _canvas);
    await _pump(
      tester,
      _Frame(
        colors: _night,
        headline: 'Dark mode,\nbuilt in.',
        api: 'ThemeData(brightness: .dark)',
        child: _CroppedPhone(
          screen: _App(
            anchor: phone,
            home: const _InboxScreen(),
            brightness: Brightness.dark,
            chrome: Colors.white,
            theme: const BetterToastThemeData(
              maxVisible: 4,
              showProgressBar: true,
              duration: Duration(seconds: 5),
              defaultStyle: ToastStyle(showCloseButton: true),
            ),
          ),
        ),
      ),
    );
    BetterToast.error(
      'Message not sent',
      description: 'You are offline.',
      action: ToastAction(label: 'Retry', onPressed: () {}),
      context: phone.currentContext,
    );
    BetterToast.loading(
      'Sending 3 photos…',
      title: 'Sending',
      context: phone.currentContext,
    );
    BetterToast.success(
      'Moved to Archive.',
      title: 'Archived',
      action: ToastAction(label: 'Undo', onPressed: () {}),
      context: phone.currentContext,
    );
    await _settle(tester);
    await _snap(tester, '04_dark');
    await _cleanUp(tester);
  });

  testWidgets('05 positions', (tester) async {
    final phone = GlobalKey();
    _view(tester, _canvas);
    await _pump(
      tester,
      _Frame(
        colors: _ocean,
        headline: 'Every position.\nRTL too.',
        api: 'ToastPosition.topStart',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight - 36;
            return Align(
              alignment: Alignment.topCenter,
              child: _Phone(
                width: height * _device.width / _device.height,
                screen: _App(
                  anchor: phone,
                  home: const _MapScreen(),
                  textDirection: TextDirection.rtl,
                  theme: const BetterToastThemeData(
                    duration: Duration.zero,
                    maxVisible: 8,
                    defaultStyle: ToastStyle(maxWidth: 176),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    const shown = [
      (ToastPosition.topStart, ToastType.info, 'topStart', 'Right side in RTL'),
      (ToastPosition.topEnd, ToastType.success, 'topEnd', 'Left side in RTL'),
      (ToastPosition.center, ToastType.loading, 'center', 'Finding a route'),
      (
        ToastPosition.bottomStart,
        ToastType.warning,
        'bottomStart',
        'Heavy traffic'
      ),
      (
        ToastPosition.bottomEnd,
        ToastType.error,
        'bottomEnd',
        'GPS signal lost'
      ),
    ];
    for (final (position, type, title, text) in shown) {
      BetterToast.show(
        text,
        type: type,
        title: title,
        position: position,
        context: phone.currentContext,
      );
    }
    await _settle(tester);
    await _snap(tester, '05_positions');
    await _cleanUp(tester);
  });

  testWidgets('06 custom', (tester) async {
    final phone = GlobalKey();
    _view(tester, _canvas);
    await _pump(
      tester,
      _Frame(
        colors: _berry,
        headline: 'Fully custom.',
        api: 'BetterToast.custom(builder: …)',
        child: _CroppedPhone(
          screen: _App(
            anchor: phone,
            home: const _ShopScreen(),
            theme: const BetterToastThemeData(
              duration: Duration.zero,
              maxVisible: 4,
              spacing: 12,
            ),
          ),
        ),
      ),
    );
    BetterToast.custom(builder: _rewardToast, context: phone.currentContext);
    BetterToast.custom(builder: _messageToast, context: phone.currentContext);
    BetterToast.custom(builder: _cartToast, context: phone.currentContext);
    await _settle(tester);
    await _snap(tester, '06_custom');
    await _cleanUp(tester);
  });

  testWidgets('banner', (tester) async {
    final phone = GlobalKey();
    final front = GlobalKey();
    final back = GlobalKey();
    _view(tester, _bannerSize, dpr: 2);
    Widget chip(String label) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Text(label,
              style: _text(13, weight: FontWeight.w600, color: Colors.white)),
        );
    await _pump(
      tester,
      SizedBox.fromSize(
        size: _bannerSize,
        child: _Backdrop(
          colors: _hero,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: 520,
                top: 34,
                child: Transform.rotate(
                  angle: 6 * math.pi / 180,
                  child: _Phone(
                    width: 250,
                    screen: _App(
                      anchor: phone,
                      home: const _MusicScreen(),
                      chrome: Colors.white,
                      theme: const BetterToastThemeData(
                        duration: Duration.zero,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 400,
                top: 140,
                child: Transform.rotate(
                  angle: -3 * math.pi / 180,
                  child: _Floating(anchor: back, size: const Size(320, 96)),
                ),
              ),
              Positioned(
                left: 430,
                top: 220,
                child: Transform.rotate(
                  angle: -3 * math.pi / 180,
                  child: _Floating(anchor: front, size: const Size(320, 96)),
                ),
              ),
              Positioned(
                left: 52,
                top: 0,
                bottom: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    chip('Flutter package'),
                    const SizedBox(height: 16),
                    Text(
                      'better_toast',
                      style: _text(60,
                          weight: FontWeight.w900,
                          color: Colors.white,
                          spacing: -2,
                          height: 1),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Beautiful, customizable\ntoasts for Flutter',
                      style: _text(24,
                          weight: FontWeight.w500,
                          color: const Color(0xEBFFFFFF),
                          height: 1.25),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: 330,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final label in [
                            'Stacking',
                            'Promise',
                            'Actions',
                            'Glass',
                            'Dark mode',
                            'RTL',
                          ])
                            chip(label),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    BetterToast.info(
      'Maya Lin started following you',
      context: phone.currentContext,
    );
    BetterToast.warning('Storage almost full', context: phone.currentContext);
    BetterToast.info(
      'Ad-free, offline, lossless.',
      title: 'Try Premium free',
      style: _gradientStyle.copyWith(
        icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
      ),
      action: ToastAction(label: 'Start', onPressed: () {}),
      context: back.currentContext,
    );
    BetterToast.success(
      'Your photo is live.',
      title: 'Post published',
      action: ToastAction(label: 'View', onPressed: () {}),
      context: front.currentContext,
    );
    await _settle(tester);
    await _snap(tester, 'banner', dpr: 2);
    await _cleanUp(tester);
  });

  testWidgets('demo', (tester) async {
    // 25 fps. Each step pumps one frame interval and saves the frame.
    const frame = Duration(milliseconds: 40);
    const pixelRatio = 1.5;
    final dir = Directory('build/demo');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);

    final phone = GlobalKey();
    _view(tester, _canvas, dpr: pixelRatio);
    await _pump(
      tester,
      _Frame(
        colors: _hero,
        headline: 'Toasts,\nbeautifully.',
        api: 'BetterToast.show(…)',
        child: _CroppedPhone(
          screen: _App(
            anchor: phone,
            home: const _FeedScreen(),
            chrome: Colors.white,
            theme: const BetterToastThemeData(
              maxVisible: 4,
              showProgressBar: true,
              duration: Duration(milliseconds: 2600),
            ),
          ),
        ),
      ),
    );

    late ToastHandle upload;
    TestGesture? swipe;
    final script = <int, Future<void> Function()>{
      8: () async => BetterToast.success(
            'Your photo is live.',
            title: 'Post published',
            duration: const Duration(milliseconds: 4400),
            context: phone.currentContext,
          ),
      24: () async => BetterToast.info(
            'Maya Lin started following you',
            duration: Duration.zero,
            action: ToastAction(label: 'Follow', onPressed: () {}),
            context: phone.currentContext,
          ),
      42: () async => upload = BetterToast.loading(
            'beach_trip.mp4 · 248 MB',
            title: 'Uploading…',
            context: phone.currentContext,
          ),
      66: () async => upload.update(
            title: 'Almost there',
            text: 'Processing on the server…',
          ),
      90: () async => upload.update(
            type: ToastType.success,
            title: 'Uploaded',
            text: 'beach_trip.mp4 is in your library.',
            duration: const Duration(milliseconds: 2400),
          ),
      108: () async => BetterToast.error(
            'Upload failed',
            description: 'Check your connection.',
            duration: const Duration(milliseconds: 2000),
            action: ToastAction(label: 'Retry', onPressed: () {}),
            context: phone.currentContext,
          ),
      // The sticky toast is left alone; swipe it up to close it.
      164: () async {
        swipe = await tester.startGesture(
          tester.getCenter(find.text('Maya Lin started following you')),
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

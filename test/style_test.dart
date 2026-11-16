import 'package:better_toast/better_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToastStyle', () {
    test('merge lets non-null fields of the other style win', () {
      const ToastStyle base = ToastStyle(
        backgroundColor: Colors.red,
        iconSize: 10,
        showCloseButton: true,
      );
      final ToastStyle merged =
          base.merge(const ToastStyle(backgroundColor: Colors.blue));
      expect(merged.backgroundColor, Colors.blue);
      expect(merged.iconSize, 10);
      expect(merged.showCloseButton, isTrue);
      expect(base.merge(null), same(base));
    });

    test('merge combines text styles', () {
      const ToastStyle base = ToastStyle(
        titleStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      );
      final ToastStyle merged = base.merge(
        const ToastStyle(titleStyle: TextStyle(color: Colors.pink)),
      );
      expect(merged.titleStyle!.fontSize, 20);
      expect(merged.titleStyle!.fontWeight, FontWeight.w700);
      expect(merged.titleStyle!.color, Colors.pink);
    });

    test('a more specific background color drops a lower gradient', () {
      const ToastStyle base = ToastStyle(
        gradient: LinearGradient(colors: <Color>[Colors.red, Colors.blue]),
      );
      expect(
        base.merge(const ToastStyle(backgroundColor: Colors.green)).gradient,
        isNull,
      );
      expect(base.merge(const ToastStyle(iconSize: 3)).gradient, isNotNull);
    });

    test('copyWith replaces only given fields', () {
      const ToastStyle style = ToastStyle(blur: 4, width: 100);
      final ToastStyle copy = style.copyWith(width: 200);
      expect(copy.blur, 4);
      expect(copy.width, 200);
    });

    test('lerp interpolates numbers and colors', () {
      const ToastStyle a = ToastStyle(
        iconSize: 10,
        backgroundColor: Color(0xFF000000),
        showIcon: true,
      );
      const ToastStyle b = ToastStyle(
        iconSize: 20,
        backgroundColor: Color(0xFFFFFFFF),
        showIcon: false,
      );
      final ToastStyle mid = ToastStyle.lerp(a, b, 0.5)!;
      expect(mid.iconSize, 15);
      expect(mid.showIcon, isFalse);
      expect(ToastStyle.lerp(a, b, 0.25)!.showIcon, isTrue);
      expect(ToastStyle.lerp(null, null, 0.5), isNull);
    });

    test('equality and hashCode are value based', () {
      ToastStyle make(double blur) => ToastStyle(
            backgroundColor: Colors.red,
            shadows: <BoxShadow>[BoxShadow(blurRadius: blur)],
            padding: EdgeInsets.all(blur),
          );
      expect(identical(make(3), make(3)), isFalse);
      expect(make(3), make(3));
      expect(make(3).hashCode, make(3).hashCode);
      expect(make(3), isNot(make(4)));
    });

    test('fallback derives colors from the color scheme', () {
      for (final Brightness brightness in Brightness.values) {
        final ThemeData theme = ThemeData(brightness: brightness);
        final ToastStyle style = ToastStyle.fallback(theme, ToastType.error);
        expect(style.iconColor, theme.colorScheme.error);
        expect(style.foregroundColor, theme.colorScheme.onSurface);
        expect(style.showIcon, isTrue);
      }
      expect(
        ToastStyle.fallback(ThemeData(), ToastType.custom).showIcon,
        isFalse,
      );
    });
  });

  group('BetterToastThemeData', () {
    test('fallback sets every behavioral field', () {
      const BetterToastThemeData t = BetterToastThemeData.fallback;
      expect(t.position, ToastPosition.top);
      expect(t.duration, const Duration(seconds: 4));
      expect(t.maxVisible, 3);
      expect(t.stackMode, ToastStackMode.stack);
      expect(t.respectSafeArea, isTrue);
    });

    test('merge combines type styles per type', () {
      const BetterToastThemeData base = BetterToastThemeData(
        maxVisible: 2,
        typeStyles: <ToastType, ToastStyle>{
          ToastType.error: ToastStyle(iconSize: 10, blur: 1),
        },
      );
      final BetterToastThemeData merged = base.merge(
        const BetterToastThemeData(
          typeStyles: <ToastType, ToastStyle>{
            ToastType.error: ToastStyle(iconSize: 30),
            ToastType.info: ToastStyle(blur: 5),
          },
        ),
      );
      expect(merged.maxVisible, 2);
      expect(merged.typeStyles![ToastType.error]!.iconSize, 30);
      expect(merged.typeStyles![ToastType.error]!.blur, 1);
      expect(merged.typeStyles![ToastType.info]!.blur, 5);
    });

    test('styleFor applies fallback < default < type < call', () {
      const BetterToastThemeData data = BetterToastThemeData(
        defaultStyle: ToastStyle(iconSize: 1, blur: 1, width: 1),
        typeStyles: <ToastType, ToastStyle>{
          ToastType.success: ToastStyle(blur: 2, width: 2),
        },
      );
      final ToastStyle style = data.styleFor(
        ThemeData(),
        ToastType.success,
        const ToastStyle(width: 3),
      );
      expect(style.iconSize, 1);
      expect(style.blur, 2);
      expect(style.width, 3);
      expect(style.padding, isNotNull);
    });

    test('works as a ThemeExtension', () {
      const BetterToastThemeData a = BetterToastThemeData(
        spacing: 0,
        position: ToastPosition.top,
      );
      const BetterToastThemeData b = BetterToastThemeData(
        spacing: 10,
        position: ToastPosition.bottom,
      );
      final BetterToastThemeData mid = a.lerp(b, 0.6);
      expect(mid.spacing, 6);
      expect(mid.position, ToastPosition.bottom);
      expect(a.copyWith(maxVisible: 9).maxVisible, 9);
      expect(a.copyWith(maxVisible: 9).position, ToastPosition.top);

      final ThemeData theme = ThemeData(
        extensions: const <ThemeExtension<dynamic>>[a],
      );
      expect(theme.extension<BetterToastThemeData>(), a);
    });

    test('equality is value based', () {
      BetterToastThemeData make(double blur) => BetterToastThemeData(
            maxVisible: 4,
            typeStyles: <ToastType, ToastStyle>{
              ToastType.info: ToastStyle(blur: blur),
            },
          );
      expect(identical(make(2), make(2)), isFalse);
      expect(make(2), make(2));
      expect(make(2).hashCode, make(2).hashCode);
      expect(make(2), isNot(make(3)));
    });
  });

  group('ToastPosition', () {
    test('edges', () {
      expect(ToastPosition.topEnd.isTop, isTrue);
      expect(ToastPosition.bottomLeft.isBottom, isTrue);
      expect(ToastPosition.center.isTop, isFalse);
      expect(ToastPosition.center.isBottom, isFalse);
      expect(ToastPosition.topStart.alignment, AlignmentDirectional.topStart);
    });
  });
}

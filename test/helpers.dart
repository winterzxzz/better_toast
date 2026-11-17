import 'package:better_toast/better_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a [MaterialApp] that hosts toasts through [BetterToast.init].
Future<void> pumpToastApp(
  WidgetTester tester, {
  BetterToastThemeData? theme,
  ThemeData? appTheme,
  Widget? home,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: appTheme,
      builder: BetterToast.init(theme: theme),
      home: home ?? const Scaffold(body: Center(child: Text('home'))),
    ),
  );
}

/// The decoration of the toast card that shows [text].
BoxDecoration cardDecoration(WidgetTester tester, String text) {
  final Finder box = find
      .ancestor(of: find.text(text), matching: find.byType(DecoratedBox))
      .first;
  return tester.widget<DecoratedBox>(box).decoration as BoxDecoration;
}

/// Lets enter animations finish without waiting for timers.
Future<void> settleIn(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Lets a just-expired timer fire and the exit animation finish.
///
/// A ticker starts on the first frame after it is scheduled, and finishes on
/// the first frame strictly after its duration, so this pumps a few frames.
Future<void> settleOut(WidgetTester tester) async {
  for (int i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

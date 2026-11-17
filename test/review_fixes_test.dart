import 'dart:async';

import 'package:better_toast/better_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Regression tests for the v0.1.0 review findings (S1-S6 and nits).
void main() {
  group('S1 init builder', () {
    testWidgets('wrappers from init(builder:) reach the toasts',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: BetterToast.init(
            theme: const BetterToastThemeData(duration: Duration.zero),
            builder: (BuildContext context, Widget? child) => Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          ),
          home: const SizedBox(),
        ),
      );
      BetterToast.show('rtl');
      await settleIn(tester);
      expect(
        Directionality.of(tester.element(find.text('rtl'))),
        TextDirection.rtl,
      );
    });

    testWidgets('init builder still wraps the app content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: BetterToast.init(
            builder: (BuildContext context, Widget? child) => Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          ),
          home: const Text('home'),
        ),
      );
      expect(
        Directionality.of(tester.element(find.text('home'))),
        TextDirection.rtl,
      );
    });
  });

  group('S2 position move', () {
    testWidgets('a toast moved by id still plays its exit animation',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      BetterToast.loading('Working', id: 'u', position: ToastPosition.bottom);
      await settleIn(tester);
      final ToastHandle handle =
          BetterToast.success('Done', id: 'u', duration: Duration.zero);
      await settleIn(tester);
      expect(find.text('Done'), findsOneWidget);

      handle.dismiss();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      // Still on screen: the exit animation runs.
      expect(find.text('Done'), findsOneWidget);
      await settleOut(tester);
      expect(find.text('Done'), findsNothing);
    });
  });

  group('S3 accessible navigation', () {
    testWidgets('toasts with an action stay while accessibleNavigation is on',
        (WidgetTester tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pumpToastApp(tester);
      BetterToast.show(
        'With action',
        duration: const Duration(seconds: 1),
        action: ToastAction(label: 'Undo', onPressed: () {}),
      );
      BetterToast.show('Plain', duration: const Duration(seconds: 1));
      await settleIn(tester);
      await tester.pump(const Duration(seconds: 2));
      await settleOut(tester);
      expect(find.text('With action'), findsOneWidget);
      expect(find.text('Plain'), findsNothing);
      BetterToast.dismissAll();
      await settleOut(tester);
    });
  });

  group('S4 update', () {
    testWidgets('clear flags remove fields', (WidgetTester tester) async {
      await pumpToastApp(tester);
      final ToastHandle handle = BetterToast.loading(
        'Uploading',
        title: 'T',
        description: 'D',
        style: const ToastStyle(showCloseButton: true),
        action: ToastAction(label: 'Cancel', onPressed: () {}),
      );
      await settleIn(tester);
      expect(find.text('Cancel'), findsOneWidget);

      handle.update(
        text: 'Uploaded',
        type: ToastType.success,
        clearTitle: true,
        clearDescription: true,
        clearAction: true,
        clearStyle: true,
      );
      await tester.pump();
      expect(find.text('Cancel'), findsNothing);
      expect(find.text('T'), findsNothing);
      expect(find.text('D'), findsNothing);
      expect(handle.action, isNull);
      expect(handle.style, isNull);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      handle.dismiss();
      await settleOut(tester);
    });

    testWidgets('loading to success starts the theme timer',
        (WidgetTester tester) async {
      await pumpToastApp(
        tester,
        theme: const BetterToastThemeData(duration: Duration(seconds: 1)),
      );
      final ToastHandle handle = BetterToast.loading('Uploading');
      await settleIn(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Uploading'), findsOneWidget);

      handle.update(text: 'Uploaded', type: ToastType.success);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      await settleOut(tester);
      expect(find.text('Uploaded'), findsNothing);
      expect(handle.isActive, isFalse);
    });
  });

  group('S5 onDismissed', () {
    testWidgets('onDismissed may call setState while the host unmounts',
        (WidgetTester tester) async {
      final ValueNotifier<bool> showApp = ValueNotifier<bool>(true);
      final ValueNotifier<int> count = ValueNotifier<int>(0);
      addTearDown(showApp.dispose);
      addTearDown(count.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<int>(
          valueListenable: count,
          builder: (BuildContext context, int c, Widget? _) =>
              ValueListenableBuilder<bool>(
            valueListenable: showApp,
            builder: (BuildContext context, bool show, Widget? _) => show
                ? MaterialApp(
                    builder: BetterToast.init(),
                    home: const SizedBox(),
                  )
                : Text('count $c', textDirection: TextDirection.ltr),
          ),
        ),
      );
      BetterToast.show(
        'bye',
        duration: Duration.zero,
        onDismissed: () => count.value++,
      );
      await settleIn(tester);

      showApp.value = false;
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pump();
      expect(count.value, 1);
      expect(find.text('count 1'), findsOneWidget);
    });

    testWidgets('a throwing onDismissed does not break unmounting',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      bool secondCalled = false;
      final ToastHandle first = BetterToast.show(
        'one',
        duration: Duration.zero,
        onDismissed: () => throw StateError('boom'),
      );
      final ToastHandle second = BetterToast.show(
        'two',
        duration: Duration.zero,
        onDismissed: () => secondCalled = true,
      );
      await settleIn(tester);
      bool firstClosed = false;
      bool secondClosed = false;
      unawaited(first.closed.then((_) => firstClosed = true));
      unawaited(second.closed.then((_) => secondClosed = true));

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isA<StateError>());
      expect(secondCalled, isTrue);
      expect(firstClosed, isTrue);
      expect(secondClosed, isTrue);
    });
  });

  group('S6 close button', () {
    testWidgets('close button has a large tap target',
        (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpToastApp(tester);
      BetterToast.show(
        'Closable',
        duration: Duration.zero,
        style: const ToastStyle(showCloseButton: true),
      );
      await settleIn(tester);

      final Finder icon = find.byIcon(Icons.close_rounded);
      // The visual stays small.
      expect(tester.getSize(icon), const Size(18, 18));

      final Rect rect = tester.getSemantics(icon).rect;
      expect(rect.width, greaterThanOrEqualTo(40));
      expect(rect.height, greaterThanOrEqualTo(40));

      // A tap 16px left of the icon center, outside the old 26x26 box,
      // still closes the toast.
      await tester.tapAt(tester.getCenter(icon) - const Offset(16, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await settleOut(tester);
      expect(find.text('Closable'), findsNothing);
      semantics.dispose();
    });

    testWidgets('close button keeps the default toast height',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      BetterToast.show(
        'B',
        duration: Duration.zero,
        style: const ToastStyle(showCloseButton: true),
      );
      await settleIn(tester);
      // 12 + 26 + 12: the height before the tap target was enlarged.
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.text('B'),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .height,
        50,
      );
    });

    testWidgets('close button meets the Android tap target guideline',
        (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpToastApp(tester);
      BetterToast.show(
        'G',
        duration: Duration.zero,
        style: const ToastStyle(showCloseButton: true),
      );
      await settleIn(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      semantics.dispose();
    });
  });

  group('S7 app lifecycle', () {
    testWidgets('timers pause while the app is in the background',
        (WidgetTester tester) async {
      addTearDown(
        () => tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      await pumpToastApp(tester);
      final ToastHandle handle =
          BetterToast.show('bg', duration: const Duration(seconds: 4));
      await settleIn(tester);
      await tester.pump(const Duration(seconds: 1));
      final double before = handle.progress.value;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 10));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // The 10 s in the background did not count.
      expect(handle.isActive, isTrue);
      expect(handle.progress.value, closeTo(before - 0.1 / 4, 0.02));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('bg'), findsOneWidget);
      expect(handle.isActive, isTrue);

      await tester.pump(const Duration(seconds: 3));
      await settleOut(tester);
      expect(find.text('bg'), findsNothing);
    });

    testWidgets('a manually paused toast stays paused after resume',
        (WidgetTester tester) async {
      addTearDown(
        () => tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      await pumpToastApp(tester);
      final ToastHandle handle =
          BetterToast.show('manual', duration: const Duration(seconds: 2));
      await settleIn(tester);
      handle.pause();
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(const Duration(seconds: 5));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await settleOut(tester);
      expect(find.text('manual'), findsOneWidget);

      handle.resume();
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await settleOut(tester);
      expect(find.text('manual'), findsNothing);
    });
  });

  group('nits', () {
    testWidgets('raising maxVisible releases queued toasts',
        (WidgetTester tester) async {
      Widget app(int maxVisible) => MaterialApp(
            builder: BetterToast.init(
              theme: BetterToastThemeData(
                maxVisible: maxVisible,
                duration: Duration.zero,
              ),
            ),
            home: const SizedBox(),
          );
      await tester.pumpWidget(app(1));
      BetterToast.show('one');
      BetterToast.show('two');
      await settleIn(tester);
      expect(find.text('two'), findsNothing);

      await tester.pumpWidget(app(2));
      await settleIn(tester);
      expect(find.text('two'), findsOneWidget);
    });

    test('ToastStyle.lerp keeps a size that is set on one side only', () {
      const ToastStyle a = ToastStyle(
        maxWidth: 400,
        width: 300,
        iconSize: 20,
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.all(4),
      );
      const ToastStyle b = ToastStyle();
      for (final double t in <double>[0, 0.25, 0.5, 0.75, 1]) {
        final ToastStyle ab = ToastStyle.lerp(a, b, t)!;
        final ToastStyle ba = ToastStyle.lerp(b, a, t)!;
        for (final ToastStyle s in <ToastStyle>[ab, ba]) {
          expect(s.maxWidth, 400);
          expect(s.width, 300);
          expect(s.iconSize, 20);
          expect(s.padding, const EdgeInsets.all(10));
          expect(s.margin, const EdgeInsets.all(4));
        }
      }
      expect(
        ToastStyle.lerp(
          const ToastStyle(maxWidth: 200),
          const ToastStyle(maxWidth: 400),
          0.5,
        )!
            .maxWidth,
        300,
      );
    });

    test('BetterToastThemeData.lerp keeps a size set on one side only', () {
      const BetterToastThemeData a = BetterToastThemeData(
        spacing: 10,
        margin: EdgeInsets.all(8),
      );
      const BetterToastThemeData b = BetterToastThemeData();
      final BetterToastThemeData ab = a.lerp(b, 0.5);
      final BetterToastThemeData ba = b.lerp(a, 0.5);
      expect(ab.spacing, 10);
      expect(ba.spacing, 10);
      expect(ab.margin, const EdgeInsets.all(8));
      expect(ba.margin, const EdgeInsets.all(8));
    });

    testWidgets('show without text or message asserts',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      expect(() => BetterToast.show(null), throwsAssertionError);
      expect(() => BetterToast.success(null), throwsAssertionError);
      // A title alone is still a toast with content.
      BetterToast.show(null, title: 'Only title', duration: Duration.zero);
      await settleIn(tester);
      expect(find.text('Only title'), findsOneWidget);
    });

    testWidgets(
        'promise does not turn a throwing success callback into '
        'an error toast', (WidgetTester tester) async {
      await pumpToastApp(tester);
      final Completer<int> completer = Completer<int>();
      Object? caught;
      unawaited(
        BetterToast.promise<int>(
          completer.future,
          loading: 'Loading…',
          success: (int value) => throw StateError('bad callback'),
          error: (Object error) => 'Failed',
          id: 'p',
        ).then<void>((_) {}, onError: (Object e) => caught = e),
      );
      await settleIn(tester);
      completer.complete(1);
      await tester.pump();
      await tester.pump();
      expect(find.text('Failed'), findsNothing);
      expect(caught, isA<StateError>());
      await settleOut(tester);
      expect(find.text('Loading…'), findsNothing);
      expect(BetterToast.isActive('p'), isFalse);
    });
  });
}

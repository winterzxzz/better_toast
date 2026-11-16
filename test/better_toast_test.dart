import 'dart:async';

import 'package:better_toast/better_toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('show and dismiss', () {
    testWidgets('shows a toast and dismisses it with the handle',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      bool dismissedCalled = false;
      final ToastHandle handle = BetterToast.show(
        'Hello',
        title: 'Title',
        description: 'Details',
        onDismissed: () => dismissedCalled = true,
      );
      await settleIn(tester);

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(handle.isActive, isTrue);

      bool closed = false;
      unawaited(handle.closed.then((_) => closed = true));
      handle.dismiss();
      expect(handle.isActive, isFalse);
      await settleOut(tester);

      expect(find.text('Hello'), findsNothing);
      expect(closed, isTrue);
      expect(dismissedCalled, isTrue);
    });

    testWidgets('accepts a widget message', (WidgetTester tester) async {
      await pumpToastApp(tester);
      BetterToast.show(null, message: const Text.rich(TextSpan(text: 'Rich')));
      await settleIn(tester);
      expect(find.text('Rich'), findsOneWidget);
    });

    testWidgets('typed helpers set the type', (WidgetTester tester) async {
      await pumpToastApp(tester);
      expect(BetterToast.success('a').type, ToastType.success);
      expect(BetterToast.error('b').type, ToastType.error);
      expect(BetterToast.warning('c').type, ToastType.warning);
      expect(BetterToast.info('d').type, ToastType.info);
      expect(BetterToast.loading('e').type, ToastType.loading);
      BetterToast.dismissAll();
      await settleOut(tester);
    });

    testWidgets('action button runs its callback and dismisses',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      int pressed = 0;
      final ToastHandle handle = BetterToast.show(
        'Archived',
        action: ToastAction(label: 'Undo', onPressed: () => pressed++),
      );
      await settleIn(tester);
      await tester.tap(find.text('Undo'));
      expect(pressed, 1);
      expect(handle.isActive, isFalse);
      await settleOut(tester);
      expect(find.text('Archived'), findsNothing);
    });

    testWidgets('close button dismisses', (WidgetTester tester) async {
      await pumpToastApp(tester);
      BetterToast.show(
        'Closable',
        style: const ToastStyle(showCloseButton: true),
      );
      await settleIn(tester);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await settleOut(tester);
      expect(find.text('Closable'), findsNothing);
    });

    testWidgets('onTap is called', (WidgetTester tester) async {
      await pumpToastApp(tester);
      int taps = 0;
      BetterToast.show('Tap me', onTap: () => taps++);
      await settleIn(tester);
      await tester.tap(find.text('Tap me'));
      expect(taps, 1);
    });

    testWidgets('swipe dismisses a top toast', (WidgetTester tester) async {
      await pumpToastApp(tester);
      bool dismissed = false;
      BetterToast.show(
        'Swipe',
        duration: Duration.zero,
        onDismissed: () => dismissed = true,
      );
      await settleIn(tester);
      await tester.fling(find.text('Swipe'), const Offset(0, -300), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Swipe'), findsNothing);
      expect(dismissed, isTrue);
    });

    testWidgets('dismissible: false ignores swipes',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      BetterToast.show('Stay', duration: Duration.zero, dismissible: false);
      await settleIn(tester);
      await tester.fling(find.text('Stay'), const Offset(0, -300), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Stay'), findsOneWidget);
    });
  });

  group('timing', () {
    testWidgets('auto-dismisses after its duration',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      final ToastHandle handle =
          BetterToast.show('Timed', duration: const Duration(seconds: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      expect(find.text('Timed'), findsOneWidget);
      expect(handle.isActive, isTrue);
      expect(handle.progress.value, lessThan(0.1));

      await tester.pump(const Duration(milliseconds: 150));
      expect(handle.isActive, isFalse);
      await settleOut(tester);
      expect(find.text('Timed'), findsNothing);
    });

    testWidgets('uses the theme duration by default',
        (WidgetTester tester) async {
      await pumpToastApp(
        tester,
        theme: const BetterToastThemeData(duration: Duration(seconds: 1)),
      );
      BetterToast.show('Theme timed');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('Theme timed'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 150));
      await settleOut(tester);
      expect(find.text('Theme timed'), findsNothing);
    });

    testWidgets('Duration.zero is sticky', (WidgetTester tester) async {
      await pumpToastApp(tester);
      final ToastHandle handle =
          BetterToast.show('Sticky', duration: Duration.zero);
      await tester.pump();
      await tester.pump(const Duration(minutes: 5));
      expect(find.text('Sticky'), findsOneWidget);
      expect(handle.isActive, isTrue);
      expect(handle.progress.value, 1.0);
    });

    testWidgets('loading toasts are sticky by default',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      BetterToast.loading('Working');
      await tester.pump();
      await tester.pump(const Duration(minutes: 1));
      expect(find.text('Working'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      BetterToast.dismissAll();
      await settleOut(tester);
    });

    testWidgets('pauses while pressed', (WidgetTester tester) async {
      await pumpToastApp(tester);
      BetterToast.show('Hold', duration: const Duration(seconds: 2));
      await settleIn(tester);

      final TestGesture gesture =
          await tester.startGesture(tester.getCenter(find.text('Hold')));
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Hold'), findsOneWidget);

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('Hold'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
      await settleOut(tester);
      expect(find.text('Hold'), findsNothing);
    });

    testWidgets('pauses while hovered', (WidgetTester tester) async {
      await pumpToastApp(tester);
      BetterToast.show('Hover', duration: const Duration(seconds: 2));
      await settleIn(tester);

      final TestGesture mouse =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Hover')));
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Hover'), findsOneWidget);

      await mouse.moveTo(const Offset(1, 599));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await settleOut(tester);
      expect(find.text('Hover'), findsNothing);
    });

    testWidgets('pauseOnTouch: false keeps the timer running',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      BetterToast.show(
        'No pause',
        duration: const Duration(seconds: 1),
        pauseOnTouch: false,
        dismissible: false,
      );
      await settleIn(tester);
      final TestGesture gesture =
          await tester.startGesture(tester.getCenter(find.text('No pause')));
      await tester.pump(const Duration(seconds: 1));
      await settleOut(tester);
      expect(find.text('No pause'), findsNothing);
      await gesture.up();
    });

    testWidgets('handle.pause and resume control the timer',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      final ToastHandle handle =
          BetterToast.show('Manual', duration: const Duration(seconds: 1));
      await tester.pump();
      handle.pause();
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Manual'), findsOneWidget);
      handle.resume();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await settleOut(tester);
      expect(find.text('Manual'), findsNothing);
    });

    testWidgets('shows a progress bar that shrinks',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      BetterToast.show(
        'Progress',
        duration: const Duration(seconds: 2),
        showProgressBar: true,
      );
      await tester.pump();
      final Finder bar = find.byType(FractionallySizedBox);
      expect(bar, findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      final double factor =
          tester.widget<FractionallySizedBox>(bar).widthFactor!;
      expect(factor, closeTo(0.5, 0.05));
    });
  });

  group('ids and updates', () {
    testWidgets('same id updates in place without a duplicate',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      final ToastHandle first = BetterToast.show('Uploading 10%', id: 'up');
      await settleIn(tester);
      final ToastHandle second = BetterToast.show('Uploading 90%', id: 'up');
      await tester.pump();

      expect(identical(first, second), isTrue);
      expect(first.id, 'up');
      expect(find.text('Uploading 10%'), findsNothing);
      expect(find.text('Uploading 90%'), findsOneWidget);
      expect(BetterToast.isActive('up'), isTrue);
    });

    testWidgets('handle.update changes content and restarts the timer',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      final ToastHandle handle =
          BetterToast.loading('Saving', id: 'save', title: 'Busy');
      await settleIn(tester);
      handle.update(
        text: 'Saved',
        type: ToastType.success,
        duration: const Duration(seconds: 1),
      );
      await tester.pump();
      expect(find.text('Saving'), findsNothing);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Busy'), findsOneWidget);
      expect(handle.type, ToastType.success);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1100));
      await settleOut(tester);
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('BetterToast.dismiss closes by id',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      BetterToast.show('Keep', duration: Duration.zero);
      BetterToast.show('Drop', id: 42, duration: Duration.zero);
      await settleIn(tester);
      BetterToast.dismiss(42);
      expect(BetterToast.isActive(42), isFalse);
      await settleOut(tester);
      expect(find.text('Drop'), findsNothing);
      expect(find.text('Keep'), findsOneWidget);
    });

    testWidgets('update after dismiss is a no-op', (WidgetTester tester) async {
      await pumpToastApp(tester);
      final ToastHandle handle = BetterToast.show('Gone');
      await settleIn(tester);
      handle.dismiss();
      handle.update(text: 'Back');
      await settleOut(tester);
      expect(find.text('Back'), findsNothing);
    });
  });

  group('stacking', () {
    testWidgets('maxVisible queues extra toasts', (WidgetTester tester) async {
      await pumpToastApp(
        tester,
        theme: const BetterToastThemeData(
          maxVisible: 2,
          duration: Duration.zero,
        ),
      );
      final ToastHandle first = BetterToast.show('one');
      BetterToast.show('two');
      final ToastHandle third = BetterToast.show('three');
      await settleIn(tester);

      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
      expect(find.text('three'), findsNothing);
      expect(third.isActive, isTrue);

      first.dismiss();
      await settleIn(tester);
      expect(find.text('three'), findsOneWidget);
      await settleOut(tester);
      expect(find.text('one'), findsNothing);
    });

    testWidgets('dismissing a queued toast removes it at once',
        (WidgetTester tester) async {
      await pumpToastApp(
        tester,
        theme: const BetterToastThemeData(
          maxVisible: 1,
          duration: Duration.zero,
        ),
      );
      BetterToast.show('visible');
      final ToastHandle queued = BetterToast.show('queued');
      bool closed = false;
      unawaited(queued.closed.then((_) => closed = true));
      queued.dismiss();
      await tester.pump();
      expect(closed, isTrue);
      expect(find.text('queued'), findsNothing);
    });

    testWidgets('newest top toast is closest to the edge',
        (WidgetTester tester) async {
      await pumpToastApp(
        tester,
        theme: const BetterToastThemeData(duration: Duration.zero),
      );
      BetterToast.show('older');
      BetterToast.show('newer');
      await settleIn(tester);
      expect(
        tester.getTopLeft(find.text('newer')).dy,
        lessThan(tester.getTopLeft(find.text('older')).dy),
      );
    });

    testWidgets('dismissAll closes visible and queued toasts',
        (WidgetTester tester) async {
      await pumpToastApp(
        tester,
        theme: const BetterToastThemeData(
          maxVisible: 2,
          duration: Duration.zero,
        ),
      );
      final List<ToastHandle> handles = <ToastHandle>[
        BetterToast.show('a'),
        BetterToast.show('b'),
        BetterToast.show('c'),
      ];
      await settleIn(tester);
      BetterToast.dismissAll();
      expect(handles.every((ToastHandle h) => !h.isActive), isTrue);
      await settleOut(tester);
      expect(find.text('a'), findsNothing);
      expect(find.text('b'), findsNothing);
      expect(find.text('c'), findsNothing);
    });

    testWidgets('queue mode shows one toast at a time',
        (WidgetTester tester) async {
      await pumpToastApp(
        tester,
        theme: const BetterToastThemeData(
          stackMode: ToastStackMode.queue,
          duration: Duration(seconds: 1),
        ),
      );
      BetterToast.show('first');
      BetterToast.show('second');
      await settleIn(tester);
      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      await settleOut(tester);
      await settleIn(tester);
      expect(find.text('first'), findsNothing);
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('replace mode closes older toasts',
        (WidgetTester tester) async {
      await pumpToastApp(
        tester,
        theme: const BetterToastThemeData(
          stackMode: ToastStackMode.replace,
          duration: Duration.zero,
        ),
      );
      final ToastHandle old = BetterToast.show('old');
      await settleIn(tester);
      BetterToast.show('new');
      expect(old.isActive, isFalse);
      await settleOut(tester);
      await settleIn(tester);
      expect(find.text('old'), findsNothing);
      expect(find.text('new'), findsOneWidget);
    });
  });

  group('theming', () {
    testWidgets('theme < type style < per-call style',
        (WidgetTester tester) async {
      const Color themeColor = Color(0xFFFF0000);
      const Color typeColor = Color(0xFF00FF00);
      const Color callColor = Color(0xFF0000FF);
      await pumpToastApp(
        tester,
        theme: const BetterToastThemeData(
          duration: Duration.zero,
          defaultStyle: ToastStyle(
            backgroundColor: themeColor,
            borderRadius: BorderRadius.all(Radius.circular(3)),
          ),
          typeStyles: <ToastType, ToastStyle>{
            ToastType.success: ToastStyle(backgroundColor: typeColor),
          },
        ),
      );
      BetterToast.info('info');
      BetterToast.success('success');
      BetterToast.success(
        'call',
        style: const ToastStyle(backgroundColor: callColor),
      );
      await settleIn(tester);

      expect(cardDecoration(tester, 'info').color, themeColor);
      expect(cardDecoration(tester, 'success').color, typeColor);
      expect(cardDecoration(tester, 'call').color, callColor);
      // Fields not overridden by higher layers still come from the theme.
      expect(
        cardDecoration(tester, 'call').borderRadius,
        const BorderRadius.all(Radius.circular(3)),
      );
    });

    testWidgets('scope theme wins over the ThemeExtension',
        (WidgetTester tester) async {
      await pumpToastApp(
        tester,
        appTheme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[
            BetterToastThemeData(
              duration: Duration.zero,
              defaultStyle: ToastStyle(
                backgroundColor: Color(0xFF111111),
                foregroundColor: Color(0xFF222222),
              ),
            ),
          ],
        ),
        theme: const BetterToastThemeData(
          defaultStyle: ToastStyle(backgroundColor: Color(0xFF333333)),
        ),
      );
      BetterToast.show('ext');
      await settleIn(tester);
      expect(cardDecoration(tester, 'ext').color, const Color(0xFF333333));
      expect(
        tester.widget<Text>(find.text('ext')).style!.color,
        const Color(0xFF222222),
      );
      // The extension's sticky duration still applies.
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('ext'), findsOneWidget);
    });

    testWidgets('default colors follow the color scheme',
        (WidgetTester tester) async {
      final ThemeData dark = ThemeData(brightness: Brightness.dark);
      await pumpToastApp(tester, appTheme: dark);
      BetterToast.show('dark', duration: Duration.zero);
      await settleIn(tester);
      expect(
        cardDecoration(tester, 'dark').color,
        dark.colorScheme.surfaceContainerHigh,
      );
      expect(
        tester.widget<Text>(find.text('dark')).style!.color,
        dark.colorScheme.onSurface,
      );
    });

    testWidgets('BetterToastTheme.resolveStyle matches the visual',
        (WidgetTester tester) async {
      late ToastStyle resolved;
      await pumpToastApp(
        tester,
        theme: const BetterToastThemeData(
          typeStyles: <ToastType, ToastStyle>{
            ToastType.error: ToastStyle(iconSize: 30),
          },
        ),
      );
      BetterToast.custom(
        builder: (BuildContext context, ToastHandle handle) {
          resolved = BetterToastTheme.resolveStyle(context, ToastType.error);
          return const Text('probe');
        },
      );
      await settleIn(tester);
      expect(resolved.iconSize, 30);
      expect(resolved.backgroundColor, isNotNull);
    });
  });

  group('custom builders', () {
    testWidgets('BetterToast.custom renders the builder',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      final ToastHandle handle = BetterToast.custom(
        id: 'chip',
        duration: Duration.zero,
        builder: (BuildContext context, ToastHandle handle) => ActionChip(
          label: Text('Custom ${handle.id}'),
          onPressed: handle.dismiss,
        ),
      );
      await settleIn(tester);
      expect(handle.type, ToastType.custom);
      expect(find.text('Custom chip'), findsOneWidget);
      await tester.tap(find.text('Custom chip'));
      await settleOut(tester);
      expect(find.text('Custom chip'), findsNothing);
    });

    testWidgets('theme builder replaces the default visual',
        (WidgetTester tester) async {
      await pumpToastApp(
        tester,
        theme: BetterToastThemeData(
          duration: Duration.zero,
          builder: (BuildContext context, ToastHandle handle) =>
              Text('[${handle.type.name}] ${handle.text}'),
        ),
      );
      BetterToast.warning('careful');
      await settleIn(tester);
      expect(find.text('[warning] careful'), findsOneWidget);
      expect(find.text('careful'), findsNothing);
    });

    testWidgets('custom transition builder is used',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      BetterToast.show(
        'spin',
        duration: Duration.zero,
        animation: ToastAnimation.custom,
        transitionBuilder: (
          BuildContext context,
          Animation<double> animation,
          ToastPosition position,
          Widget child,
        ) =>
            RotationTransition(
          key: const ValueKey<String>('custom-transition'),
          turns: animation,
          child: child,
        ),
      );
      await settleIn(tester);
      expect(
        find.byKey(const ValueKey<String>('custom-transition')),
        findsOneWidget,
      );
    });
  });

  group('promise', () {
    testWidgets('turns into a success toast', (WidgetTester tester) async {
      await pumpToastApp(tester);
      final Completer<int> completer = Completer<int>();
      int? result;
      unawaited(
        BetterToast.promise<int>(
          completer.future,
          loading: 'Loading…',
          success: (int value) => 'Got $value',
          error: (Object error) => 'Failed',
          duration: const Duration(seconds: 1),
        ).then((int value) => result = value),
      );
      await settleIn(tester);
      expect(find.text('Loading…'), findsOneWidget);

      completer.complete(42);
      await tester.pump();
      await tester.pump();
      expect(find.text('Loading…'), findsNothing);
      expect(find.text('Got 42'), findsOneWidget);
      expect(result, 42);

      await tester.pump(const Duration(milliseconds: 1100));
      await settleOut(tester);
      expect(find.text('Got 42'), findsNothing);
    });

    testWidgets('turns into an error toast and rethrows',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      final Completer<int> completer = Completer<int>();
      Object? caught;
      unawaited(
        BetterToast.promise<int>(
          completer.future,
          loading: 'Loading…',
          success: (int value) => 'Got $value',
          error: (Object error) => 'Failed: $error',
        ).then<void>((_) {}, onError: (Object e) => caught = e),
      );
      await settleIn(tester);
      completer.completeError(StateError('boom'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Failed: Bad state: boom'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
      expect(caught, isA<StateError>());
      BetterToast.dismissAll();
      await settleOut(tester);
    });
  });

  group('platform behavior', () {
    testWidgets('reduce motion skips animations but keeps timing',
        (WidgetTester tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpToastApp(tester);
      final ToastHandle handle =
          BetterToast.show('Calm', duration: const Duration(seconds: 2));
      await tester.pump();
      final Offset shown = tester.getTopLeft(find.text('Calm'));
      expect(
          find.byType(FadeTransition).evaluate().where(
                (Element e) => (e.widget as FadeTransition).opacity.value < 1,
              ),
          isEmpty);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.getTopLeft(find.text('Calm')), shown);

      // The display time is not shortened by the accessibility setting.
      await tester.pump(const Duration(milliseconds: 1000));
      expect(handle.isActive, isTrue);

      handle.dismiss();
      await tester.pump();
      await tester.pump();
      expect(find.text('Calm'), findsNothing);
    });

    testWidgets('announces toasts as a live region',
        (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpToastApp(tester);
      BetterToast.show('Announced', duration: Duration.zero);
      await settleIn(tester);
      expect(
        tester.getSemantics(find.text('Announced')),
        isSemantics(label: 'Announced', isLiveRegion: true),
      );
      semantics.dispose();
    });

    testWidgets('toasts survive route changes', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          builder: BetterToast.init(),
          home: const Scaffold(body: Text('first page')),
        ),
      );
      BetterToast.show('Persistent', duration: Duration.zero);
      await settleIn(tester);
      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('second page')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('second page'), findsOneWidget);
      expect(find.text('Persistent'), findsOneWidget);
    });

    testWidgets('positions place toasts at the right edge',
        (WidgetTester tester) async {
      await pumpToastApp(
        tester,
        theme: const BetterToastThemeData(duration: Duration.zero),
      );
      BetterToast.show('top', position: ToastPosition.top);
      BetterToast.show('bottom', position: ToastPosition.bottom);
      BetterToast.show('center', position: ToastPosition.center);
      await settleIn(tester);
      final double height =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(tester.getCenter(find.text('top')).dy, lessThan(height / 3));
      expect(
        tester.getCenter(find.text('bottom')).dy,
        greaterThan(height * 2 / 3),
      );
      expect(
        tester.getCenter(find.text('center')).dy,
        closeTo(height / 2, 40),
      );
    });

    testWidgets('start positions follow RTL', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2400, 1800);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (BuildContext context, Widget? child) => Directionality(
            textDirection: TextDirection.rtl,
            child: BetterToast.init()(context, child),
          ),
          home: const SizedBox(),
        ),
      );
      BetterToast.show(
        'rtl',
        position: ToastPosition.topStart,
        duration: Duration.zero,
      );
      BetterToast.show(
        'left',
        position: ToastPosition.bottomLeft,
        duration: Duration.zero,
      );
      await settleIn(tester);
      expect(tester.getCenter(find.text('rtl')).dx, greaterThan(600));
      expect(tester.getCenter(find.text('left')).dx, lessThan(600));
    });

    testWidgets('show during a build is deferred safely',
        (WidgetTester tester) async {
      await pumpToastApp(tester, home: const _ShowsInInitState());
      await settleIn(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('from initState'), findsOneWidget);
    });

    testWidgets('context picks the nearest scope', (WidgetTester tester) async {
      await pumpToastApp(
        tester,
        home: Column(
          children: <Widget>[
            const Expanded(child: SizedBox()),
            SizedBox(
              height: 200,
              child: BetterToastScope(
                theme: const BetterToastThemeData(
                  position: ToastPosition.bottom,
                  respectSafeArea: false,
                ),
                child: Builder(
                  builder: (BuildContext context) => TextButton(
                    onPressed: () => BetterToast.show(
                      'inner',
                      context: context,
                      duration: Duration.zero,
                    ),
                    child: const Text('go'),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      await tester.tap(find.text('go'));
      await settleIn(tester);
      final double height =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(
        tester.getCenter(find.text('inner')).dy,
        greaterThan(height - 200),
      );
      // Without context, the most recently mounted scope (the inner one)
      // is used.
      expect(BetterToast.isActive('nope'), isFalse);
    });

    testWidgets('throws a clear error without a host',
        (WidgetTester tester) async {
      expect(
        () => BetterToast.show('nowhere'),
        throwsA(
          isA<FlutterError>().having(
            (FlutterError e) => e.toString(),
            'message',
            allOf(
              contains('no BetterToastScope is mounted'),
              contains('BetterToast.init()'),
            ),
          ),
        ),
      );
    });

    testWidgets('unmounting the host completes pending handles',
        (WidgetTester tester) async {
      await pumpToastApp(tester);
      final ToastHandle handle =
          BetterToast.show('bye', duration: Duration.zero);
      await settleIn(tester);
      bool closed = false;
      unawaited(handle.closed.then((_) => closed = true));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(closed, isTrue);
      expect(handle.isActive, isFalse);
      expect(() => BetterToast.show('x'), throwsFlutterError);
    });

    testWidgets('BetterToastScope works above WidgetsApp',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const BetterToastScope(
          theme: BetterToastThemeData(duration: Duration.zero),
          child: MaterialApp(home: SizedBox()),
        ),
      );
      BetterToast.show('outside');
      await settleIn(tester);
      expect(find.text('outside'), findsOneWidget);
    });
  });
}

class _ShowsInInitState extends StatefulWidget {
  const _ShowsInInitState();

  @override
  State<_ShowsInInitState> createState() => _ShowsInInitStateState();
}

class _ShowsInInitStateState extends State<_ShowsInInitState> {
  @override
  void initState() {
    super.initState();
    BetterToast.show('from initState', duration: Duration.zero);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

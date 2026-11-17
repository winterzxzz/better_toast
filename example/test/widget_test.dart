import 'package:better_toast_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showcase shows a success toast', (tester) async {
    await tester.pumpWidget(const ShowcaseApp());
    await tester.tap(find.text('Success'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Changes saved'), findsOneWidget);

    await tester.tap(find.text('Dismiss all'));
    await tester.pumpAndSettle();
    expect(find.text('Changes saved'), findsNothing);
  });
}

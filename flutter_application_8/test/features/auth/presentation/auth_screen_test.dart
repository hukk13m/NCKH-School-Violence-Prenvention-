import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_8/main.dart';

void main() {
  testWidgets('teacher switch changes the active portal without losing auth shell',
      (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Student portal'), findsOneWidget);

    await tester.tap(find.text('Switch to Teacher'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Teacher portal'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}

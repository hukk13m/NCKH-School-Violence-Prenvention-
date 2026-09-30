import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_8/main.dart';

void main() {
  testWidgets('renders the authentication experience', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Welcome back'), findsOneWidget);
  });
}

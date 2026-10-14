import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_web/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  testWidgets('Dashboard screen shows report form and side menu actions', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    expect(find.text('TrÆ°á»ng Äáº¡i há»c Kinh táº¿ - Luáº­t'), findsOneWidget);
    expect(find.text('BÃ¡o cÃ¡o'), findsWidgets);
    expect(find.text('SOS'), findsWidgets);
    expect(find.text('BÃ¡o cÃ¡o'), findsWidgets);
    expect(find.text('Ghi lá»i'), findsOneWidget);
    expect(find.text('Táº£i file lÃªn'), findsOneWidget);
    expect(find.byTooltip('XÃ³a file'), findsWidgets);
    expect(find.text('Gá»­i bÃ¡o cÃ¡o'), findsOneWidget);
    expect(find.text('ÄÄƒng nháº­p'), findsOneWidget);
    expect(find.text('CÃ³ thÃ´ng bÃ¡o'), findsOneWidget);

    await tester.tap(find.text('SOS').last);
    await tester.pumpAndSettle();

    expect(find.text('Gá»­i SOS'), findsOneWidget);
  });
}

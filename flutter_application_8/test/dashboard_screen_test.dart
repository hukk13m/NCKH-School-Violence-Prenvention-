import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_8/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  testWidgets('Dashboard screen shows report form and side menu actions', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    expect(find.text('Trường Đại học Kinh tế - Luật'), findsOneWidget);
    expect(find.text('Báo cáo'), findsWidgets);
    expect(find.text('SOS'), findsWidgets);
    expect(find.text('Báo cáo'), findsWidgets);
    expect(find.text('Ghi lời'), findsOneWidget);
    expect(find.text('Tải file lên'), findsOneWidget);
    expect(find.byTooltip('Xóa file'), findsWidgets);
    expect(find.text('Gửi báo cáo'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Có thông báo'), findsOneWidget);

    await tester.tap(find.text('SOS').last);
    await tester.pumpAndSettle();

    expect(find.text('Gửi SOS'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App loads and contains correct elements', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LaiHoaApp());

    // Verify that our title is present.
    expect(find.text('Tạo Video Lai Hòa'), findsOneWidget);
    expect(find.text('Nhập thông tin Video'), findsOneWidget);

    // Verify text fields are present
    expect(find.byType(TextField), findsNWidgets(2));
    
    // Verify button is present
    expect(find.text('Tạo Video Mới'), findsOneWidget);
  });
}

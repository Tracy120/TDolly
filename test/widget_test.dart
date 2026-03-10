// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teacherdolly/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(const {'lang': 'en'});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const TeacherDollyApp());
    await tester.pump();

    // Verify that the app starts
    expect(find.byType(TeacherDollyApp), findsOneWidget);
    expect(find.text('TeacherDolly'), findsOneWidget);
  });
}

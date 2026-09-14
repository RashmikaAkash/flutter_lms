import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lms/app.dart';

void main() {
  testWidgets('Login screen loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const FlutterLmsApp());

    expect(find.text('Flutter LMS'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inno/main.dart';

void main() {
  testWidgets('App renders login page', (WidgetTester tester) async {
    await tester.pumpWidget(const InnoGarageApp());
    expect(find.text('Login Page'), findsOneWidget);
  });
}

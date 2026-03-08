import 'package:flutter_test/flutter_test.dart';
import 'package:freelance_assistant/main.dart';

void main() {
  testWidgets('App should launch', (WidgetTester tester) async {
    await tester.pumpWidget(const FreelanceAssistantApp());
    expect(find.text('Dashboard'), findsOneWidget);
  });
}

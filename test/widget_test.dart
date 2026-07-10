import 'package:flutter_test/flutter_test.dart';
import 'package:peek/main.dart';

void main() {
  testWidgets('App landing smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app displays the main dashboard title.
    expect(find.text('Peek Camera Detector'), findsOneWidget);
    expect(find.text('SPY SHIELD'), findsOneWidget);
  });
}

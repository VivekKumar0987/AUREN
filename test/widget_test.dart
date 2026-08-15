import 'package:auren/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AUREN shell shows brand and real date header', (tester) async {
    await tester.pumpWidget(const AurenApp());
    await tester.pumpAndSettle();

    expect(find.text('AUREN'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:berberim/main.dart';

void main() {
  testWidgets('Berberim opens the role selection screen', (tester) async {
    await tester.pumpWidget(const BerberimApp());
    expect(find.text('Berberim'), findsOneWidget);
    expect(find.text('Müşteri olarak devam et'), findsOneWidget);
    expect(find.text('Berber paneli'), findsOneWidget);
  });
}

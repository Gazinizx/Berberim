import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:berberim/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Berberim opens the local dashboard', (tester) async {
    await tester.pumpWidget(const BerberimApp());
    await tester.pumpAndSettle();
    expect(find.text('Bugünkü randevular'), findsOneWidget);
    expect(find.text('Ana Sayfa'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:berberim/main.dart';

void main() {
  test('Berberim theme uses the agreed gold accent', () {
    expect(gold.value, 0xFFF2B84B);
  });
}

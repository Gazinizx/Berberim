import 'package:flutter_test/flutter_test.dart';
import 'package:berberim/main.dart';

void main() {
  test('Berberim theme uses the agreed gold accent', () {
    expect(gold.value, 0xFFD8B36A);
  });

  test('customer upcoming appointments are sorted from soonest to latest', () {
    final rows = <Map<String, dynamic>>[
      {
        'id': 'later',
        'status': 'confirmed',
        'starts_at': '2026-11-23T12:00:00Z',
      },
      {
        'id': 'completed',
        'status': 'completed',
        'starts_at': '2026-11-20T12:00:00Z',
      },
      {
        'id': 'soon',
        'status': 'pending',
        'starts_at': '2026-11-22T12:00:00Z',
      },
      {
        'id': 'cancelled',
        'status': 'cancelled',
        'starts_at': '2026-11-21T12:00:00Z',
      },
    ];

    final result = filterCustomerAppointments(rows, 'upcoming');

    expect(result.map((row) => row['id']).toList(), ['soon', 'later']);
  });

  test('customer appointment groups keep completed and cancelled separate', () {
    final rows = <Map<String, dynamic>>[
      {'id': 'done', 'status': 'completed'},
      {'id': 'cancelled', 'status': 'cancelled'},
      {'id': 'no-show', 'status': 'no_show'},
      {'id': 'active', 'status': 'confirmed', 'starts_at': '2026-11-23T12:00:00Z'},
    ];

    expect(
      filterCustomerAppointments(rows, 'completed').map((row) => row['id']).toList(),
      ['done'],
    );
    expect(
      filterCustomerAppointments(rows, 'cancelled').map((row) => row['id']).toList(),
      ['cancelled', 'no-show'],
    );
  });
}

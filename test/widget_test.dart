import 'package:flutter_test/flutter_test.dart';
import 'package:berberim/main.dart';

void main() {
  test('business QR payload strips the Berberim prefix and normalizes the code', () {
    expect(normalizeBusinessJoinCode('BERBERIM: ab12cd '), 'AB12CD');
  });

  test('manual business code is normalized without requiring a camera', () {
    expect(normalizeBusinessJoinCode(' ab12cd '), 'AB12CD');
  });


  test('only past active appointments can be marked as no-show', () {
    final now = DateTime.utc(2026, 11, 22, 20);
    expect(
      canMarkAppointmentNoShow({
        'status': 'confirmed',
        'starts_at': '2026-11-22T19:00:00Z',
      }, now: now),
      isTrue,
    );
    expect(
      canMarkAppointmentNoShow({
        'status': 'confirmed',
        'starts_at': '2026-11-22T21:00:00Z',
      }, now: now),
      isFalse,
    );
    expect(
      canMarkAppointmentNoShow({
        'status': 'pending',
        'starts_at': '2026-11-22T19:00:00Z',
        'requires_business_approval': true,
      }, now: now),
      isFalse,
    );
    expect(
      canMarkAppointmentNoShow({
        'status': 'no_show',
        'starts_at': '2026-11-22T19:00:00Z',
      }, now: now),
      isFalse,
    );
  });

  test('business customer search matches name and phone and filters blacklist', () {
    final rows = <Map<String, dynamic>>[
      {'customer_id': '1', 'full_name': 'Ayşe Yılmaz', 'phone': '5551112233', 'is_blacklisted': true},
      {'customer_id': '2', 'full_name': 'Mehmet Demir', 'phone': '5552223344', 'is_blacklisted': false},
    ];

    expect(
      filterBusinessCustomers(rows, query: 'ayşe').map((row) => row['customer_id']).toList(),
      ['1'],
    );
    expect(
      filterBusinessCustomers(rows, query: '2223').map((row) => row['customer_id']).toList(),
      ['2'],
    );
    expect(
      filterBusinessCustomers(rows, onlyBlacklisted: true).map((row) => row['customer_id']).toList(),
      ['1'],
    );
  });

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

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/company_address.dart';

void main() {
  test('legacy US address splits only when structure is recognizable', () {
    final address = CompanyAddress.fromLegacy(
      '1840 Service Road\nRoanoke, VA 24012',
    );
    expect(address.street, '1840 Service Road');
    expect(address.city, 'Roanoke');
    expect(address.state, 'VA');
    expect(address.zip, '24012');
    expect(address.formatted, '1840 Service Road\nRoanoke, VA 24012');
  });
  test('unrecognized address is preserved exactly without guessing', () {
    const source = 'Delivery entrance behind the shop; call first';
    final address = CompanyAddress.fromLegacy(source);
    expect(address.street, '');
    expect(address.legacy, source);
    expect(address.formatted, source);
  });
  test('suite and ZIP+4 survive structured round trip', () {
    const source = CompanyAddress(
      street: '42 Main St',
      unit: 'Suite 3',
      city: 'Roanoke',
      state: 'VA',
      zip: '24012-1234',
    );
    expect(
      CompanyAddress.fromMap(source.toMap()).formatted,
      '42 Main St\nSuite 3\nRoanoke, VA 24012-1234',
    );
  });
}

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ui_lab_2_1/src/shared/documents/customer_portal_gateway.dart';
import 'package:ui_lab_2_1/src/screens/work/work_customer_document.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_demo_data.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';

void main() {
  test('customer links require HTTPS and send only the public document', () async {
    expect(() => CustomerPortalGateway(origin: Uri.parse('http://example.test'),
      idToken: () async => 'token'), throwsArgumentError);
    var requests = 0;
    final gateway = CustomerPortalGateway(origin: Uri.parse('https://example.test'),
      idToken: () async => 'fresh-id-token', client: MockClient((request) async {
        requests++;
        expect(request.headers['Authorization'], 'Bearer fresh-id-token');
        expect(request.url.path, '/api/issue');
        final body = jsonDecode(request.body) as Map;
        final snapshot = body['snapshot'] as Map;
        expect(snapshot.containsKey('internalNotes'), false);
        expect(snapshot['currency'], 'USD');
        expect((snapshot['items'] as List).first, isNot(contains('internalCost')));
        return http.Response(jsonEncode({'token': 'a' * 43, 'digest': 'digest',
          'expiresAt': DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch}), 200);
      }));
    addTearDown(gateway.close);
    final data = workCustomerDocument(prototypeDemoWorkRecords().first, demoWorkCompany, demoWorkCustomers.first);
    final link = await gateway.create('saved-estimate', data);
    expect(link.url.fragment, 'a' * 43);
    expect(link.url.query, isEmpty);
    expect(requests, 1);
  });
}

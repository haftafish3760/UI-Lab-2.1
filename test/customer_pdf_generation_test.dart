import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/work/documents/document_pdf_assets.dart';
import 'package:ui_lab_2_1/src/screens/work/documents/document_template.dart';
import 'package:ui_lab_2_1/src/screens/work/work_customer_document.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_demo_data.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all templates produce real PDFs from customer-safe data', () async {
    final record = prototypeDemoWorkRecords().first;
    final data = workCustomerDocument(
      record,
      demoWorkCompany,
      demoWorkCustomers.first,
    );
    expect(data.items.length, record.items.length);
    expect(data.totalCents, (record.total * 100).round());
    expect(data.terms, record.terms);
    final output = Directory('output/pdf')..createSync(recursive: true);
    for (final template in DocumentTemplate.catalog) {
      final bytes = await generateCustomerPdf(data, templateId: template.id);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
      File(
        '${output.path}/${template.id.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '-').toLowerCase()}-estimate.pdf',
      ).writeAsBytesSync(bytes);
    }
  });
}

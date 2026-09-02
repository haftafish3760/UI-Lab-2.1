import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release-one portal is a secure document QR flow, not messaging', () {
    final work = File('docs/work_lifecycle_blueprint.md').readAsStringSync();

    expect(work, contains('Release-one customer portal and QR handoff'));
    expect(work, contains('generates a QR code'));
    expect(work, contains('opaque HTTPS capability link'));
    expect(work, contains('exact recipient and revision'));
    expect(work, contains('approve and sign that exact revision'));
    expect(work, contains('request changes'));
    expect(work, contains('not a counteroffer engine'));
    expect(work, contains('contractor/customer chat are deferred'));
    expect(work, contains('An Invoice is not presented as something'));
    expect(work, contains('payment plan for an issued Invoice'));
    expect(work, contains('notification consent. Changing an installment'));
    expect(work, contains('initially unselected choices'));
    expect(work, contains('email, SMS/text, and browser push'));
    expect(work, contains('cancels future scheduled deliveries'));
    expect(work, contains('can never mark an installment paid'));
    expect(work, contains('Estimate and Invoice terms'));
    expect(work, contains('Service terms'));
    expect(work, contains('Payment terms'));
    expect(work, contains('template is never the historical agreement'));
    expect(
      work,
      contains('does not pretend the customer approved the Invoice'),
    );
  });

  test('governing blueprints preserve the portal boundary', () {
    final product = File(
      'docs/product_control_blueprint.md',
    ).readAsStringSync();
    final application = File(
      'docs/maintainiac_app_blueprint.md',
    ).readAsStringSync();

    expect(product, contains('matching contractor QR code'));
    expect(product, contains('no chat or customer record editing'));
    expect(product, contains('Customer reminder delivery'));
    expect(product, contains('infer consent'));
    expect(product, contains('document-specific terms snapshot'));
    final notifications = File(
      'docs/notification_system_blueprint.md',
    ).readAsStringSync();
    expect(notifications, contains('separately governed'));
    expect(notifications, contains('appear in an employee unread count'));
    expect(
      application,
      contains('document-specific, revision-bound access only'),
    );
    expect(application, contains('Platform payment and contract boundary'));
    expect(application, contains('not the service contractor'));
    expect(product, contains('not a party to contractor/customer work'));
    expect(application, contains('qualified legal review'));
    expect(application, contains('Tax and recordkeeping boundary'));
    expect(application, contains('IRS audit'));
    expect(application, contains('account owner is solely responsible'));
    expect(application, contains('retaining original supporting documents'));
    expect(application, contains('does not transfer that responsibility'));
    expect(application, contains('storage and rendering of committed data'));
    expect(product, contains('does not certify that an account or export'));
  });
}

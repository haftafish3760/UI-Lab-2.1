import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets('native lifecycle helper preserves the original failure type', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    final original = StateError('expected fixture failure');
    Object? caught;
    try {
      await finishNativeOperation(tester, () async => throw original);
    } catch (error) {
      caught = error;
    }
    expect(caught, same(original));
    var completed = false;
    await finishNativeOperation(tester, () async {
      completed = true;
    });
    expect(completed, isTrue);
    expect(tester.takeException(), isNull);
  });
}

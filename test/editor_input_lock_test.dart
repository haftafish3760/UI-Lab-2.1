import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/shared/editor_input_lock.dart';

void main() {
  testWidgets(
    'pending action lock prevents keyboard activation and restores normal actions afterward',
    (tester) async {
      final locked = ValueNotifier(false);
      final focus = FocusNode();
      addTearDown(locked.dispose);
      addTearDown(focus.dispose);
      var actions = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: locked,
              builder: (_, value, _) => EditorInputLock(
                locked: value,
                child: TextButton(
                  focusNode: focus,
                  onPressed: () => actions++,
                  child: const Text('Pick source'),
                ),
              ),
            ),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(actions, 1);
      locked.value = true;
      await tester.pump();
      await tester.pump();
      expect(focus.hasFocus, isFalse);
      expect(focus.canRequestFocus, isFalse);
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.tap(find.text('Pick source'), warnIfMissed: false);
      expect(actions, 1);
      locked.value = false;
      await tester.pump();
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(actions, 2);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

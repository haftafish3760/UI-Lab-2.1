import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/workday/odometer_input.dart';
import 'package:ui_lab_2_1/src/data/workday/start_workday_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/workday/end_workday_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_ui_lab_bootstrap.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'miles convert exactly without rounding; syntax and maximum remain explicit',
    () {
      for (final value in {
        '0': 0,
        '0.1': 1,
        '12.3': 123,
        ' 1,234.5 ': 12345,
        '9,999,999.0': 99999990,
      }.entries) {
        expect(parseExactOdometerMiles(value.key), value.value);
        expect(tryParseWorkdayOdometerMiles(value.key), value.value);
      }
      for (final text in [
        '',
        '.',
        '1e3',
        'NaN',
        'Infinity',
        '-1',
        '+1',
        '12.34',
        '12.30',
        '1,23.4',
        '1,,234',
        '1 234',
        '9,999,999.1',
        '10000000',
      ]) {
        expect(
          () => parseExactOdometerMiles(text),
          throwsFormatException,
          reason: text,
        );
        expect(tryParseWorkdayOdometerMiles(text), isNull, reason: text);
      }
      expect(tryParseWorkdayOdometerMiles('12,345.'), 123450);
      expect(() => parseExactOdometerMiles('12,345.'), throwsFormatException);
    },
  );
  for (final ending in [false, true]) {
    test(
      '${ending ? 'ending' : 'starting'} rejects lossy mileage, retains raw input on reopen and commits exact tenths',
      () async {
        final harness = await DatabaseHarness.create();
        addTearDown(harness.dispose);
        var db = await harness.open();
        var work = await openUiLabWorkdaySession(db);
        if (ending) {
          expect(
            (await work.start(
              id: 'day',
              employeeId: 'alex',
              vehicleId: 'transit-12',
              odometerTenths: 1000,
              expectedOdometerRevision: 0,
              at: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
            )).committed,
            isTrue,
          );
        }
        var start = ending
            ? null
            : await work.openStartDraft(
                employeeId: 'alex',
                vehicleId: 'transit-12',
                initialOdometer: '101.',
              );
        var end = ending
            ? await work.openEndDraft(workdayId: 'day', initialOdometer: '101.')
            : null;
        for (final raw in ['101.04', '1,01.2', '1e3']) {
          if (ending) {
            end!.update(raw);
            await expectLater(
              end.confirm(),
              throwsA(isA<EndWorkdayInputValidation>()),
            );
            expect(end.input.confirmedAt, isNull);
          } else {
            start!.update(
              employeeId: 'alex',
              vehicleId: 'transit-12',
              odometer: raw,
              gpsAssistance: false,
            );
            await expectLater(
              start.confirm(),
              throwsA(isA<StartWorkdayInputValidation>()),
            );
            expect(start.input.confirmedAt, isNull);
          }
          expect((start?.session ?? end!.session).input['odometer'], raw);
          expect(work.records, hasLength(ending ? 1 : 0));
          expect(
            work.odometerFor('transit-12')!.readingTenths,
            ending ? 1000 : 0,
          );
        }
        await (start?.session ?? end!.session).close();
        work.dispose();
        await harness.close(db);
        db = await harness.open();
        work = await openUiLabWorkdaySession(db);
        addTearDown(work.dispose);
        if (ending) {
          end = await work.openEndDraft(workdayId: 'day', initialOdometer: '0');
          expect(end.input.odometer, '1e3');
          end.update('101.1');
          expect((await end.confirm()).committed, isTrue);
          await end.session.close();
        } else {
          start = await work.openStartDraft(
            employeeId: 'alex',
            vehicleId: 'transit-12',
            initialOdometer: '0',
          );
          expect(start.input.odometer, '1e3');
          start.update(
            employeeId: 'alex',
            vehicleId: 'transit-12',
            odometer: '101.1',
            gpsAssistance: false,
          );
          expect((await start.confirm()).committed, isTrue);
          await start.session.close();
        }
        expect(work.odometerFor('transit-12')!.readingTenths, 1011);
      },
    );
  }
}

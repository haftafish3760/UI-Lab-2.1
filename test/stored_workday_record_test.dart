import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/workday/stored_workday_record.dart';

void main() {
  final start = DateTime.utc(2030, 1, 1, 8);
  StoredWorkdayRecord record() => StoredWorkdayRecord.start(
    id: 'day-1',
    organizationId: 'company',
    employeeId: 'alex',
    vehicleId: 'van',
    at: start,
    odometerTenths: 100001,
  );
  StoredWorkdayRecord reopen(StoredWorkdayRecord record) =>
      StoredWorkdayRecord.fromJson(
        (jsonDecode(jsonEncode(record.toJson())) as Map)
            .cast<String, Object?>(),
      );
  test(
    'paused interval survives serialization and ended elapsed time stays fixed',
    () {
      final paused = reopen(
        record().pause(start.add(const Duration(hours: 2))),
      );
      expect(
        paused.elapsedAt(start.add(const Duration(hours: 8))),
        const Duration(hours: 2),
      );
      final resumed = reopen(
        paused.resume(start.add(const Duration(hours: 3))),
      );
      final ended = reopen(
        resumed.end(
          at: start.add(const Duration(hours: 5)),
          odometerTenths: 100123,
        ),
      );
      expect(
        ended.elapsedAt(start.add(const Duration(days: 20))),
        const Duration(hours: 4),
      );
      expect(ended.currentOdometerTenths - ended.startOdometerTenths, 122);
      expect(ended.employeeId, 'alex');
      expect(ended.vehicleId, 'van');
    },
  );
  test('ending while paused excludes the whole final pause interval', () {
    final ended = record()
        .pause(start.add(const Duration(hours: 2)))
        .end(at: start.add(const Duration(hours: 4)), odometerTenths: 100001);
    expect(
      reopen(ended).elapsedAt(start.add(const Duration(days: 2))),
      const Duration(hours: 2),
    );
    expect(ended.pausedAt, isNull);
    expect(ended.endedAt, start.add(const Duration(hours: 4)));
  });
  test('out-of-order transitions and decreasing odometer reject', () {
    final paused = record().pause(start.add(const Duration(hours: 1)));
    expect(
      () => paused.pause(start.add(const Duration(hours: 2))),
      throwsStateError,
    );
    expect(() => paused.resume(start), throwsStateError);
    expect(
      () => record().end(at: start, odometerTenths: 100000),
      throwsArgumentError,
    );
    final ended = record().end(
      at: start.add(const Duration(hours: 1)),
      odometerTenths: 100001,
    );
    expect(
      () => ended.end(
        at: start.add(const Duration(hours: 2)),
        odometerTenths: 100001,
      ),
      throwsStateError,
    );
    expect(
      () => ended.resume(start.add(const Duration(hours: 2))),
      throwsStateError,
    );
  });
  test('invalid retained state is rejected rather than repaired silently', () {
    final json = record().toJson();
    expect(
      () => StoredWorkdayRecord.fromJson({...json, 'status': 'paused'}),
      throwsArgumentError,
    );
    expect(
      () => StoredWorkdayRecord.fromJson({...json, 'employeeId': ''}),
      throwsArgumentError,
    );
    expect(
      () => StoredWorkdayRecord.fromJson({...json, 'pausedMicroseconds': 1}),
      throwsArgumentError,
    );
    expect(
      () => StoredWorkdayRecord.fromJson({...json, 'currentOdometerTenths': 1}),
      throwsArgumentError,
    );
  });
}

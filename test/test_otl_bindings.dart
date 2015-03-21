library ebisu_cpp_db.test.test_otl_bindings;

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:unittest/unittest.dart';
// custom <additional imports>
import 'package:magus/schema.dart';
import 'package:ebisu_cpp_db/ebisu_cpp_db.dart';
// end <additional imports>

final _logger = new Logger('test_otl_bindings');

// custom <library test_otl_bindings>
// end <library test_otl_bindings>
main([List<String> args]) {
  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.OFF;
// custom <main>

  group('OtlBindVariable', () {
    [1, 2, 3, 4].forEach((int bytes) {
      test('sql int of $bytes bytes is int', () {
        final t = new SqlInt(bytes, 10);
        final obv = new OtlBindVariable.fromDataType('age', t);
        expect(obv.toString(), ':age<int>');
      });
    });
    test('sql int of 5 bytes is bigint', () {
      final t = new SqlInt(5, 10);
      final obv = new OtlBindVariable.fromDataType('age', t);
      expect(obv.toString(), ':age<bigint>');
    });

    [10, 20, 30].forEach((int chars) {
      [true, false].forEach((final bool isVarying) {
        test('sql string of length $chars varying $isVarying', () {
          final t = new SqlString(chars, isVarying);
          final obv = new OtlBindVariable.fromDataType('name', t);
          expect(obv.toString(), ':name<char[$chars]>');
        });
        test('sql string of length $chars varying $isVarying', () {
          final t = new SqlString(chars, isVarying);
          final obv = new OtlBindVariable.fromDataType('name', t);
          expect(obv.toString(), ':name<char[$chars]>');
        });
      });
    });

    {
      final precisions = [2, 5, 10];
      final scale = [2, 4];
      precisions.forEach((int precision) {
        scale.forEach((int scale) {
          test('sql float precision $precision scale $scale', () {
            final t = new SqlFloat(precision, scale);
            final obv = new OtlBindVariable.fromDataType('measurement', t);
            expect(obv.toString(), ':measurement<double>');
          });
        });
      });
    }

    test('sql date', () {
      final t = new SqlDate();
      final obv = new OtlBindVariable.fromDataType('birth_date', t);
      expect(obv.toString(), ':birth_date<timestamp>');
    });

    {
      final hasTimezones = [false, true];
      final autoUpdates = [false, true];
      hasTimezones.forEach((bool hasTimezone) {
        autoUpdates.forEach((bool autoUpdate) {
          test('sql timestamp hasTimezone $hasTimezone autoUpdate $autoUpdate',
              () {
            final t = new SqlTimestamp(hasTimezone, autoUpdate);
            final obv = new OtlBindVariable.fromDataType('birth_date', t);
            expect(obv.toString(), ':birth_date<timestamp>');
          });
        });
      });
    }
  });

// end <main>

}

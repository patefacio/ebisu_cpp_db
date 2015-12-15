import 'package:logging/logging.dart';
import 'test_otl_bindings.dart' as test_otl_bindings;
import 'test_mysql_code_metrics.dart' as test_mysql_code_metrics;

main() {
  Logger.root.level = Level.OFF;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  test_otl_bindings.main();
  test_mysql_code_metrics.main();
}

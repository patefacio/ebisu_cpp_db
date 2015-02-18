/// This test library passes a sample schema, *code_metrics*, through the
/// schema generator. It does not require access to a database. The
/// *magus* project parses the schema and provides the
/// metadata. *ebisu_cpp_db* uses *ebisu_cpp* to generate the crud
/// support. This test does not ensure much other than that the
/// appropriate classes are created, with expected members and
/// methods. The real test for generated code is in the usage.
///
library ebisu_cpp_db.test.test_mysql_code_metrics;

import 'package:unittest/unittest.dart';
// custom <additional imports>

import 'package:magus/schema.dart';
import 'package:magus/mysql.dart';
import 'package:ebisu/ebisu.dart';
import 'package:ebisu_cpp_db/ebisu_cpp_db.dart';
import 'package:ebisu_cpp/ebisu_cpp.dart';
import 'package:id/id.dart';

// end <additional imports>

// custom <library test_mysql_code_metrics>
final ddl = {
  'code_packages': '''
CREATE TABLE `code_packages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `descr` varchar(256) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1''',
  'code_locations': '''
CREATE TABLE `code_locations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code_packages_id` int(11) NOT NULL,
  `label` varchar(256) NOT NULL,
  `file_name` varchar(256) NOT NULL,
  `line_number` int(11) NOT NULL,
  `git_commit` varchar(40) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code_packages_id` (`code_packages_id`,`label`,`file_name`,`line_number`),
  CONSTRAINT `code_locations_ibfk_1` FOREIGN KEY (`code_packages_id`) REFERENCES `code_packages` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1''',
  'rusage_delta': '''
CREATE TABLE `rusage_delta` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code_locations_id` int(11) NOT NULL,
  `created` datetime NOT NULL,
  `start_processor` int(11) NOT NULL,
  `end_processor` int(11) NOT NULL,
  `cpu_mhz` double NOT NULL,
  `debug` int(11) NOT NULL,
  `user_time_sec` bigint(20) NOT NULL,
  `user_time_usec` bigint(20) NOT NULL,
  `system_time_sec` bigint(20) NOT NULL,
  `system_time_usec` bigint(20) NOT NULL,
  `ru_maxrss` bigint(20) NOT NULL,
  `ru_ixrss` bigint(20) NOT NULL,
  `ru_idrss` bigint(20) NOT NULL,
  `ru_isrss` bigint(20) NOT NULL,
  `ru_minflt` bigint(20) NOT NULL,
  `ru_majflt` bigint(20) NOT NULL,
  `ru_nswap` bigint(20) NOT NULL,
  `ru_inblock` bigint(20) NOT NULL,
  `ru_oublock` bigint(20) NOT NULL,
  `ru_msgsnd` bigint(20) NOT NULL,
  `ru_msgrcv` bigint(20) NOT NULL,
  `ru_nsignals` bigint(20) NOT NULL,
  `ru_nvcsw` bigint(20) NOT NULL,
  `ru_nivcsw` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `code_locations_id` (`code_locations_id`),
  CONSTRAINT `rusage_delta_ibfk_1` FOREIGN KEY (`code_locations_id`) REFERENCES `code_locations` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1'''
};

// end <library test_mysql_code_metrics>
main() {
// custom <main>
  final parser = new MysqlSchemaParser();

  hasOpEqual(definition, clsName) => definition
      .contains(darkMatter('bool operator==($clsName const& rhs) const'));
  hasOpNotEqual(definition, clsName) => definition
      .contains(darkMatter('bool operator!=($clsName const& rhs) const'));
  hasOpLess(definition, clsName) => definition
      .contains(darkMatter('bool operator<($clsName const& rhs) const'));
  hasMemberNames(definition, clsName) => definition.contains(
      darkMatter('static inline void member_names_list(String_list_t &out)'));
  hasOpOut(definition, clsName) => definition.contains(
      darkMatter('operator<<(std::ostream& out, $clsName const& item)'));

  getClass(Header header, className) =>
      header.classes.firstWhere((c) => c.className == className);

  testStandardMethods(definition, clsName) {
    test('has OpEqual', () => hasOpEqual(definition, clsName));
    test('has OpNotEqual', () => hasOpNotEqual(definition, clsName));
    test('has OpLess', () => hasOpLess(definition, clsName));
    test('has member names', () => hasMemberNames(definition, clsName));
    test('has OpOut', () => hasOpOut(definition, clsName));
  }

  //////////////////////////////////////////////////////////////////////////////
  // This test does not interact with database at all. Nor does it generate
  // files, rather just the code in memory. The tests are not complete since a
  // true test is to compile, build and run. But this should catch errors
  // introduced in generation.
  group('code_metrics', () {
    final tables = parser.parseTables(ddl);
    final engine = new MysqlEngine(null);
    final installation = new Installation(new Id('test'))..root = '/tmp';
    final schema = new Schema(engine, 'code_metrics', tables);
    final generator = new OtlSchemaCodeGenerator(schema)
      ..installation = installation;
    final lib = generator.lib;
    final headers = lib.headers;

    test('creates header for each table', () {
      [
        'code_packages',
        'code_locations',
        'rusage_delta'
      ].forEach((String tableName) {
        expect(headers.any((Header h) => h.id.snake == tableName), true);
      });
    });
    test('creates single header for schema', () {
      expect(headers.any((Header h) => h.id.snake == 'code_metrics'), true);
    });

    final codePackagesHeader =
        headers.firstWhere((Header h) => h.id.snake == 'code_packages');

    print(codePackagesHeader.classes.map((c) => c.className));

    group('code_packages', () {
      group('pkey', () {
        final className = 'Code_packages_pkey';
        final keyClass = getClass(codePackagesHeader, className);
        final definition = darkMatter(keyClass.definition);
        testStandardMethods(definition, className);
        test('has primary key', () {
          expect(definition.contains(darkMatter('int32_t id;')), true);
        });
      });

      group('value', () {
        final className = 'Code_packages_value';
        final valueClass = getClass(codePackagesHeader, className);
        final definition = darkMatter(valueClass.definition);
        testStandardMethods(definition, className);
        [
          'fcs::utils::Fixed_size_char_array< 64 > name',
          'fcs::utils::Fixed_size_char_array< 256 > descr',
        ].forEach((String member) {
          test('has $member', () {
            expect(definition.contains(darkMatter(member)), true);
          });
        });
      });

      group('gateway', () {
        final className = 'Code_packages';
        final gateway = getClass(codePackagesHeader, className);
      });
    });
  });

  // end <main>

}

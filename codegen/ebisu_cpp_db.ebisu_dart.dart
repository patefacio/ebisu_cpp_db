#!/usr/bin/env dart
import 'dart:io';
import 'package:args/args.dart';
import 'package:ebisu/ebisu.dart';
import 'package:ebisu/ebisu_dart_meta.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
// custom <additional imports>
// end <additional imports>
final _logger = new Logger('ebisuCppDbEbisuDart');

main(List<String> args) {
  Logger.root.onRecord.listen((LogRecord r) =>
      print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.OFF;
  useDartFormatter = true;
  String here = absolute(Platform.script.toFilePath());
  // custom <ebisuCppDbEbisuDart main>
  final briefDoc = 'A library that supports code generation of C++ database access';

  String _topDir = dirname(dirname(here));
  useDartFormatter = true;
  System ebisu = system('ebisu_cpp_db')
    ..includesHop = true
    ..license = 'boost'
    ..pubSpec.homepage = 'https://github.com/patefacio/ebisu_cpp_db'
    ..pubSpec.version = '0.0.10'
    ..pubSpec.doc = briefDoc
    ..pubSpec.addDependency(new PubDependency('path')..version = ">=1.3.0<1.4.0")
    ..rootPath = _topDir
    ..doc = briefDoc
    ..testLibraries = [
      library('test_otl_bindings'),
      library('test_mysql_code_metrics')
      ..doc = '''
This test library passes a sample schema, *code_metrics*, through the
schema generator. It does not require access to a database. The
*magus* project parses the schema and provides the
metadata. *ebisu_cpp_db* uses *ebisu_cpp* to generate the crud
support. This test does not ensure much other than that the
appropriate classes are created, with expected members and
methods. The real test for generated code is in the usage.
''',
    ]
    ..libraries = [
      library('ebisu_cpp_db')
      ..includesLogger = true
      ..doc = dbSchemaDoc
      ..imports = [
        'dart:io',
        'package:id/id.dart',
        'package:ebisu/ebisu.dart',
        "'package:path/path.dart' as path",
        'package:ini/ini.dart',
        '"package:sqljocky/sqljocky.dart" hide Query',
        'package:ebisu_cpp/ebisu_cpp.dart',
        'package:magus/schema.dart',
        'dart:async',
      ]
      ..parts = [
        part('meta')
        ..classes = [
          class_('data_type')
          ..ctorConst = ['']
          ..hasOpEquals = true
          ..members = [
            member('db_type')..isFinal = true..ctors = [''],
            member('cpp_type')..isFinal = true..ctors = [''],
          ],
          class_('fixed_varchar')
          ..extend = 'DataType'
          ..members = [
            member('size')..type = 'int'
          ],
        ],
        part('test_support')
        ..classes = [
          class_('gateway')
          ..isImmutable = true
          ..members = [
            member('table_details')..type = 'TableDetails',
          ],
          class_('gateway_test_generator')
          ..doc = 'Class to generate test code to exercise the table gateway'
          ..ctorCustoms = ['']
          ..members = [
            member('test')..type = 'Test'..ctors = [''],
            member('table_details')..type = 'TableDetails'..ctors = [''],
            member('namespace')..type = 'Namespace'..ctors = [''],
            member('gateways')
            ..doc = 'Table details for transitive closure by foreign keys'
            ..type = 'List<Gateway>'
            ..classInit = [],
          ],
        ],
        part('generator')
        ..classes = [
          class_('schema_lib_creator')
          ..doc = '''
Creates a single C++ [Library] that supports accessing the tables
associated with the schema. The [lib] property with create the
[Library] when called. If not all tables are desired to have *CRUD*
access, they can be filtered with [tableFilter] prior to accessing the
[lib].
'''
          ..isAbstract = true
          ..members = [
            member('installation')..type = 'Installation',
            member('schema')
            ..doc = 'Target schema for generating C++ *CRUD* support'
            ..type = 'Schema',
            member('id')
            ..doc = 'Id associated with the schema'
            ..type = 'Id'..access = RO,
            member('queries')
            ..doc = 'Set of SQL queries to add C++ support'
            ..type = 'List<Query>'..classInit = [],
            member('table_filter')
            ..doc = 'Can be used to filter to just the tables to be provided *CRUD* support'
            ..type = 'TableFilter'..classInit = '(Table t) => true',
            member('namespace')
            ..doc = 'Namespace for the lib'
            ..type = 'Namespace'
            ..access = WO,
          ],
          class_('table_details')
          ..isImmutable = true
          ..members = [
            member('schema')..type = 'Schema',
            member('table')..type = 'Table',
            member('table_id')..type = 'Id',
            member('table_name'),
            member('class_name'),
            member('key_class_id')..type = 'Id',
            member('value_class_id')..type = 'Id',
          ],
          class_('table_gateway_generator')
          ..isAbstract = true
          ..members = [
            member('schema_lib_creator')..type = 'SchemaLibCreator',
            member('table_details')..type = 'TableDetails'..access = IA,
            member('key_class')..type = 'Class',
            member('value_class')..type = 'Class',
            member('header')..type = 'Header'..access = IA,
          ]
        ],
        part('otl_generator')
        ..enums = [
          enum_('bind_data_type')
          ..doc = '''
Data to/from the database must be converted from/to C++ datatypes. Otl supports
binding specific datatypes. The following enum establishes the binding datatypes
Otl supports so that code generation logic can manage the required
transformations on data to/from the otl library.
'''
          ..hasLibraryScopedValues = true
          ..values = [
            id('bdt_int'),
            id('bdt_short'),
            id('bdt_double'),
            id('bdt_bigint'),
            id('bdt_sized_char'),
            id('bdt_unsized_char'),
            id('bdt_varchar_long'),
            id('bdt_timestamp'),
          ]
        ]
        ..classes = [
          class_('otl_bind_variable')
          ..members = [
            member('name'),
            member('data_type')..type = 'BindDataType',
            member('size')..classInit = 0,
          ],
          class_('otl_schema_code_generator')
          ..extend = 'SchemaLibCreator'
          ..doc = '''
Given a schema generates code to support accessing tables and configured
queries. Makes use of the otl c++ library.
'''
          ..members = [
            member('connection_class_id')..type = 'Id'..access = RO,
            member('connection_class_name')..access = RO,
          ],
          class_('otl_table_gateway_generator')
          ..extend = 'TableGatewayGenerator'
        ],
        part('poco_generator')
        ..classes = [
          class_('poco_schema_code_generator')
          ..extend = 'SchemaLibCreator'
          ..doc = '''
Given a schema generates code to support accessing tables and configured
queries. Makes use of the poco c++ library.
'''
          ..members = [
            member('session_class_id')..type = 'Id'..access = RO,
            member('session_class_name')..access = RO,
          ],
          class_('poco_table_gateway_generator')
          ..extend = 'TableGatewayGenerator'
        ]
      ],
    ];

  ebisu.generate();

  // end <ebisuCppDbEbisuDart main>
}

// custom <ebisuCppDbEbisuDart global>

final dbSchemaDoc = '''
Generates code to support **CRUD** operations and other tasks on relational database.

Coding support for C++ access is a pain filled with boilerplate code. The goal
of this package is to help eliminate that boilerplate by generating required
CRUD operations. Another motivation is to demonstrate how to generate C++ for a
specific task using the *ebisu_cpp* set of tools.

In terms of supported platforms, the target is linux environments. However, the
code is fairly portable and the initial implementation sits on top of *Otl*
template library making use of the ODBC interface. The initial target database
is MySql. However the code is generated and attempts are made to make it easy to
add support for other databases.

''';
// end <ebisuCppDbEbisuDart global>

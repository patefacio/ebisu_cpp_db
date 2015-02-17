import "dart:io";
import "package:path/path.dart" as path;
import "package:ebisu/ebisu.dart";
import "package:ebisu/ebisu_dart_meta.dart";
import "package:logging/logging.dart";

String _topDir;

void main() {

  final briefDoc = 'A library that supports code generation of C++ database access';

  Logger.root.onRecord.listen((LogRecord r) =>
      print("${r.loggerName} [${r.level}]:\t${r.message}"));
  String here = path.absolute(Platform.script.path);
  _topDir = path.dirname(path.dirname(here));
  useDartFormatter = true;
  System ebisu = system('ebisu_cpp_db')
    ..includeHop = true
    ..license = 'boost'
    ..pubSpec.homepage = 'https://github.com/patefacio/ebisu_cpp_db'
    ..pubSpec.version = '0.0.1'
    ..pubSpec.doc = briefDoc
    ..pubSpec.addDependency(new PubDependency('path')..version = ">=1.3.0<1.4.0")
    ..pubSpec.addDevDependency(new PubDependency('unittest'))
    ..rootPath = _topDir
    ..doc = briefDoc
    ..testLibraries = [
      library('test_otl_bindings')
    ]
    ..libraries = [
      library('db_schema')
      ..doc = dbSchemaDoc
      ..imports = [
        'dart:io',
        'package:id/id.dart',
        'package:ebisu/ebisu.dart',
        "'package:path/path.dart' as path",
        'package:ini/ini.dart',
        '"package:sqljocky/sqljocky.dart" hide Query',
        'package:ebisu_cpp/cpp.dart',
        'package:magus/schema.dart',
        'dart:async',
      ]
      ..parts = [
        part('meta')
        ..classes = [
          class_('data_type')
          ..ctorConst = ['']
          ..opEquals = true
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
          ..immutable = true
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
          class_('schema_code_generator')
          ..mixins = [ 'InstallationContainer' ]
          ..implement = [ 'CodeGenerator' ]
          ..isAbstract = true
          ..members = [
            member('schema')..type = 'Schema',
            member('id')..type = 'Id'..access = RO,
            member('queries')..type = 'List<Query>'..classInit = [],
            member('table_filter')..type = 'TableFilter'..classInit = '(Table t) => true',
          ],
          class_('table_details')
          ..immutable = true
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
            member('installation')..type = 'Installation',
            member('schema_code_generator')..type = 'SchemaCodeGenerator',
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
          ..libraryScopedValues = true
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
          ..extend = 'SchemaCodeGenerator'
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
          ..extend = 'SchemaCodeGenerator'
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
}


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
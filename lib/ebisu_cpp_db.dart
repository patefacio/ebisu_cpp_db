/// Generates code to support **CRUD** operations and other tasks on relational database.
///
/// Coding support for C++ access is a pain filled with boilerplate code. The goal
/// of this package is to help eliminate that boilerplate by generating required
/// CRUD operations. Another motivation is to demonstrate how to generate C++ for a
/// specific task using the *ebisu_cpp* set of tools.
///
/// In terms of supported platforms, the target is linux environments. However, the
/// code is fairly portable and the initial implementation sits on top of *Otl*
/// template library making use of the ODBC interface. The initial target database
/// is MySql. However the code is generated and attempts are made to make it easy to
/// add support for other databases.
library ebisu_cpp_db.ebisu_cpp_db;

import 'dart:async';
import 'dart:io';
import 'package:ebisu/ebisu.dart';
import 'package:ebisu_cpp/ebisu_cpp.dart';
import 'package:id/id.dart';
import 'package:ini/ini.dart';
import 'package:logging/logging.dart';
import 'package:magus/schema.dart';
import 'package:path/path.dart' as path;
import 'package:quiver/core.dart';
import 'package:sqljocky/sqljocky.dart' hide Query;

// custom <additional imports>
// end <additional imports>

part 'src/ebisu_cpp_db/generator.dart';
part 'src/ebisu_cpp_db/meta.dart';
part 'src/ebisu_cpp_db/otl_generator.dart';
part 'src/ebisu_cpp_db/poco_generator.dart';
part 'src/ebisu_cpp_db/test_support.dart';

final _logger = new Logger('ebisu_cpp_db');

// custom <library ebisu_cpp_db>
// end <library ebisu_cpp_db>

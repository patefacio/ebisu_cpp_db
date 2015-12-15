part of ebisu_cpp_db.ebisu_cpp_db;

/// Creates a single C++ [Library] that supports accessing the tables
/// associated with the schema. The [lib] property with create the
/// [Library] when called. If not all tables are desired to have *CRUD*
/// access, they can be filtered with [tableFilter] prior to accessing the
/// [lib].
abstract class SchemaLibCreator {
  Installation installation;

  /// Target schema for generating C++ *CRUD* support
  Schema schema;

  /// Id associated with the schema
  Id get id => _id;

  /// Set of SQL queries to add C++ support
  List<Query> queries = [];

  /// Can be used to filter to just the tables to be provided *CRUD* support
  TableFilter tableFilter = (Table t) => true;

  // custom <class SchemaLibCreator>

  get namespace => new Namespace(['ebisu', 'orm', id.snake]);
  get tables => schema.tables.where((t) => tableFilter(t));
  TableGatewayGenerator createTableGatewayGenerator(Table t);
  finishCommonHeader(Header commonHeader);

  SchemaLibCreator(this.installation, this.schema) {
    _id = idFromString(schema.name);
  }

  Lib get lib {
    final queryVisitor = schema.engine.queryVisitor;
    _logger.info('Queries: ${queries.map((q) => queryVisitor.select(q))}');
    final ns = namespace;

    final result = new Lib(id)
      ..namespace = ns
      ..withStandardizedHeader(libCommonHeader, (Header commonHeader) {
        commonHeader
          ..namespace = ns
          ..setFilePathFromRoot(this.installation.cppPath);

        finishCommonHeader(commonHeader);
      });

    tables.forEach(
        (Table t) => result.headers.add(createTableGatewayGenerator(t).header));

    return result;
  }

  // end <class SchemaLibCreator>

  Id _id;
}

class TableDetails {
  const TableDetails(this.schema, this.table, this.tableId, this.tableName,
      this.className, this.keyClassId, this.valueClassId);

  final Schema schema;
  final Table table;
  final Id tableId;
  final String tableName;
  final String className;
  final Id keyClassId;
  final Id valueClassId;

  // custom <class TableDetails>

  factory TableDetails.fromTable(Schema schema, Table table) {
    final tableId = idFromString(table.name);
    return new TableDetails(
        schema,
        table,
        tableId,
        table.name,
        tableId.capSnake,
        idFromString('${tableId.snake}_pkey'),
        idFromString('${tableId.snake}_value'));
  }

  get columnIds => table.columns.map((c) => idFromString(c.name));
  get keyClassName => keyClassId.capSnake;
  get valueClassName => valueClassId.capSnake;
  get keyColumns => table.primaryKey;
  get valueColumns => table.valueColumns;
  get fkeyPath => schema.getDfsPath(table.name);
  get rowType => '$className<>::Row_t';

  // end <class TableDetails>

}

abstract class TableGatewayGenerator {
  SchemaLibCreator schemaLibCreator;
  Class keyClass;
  Class valueClass;

  // custom <class TableGatewayGenerator>

  TableGatewayGenerator(this.schemaLibCreator, Table table) {
    _tableDetails = new TableDetails.fromTable(schemaLibCreator.schema, table);
    keyClass = _makeClass(keyClassId.snake, table.primaryKey);
    valueClass = _makeClass(valueClassId.snake, table.valueColumns);
  }

  get installation => schemaLibCreator.installation;
  get schema => _tableDetails.schema;
  get table => _tableDetails.table;
  get tableId => _tableDetails.tableId;
  get tableName => _tableDetails.tableName;
  get className => _tableDetails.className;
  get rowType => _tableDetails.rowType;
  get keyClassId => _tableDetails.keyClassId;
  get valueClassId => _tableDetails.valueClassId;

  void finishClass(Class cls);
  void finishGatewayClass(Class cls);
  void addRequiredIncludes(Header hdr);

  get selectLastInsertId;
  get selectAffectedRowCount;
  get selectTableRowCount;
  get selectAllRows;
  get findRowByKey;
  get findRowByValue;
  get insertRowList;
  get updateRowList;
  get deleteRow;
  get deleteAllRows;

  _makeMember(c) => member(c.name)
    ..cppAccess = public
    ..type = _cppType(c.type)
    ..hasNoInit = true;

  _colInRow(Table table, Column c) =>
      table.isPrimaryKeyColumn(c) ? 'first.${c.name}' : 'second.${c.name}';

  _linkToMethod(ForeignKey fk) {
    final ref = new TableDetails.fromTable(schema, fk.refTable);
    return '''
// Establish link from $className to ${ref.className}
// across foreign key $tableName.`${fk.name}`
inline void
link_rows($rowType & from_row,
          ${ref.rowType} const& to_row) {
  ${
fk.columnPairs.map((l) =>
  'from_row.${_colInRow(table, l[0])} = to_row.${_colInRow(ref.table, l[1])}').join(';\n  ')};
}''';
  }

  get _foreignLinks => combine(table.foreignKeys.values
      //.where((ForeignKey fk) => td.table == table)
      .map((ForeignKey fk) => _linkToMethod(fk)));

  _stringListSupport(Iterable<Member> members) => '''
/// Access to list of names of members
static inline
void member_names_list(String_list_t &out) {
  ${members.map((m) => 'out.push_back("${m.name}");').join('\n  ')}
}

/// The values of the members as list of strings
inline void
to_string_list(String_list_t &out) const {
  ${members.map((m) => 'out.push_back(boost::lexical_cast< std::string >(${m.vname}));').join('\n  ')}
}
''';

  _makeClass(String id, Iterable<Column> columns) {
    final result = class_(id)
      ..isStruct = true
      ..opEqual
      ..opLess
      ..isStreamable = true
      ..members = columns.map((c) => _makeMember(c)).toList();
    result
        .getCodeBlock(clsPublic)
        .snippets
        .add(_stringListSupport(result.members));
    finishClass(result);
    return result;
  }

  setFilePathFromRoot(String root) => header.setFilePathFromRoot(root);

  Header get header {
    if (_header == null) {
      _header = _makeHeader();
    }
    return _header;
  }

  Namespace get namespace => new Namespace(
      []..addAll(schemaLibCreator.namespace.names)..addAll(['table']));

  Header _makeHeader() {
    final keyClassType = keyClass.className;
    final valueClassType = valueClass.className;
    final valueColumns = table.valueColumns;
    final hasForeignKey = table.hasForeignKey;
    var fkeyIncludes = [];
    table.foreignKeys.values.forEach((ForeignKey fk) {
      final refTableId = idFromString(fk.refTable.name);
      fkeyIncludes.add('${refTableId.snake}.hpp');
    });

    final gatewayClass = class_('${tableName}')
      ..isSingleton = true
      ..testScenarios = [
        testScenario('delete rows deletes rows'),
        testScenario('insert rows inserts rows'),
        testScenario('update rows updates rows'),
      ]
      ..template = [
        'typename PKEY_LIST_TYPE = std::vector< $keyClassType >',
        'typename VALUE_LIST_TYPE = std::vector< $valueClassType >',
      ]
      ..usings = [
        'Pkey_t = $keyClassType',
        'Value_t = $valueClassType',
        'Pkey_list_t = PKEY_LIST_TYPE',
        'Value_list_t = VALUE_LIST_TYPE',
        'Row_t = std::pair< Pkey_t, Value_t >',
        'Row_list_t = std::vector< Row_t >',
      ]
      ..getCodeBlock(clsPublic).snippets.addAll([
        _printSupport,
        selectLastInsertId,
        selectAffectedRowCount,
        selectTableRowCount,
        selectAllRows,
        findRowByKey,
        findRowByValue,
        insertRowList,
        updateRowList,
        deleteRow,
        deleteAllRows
      ])
      ..getCodeBlock(clsPostDecl).snippets.add(_foreignLinks);

    finishGatewayClass(gatewayClass);

    final result = new Header(tableId)
      ..namespace = namespace
      ..includes = ([
        'cstdint',
        'utility',
        'sstream',
        'vector',
        'boost/any.hpp',
      ]..addAll(fkeyIncludes))
      ..classes = [keyClass, valueClass, gatewayClass];

    //    if(!hasForeignKey) {
    new GatewayTestGenerator(result.test, _tableDetails, namespace);
    //    }

    addRequiredIncludes(result);
    return result;
  }

  get _printSupport => '''
static void
print_recordset_as_table(Row_list_t const& recordset,
                         std::ostream &out) {
  ebisu::orm::print_recordset_as_table< $className >(recordset, out);
}

static void
print_values_as_table(Value_list_t const& values,
                      std::ostream &out) {
  ebisu::orm::print_values_as_table< $className >(values, out);
}

''';

  // end <class TableGatewayGenerator>

  TableDetails _tableDetails;
  Header _header;
}

// custom <part generator>

typedef bool TableFilter(Table);

TableFilter TableNameFilter(Iterable<String> tableNames) =>
    (Table t) => tableNames.contains(t.name);

_nonAutoColumns(Table table) => table.columns.where((c) => !c.autoIncrement);
_joined(Iterable<Column> cols) => cols.map((c) => c.name).join(',\n');

_selectKey(Table table) {
  final name = table.name;
  final keyColumnsJoined = table.primaryKey.map((c) => c.name).join(',\n');
  return '''
select
${indentBlock(keyColumnsJoined)}
from
  $name
''';
}

_selectValues(Table table) {
  final name = table.name;
  final valueColumnsJoined = _joined(table.valueColumns);
  return '''
select
${indentBlock(valueColumnsJoined)}
from
  $name
''';
}

_selectAll(Table table) {
  final name = table.name;
  final allColumnsJoined = _joined(table.columns);
  return '''
select
${indentBlock(allColumnsJoined)}
from
  $name
''';
}

String _cppType(SqlType sqlType) {
  switch (sqlType.runtimeType) {
    case SqlString:
      final str = sqlType as SqlString;
      return (str.length > 0)
          ? 'ebisu::utils::Fixed_size_char_array< ${str.length} >'
          : 'std::string';
    case SqlInt:
      return (sqlType as SqlInt).length <= 4 ? 'int32_t' : 'Orm_bigint_t';
    case SqlDecimal:
      return 'decimal';
    case SqlBinary:
      throw 'Add support for SqlDecimal';
    case SqlFloat:
      return 'double';
    case SqlDate:
    case SqlTime:
    case SqlTimestamp:
      return 'Orm_timestamp_t';
  }
  throw 'SqlType $sqlType not supported';
}

// end <part generator>

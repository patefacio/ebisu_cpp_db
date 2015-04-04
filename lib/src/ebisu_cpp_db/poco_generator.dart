part of ebisu_cpp_db.ebisu_cpp_db;

/// Given a schema generates code to support accessing tables and configured
/// queries. Makes use of the poco c++ library.
///
class PocoSchemaCodeGenerator extends SchemaLibCreator {
  Id get sessionClassId => _sessionClassId;
  String get sessionClassName => _sessionClassName;

  // custom <class PocoSchemaCodeGenerator>

  PocoSchemaCodeGenerator(Installation installation, Schema schema)
      : super(installation, schema) {
    _sessionClassId = new Id('connection_${id.snake}');
    _sessionClassName = _sessionClassId.capSnake;
  }

  get namespace => super.namespace;

  TableGatewayGenerator createTableGatewayGenerator(Table t) =>
      new PocoTableGatewayGenerator(installation, this, t);

  finishApiHeader(Header apiHeader) => throw 'TODO';

  // end <class PocoSchemaCodeGenerator>

  Id _sessionClassId;
  String _sessionClassName;
}

class PocoTableGatewayGenerator extends TableGatewayGenerator {

  // custom <class PocoTableGatewayGenerator>

  PocoTableGatewayGenerator(
      Installation installation, SchemaLibCreator schemaLibCreator, Table table)
      : super(installation, schemaLibCreator, table);

  void finishClass(Class cls) => throw 'TODO';

  void finishGatewayClass(Class gatewayClass) => throw 'TODO';

  void addRequiredIncludes(Header hdr) => hdr.includes.addAll([]);

  get selectLastInsertId => throw 'TODO';
  get selectAffectedRowCount => throw 'TODO';
  get selectTableRowCount => throw 'TODO';
  get selectAllRows => throw 'TODO';
  get findRowByKey => throw 'TODO';
  get findRowByValue => throw 'TODO';
  get insertRowList => throw 'TODO';
  get updateRowList => throw 'TODO';
  get deleteRow => throw 'TODO';
  get deleteAllRows => throw 'TODO';

  // end <class PocoTableGatewayGenerator>

}

// custom <part poco_generator>
// end <part poco_generator>

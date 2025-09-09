import 'dart:convert';
import 'package:csv/csv.dart';
import '../db/database.dart';


// Función para generar CSV para que incluye los ingresos, gastos y ahorros
String generarCsvMovimientos(List<Map<String, dynamic>> data) {
  List<List<String>> rows = [];

  // Encabezados personalizados para movimientos
  rows.add([
    'Cantidad (€)',
    'Descripción',
    'Fecha de inserción',
    'Fecha de ocurrencia',
    'Categoría',
  ]);

  for (var row in data) {
    rows.add([
      row['amount']?.toString() ?? '',
      row['description']?.toString() ?? '',
      row['date']?.toString() ?? '',
      row['occurrenceDate']?.toString() ?? '',
      row['categoria_nombre']?.toString() ?? '',
    ]);
  }

  // Convertir a CSV
  String csv = const ListToCsvConverter().convert(rows);
  return csv;
}

String generarCsvActivos(List<Map<String, dynamic>> data) {
  List<List<String>> filas = [];

  List<String> encabezados = [
    'Nombre',
    'Simbolo',
    'Tipo',
    'Valor Actual',
    'Notas',
    'Ubicacion',
    'Estado Propiedad',
    'Ingreso Mensual',
    'Gasto Mensual',
    'Gastos Mantenimiento Anual',
    'Valor Catastral',
    'Hipoteca Pendiente',
    'Impuesto Anual',
  ];

  filas.add(encabezados);

  for (var fila in data) {
    filas.add([
      fila['nombre'] ?? '',
      fila['simbolo'] ?? '',
      fila['tipo'] ?? '',
      fila['valorActual'].toString(),
      fila['notas'] ?? '',
      fila['ubicacion'] ?? '',
      fila['estadoPropiedad'] ?? '',
      fila['ingresoMensual']?.toString() ?? '',
      fila['gastoMensual']?.toString() ?? '',
      fila['gastosMantenimientoAnual']?.toString() ?? '',
      fila['valorCatastral']?.toString() ?? '',
      fila['hipotecaPendiente']?.toString() ?? '',
      fila['impuestoAnual']?.toString() ?? '',
    ]);
  }

  return const ListToCsvConverter().convert(filas);
}

Future<String> generarCsvOperaciones(List<Map<String, dynamic>> data) async {
  List<List<String>> filas = [];

  List<String> encabezados = [
    'Nombre activo',
    'Tipo de Operación',
    'Cantidad',
    'Precio Unitario',
    'Comisión',
    'Notas',
    'Fecha',
  ];

  filas.add(encabezados);

  for (var fila in data) {
    final int idActivo = fila['idActivo'];
    final String? nombreActivo = await obtenerNombreActivoPorId(idActivo);
    if (nombreActivo == null) continue;

    filas.add([
      nombreActivo,
      fila['tipoOperacion']?.toString() ?? '',
      fila['cantidad']?.toString() ?? '',
      fila['precioUnitario']?.toString() ?? '',
      fila['comision']?.toString() ?? '',
      fila['notas']?.toString() ?? '',
      fila['fecha']?.toString() ?? '',
    ]);
  }

  return const ListToCsvConverter().convert(filas);
}

Future<String> generarCsvHistorialValorPromedio(List<Map<String, dynamic>> data) async {
  List<List<String>> filas = [];

  List<String> encabezados = [
    'Nombre activo',
    'Fecha',
    'Valor Compra Promedio',
    'Valor Mercado Actual',
  ];

  filas.add(encabezados);

  for (var fila in data) {
    final int idActivo = fila['activo_id'];
    final String? nombreActivo = await obtenerNombreActivoPorId(idActivo);
    if (nombreActivo == null) continue;

    filas.add([
      nombreActivo,
      fila['fecha']?.toString() ?? '',
      fila['valor_compra_promedio']?.toString() ?? '',
      fila['valor_mercado_actual']?.toString() ?? '',
    ]);
  }

  return const ListToCsvConverter().convert(filas);
}

Future<String?> obtenerNombreActivoPorId(int idActivo) async {
  final db = await DatabaseHelper.instance.database;
  final resultado = await db.query(
    'activos',
    columns: ['nombre'],
    where: 'id = ?',
    whereArgs: [idActivo],
    limit: 1,
  );
  if (resultado.isNotEmpty) {
    return resultado.first['nombre'] as String?;
  }
  return null;
}

Future<String?> obtenerEntidadDeudaPorId(int idDeuda) async {
  final db = await DatabaseHelper.instance.database;
  final resultado = await db.query(
    'deudas',
    columns: ['entidad'],
    where: 'id = ?',
    whereArgs: [idDeuda],
    limit: 1,
  );
  if (resultado.isNotEmpty) {
    return resultado.first['entidad'] as String?;
  }
  return null;
}

Future<String> generarCsvHistorialValoresActivos(List<Map<String, dynamic>> data) async {
  List<List<String>> filas = [];

  List<String> encabezados = [
    'Activo',
    'Fecha',
    'Valor Compra Promedio',
    'Valor Mercado Actual',
  ];

  filas.add(encabezados);

  for (var fila in data) {
    final int idActivo = fila['activo_id'];
    final String? nombreActivo = await obtenerNombreActivoPorId(idActivo);
    if (nombreActivo == null) continue;

    filas.add([
      nombreActivo,
      fila['fecha'] ?? '',
      fila['valor_compra_promedio'].toString(),
      fila['valor_mercado_actual'].toString(),
    ]);
  }

  return const ListToCsvConverter().convert(filas);
}

String generarCsvDeudas(List<Map<String, dynamic>> data) {
  List<List<String>> filas = [];

  // Encabezados personalizados para activos
  List<String> encabezados = [
    'Entidad',
    'Valor',
    'Interés',
    'Nº plazos (meses)',
    'Cuota mensual',
    'Fecha inicio',
    'Fecha fin',
    'Pagos realizados',
    'Notas',
  ];

  filas.add(encabezados);

  for (var fila in data) {
    filas.add([
      fila['entidad']?.toString() ?? '',
      fila['valorTotal']?.toString() ?? '',
      fila['interesAnual']?.toString() ?? '',
      fila['plazoMeses']?.toString() ?? '',
      fila['cuotaMensual']?.toString() ?? '',
      fila['fechaInicio']?.toString() ?? '',
      fila['fechaFin']?.toString() ?? '',
      fila['pagosRealizados']?.toString() ?? '',
      fila['notas']?.toString() ?? '',
    ]);
  }

  return const ListToCsvConverter().convert(filas);
}

Future<String> generarCsvPagos(List<Map<String, dynamic>> data) async {
  List<List<String>> filas = [];

  List<String> encabezados = [
    'Deuda',
    'Cantidad',
    'Fecha',
    'Notas',
  ];

  filas.add(encabezados);

  for (var fila in data) {
    final dynamic rawId = fila['deudaId'];
    final int? idDeuda = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    if (idDeuda == null) continue;

    final String? entidadDeuda = await obtenerEntidadDeudaPorId(idDeuda);
    if (entidadDeuda == null) continue;

    filas.add([
      entidadDeuda,
      fila['cantidad']?.toString() ?? '',
      fila['fecha']?.toString() ?? '',
      fila['notas']?.toString() ?? '',
    ]);
  }

  return const ListToCsvConverter().convert(filas);
}

List<Map<String, dynamic>> parseCsvHistorialValoresActivos(String csvContent) {

  List<List<dynamic>> rows;
  try {
    rows = const CsvToListConverter(eol: '\n').convert(csvContent);
  } catch (e) {
    return [];
  }

  if (rows.length < 2) {
    return [];
  }

  final headers = rows.first.map((h) => h.toString().trim()).toList();

  final result = <Map<String, dynamic>>[];

  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];

    if (row.length != headers.length) {
      continue;
    }

    try {
      final map = <String, dynamic>{
        'activo': row[0]?.toString() ?? '',
        'fecha': row[1]?.toString() ?? '',
        'valor_compra_promedio': double.tryParse(row[2].toString()) ?? 0.0,
        'valor_mercado_actual': double.tryParse(row[3].toString()) ?? 0.0,
      };
      print("Fila $i parseada correctamente: $map");
      result.add(map);
    } catch (e) {
    }
  }

  if (result.isEmpty) {
    print("El resultado final está vacío. Ninguna fila válida fue parseada.");
  } else {
    print("Parseo completo. Total de filas parseadas: ${result.length}");
  }

  return result;
}

List<Map<String, dynamic>> parseCsvDeudas(String csvContent) {

  List<List<dynamic>> rows;
  try {
    rows = const CsvToListConverter(eol: '\n').convert(csvContent);
    print("CSV convertido a lista de filas. Total filas: ${rows.length}");
  } catch (e) {
    print("Error al convertir CSV a lista: $e");
    return [];
  }

  if (rows.length < 2) {
    print("CSV no tiene suficientes filas (mínimo encabezado + 1 dato)");
    return [];
  }

  final headers = rows.first.map((h) => h.toString().trim()).toList();
  print("Encabezados detectados: $headers");

  final result = <Map<String, dynamic>>[];

  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    print("Procesando fila $i: $row");

    if (row.length != headers.length) {
      print("Fila $i ignorada por longitud distinta (${row.length} vs ${headers.length})");
      continue;
    }

    try {
      final map = <String, dynamic>{
        'entidad': row[0]?.toString() ?? '',
        'valorTotal': double.tryParse(row[1].toString()) ?? 0.0,
        'interesAnual': double.tryParse(row[2].toString()) ?? 0.0,
        'plazoMeses': int.tryParse(row[3].toString()) ?? 0,
        'cuotaMensual': double.tryParse(row[4].toString()) ?? 0.0,
        'fechaInicio': row[5]?.toString() ?? '',
        'fechaFin': row[6]?.toString() ?? '',
        'pagosRealizados': int.tryParse(row[7].toString()) ?? 0,
        'notas': row[8]?.toString() ?? '',
        'tipo': 'prestamo',
      };
      print("Fila $i parseada correctamente: $map");
      result.add(map);
    } catch (e) {
      print("Error procesando fila $i: $e");
    }
  }

  if (result.isEmpty) {
    print("El resultado final está vacío. Ninguna fila válida fue parseada.");
  } else {
    print("Parseo completo. Total de filas parseadas: ${result.length}");
  }

  return result;
}

Future<List<Map<String, dynamic>>> parseCsvPagos(String csvContent) async {

  List<List<dynamic>> rows;
  try {
    rows = const CsvToListConverter(eol: '\n').convert(csvContent);
    print("CSV convertido a lista de filas. Total filas: ${rows.length}");
  } catch (e) {
    print("Error al convertir CSV a lista: $e");
    return [];
  }

  if (rows.length < 2) {
    print("CSV no tiene suficientes filas (mínimo encabezado + 1 dato)");
    return [];
  }

  final headers = rows.first.map((h) => h.toString().trim()).toList();


  final result = <Map<String, dynamic>>[];

  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    print("Procesando fila $i: $row");

    if (row.length != headers.length) {
      print("Fila $i ignorada por longitud distinta (${row.length} vs ${headers.length})");
      continue;
    }

    try {
      final map = <String, dynamic>{
        'Deuda': row[0]?.toString().trim() ?? '',
        'Cantidad': row[1]?.toString().trim() ?? '',
        'Fecha': row[2]?.toString().trim() ?? '',
        'Notas': row.length > 3 ? row[3]?.toString().trim() ?? '' : '',
      };

      if (map['Deuda'].isEmpty) {
        print("Fila $i ignorada: nombre de deuda vacío");
        continue;
      }

      print("Fila $i parseada correctamente: $map");
      result.add(map);
    } catch (e) {
      print("Error procesando fila $i: $e");
    }
  }

  if (result.isEmpty) {
    print("El resultado final está vacío. Ninguna fila válida fue parseada.");
  } else {
    print("Parseo completo. Total de filas parseadas: ${result.length}");
  }

  return result;
}

Future<int?> obtenerIdDeudaPorEntidad(String entidad) async {
  final db = await DatabaseHelper.instance.database;
  final resultado = await db.query(
    'deudas',
    columns: ['id'],
    where: 'entidad = ?',
    whereArgs: [entidad],
    limit: 1,
  );
  if (resultado.isNotEmpty) {
    return resultado.first['id'] as int?;
  }
  return null;
}

List<Map<String, dynamic>> parseCsvMovimientos(String csvContent) {

  List<List<dynamic>> rows;
  try {
    rows = const CsvToListConverter(eol: '\n').convert(csvContent);
    print("CSV convertido a lista de filas. Total filas: ${rows.length}");
  } catch (e) {
    print("Error al convertir CSV a lista: $e");
    return [];
  }

  if (rows.length < 2) {
    print("CSV no tiene suficientes filas (mínimo encabezado + 1 dato)");
    return [];
  }

  final headers = rows.first.map((h) => h.toString().trim()).toList();
  print("Encabezados detectados: $headers");

  final result = <Map<String, dynamic>>[];

  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    print("Procesando fila $i: $row");

    if (row.length != headers.length) {
      print("Fila $i ignorada por longitud distinta (${row.length} vs ${headers.length})");
      continue;
    }

    try {
      final map = <String, dynamic>{
        'amount': double.tryParse(row[0].toString()) ?? 0.0,
        'description': row[1].toString(),
        'date': row[2].toString(),
        'occurrenceDate': row[3].toString(),
        'categoria': row[4].toString(),
      };
      print("Fila $i parseada correctamente: $map");
      result.add(map);
    } catch (e) {
      print("Error procesando fila $i: $e");
    }
  }

  if (result.isEmpty) {
    print("El resultado final está vacío. Ninguna fila válida fue parseada.");
  } else {
    print("Parseo completo. Total de filas parseadas: ${result.length}");
  }

  return result;
}

List<Map<String, dynamic>> parseCsvOperaciones(String csvContent) {

  List<List<dynamic>> rows;
  try {
    rows = const CsvToListConverter(eol: '\n').convert(csvContent);
  } catch (e) {
    print("Error al convertir CSV: $e");
    return [];
  }

  if (rows.length < 2) {
    print("CSV operaciones vacío (mínimo encabezado + 1 fila)");
    return [];
  }

  List<String> headers = rows.first
      .map((h) => h.toString().trim().toLowerCase().replaceAll(' ', ''))
      .toList();

  int idxNombreActivo   = headers.indexOf('nombreactivo');
  int idxTipoOperacion  = headers.indexOf('tipodeoperación');
  int idxCantidad       = headers.indexOf('cantidad');
  int idxPrecioUnitario = headers.indexOf('preciounitario');
  int idxComision       = headers.indexOf('comisión');
  int idxNotas          = headers.indexOf('notas');
  int idxFecha          = headers.indexOf('fecha');

  if (idxNombreActivo == -1 || idxTipoOperacion == -1 || idxCantidad == -1 ||
      idxPrecioUnitario == -1 || idxComision == -1 || idxNotas == -1 || idxFecha == -1) {
    print("Encabezados insuficientes en operaciones.");
    return [];
  }

  final result = <Map<String, dynamic>>[];

  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.isEmpty) continue;

    final map = <String, dynamic>{
      'Activo': (idxNombreActivo < row.length) ? row[idxNombreActivo]?.toString().trim() : '',
      'Tipo de Operación': (idxTipoOperacion < row.length) ? row[idxTipoOperacion]?.toString().trim() : '',
      'Cantidad': (idxCantidad < row.length) ? (double.tryParse(row[idxCantidad]?.toString() ?? '') ?? 0.0) : 0.0,
      'Precio Unitario': (idxPrecioUnitario < row.length) ? (double.tryParse(row[idxPrecioUnitario]?.toString() ?? '') ?? 0.0) : 0.0,
      'Comisión': (idxComision < row.length) ? (double.tryParse(row[idxComision]?.toString() ?? '') ?? 0.0) : 0.0,
      'Notas': (idxNotas < row.length) ? row[idxNotas]?.toString() : '',
      'Fecha': (idxFecha < row.length) ? row[idxFecha]?.toString() : '',
    };

    print("Fila $i parseada: $map");
    result.add(map);
  }

  print("Parseo operaciones completo. Total: ${result.length}");
  return result;
}

List<Map<String, dynamic>> parseCsvActivos(String csvContent) {
  List<List<dynamic>> rows;
  try {
    rows = const CsvToListConverter(eol: '\n').convert(csvContent);
  } catch (e) {
    print("Error convirtiendo CSV a lista: $e");
    return [];
  }

  if (rows.length < 2) return [];

  final headers = rows.first.map((h) => h.toString().replaceAll('"', '').trim()).toList();
  final result = <Map<String, dynamic>>[];

  for (int i = 1; i < rows.length; i++) {
    final cleanRow = rows[i].map((e) => e.toString().replaceAll('"', '').trim()).toList();
    if (cleanRow.length != headers.length) continue;

    result.add({
      'nombre': cleanRow[0],
      'simbolo': cleanRow[1],
      'tipo': cleanRow[2],
      'valorActual': double.tryParse(cleanRow[3]) ?? 0.0,
      'notas': cleanRow[4],
      'ubicacion': cleanRow[5],
      'estadoPropiedad': cleanRow[6],
      'ingresoMensual': cleanRow[7].isEmpty ? null : double.tryParse(cleanRow[7]),
      'gastoMensual': cleanRow[8].isEmpty ? null : double.tryParse(cleanRow[8]),
      'gastosMantenimientoAnual': cleanRow[9].isEmpty ? null : double.tryParse(cleanRow[9]),
      'valorCatastral': cleanRow[10].isEmpty ? null : double.tryParse(cleanRow[10]),
      'hipotecaPendiente': cleanRow[11].isEmpty ? null : double.tryParse(cleanRow[11]),
      'impuestoAnual': cleanRow[12].isEmpty ? null : double.tryParse(cleanRow[12]),
    });
  }

  return result;
}

List<Map<String, String>> parseCsv(String csvContent) {
  final lines = const LineSplitter().convert(csvContent.trim());
  if (lines.isEmpty) return [];

  final headers = lines.first.split(',');
  return lines.skip(1).map((line) {
    final values = line.split(',');
    return Map.fromIterables(headers, values);
  }).toList();
}

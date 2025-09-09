import 'package:finanzas_app/models/pagosDeuda_class.dart';
import 'package:sqflite/sqflite.dart';
import '../models/deuda_class.dart';
import 'database.dart';

class DeudasDao {
  static final DeudasDao _instance = DeudasDao._internal();
  DeudasDao._internal();
  static DeudasDao get instance => _instance;

  Future<int> insertardeuda(Deuda deuda) async {
    final db = await DatabaseHelper.instance.database;

    // Insertar el deuda
    final id = await db.insert(
      'deudas',
      deuda.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }


  Future<bool> deudaExists(String entidad) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'deudas',
      where: 'entidad = ?',
      whereArgs: [entidad],
    );
    return result.isNotEmpty;
  }

  Future<List<Deuda>> obtenerTodasLasDeudas() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('deudas');
    List<Deuda> deudas = [];

    for (var map in maps) {
      final id = map['id'];
      final pagos = await obtenerPagosPorDeuda(id);
      final deuda = Deuda.fromMap(map)..historialPagos = pagos;
      deudas.add(deuda);
    }

    return deudas;
  }

  Future<bool> pagoExists({
    required int deudaId,
    required double cantidad,
    required DateTime fecha,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'pagos',
      columns: ['id'],
      where: 'deudaId = ? AND cantidad = ? AND fecha = ?',
      whereArgs: [
        deudaId,
        cantidad,
        fecha.toIso8601String(),
      ],
      limit: 1,
    );

    return result.isNotEmpty;
  }





  Future<void> actualizardeuda(Deuda deuda) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'deudas',
      deuda.toMap(),
      where: 'id = ?',
      whereArgs: [deuda.id],
    );
  }

  Future<int?> getIdByNombre(String nombre) async {
    final db = await DatabaseHelper.instance.database;

    final res = await db.query(
      'deudas',
      columns: ['id'],
      where: 'entidad = ?',
      whereArgs: [nombre],
      limit: 1,
    );

    if (res.isNotEmpty) {
      return res.first['id'] as int;
    }
    return null;
  }

  Future<void> eliminardeuda(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('pagos', where: 'deudaId = ?', whereArgs: [id]);
    await db.delete('deudas', where: 'id = ?', whereArgs: [id]);
  }

  Future<int?> getIdByEntidad(String entidad) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query(
      'deudas',
      columns: ['id'],
      where: 'entidad = ?',
      whereArgs: [entidad],
      limit: 1,
    );

    if (res.isNotEmpty) {
      return res.first['id'] as int;
    }
    return null;
  }


  Future<void> insertarPago(int idDeuda, PagoDeuda pago) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'pagos',
      pago.toMap()..['deudaId'] = idDeuda,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  Future<bool> eliminarPago(int idPago, int idDeuda) async {
    final db = await DatabaseHelper.instance.database;

    try {
      // Eliminamos la operación de la base de datos
      final rowsAffected = await db.delete(
        'pagos',
        where: 'id = ? AND deudaId = ?',
        whereArgs: [idPago, idDeuda],
      );

      return rowsAffected > 0;
    } catch (e) {
      print("Error al eliminar el pago de la base de datos: $e");
      return false;
    }
  }

  Future<List<PagoDeuda>> obtenerPagosPorDeuda(int idDeuda) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pagos',
      where: 'deudaId = ?',
      whereArgs: [idDeuda],
    );

    return maps.map((map) => PagoDeuda.fromMap(map)).toList();
  }

  Future<Deuda?> obtenerDeudaPorId(int id) async {
    final db = await DatabaseHelper.instance.database;

    final resultado = await db.query(
      'deudas',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (resultado.isNotEmpty) {
      return Deuda.fromMap(resultado.first);
    }

    return null;
  }


  Future<List<Deuda>> obtenerDeudasPorTipo(TipoDeuda tipo) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'deudas',
      where: 'tipo = ?',
      whereArgs: [tipo.name],
    );

    final List<Deuda> deudas = [];

    for (var map in maps) {
      final deuda = Deuda.fromMap(map);
      deuda.historialPagos = await obtenerPagosPorDeuda(deuda.id);
      deudas.add(deuda);
    }

    return deudas;
  }


  Future<void> actualizarPago(PagoDeuda pago) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'pagos',
      pago.toMap(),
      where: 'id = ?',
      whereArgs: [pago.id],
    );
  }


  Future<List<Map<String, dynamic>>> obtenerTodasDeudasComoMapa() async {
    final db = await DatabaseHelper.instance.database;

    final resultado = await db.rawQuery('''
    SELECT 
      entidad,
      valorTotal,
      interesAnual,
      plazoMeses,
      cuotaMensual,
      fechaInicio,
      fechaFin,
      pagosRealizados,
      notas
    FROM deudas
  ''');

    return resultado;
  }

  Future<List<Map<String, dynamic>>> obtenerTodosPagos() async {
    final db = await DatabaseHelper.instance.database;

    final resultado = await db.rawQuery('''
    SELECT 
      id,
      deudaId,
      fecha,
      cantidad,
      notas
    FROM pagos
  ''');

    return resultado;
  }

}

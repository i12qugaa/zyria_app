import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../models/activo_class.dart';
import '../models/operacion_class.dart';
import '../models/valorHistorico_class.dart';
import 'database.dart';

class ActivosDao {
  static final ActivosDao _instance = ActivosDao._internal();
  ActivosDao._internal();
  static ActivosDao get instance => _instance;

  Future<int> insertarActivo(Activo activo) async {
    final db = await DatabaseHelper.instance.database;

    // Insertar el activo
    final id = await db.insert(
      'activos',
      activo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return id;
  }

  // Insertar un valor histórico para un activo
  Future<void> insertarValorHistorico(int idActivo, ValorHistorico valorHistorico) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert(
      'historial_valor_promedio',
      {
        'activo_id': idActivo,
        'fecha': valorHistorico.fecha.toIso8601String(),
        'valor_compra_promedio': valorHistorico.valorCompraPromedio,
        'valor_mercado_actual': valorHistorico.valorMercadoActual,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> getIdByNombre(String nombre) async {
    final db = await DatabaseHelper.instance.database;

    final res = await db.query(
      'activos',
      columns: ['id'],
      where: 'nombre = ?',
      whereArgs: [nombre],
      limit: 1,
    );

    if (res.isNotEmpty) {
      return res.first['id'] as int;
    }
    return null;
  }



  Future<void> insertarOperacion(int idActivo, Operacion operacion) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'operaciones',
      operacion.toMap()..['idActivo'] = idActivo,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> actualizarOperacion(Operacion operacion) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'operaciones',
      operacion.toMap(),
      where: 'id = ?',
      whereArgs: [operacion.id],
    );
  }


  Future<List<Activo>> obtenerTodosLosActivos() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('activos');

    List<Activo> activos = [];

    for (var map in maps) {
      final id = map['id'];
      final operaciones = await obtenerOperacionesPorActivo(id);
      final activo = Activo.fromMap(map)..historialOperaciones = operaciones;
      activos.add(activo);
    }

    return activos;
  }

  Future<List<Operacion>> obtenerOperacionesPorActivo(int idActivo) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'operaciones',
      where: 'idActivo = ?',
      whereArgs: [idActivo],
    );

    return maps.map((map) => Operacion.fromMap(map)).toList();
  }

  Future<void> actualizarActivo(Activo activo) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'activos',
      activo.toMap(),
      where: 'id = ?',
      whereArgs: [activo.id],
    );

    // Eliminar operaciones antiguas y volver a insertar las actuales
    await db.delete('operaciones', where: 'idActivo = ?', whereArgs: [activo.id]);

    for (final op in activo.historialOperaciones) {
      await insertarOperacion(activo.id, op);
    }
  }

  Future<void> eliminarActivo(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('operaciones', where: 'idActivo = ?', whereArgs: [id]);
    await db.delete('historial_valor_promedio', where: 'activo_id = ?', whereArgs: [id]);
    await db.delete('activos', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> eliminarOperacion(int idOperacion, int idActivo) async {
    final db = await DatabaseHelper.instance.database;

    try {
      // Eliminamos la operación de la base de datos
      final rowsAffected = await db.delete(
        'operaciones',
        where: 'id = ? AND idActivo = ?',
        whereArgs: [idOperacion, idActivo],
      );

      return rowsAffected > 0;
    } catch (e) {
      print("Error al eliminar operación de la base de datos: $e");
      return false;
    }
  }

  Future<List<ValorHistorico>> obtenerHistorialDeActivo(int activoId) async {
    final db = await DatabaseHelper.instance.database;
    final resultado = await db.query(
      'historial_valor_promedio',
      where: 'activo_id = ?',
      whereArgs: [activoId],
      orderBy: 'fecha ASC',
    );

    return resultado.map((e) => ValorHistorico.fromMap(e)).toList();
  }


  Future<void> insertarHistorialValorPromedio({
    required int activoId,
    required DateTime fecha,
    required double? valorCompra,
    required double? valorMercado,
  }) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert('historial_valor_promedio', {
      'activo_id': activoId,
      'fecha': fecha.toIso8601String(),
      'valor_compra_promedio': valorCompra,
      'valor_mercado_actual': valorMercado,
    });
  }

  Future<Activo?> obtenerActivoPorId(int id) async {
    final db = await DatabaseHelper.instance.database;

    final resultado = await db.query(
      'activos',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (resultado.isNotEmpty) {
      return Activo.fromMap(resultado.first);
    }

    return null;
  }


  Future<List<Activo>> obtenerActivosPorTipo(TipoActivo tipo) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'activos',
      where: 'tipo = ?',
      whereArgs: [tipo.name],
    );

    List<Activo> activos = [];

    for (var map in maps) {
      final id = map['id'];
      final operaciones = await obtenerOperacionesPorActivo(id);
      final activo = Activo.fromMap(map)..historialOperaciones = operaciones;
      activos.add(activo);
    }

    return activos;
  }

  Future<List<Map<String, dynamic>>> obtenerTodosActivosComoMapa() async {
    final db = await DatabaseHelper.instance.database;

    final resultado = await db.rawQuery('''
    SELECT 
      nombre,
      simbolo,
      tipo,
      valorActual,
      notas,
      ubicacion,
      estadoPropiedad,
      ingresoMensual,
      gastoMensual,
      gastosMantenimientoAnual,
      valorCatastral,
      hipotecaPendiente,
      impuestoAnual
    FROM activos
  ''');

    return resultado;
  }

  Future<bool> operacionExists({
    required int idActivo,
    required TipoOperacion tipo,
    required double cantidad,
    required DateTime fecha,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'operaciones',
      columns: ['id'],
      where: 'idActivo = ? AND tipoOperacion = ? AND cantidad = ? AND fecha = ?',
      whereArgs: [
        idActivo,
        tipo.toString().split('.').last,
        cantidad,
        fecha.toIso8601String(),
      ],
      limit: 1,
    );

    return result.isNotEmpty;
  }


  Future<bool> activoExists(String simbolo) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'activos',
      where: 'simbolo = ?',
      whereArgs: [simbolo],
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> obtenerTodasOperaciones() async {
    final db = await DatabaseHelper.instance.database;

    final resultado = await db.rawQuery('''
    SELECT 
      id,
      idActivo,
      tipoOperacion,
      cantidad,
      precioUnitario,
      comision,
      notas,
      fecha
    FROM operaciones
  ''');

    return resultado;
  }

  Future<List<Map<String, dynamic>>> obtenerTodoHistorialValorPromedio() async {
    final db = await DatabaseHelper.instance.database;

    final resultado = await db.rawQuery('''
    SELECT 
      id,
      activo_id,
      fecha,
      valor_compra_promedio,
      valor_mercado_actual
    FROM historial_valor_promedio
  ''');

    return resultado;
  }
}

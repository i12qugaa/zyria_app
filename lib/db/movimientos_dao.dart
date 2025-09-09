import 'package:sqflite/sqflite.dart';
import '../models/movimiento_class.dart';
import 'database.dart';

class MovimientosDao {

  // Patrón Singleton: Crea una única instancia de la clase MovimientosDao
  static final MovimientosDao _instance = MovimientosDao._internal();

  // Constructor privado para evitar múltiples instancias
  MovimientosDao._internal();

  // Getter que devuelve la instancia única de MovimientosDao
  static MovimientosDao get instance => _instance;

  // Verifica la existencia del movimiento en la base de datos (ingreso o gasto)
  Future<bool> movimientoExists(String date, String description) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'movimientos',
      where: 'date = ? AND description = ?',
      whereArgs: [date, description],
    );
    return result.isNotEmpty;
  }

  // Ingresa un nuevo movimiento (ingreso, gasto, ahorro)
  Future<int> insertMovimiento(Movimiento movimiento) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('movimientos', movimiento.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Obtiene todos los movimientos (ingresos, gastos, ahorros)
  Future<List<Movimiento>> getAllMovimientos() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> result = await db.query('movimientos');
    return result.map((map) => Movimiento.fromMap(map)).toList();
  }

  // Elimina un movimiento por tipo (ingreso o gasto)
  Future<void> deleteMovimiento(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'movimientos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Actualiza un movimiento por tipo
  Future<void> updateMovimiento(Movimiento movimiento) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'movimientos',
      {
        'amount': movimiento.amount,
        'description': movimiento.description,
        'date': movimiento.date,
        'occurrenceDate': movimiento.occurrenceDate,
        'tipo': movimiento.tipo,
        'categoriaId': movimiento.categoriaId,
      },
      where: 'id = ?',
      whereArgs: [movimiento.id],
    );
  }


  Future<List<Movimiento>> getMovimientoByMonth({required int year, required int month, required String tipo}) async {
    final db = await DatabaseHelper.instance.database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final List<Map<String, dynamic>> result = await db.query(
      'movimientos',
      where: 'occurrenceDate >= ? AND occurrenceDate <= ? AND tipo = ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String(), tipo],
      orderBy: 'occurrenceDate DESC',
    );

    return result.map((e) => Movimiento.fromMap(e)).toList();
  }

  Future<List<Movimiento>> getMovimientoByYear({required int year, required String tipo}) async {
    final db = await DatabaseHelper.instance.database;

    // Fecha de inicio: 1 de enero del año
    final startDate = DateTime(year, 1, 1);

    // Fecha de fin: 31 de diciembre del año
    final endDate = DateTime(year, 12, 31, 23, 59, 59);

    final List<Map<String, dynamic>> result = await db.query(
      'movimientos',
      where: 'occurrenceDate >= ? AND occurrenceDate <= ? AND tipo = ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String(), tipo],
      orderBy: 'occurrenceDate DESC',
    );

    return result.map((e) => Movimiento.fromMap(e)).toList();
  }


  Future<List<Movimiento>> getMovimientoByDay({required int year, required int month, required int day, required String tipo}) async {
    final db = await DatabaseHelper.instance.database;

    // Fecha de inicio: a las 00:00 del día seleccionado
    final startDate = DateTime(year, month, day, 0, 0, 0);

    // Fecha de fin: a las 23:59:59 del mismo día
    final endDate = DateTime(year, month, day, 23, 59, 59);

    final List<Map<String, dynamic>> result = await db.query(
      'movimientos',
      where: 'occurrenceDate >= ? AND occurrenceDate <= ? AND tipo = ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String(), tipo],
      orderBy: 'occurrenceDate DESC',
    );

    return result.map((e) => Movimiento.fromMap(e)).toList();
  }


  // Obtiene un movimiento en específico por ID
  Future<Movimiento?> getMovimientoById(int movimientoId) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> result = await db.query(
      'movimientos',
      where: 'id = ?',
      whereArgs: [movimientoId],
    );

    if (result.isNotEmpty) {
      return Movimiento.fromMap(result.first);
    }

    return null;
  }

  Future<List<Movimiento>> getMovimiento(String tipo) async {
    return await _getMovimientosPorTipo(tipo);
  }

  // Metodo para obtener movimientos por tipo
  Future<List<Movimiento>> _getMovimientosPorTipo(String tipo) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> result = await db.query(
      'movimientos',
      where: 'tipo = ?',
      whereArgs: [tipo],
      orderBy: 'occurrenceDate DESC',
    );

    return result.map((e) => Movimiento.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> obtenerMovimientosPorTipo(String tipo) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
    SELECT 
      m.amount, 
      m.description, 
      m.date, 
      m.occurrenceDate, 
      c.nombre AS categoria_nombre
    FROM movimientos m
    LEFT JOIN categorias c ON m.categoriaId = c.id
    WHERE m.tipo = ?
  ''', [tipo]);

    return result;
  }


  Future<void> actualizarMovimiento(Movimiento movimiento) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'movimientos',
      movimiento.toMap(),
      where: 'id = ?',
      whereArgs: [movimiento.id],
    );
  }

}

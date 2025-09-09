import 'package:sqflite/sqflite.dart';
import '../db/database.dart';
import '../models/mensaje_class.dart';

class MensajesDao {
  static final MensajesDao _instance = MensajesDao._internal();
  MensajesDao._internal();
  static MensajesDao get instance => _instance;

  Future<int> insertarMensaje(Mensaje mensaje) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(
      'mensajes',
      mensaje.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Mensaje>> obtenerMensajes() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mensajes',
      orderBy: 'fecha ASC',
    );
    return maps.map((m) => Mensaje.fromMap(m)).toList();
  }

  Future<void> eliminarTodosLosMensajes() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('mensajes');
  }

  Future<List<Map<String, dynamic>>> obtenerMovimientos() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('movimientos');
    return result;
  }

  Future<List<Map<String, dynamic>>> obtener_Movimientos() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
    SELECT m.*, c.nombre AS categoria
    FROM movimientos m
    LEFT JOIN categorias c
    ON m.categoriaId = c.id
  ''');

    return result;
  }

  Future<List<Map<String, dynamic>>> obtenerCategorias() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('categorias');
    return result;
  }


  Future<List<Map<String, dynamic>>> obtenerActivos() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('activos');
    return result;
  }

  Future<List<Map<String, dynamic>>> obtenerDeudas() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('deudas');
    return result;
  }

  Future<List<Map<String, dynamic>>> obtenerOperacionesDeActivo(int activoId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'operaciones',
      where: 'idActivo = ?',
      whereArgs: [activoId],
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> obtenerPagosDeuda(int deudaId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'pagos',
      where: 'deudaId = ?',
      whereArgs: [deudaId],
    );
    return result;
  }

}

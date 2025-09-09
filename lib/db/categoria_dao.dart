import 'package:sqflite/sqflite.dart';
import 'database.dart';
import '../models/category_class.dart';

class CategoriasDao {

  // Patrón Singleton: Crea una única instancia de la clase IngresosDao
  static final CategoriasDao _instance = CategoriasDao._internal();

  // Constructor privado para evitar múltiples instancias
  CategoriasDao._internal();

  // Getter que devuelve la instancia única de IngresosDao
  static CategoriasDao get instance => _instance;

  // Ingresa una nueva categoria en la base de datos
  Future<int> insertCategoria(Categoria categoria) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(
      'categorias',
      categoria.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtiene las categorias por tipo
  Future<List<Categoria>> getCategoriasByTipo(String tipo) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> result =
    await db.query('categorias', where: 'tipo = ?', whereArgs: [tipo]);
    return result.map((map) => Categoria.fromMap(map)).toList();
  }

  // Obtiene el nombre de la categoría a partir de su ID
  Future<String?> getCategoriaNombreById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'categorias',
      columns: ['nombre'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return result.first['nombre'] as String;
    } else {
      return null;
    }
  }

  // Obtiene el ID de la categoría a partir de su nombre

  Future<int?> getCategoriaIDByNombre(String nombre) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'categorias',
      columns: ['id'],
      where: 'LOWER(TRIM(nombre)) = ?',
      whereArgs: [nombre.trim().toLowerCase()],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    } else {
      return null;
    }
  }



  // Borra una categoria
  Future<void> deleteCategoria(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('categorias', where: 'id = ?', whereArgs: [id]);
  }

  // Modifica una categoria (nombre)
  Future<void> updateCategoria(Categoria categoria) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'categorias',
      categoria.toMap(),
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  Future<bool> categoriaExists(String nombre, String tipo) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'categorias',
      where: 'nombre = ? AND tipo = ?',
      whereArgs: [nombre, tipo],
    );
    return result.isNotEmpty;
  }

}



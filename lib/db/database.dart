// Clase DatabaseHelper para la gestión de la base de datos

import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {

  // Nombre y versión de la base de datos
  static const _databaseName = 'database.db';
  static const _databaseVersion = 1;

  // Instancia única (Singleton) de DatabaseHelper
  static final DatabaseHelper instance = DatabaseHelper._internal();

  // Constructor privado para evitar múltiples instancias
  DatabaseHelper._internal();

  //Variable que referencia a la base de datos
  Database? _database;

  // Getter para obtener la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializa la base de datos
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName); // Construye la ruta completa de la base de datos
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate, // Llama a _onCreate para crear las tablas si la base de datos es nueva
    );
  }

  // Resetear la base de datos
  Future<void> resetDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    // Elimina la base de datos si existe
    await deleteDatabase(path);
    debugPrint("Base de datos eliminada: $path");
  }

  // Crear tablas de la base de datos

  Future<void> _onCreate(Database db, int version) async {

    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        tipo TEXT NOT NULL,
        color INTEGER,
        erasable INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE movimientos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        occurrenceDate TEXT NOT NULL,
        tipo TEXT NOT NULL,
        categoriaId INTEGER,
        FOREIGN KEY (categoriaId) REFERENCES categoria(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE activos (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        simbolo TEXT,
        tipo TEXT NOT NULL CHECK (
          tipo IN ('accionesEtfs', 'inmobiliario', 'criptomonedas', 'fondosInversion')
        ),
        autoActualizar INTEGER DEFAULT 1,
        valorActual REAL NOT NULL,
        notas TEXT,
      
        -- Campos específicos para activos inmobiliarios (todos opcionales)
        ubicacion TEXT,
        estadoPropiedad TEXT CHECK (
          estadoPropiedad IN ('enPropiedad', 'alquilado', 'enVenta', 'usoPropio')
        ),
        ingresoMensual REAL,
        gastoMensual REAL,
        gastosMantenimientoAnual REAL,
        valorCatastral REAL,
        hipotecaPendiente REAL,
        impuestoAnual REAL
      );
    ''');

    await db.execute('''
      CREATE TABLE historial_valor_promedio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activo_id INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        valor_compra_promedio REAL NOT NULL,
        valor_mercado_actual REAL NOT NULL,
        FOREIGN KEY (activo_id) REFERENCES activos(id) ON DELETE CASCADE
        );
    ''');

    await db.execute('''
      CREATE TABLE operaciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idActivo INTEGER NOT NULL,
        tipoOperacion TEXT NOT NULL CHECK (tipoOperacion IN ('compra', 'venta')),
        cantidad REAL NOT NULL,
        precioUnitario REAL NOT NULL,
        comision REAL DEFAULT 0.0,
        notas TEXT,
        fecha TEXT NOT NULL,
        FOREIGN KEY(idActivo) REFERENCES activos(id)
       );
      ''');

    await db.execute('''
      CREATE TABLE deudas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL CHECK (tipo IN ('hipoteca', 'prestamo', 'credito')),
        entidad TEXT NOT NULL,
        valorTotal REAL NOT NULL,
        interesAnual REAL NOT NULL,
        plazoMeses INTEGER NOT NULL,
        cuotaMensual REAL,
        fechaInicio TEXT NOT NULL,
        fechaFin TEXT,
        pagosRealizados INTEGER DEFAULT 0,
        notas TEXT
      );
     ''');

    await db.execute('''
      CREATE TABLE pagos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deudaId TEXT NOT NULL,
        fecha TEXT NOT NULL,
        cantidad REAL NOT NULL,
        notas TEXT,
        FOREIGN KEY(deudaId) REFERENCES deudas(id)
      )
    ''');

    await db.execute('''
       CREATE TABLE mensajes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contenido TEXT NOT NULL,
        esUsuario INTEGER NOT NULL,
        fecha TEXT NOT NULL
      )
      ''');

    await db.insert('activos', {
      'id': 2,
      'nombre': 'Acciones Apple',
      'simbolo': 'AAPL',
      'tipo': 'accionesEtfs',
      'valorActual': 175.0,
      'notas': 'Comprado tras buenos resultados trimestrales',
    });


    await db.insert('operaciones', {
      'idActivo': 2,
      'tipoOperacion': 'compra',
      'cantidad': 10,
      'precioUnitario': 135.0,
      'comision': 1.5,
      'fecha': '2023-02-20T09:00:00Z',
      'notas' : 'sda',
    });

    await db.insert('operaciones', {
      'idActivo': 2,
      'tipoOperacion': 'compra',
      'cantidad': 10,
      'precioUnitario': 145.0,
      'comision': 2.0,
      'fecha': '2023-03-01T10:00:00Z',
      'notas' : 'sda',
    });


    // Insertar categorías iniciales

    await db.insert('categorias', {'nombre': 'Alimentación', 'tipo': 'gasto', 'erasable': 0});
    await db.insert('categorias', {'nombre': 'Vivienda', 'tipo': 'gasto', 'erasable': 0});
    await db.insert('categorias', {'nombre': 'Ropa', 'tipo': 'gasto', 'erasable': 0});
    await db.insert('categorias', {'nombre': 'Transporte', 'tipo': 'gasto', 'erasable': 0});
    await db.insert('categorias', {'nombre': 'Salud', 'tipo': 'gasto', 'erasable': 0});
    await db.insert('categorias', {'nombre': 'Ocio', 'tipo': 'gasto', 'erasable': 0});
    await db.insert('categorias', {'nombre': 'Educación', 'tipo': 'gasto', 'erasable': 0});
    await db.insert('categorias', {'nombre': 'Compras', 'tipo': 'gasto', 'erasable': 0});
    await db.insert('categorias', {'nombre': 'Automovil', 'tipo': 'gasto', 'erasable': 0});
    await db.insert('categorias', {'nombre': 'Impuestos', 'tipo': 'gasto', 'erasable': 0});
    await db.insert('categorias', {'nombre': 'Vacaciones', 'tipo': 'gasto', 'erasable': 0});
    await db.insert('categorias', {'nombre': 'Ahorro', 'tipo': 'ahorro', 'erasable': 0});
    await db.insert('categorias', {'nombre': 'Salario', 'tipo': 'ingreso', 'erasable': 0});
  }
}

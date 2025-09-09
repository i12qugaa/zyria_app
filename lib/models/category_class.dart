import 'dart:ui';

class Categoria {

  // Atributos de la clase Categoria
  final int? id;
  final String nombre;
  final String tipo;    // Hay 2 tipos: 'Gasto' y 'Ingreso'
  final Color color;
  final bool erasable;


  // Constructor de la clase Categoria
  Categoria({
    this.id,             // ID asignado automáticamente por la base de datos
    required this.nombre,
    required this.tipo,
    Color? color,
    this.erasable = true,// Color opcional
  }) : color = color ?? _generateColor(nombre);  // Si no se pasa color, se genera uno basado en el nombre de la categoría

  // Función que genera un color único para cada categoría basado en su nombre
  static Color _generateColor(String nombre) {
    int hash = nombre.hashCode;  // Obtiene un valor hash único del nombre
    return Color((hash & 0xFFFFFF) | 0xFF000000);  // Crea un color basado en el hash
  }

  // Convierte la categoría a un mapa para guardarla en la base de datos (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'color': color.value, // Convierte el color a un entero ARGB para almacenarlo en la base de datos
      'erasable': erasable ? 1 : 0,

    };
  }

  // Convierte el mapa obtenido de la base de datos en un objeto Categoria
  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'],
      nombre: map['nombre'],
      tipo: map['tipo'],
      color: map['color'] != null
          ? Color(map['color']) // Si se pasó un color, se usa
          : _generateColor(map['nombre']), // Si no, genera un color basado en el nombre
      erasable: map['erasable'] == 1,
    );
  }
}

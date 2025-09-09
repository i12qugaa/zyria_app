class Movimiento {

  // Atributos de la clase Movimiento
  final int? id;
  final double amount;
  final String description;
  final String date;
  final String occurrenceDate;
  final String tipo;
  final int? categoriaId;

  // Constructor de la clase Movimiento
  Movimiento({
    this.id,                     // ID asignado automáticamente por la base de datos
    required this.amount,
    required this.description,
    required this.date,
    required this.occurrenceDate,
    required this.tipo,           // 'ingreso', 'gasto' o 'ahorro'
    required this.categoriaId,
  });

  // Convierte el Movimiento a un mapa para guardarlo en la base de datos (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'date': date,
      'occurrenceDate': occurrenceDate,
      'tipo': tipo,
      'categoriaId': categoriaId,
    };
  }

  // Convierte el mapa obtenido de la base de datos en un objeto Movimiento
  factory Movimiento.fromMap(Map<String, dynamic> map) {
    return Movimiento(
      id: map['id'],
      amount: map['amount'],
      description: map['description'] ?? '',
      date: map['date'],
      occurrenceDate: map['occurrenceDate'],
      tipo: map['tipo'],
      categoriaId: map['categoriaId'],
    );
  }
}

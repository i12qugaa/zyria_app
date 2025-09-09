class Mensaje {
  final int? id;
  final String contenido;
  final bool esUsuario;
  final DateTime fecha;

  Mensaje({
    this.id,
    required this.contenido,
    required this.esUsuario,
    required this.fecha,
  });

  factory Mensaje.fromMap(Map<String, dynamic> map) => Mensaje(
    id: map['id'],
    contenido: map['contenido'],
    esUsuario: map['esUsuario'] == 1,
    fecha: DateTime.parse(map['fecha']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'contenido': contenido,
    'esUsuario': esUsuario ? 1 : 0,
    'fecha': fecha.toIso8601String(),
  };
}

enum TipoOperacion { compra, venta }

class Operacion {
  int id;
  int idActivo;
  TipoOperacion tipo;
  double cantidad;
  double precioUnitario;
  double? comision;
  String? notas;
  DateTime fecha;

  Operacion({
    required this.id,
    required this.idActivo,
    required this.tipo,
    required this.cantidad,
    required this.precioUnitario,
    this.comision,
    this.notas,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'idActivo': idActivo,
      'tipoOperacion': tipo.name,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'comision': comision,
      'notas': notas,
      'fecha': fecha.toIso8601String(),
    };
    if (id != 0) map['id'] = id;
    return map;
  }


  factory Operacion.fromMap(Map<String, dynamic> map) {
    return Operacion(
      id: map['id'],
      idActivo: map['idActivo'],
      tipo: TipoOperacion.values.firstWhere((e) => e.name == map['tipoOperacion']),
      cantidad: map['cantidad'],
      precioUnitario: map['precioUnitario'],
      comision: map['comision'],
      notas: map['notas'],
      fecha: DateTime.parse(map['fecha']),
    );
  }
}
class PagoDeuda {
  int id;
  int deudaId;
  DateTime fecha;
  double cantidad;
  String? notas;

  PagoDeuda({
    required this.id,
    required this.deudaId,
    required this.fecha,
    required this.cantidad,
    this.notas,
  });

  Map<String, dynamic> toMap() => {
    'deudaId': deudaId,
    'fecha': fecha.toIso8601String(),
    'cantidad': cantidad,
    'notas': notas,
  };

  factory PagoDeuda.fromMap(Map<String, dynamic> map) => PagoDeuda(
    id: map['id'],
    deudaId: map['deudaId'] is int ? map['deudaId'] : int.parse(map['deudaId'].toString()),
    fecha: DateTime.parse(map['fecha']),
    cantidad: (map['cantidad'] as num).toDouble(),
    notas: map['notas'],
  );
}

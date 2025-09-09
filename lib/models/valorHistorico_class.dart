class ValorHistorico {
  final DateTime fecha;
  final double valorMercadoActual;
  final double valorCompraPromedio;

  ValorHistorico({
    required this.fecha,
    required this.valorMercadoActual,
    required this.valorCompraPromedio,
  });


  factory ValorHistorico.fromMap(Map<String, dynamic> map) {
    double compra = map['valor_compra_promedio'] ?? 0;
    if (compra < 0) compra = 0;

    double mercado = map['valor_mercado_actual'] ?? 0;
    if (mercado < 0) mercado = 0;

    return ValorHistorico(
      fecha: DateTime.parse(map['fecha']),
      valorCompraPromedio: compra,
      valorMercadoActual: mercado,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fecha': fecha.toIso8601String(),
      'valor_compra_promedio': valorCompraPromedio,
      'valor_mercado_actual': valorMercadoActual,
    };
  }
}

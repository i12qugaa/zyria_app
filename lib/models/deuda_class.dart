import 'package:finanzas_app/models/pagosDeuda_class.dart';

enum TipoDeuda { hipoteca, prestamo }

class Deuda {
  final int id;
  final TipoDeuda tipo;
  String entidad;
  double valorTotal;
  double interesAnual;
  int plazoMeses;
  DateTime fechaInicio;
  int? idActivo;
  String? notas;
  double? saldo;
  double? cuotaMensual;
  DateTime? fechaFin;

  List<PagoDeuda> historialPagos;

  Deuda({
    required this.id,
    required this.tipo,
    required this.entidad,
    required this.valorTotal,
    required this.interesAnual,
    required this.plazoMeses,
    required this.fechaInicio,
    this.idActivo,
    this.notas,
    this.saldo,
    this.cuotaMensual,
    this.fechaFin,
    List<PagoDeuda>? historialPagos,
  })
      : historialPagos = historialPagos ?? [];



  Map<String, dynamic> toMap() {
    final map = {
      'tipo': tipo.name,
      'entidad': entidad,
      'valorTotal': valorTotal,
      'interesAnual': interesAnual,
      'plazoMeses': plazoMeses,
      'fechaInicio': fechaInicio.toIso8601String(),
      'notas': notas,
      'cuotaMensual': cuotaMensual,
      'fechaFin': fechaFin?.toIso8601String(),
    };

    if (id != 0) {
      map['id'] = id;
    }

    return map;
  }


  factory Deuda.fromMap(Map<String, dynamic> map) {
    return Deuda(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
      tipo: TipoDeuda.values.firstWhere(
            (e) => e.name.toLowerCase() == map['tipo'].toString().toLowerCase(),
        orElse: () => TipoDeuda.prestamo,
      ),
      entidad: map['entidad'] ?? '',
      valorTotal: (map['valorTotal'] as num?)?.toDouble() ?? 0.0,
      interesAnual: (map['interesAnual'] as num?)?.toDouble() ?? 0.0,
      plazoMeses: map['plazoMeses'] ?? 0,
      fechaInicio: DateTime.tryParse(map['fechaInicio'] ?? '') ?? DateTime.now(),
      notas: map['notas'],
      cuotaMensual: (map['cuotaMensual'] as num?)?.toDouble(),
      fechaFin: map['fechaFin'] != null
          ? DateTime.tryParse(map['fechaFin'])
          : null,
    );
  }

  double get saldoTotal {
    double interesTotal = valorTotal * (interesAnual / 100) * (plazoMeses / 12);
    return valorTotal + interesTotal;
  }

  double get saldoPendiente {
    double totalPagado = 0.0;
    for (var pago in historialPagos) {
      totalPagado += pago.cantidad;
    }

    return saldoTotal - totalPagado;
  }
}

import 'package:finanzas_app/models/valorHistorico_class.dart';
import 'operacion_class.dart';

class Activo {
  int id;
  String nombre;
  String? simbolo;
  TipoActivo tipo;
  bool autoActualizar;
  double valorActual;
  String? notas;
  List<Operacion> historialOperaciones;
  List<ValorHistorico> historialValores;

  // Campos inmobiliarios opcionales
  String? ubicacion;
  EstadoPropiedad? estadoPropiedad;
  double? ingresoMensual;
  double? gastoMensual;
  double? gastosMantenimientoAnual;
  double? valorCatastral;
  double? hipotecaPendiente;
  double? impuestoAnual;

  Activo({
    required this.id,
    required this.nombre,
    this.simbolo,
    required this.tipo,
    this.autoActualizar = true,
    required this.valorActual,
    this.notas,
    this.ubicacion,
    this.estadoPropiedad,
    this.ingresoMensual,
    this.gastoMensual,
    this.gastosMantenimientoAnual,
    this.valorCatastral,
    this.hipotecaPendiente,
    this.impuestoAnual,
    List<Operacion>? historialOperaciones,
    List<ValorHistorico>? historialValores,

  })
      : historialOperaciones = historialOperaciones ?? [],
        historialValores = historialValores ?? [];

  factory Activo.fromMap(Map<String, dynamic> map) {
    return Activo(
      id: map['id'],
      nombre: map['nombre'],
      simbolo: map['simbolo'],
      tipo: TipoActivo.values.firstWhere(
            (e) => e.name.toLowerCase() == map['tipo'].toString().toLowerCase(),
        orElse: () => TipoActivo.accionesEtfs,
      ),
      autoActualizar: map['autoActualizar'] == 1,
      valorActual: (map['valorActual'] as num).toDouble(),
      notas: map['notas'],
      ubicacion: map['ubicacion'],
      estadoPropiedad: map['estadoPropiedad'] != null
          ? EstadoPropiedad.values.firstWhere(
            (e) => e.name.toLowerCase() == map['estadoPropiedad'].toString().toLowerCase(),
        orElse: () => EstadoPropiedad.enPropiedad,
      )
          : null,
      ingresoMensual: map['ingresoMensual'] != null ? (map['ingresoMensual'] as num).toDouble() : null,
      gastoMensual: map['gastoMensual'] != null ? (map['gastoMensual'] as num).toDouble() : null,
      gastosMantenimientoAnual: map['gastosMantenimientoAnual'] != null ? (map['gastosMantenimientoAnual'] as num).toDouble() : null,
      valorCatastral: map['valorCatastral'] != null ? (map['valorCatastral'] as num).toDouble() : null,
      hipotecaPendiente: map['hipotecaPendiente'] != null ? (map['hipotecaPendiente'] as num).toDouble() : null,
      impuestoAnual: map['impuestoAnual'] != null ? (map['impuestoAnual'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'simbolo': simbolo,
      'tipo': tipo.name,
      'autoActualizar': autoActualizar ? 1 : 0,
      'valorActual': valorActual,
      'notas': notas,
      'ubicacion': ubicacion,
      'estadoPropiedad': estadoPropiedad?.name,
      'ingresoMensual': ingresoMensual,
      'gastoMensual': gastoMensual,
      'gastosMantenimientoAnual': gastosMantenimientoAnual,
      'valorCatastral': valorCatastral,
      'hipotecaPendiente': hipotecaPendiente,
      'impuestoAnual': impuestoAnual,
    };
  }


  double get cantidad {
    double total = 0;
    for (var op in historialOperaciones) {
      if (op.tipo == TipoOperacion.compra) {
        total += op.cantidad;
      } else {
        total -= op.cantidad;
      }
    }
    return total;
  }


  double get valorCompraPromedio {
    if (cantidad == 0) return 0;

    double unidadesRestantes = cantidad;
    double costoTotal = 0.0;

    // Crear una cola de compras (FIFO)
    final compras = historialOperaciones
        .where((op) => op.tipo == TipoOperacion.compra)
        .toList();

    final ventas = historialOperaciones
        .where((op) => op.tipo == TipoOperacion.venta)
        .toList();

    double unidadesVendidas = ventas.fold(0.0, (sum, op) => sum + op.cantidad);

    for (var compra in compras) {
      if (unidadesVendidas >= compra.cantidad) {
        unidadesVendidas -= compra.cantidad;
      } else {
        double unidadesUtiles = compra.cantidad - unidadesVendidas;
        unidadesVendidas = 0;

        final costoCompra = (compra.precioUnitario * unidadesUtiles) +
            ((compra.comision ?? 0) * (unidadesUtiles / compra.cantidad));

        costoTotal += costoCompra;

        unidadesRestantes -= unidadesUtiles;
        if (unidadesRestantes <= 0) break;
      }
    }

    return cantidad == 0 ? 0 : costoTotal / cantidad;
  }

  double get valorTotalActual => cantidad * valorActual;

  double get rentabilidadAbsoluta =>
      valorTotalActual - (valorCompraPromedio * cantidad);

  double get rentabilidadPorcentual {
    final totalInvertido = valorCompraPromedio * cantidad;

    if (totalInvertido == 0 || totalInvertido.isNaN ||
        totalInvertido.isInfinite) {
      return 0;
    }

    return (rentabilidadAbsoluta / totalInvertido) * 100;
  }

  double get rentabilidadInmobiliaria {
    if (ingresoMensual == null || valorActual == 0) return 0;

    final ingresosAnuales = ingresoMensual! * 12;
    final gastosAnuales = (gastoMensual ?? 0) * 12 +
        (gastosMantenimientoAnual ?? 0) +
        (impuestoAnual ?? 0);

    final ingresoNetoAnual = ingresosAnuales - gastosAnuales;

    final hipoteca = hipotecaPendiente ?? 0;
    final capitalInvertido = valorActual - hipoteca;

    if (capitalInvertido <= 0) return 0;

    return (ingresoNetoAnual / capitalInvertido) * 100;
  }

}
enum TipoActivo {
  accionesEtfs,
  inmobiliario,
  criptomonedas,
  fondosInversion,
}

enum EstadoPropiedad {
  enPropiedad,
  alquilado,
  enVenta,
  usoPropio,
}

extension EstadoPropiedadExtension on EstadoPropiedad {
  String get descripcion {
    switch (this) {
      case EstadoPropiedad.enPropiedad:
        return "En propiedad";
      case EstadoPropiedad.alquilado:
        return "Alquilado";
      case EstadoPropiedad.enVenta:
        return "En venta";
      case EstadoPropiedad.usoPropio:
        return "De uso propio";
    }
  }
}


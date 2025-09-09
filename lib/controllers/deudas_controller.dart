import 'package:finanzas_app/models/pagosDeuda_class.dart';
import 'package:flutter/material.dart';
import '../db/deudas_dao.dart';
import '../models/deuda_class.dart';
import '../views/deudas/deudas_view.dart';
import 'dart:math';
import '../views/deudas/prestamos_view.dart';


class DeudasController extends ChangeNotifier {
  static final DeudasController _instance = DeudasController._internal();

  factory DeudasController() => _instance;

  DeudasController._internal();

  final DeudasDao _dao = DeudasDao.instance;


  //Validaciones

  String? validarEntidad(String entidad) {
    if (entidad.trim().isEmpty) return 'Por favor, ingresa una entidad.';
    return null;
  }

  String? validarValor(String valor) {
    final val = valor.trim().replaceAll(',', '.');
    if (val.isEmpty) return 'Por favor, ingresa un valor.';
    final numero = double.tryParse(val);
    if (numero == null) return 'Por favor, ingresa un valor válido.';
    return null;
  }

  String? validarInteres(String interes) {
    final val = interes.trim().replaceAll(',', '.');
    if (val.isEmpty) return 'Por favor, ingresa un interés.';
    final numero = double.tryParse(val);
    if (numero == null || numero < 0) return 'Interés inválido.';
    return null;
  }

  String? validarPlazo(String plazo) {
    if (plazo.trim().isEmpty) return 'Por favor, ingresa el plazo.';
    final numero = int.tryParse(plazo);
    if (numero == null || numero <= 0) return 'Plazo inválido.';
    return null;
  }

  String? validarFecha(DateTime? fecha) {
    if (fecha == null) return 'Selecciona una fecha de inicio.';
    return null;
  }

  String? validarCantidad(String cantidad) {
    if (cantidad.trim().isEmpty) return 'Por favor, ingresa un valor.';
    final valor = double.tryParse(cantidad.trim().replaceAll(',', '.'));
    if (valor == null || valor <= 0) return "Cantidad inválida (debe ser > 0)";
    return null;
  }

  // Obtener todas las deudas
  Future<List<Deuda>> obtenerTodasLasDeudas() async {
    return await _dao.obtenerTodasLasDeudas();
  }

  // Obtener deudas por tipo
  Future<List<Deuda>> obtenerDeudasPorTipo(TipoDeuda tipo) async {
    return await _dao.obtenerDeudasPorTipo(tipo);
  }

  // Insertar deuda
  Future<int> insertarDeuda(Deuda deuda) async {
    return await _dao.insertardeuda(deuda);
  }

  // Actualizar deuda
  Future<void> actualizarDeuda(Deuda deuda) async {
    await _dao.actualizardeuda(deuda);
    notifyListeners();
  }

  // Eliminar deuda
  Future<void> eliminarDeuda(int id) async {
    await _dao.eliminardeuda(id);
    notifyListeners();
  }

  // Obtener deuda por ID
  Future<Deuda?> obtenerDeudaPorId(int id) async {
    return await _dao.obtenerDeudaPorId(id);
  }

  Future<int> crearYGuardarPrestamo({
    required String entidad,
    required double valorTotal,
    required double interesAnual,
    required int plazoMeses,
    String? notas,
  }) async {
    final double tasaMensual = interesAnual / 12 / 100;
    final double cuotaMensual = tasaMensual == 0
        ? valorTotal / plazoMeses
        : (valorTotal * tasaMensual) /
        (1 - 1 / pow(1 + tasaMensual, plazoMeses));

    final DateTime fechaInicio = DateTime.now();

    final deuda = Deuda(
      id: 0,
      tipo: TipoDeuda.prestamo,
      entidad: entidad.trim(),
      valorTotal: valorTotal,
      interesAnual: interesAnual,
      plazoMeses: plazoMeses,
      fechaInicio: fechaInicio,
      cuotaMensual: cuotaMensual,
      notas: notas?.trim().isEmpty == true ? null : notas?.trim(),
      fechaFin: fechaInicio.add(Duration(days: plazoMeses * 30)),
      idActivo: null,
    );

    final int deudaId = await insertarDeuda(deuda);
    return deudaId;
  }


  Future<void> navigateToDeudas(BuildContext context) async {
    try {
      print("⏳ Iniciando navegación a DeudasView...");

      print("🔍 Obteniendo todas las deudas...");
      final deudas = await obtenerTodasLasDeudas();

      final totalPrestamos = await obtenerTotalPrestamos();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeudasView(
            deudas: deudas,
            totalPrestamos: totalPrestamos,
          ),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar las deudas: $error')),
      );
    }
  }


  Future<double> getTotalDeudas() async {
    final List<Deuda> deudas = await obtenerTodasLasDeudas();
    double total = 0.0;

    for (var deuda in deudas) {
      total += deuda.valorTotal;
    }

    return total;
  }

  Future<void> agregarPago(int idDeuda, PagoDeuda pago) async {
    if (pago.cantidad <= 0) {
      throw ArgumentError("La cantidad debe ser mayor que cero.");
    }

    // Insertar pago en la base de datos
    await _dao.insertarPago(idDeuda, pago);

    final deuda = await _dao.obtenerDeudaPorId(idDeuda);
    if (deuda == null) {
      throw Exception("No se encontró la deuda con ID $idDeuda.");
    }

    final nuevoHistorial = await _dao.obtenerPagosPorDeuda(idDeuda);
    deuda.historialPagos = nuevoHistorial;

    notifyListeners();
  }


  Future<bool> eliminarPago(PagoDeuda pago, int idDeuda) async {
    try {
      final bool success = await _dao.eliminarPago(pago.id, idDeuda);
      return success;
    } catch (e) {
      print("Error al eliminar operación: $e");
      return false;
    }
  }


  Future<double> obtenerTotalPrestamos() async {
    final prestamos = await obtenerDeudasPorTipo(TipoDeuda.prestamo);

    double total = 0.0;

    for (var deuda in prestamos) {
      total += deuda.saldoPendiente;
    }

    return total;
  }


  // Navegar a la vista de préstamos
  Future<void> navigateToPrestamos(BuildContext context) async {
    try {
      final prestamos = await obtenerDeudasPorTipo(TipoDeuda.prestamo);

      // Calculamos el total de préstamos sumando el valorTotal de cada uno
      final totalPrestamos = await obtenerTotalPrestamos();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PrestamosView(
            prestamos: prestamos,
            totalPrestamos: totalPrestamos,
          ),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los préstamos: $error')),
      );
    }
  }


  Future<void> actualizarPago(PagoDeuda pago) async {
    if (pago.cantidad <= 0) {
      throw ArgumentError("La cantidad debe ser mayor que cero.");
    }
    await _dao.actualizarPago(pago);
    notifyListeners();
  }
}

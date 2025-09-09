import 'dart:async';
import 'package:finanzas_app/views/activos/criptomonedas_view.dart';
import 'package:finanzas_app/views/activos/fondosInversion_view.dart';
import 'package:finanzas_app/views/activos/inmobiliario_view.dart';
import 'package:flutter/material.dart';
import '../models/activo_class.dart';
import '../models/operacion_class.dart';
import '../db/activos_dao.dart';
import '../models/valorHistorico_class.dart';
import '../views/activos/accionesetfs_view.dart';
import '../views/activos/activos_view.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import './../config.dart';


class ActivosController extends ChangeNotifier {
  static final ActivosController _instance = ActivosController._internal();
  factory ActivosController() => _instance;
  ActivosController._internal();

  final ActivosDao _dao = ActivosDao.instance;

  DateTime _lastUpdateTime = DateTime(1970);

  // Tiempo mínimo entre actualizaciones
  final Duration _minUpdateInterval = Duration(seconds: 10);

  // Validaciones

  String? validarNombre(String nombre) {
    if (nombre.trim().isEmpty) return 'Por favor, ingresa un nombre.';
    return null;
  }

  String? validarSimbolo(String simbolo) {
    if (simbolo.trim().isEmpty) return 'Por favor, ingresa un símbolo.';
    return null;
  }

  String? validarValor(String valor) {
    final val = valor.trim().replaceAll(',', '.');
    if (val.isEmpty) return 'Por favor, ingresa un valor.';
    final double? numero = double.tryParse(val);
    if (numero == null) return 'Por favor, ingresa un valor válido.';
    return null;
  }

  String? validarIngresoMensual(String ingresoMensual) {
    final i = ingresoMensual.trim().replaceAll(',', '.');
    if (i.isEmpty) return 'Por favor, introduzca el ingreso mensual.';
    final double? numero = double.tryParse(i);
    if (numero == null) return 'Por favor, ingresa un ingreso válido.';
    return null;
  }

  String? validarGastoMensual(String gastoMensual) {
    final g = gastoMensual.trim().replaceAll(',', '.');
    if (g.isEmpty) return 'Por favor, introduzca el gasto mensual.';
    final double? numero = double.tryParse(g);
    if (numero == null) return 'Por favor, ingresa un gasto válido.';
    return null;
  }

  String? validarGastoMantenimientoAnual(String gasto) {
    final g = gasto.trim().replaceAll(',', '.');
    if (g.isEmpty) return 'Por favor, introduzca el gasto de mantenimiento anual.';
    final double? numero = double.tryParse(g);
    if (numero == null) return 'Por favor, ingresa un valor válido.';
    return null;
  }

  String? validarValorCatastral(String valor) {
    final v = valor.trim().replaceAll(',', '.');
    if (v.isEmpty) return 'Por favor, introduzca el valor catastral.';
    final double? numero = double.tryParse(v);
    if (numero == null) return 'Por favor, ingresa un valor válido.';
    return null;
  }

  String? validarHipotecaPendiente(String hipoteca) {
    final h = hipoteca.trim().replaceAll(',', '.');

    if (h.isEmpty) return null;

    final double? numero = double.tryParse(h);
    if (numero == null) return 'Por favor, ingresa un valor válido.';

    return null;
  }


  String? validarImpuestoAnual(String impuesto) {
    final i = impuesto.trim().replaceAll(',', '.');
    if (i.isEmpty) return 'Por favor, introduzca el impuesto anual.';
    final double? numero = double.tryParse(i);
    if (numero == null) return 'Por favor, ingresa un valor válido.';
    return null;
  }

  String? validarEstadoPropiedad(EstadoPropiedad? estado) {
    if (estado == null) {
      return 'Por favor, seleccione el estado de la propiedad.';
    }
    return null;
  }


  String? validarCantidad(String cantidad) {
    if (cantidad.trim().isEmpty) return 'Por favor, ingresa un valor.';
    final valor = double.tryParse(cantidad.trim().replaceAll(',', '.'));
    if (valor == null || valor <= 0) return "Cantidad inválida (debe ser > 0)";
    return null;
  }

  String? validarPrecio(String precio) {
    if (precio.trim().isEmpty) return 'Por favor, ingresa un valor.';
    final valor = double.tryParse(precio.trim().replaceAll(',', '.'));
    if (valor == null || valor <= 0) return "Precio inválido (debe ser > 0)";
    return null;
  }

  String? validarComision(String comision) {
    if (comision.trim().isEmpty) return null;
    final valor = double.tryParse(comision.trim().replaceAll(',', '.'));
    if (valor == null || valor < 0) return "Comisión inválida";
    return null;
  }

  bool validarActivo({
    required String nombre,
    required String simbolo,
    required String valor,
  }) {
    return validarNombre(nombre) == null &&
        validarSimbolo(simbolo) == null &&
        validarValor(valor) == null;
  }

  // Funciones

  Future<int> insertarActivo(Activo activo) async {
    final id = await _dao.insertarActivo(activo);
    notifyListeners();
    return id;
  }


  Future<List<Activo>> obtenerTodosLosActivos() async {
    return await _dao.obtenerTodosLosActivos();
  }


  Future<List<Activo>> obtenerActivosPorTipo(TipoActivo tipo) async {
    final todos = await obtenerTodosLosActivos();
    final resultado = <Activo>[];

    for (var activo in todos) {
      if (activo.tipo == tipo) {
        resultado.add(activo);
      }
    }

    return resultado;
  }


  Future<void> actualizarActivo(Activo activo) async {
    await _dao.actualizarActivo(activo);
    notifyListeners();
  }

  Future<void> eliminarActivo(int id) async {
    await _dao.eliminarActivo(id);
    notifyListeners();
  }


 /* Future<void> agregarOperacion(int idActivo, Operacion operacion) async {
    if (operacion.cantidad <= 0) {
      throw ArgumentError("La cantidad debe ser mayor que cero.");
    }
    if (operacion.precioUnitario <= 0) {
      throw ArgumentError("El precio unitario debe ser mayor que cero.");
    }
    if (operacion.comision != null && operacion.comision! < 0) {
      throw ArgumentError("La comisión no puede ser negativa.");
    }

    // Insertar operación en la base de datos
    await _dao.insertarOperacion(idActivo, operacion);

    // Cargar todas las operaciones actualizadas del activo
    final operacionesActualizadas = await _dao.obtenerOperacionesPorActivo(idActivo);

    // Calcular la cantidad disponible
    double cantidadActual = 0.0;

    for (var op in operacionesActualizadas) {
      if (op.tipo == TipoOperacion.compra) {
        cantidadActual += op.cantidad;
      } else {
        cantidadActual -= op.cantidad;
      }
    }

    // Validar que si es venta, haya suficiente cantidad
    if (operacion.tipo == TipoOperacion.venta && operacion.cantidad > cantidadActual) {
      throw ArgumentError("No tienes suficientes unidades para vender.");
    }

    // Recargar el activo y asignar las operaciones actualizadas
    final activo = await _dao.obtenerActivoPorId(idActivo);
    if (activo != null) {
      // Asignar historial actualizado antes de actualizar el activo
      activo.historialOperaciones = operacionesActualizadas;

      // Actualizar precio si aplica
      if (activo.autoActualizar && activo.simbolo != null && activo.simbolo!.isNotEmpty) {
        final nuevoValor = await obtenerPrecioActual(activo.simbolo!);

        if (nuevoValor != null && nuevoValor > 0) {
          // Actualiza solo si es un valor válido
          await actualizarValorDeActivo(activo, nuevoValor);
        } else {
          // Si la API de FinnHub devuelve 0 o null no se modifica el valor actual del activo
          debugPrint(
            "No se actualizó el precio de ${activo.simbolo}, se mantuvo ${activo.valorActual}",
          );
        }
      }

      // Actualizar histórico de valores
      final nuevoValorCompra = activo.valorCompraPromedio;
      final valorMercado = activo.valorActual;

      await _dao.insertarHistorialValorPromedio(
        activoId: idActivo,
        fecha: DateTime.now(),
        valorCompra: nuevoValorCompra,
        valorMercado: valorMercado,
      );

      await _dao.actualizarActivo(activo);
    }

    notifyListeners();
  }*/


  Future<void> agregarOperacion(int idActivo, Operacion operacion) async {
    if (operacion.cantidad <= 0) {
      throw ArgumentError("La cantidad debe ser mayor que cero.");
    }
    if (operacion.precioUnitario <= 0) {
      throw ArgumentError("El precio unitario debe ser mayor que cero.");
    }
    if (operacion.comision != null && operacion.comision! < 0) {
      throw ArgumentError("La comisión no puede ser negativa.");
    }

    // Cargar todas las operaciones existentes
    final operacionesActualizadas = await _dao.obtenerOperacionesPorActivo(idActivo);

    // Calcular cantidad disponible **sin incluir la operación actual todavía**
    double cantidadActual = 0.0;
    for (var op in operacionesActualizadas) {
      if (op.tipo == TipoOperacion.compra) {
        cantidadActual += op.cantidad;
      } else {
        cantidadActual -= op.cantidad;
      }
    }

    // Validar solo si es una venta
    if (operacion.tipo == TipoOperacion.venta && operacion.cantidad > cantidadActual) {
      throw ArgumentError("No tienes suficientes unidades para vender.");
    }

    // ✅ Insertar la operación después de la validación
    await _dao.insertarOperacion(idActivo, operacion);

    // Recargar todas las operaciones actualizadas **ya incluyendo la nueva**
    final operacionesActualizadasPost = await _dao.obtenerOperacionesPorActivo(idActivo);

    // Recargar el activo y asignar las operaciones actualizadas
    final activo = await _dao.obtenerActivoPorId(idActivo);
    if (activo != null) {
      activo.historialOperaciones = operacionesActualizadasPost;

      // Actualizar precio si aplica
      if (activo.autoActualizar && activo.simbolo != null && activo.simbolo!.isNotEmpty) {
        final nuevoValor = await obtenerPrecioActual(activo.simbolo!);
        if (nuevoValor != null && nuevoValor > 0) {
          await actualizarValorDeActivo(activo, nuevoValor);
        } else {
          debugPrint(
            "No se actualizó el precio de ${activo.simbolo}, se mantuvo ${activo.valorActual}",
          );
        }
      }

      // Actualizar histórico de valores
      final nuevoValorCompra = activo.valorCompraPromedio;
      final valorMercado = activo.valorActual;

      await _dao.insertarHistorialValorPromedio(
        activoId: idActivo,
        fecha: DateTime.now(),
        valorCompra: nuevoValorCompra,
        valorMercado: valorMercado,
      );

      await _dao.actualizarActivo(activo);
    }

    notifyListeners();
  }


  Future<int?> obtenerIdActivoPorNombre(String nombreActivo) async {
    return await _dao.getIdByNombre(nombreActivo);
  }



  Future<Activo> obtenerActivoPorId(int id) async {
    final activo = await _dao.obtenerActivoPorId(id);
    if (activo == null) {
      throw Exception("Activo con ID $id no encontrado.");
    }

    activo.historialOperaciones = await _dao.obtenerOperacionesPorActivo(id);

    return activo;
  }


  Future<void> actualizarOperacion(int idActivo, Operacion operacion) async {
    if (operacion.cantidad <= 0) {
      throw ArgumentError("La cantidad debe ser mayor que cero.");
    }
    if (operacion.precioUnitario <= 0) {
      throw ArgumentError("El precio unitario debe ser mayor que cero.");
    }
    if (operacion.comision != null && operacion.comision! < 0) {
      throw ArgumentError("La comisión no puede ser negativa.");
    }

    // Cargar historial actual
    final operaciones = await _dao.obtenerOperacionesPorActivo(idActivo);

    // Calcular cantidad disponible sin contar esta operación
    double cantidadActual = 0.0;

    for (var op in operaciones) {
      if (op.id == operacion.id) {
        continue;
      }

      if (op.tipo == TipoOperacion.compra) {
        cantidadActual += op.cantidad;
      } else {
        cantidadActual -= op.cantidad;
      }
    }

    // Validar si es venta y hay suficientes unidades
    if (operacion.tipo == TipoOperacion.venta && operacion.cantidad > cantidadActual) {
      throw ArgumentError("Sin suficientes unidades para vender.");
    }

    // Actualizar operación en base de datos
    await _dao.actualizarOperacion(operacion);

    // Recargar el activo y su historial actualizado
    final activo = await _dao.obtenerActivoPorId(idActivo);
    final nuevasOperaciones = await _dao.obtenerOperacionesPorActivo(idActivo);
    activo?.historialOperaciones = nuevasOperaciones;

    // Calcular valores actualizados
    final nuevoValorCompra = activo?.valorCompraPromedio;
    final valorMercado = activo?.valorActual;

    // Guardar solo si el valor de compra es mayor que cero

      await _dao.insertarHistorialValorPromedio(
        activoId: idActivo,
        fecha: DateTime.now(),
        valorCompra: nuevoValorCompra,
        valorMercado: valorMercado,
      );

    notifyListeners();
  }


  Future<double> getTotalActivos() async {
    final List<Activo> activos = await obtenerTodosLosActivos();
    double total = 0.0;

    for (var activo in activos) {
      final cantidad = activo.cantidad;
      total += activo.valorActual * cantidad;
    }

    return total;
  }

  Future<List<ValorHistorico>> obtenerHistorialDeActivo(int activoId) async {
    try {
      return await _dao.obtenerHistorialDeActivo(activoId);
    } catch (e) {
      print("Error obteniendo historial del activo $activoId: $e");
      return [];
    }
  }

  String traducirASimboloFinnhub(String entradaUsuario) {
    final simbolos = {
      'btc': 'BINANCE:BTCUSDT',
      'bitcoin': 'BINANCE:BTCUSDT',
      'eth': 'BINANCE:ETHUSDT',
      'ethereum': 'BINANCE:ETHUSDT',
      'sol': 'BINANCE:SOLUSDT',
      'solana': 'BINANCE:SOLUSDT',
      'xrp': 'BINANCE:XRPUSDT',
      'cardano': 'BINANCE:ADAUSDT',
      'ada': 'BINANCE:ADAUSDT',
      'doge': 'BINANCE:DOGEUSDT',
      'dogecoin': 'BINANCE:DOGEUSDT',
    };

    final entrada = entradaUsuario.toLowerCase().trim();
    return simbolos[entrada] ?? '';
  }

  Future<Map<TipoActivo, double>> obtenerTotalesPorCategoria() async {
    final activos = await obtenerTodosLosActivos();
    final Map<TipoActivo, double> totales = {
      for (var tipo in TipoActivo.values) tipo: 0.0,
    };

    for (var activo in activos) {
      final cantidad = activo.cantidad;
      totales[activo.tipo] = (totales[activo.tipo] ?? 0) + (activo.valorActual * cantidad);
    }

    return totales;
  }


  Future<void> navigateToActivos(BuildContext context) async {
    try {
      final totalActivoss = await getTotalActivos();
      final activoss = await obtenerTodosLosActivos();
      final totalesPorCategoria = await obtenerTotalesPorCategoria();
      final totalCatastral = await calcularTotalCatastralPorTipo(TipoActivo.inmobiliario);

      final totalActivos = totalActivoss + totalCatastral;


      final rentabilidadTotall = await ActivosController().calcularRentabilidadTotal();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActivosView(
            totalActivos: totalActivos,
            activos: activoss,
            totalesPorCategoria: totalesPorCategoria,
            rentabilidadTotal: rentabilidadTotall,
              totalCatastral: totalCatastral,
          ),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los activos: $error')),
      );
    }
  }



  Future<double?> obtenerPrecioActual(String simbolo) async {
    final url = Uri.parse('https://finnhub.io/api/v1/quote?symbol=$simbolo&token=$FINNHUB_API_KEY');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final precio = data['c']; // 'c' es el precio actual
        if (precio is num) return precio.toDouble();
      }
    } catch (e) {
      print("Error al obtener el precio de $simbolo: $e");
    }
    return null;
  }

  Future<void> actualizarValoresActuales(BuildContext context, {int delayMs = 2000}) async {
    final now = DateTime.now();
    final timeDifference = now.difference(_lastUpdateTime);

    // Verificar si ha pasado el tiempo mínimo desde la última actualización
    if (timeDifference < _minUpdateInterval) {
      final remainingTime = _minUpdateInterval - timeDifference;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Espere ${remainingTime.inSeconds} segundos para actualizar nuevamente.')),
      );
      return;
    }

    // Actualizar el tiempo de la última actualización
    _lastUpdateTime = now;

    final activos = await obtenerTodosLosActivos();

    for (var activo in activos) {
      if (!activo.autoActualizar) continue;
      if (activo.simbolo != null && activo.simbolo!.isNotEmpty) {
        final nuevoValor = await obtenerPrecioActual(activo.simbolo!);

        if (nuevoValor != null) {

          await actualizarValorDeActivo(activo, nuevoValor);

          print('Actualizado ${activo.simbolo} a ${activo.valorActual}');
          notifyListeners();
        }

        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  int _indiceActual = 0;
  Timer? _timerActualizacion;
  bool _actualizando = false;
  static const String _claveIndice = 'indice_actual_activos';

  Future<void> _cargarIndiceGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    _indiceActual = prefs.getInt(_claveIndice) ?? 0;
  }

  Future<void> _guardarIndiceActual() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_claveIndice, _indiceActual);
  }



  Future<void> iniciarActualizacionProgresiva() async {
    if (_actualizando) return;
    _actualizando = true;

    await _cargarIndiceGuardado();

    _timerActualizacion = Timer.periodic(const Duration(seconds: 60), (_) async {
      final activos = await obtenerTodosLosActivos();
      if (_indiceActual >= activos.length) _indiceActual = 0;

      final int fin = (_indiceActual + 10).clamp(0, activos.length);
      final bloque = activos.sublist(_indiceActual, fin);

      for (final activo in bloque) {
        if (!activo.autoActualizar) continue;

        if (activo.simbolo != null && activo.simbolo!.isNotEmpty) {
          final nuevoValor = await obtenerPrecioActual(activo.simbolo!);
          if (nuevoValor != null) {
            activo.valorActual = nuevoValor;
            await actualizarActivo(activo);
            notifyListeners();
          }
          await Future.delayed(const Duration(milliseconds: 2000)); // espera entre llamadas
        }
      }

      _indiceActual = fin;
      await _guardarIndiceActual();
    });
  }



  void detenerActualizacion() {
    _timerActualizacion?.cancel();
    _actualizando = false;
  }

  Future<bool> eliminarOperacion(Operacion operacion, int idActivo) async {
    try {
      final bool success = await _dao.eliminarOperacion(operacion.id, idActivo);

      if (success) {
        // 1. Obtener el activo
        final activo = await _dao.obtenerActivoPorId(idActivo);

        // 2. Obtener todas las operaciones actualizadas
        final nuevasOperaciones = await _dao.obtenerOperacionesPorActivo(idActivo);

        // 3. Asignar el historial actualizado al activo (necesario para calcular bien)
        activo?.historialOperaciones = nuevasOperaciones;

        // 4. Calcular los valores una vez se han actualizado las operaciones
        final nuevoValorCompra = activo?.valorCompraPromedio;
        final valorMercado = activo?.valorActual;

          await _dao.insertarHistorialValorPromedio(
            activoId: idActivo,
            fecha: DateTime.now(),
            valorCompra: nuevoValorCompra,
            valorMercado: valorMercado,
          );

        notifyListeners();
      }

      return success;
    } catch (e) {
      print("Error al eliminar operación: $e");
      return false;
    }
  }


  Future<void> actualizarValorDeActivo(Activo activo, double nuevoValor) async {
    final valorAnterior = activo.valorActual;
    if (valorAnterior != nuevoValor) {
      activo.valorActual = nuevoValor;
      await _dao.actualizarActivo(activo);

      final fechaHoy = DateTime.now();
      final valorCompraPromedio = activo.valorCompraPromedio;

      await _dao.insertarHistorialValorPromedio(
        activoId: activo.id,
        fecha: fechaHoy,
        valorCompra: valorCompraPromedio,
        valorMercado: nuevoValor,
      );

      notifyListeners();
    }
  }


  double calcularRentabilidadHistorica(Activo activo) {
    double totalCompras = 0.0;
    double totalVentas = 0.0;
    double comisiones = 0.0;

    for (var op in activo.historialOperaciones) {
      if (op.tipo == TipoOperacion.compra) {
        totalCompras += op.precioUnitario * op.cantidad;
        comisiones += op.comision ?? 0;
      } else if (op.tipo == TipoOperacion.venta) {
        totalVentas += op.precioUnitario * op.cantidad;
        comisiones += op.comision ?? 0;
      }
    }

    double valorActualActivo = activo.cantidad * activo.valorActual;
    double beneficio = totalVentas + valorActualActivo - totalCompras - comisiones;

    if (totalCompras + comisiones == 0) return 0;

    return (beneficio / (totalCompras + comisiones)) * 100;
  }

  Future<double> calcularRentabilidadGlobal() async {
    final activos = await _dao.obtenerTodosLosActivos();

    double valorActualTotal = 0;
    double totalInvertido = 0;

    for (var activo in activos) {
      valorActualTotal += activo.valorTotalActual;

      for (var op in activo.historialOperaciones) {
        if (op.tipo == TipoOperacion.compra) {
          totalInvertido += (op.precioUnitario * op.cantidad) + (op.comision ?? 0);
        }
      }
    }

    if (totalInvertido == 0) return 0;

    return ((valorActualTotal - totalInvertido) / totalInvertido) * 100;
  }


  double calcularRentabilidadActualTotal(List<Activo> activos) {
    double valorActualTotal = 0;
    double totalInvertido = 0;

    for (var activo in activos) {
      // Valor actual total
      valorActualTotal += activo.valorTotalActual;

      // Inversión total (solo compras)
      for (var op in activo.historialOperaciones) {
        if (op.tipo == TipoOperacion.compra) {
          totalInvertido += (op.precioUnitario * op.cantidad) + (op.comision ?? 0);
        }
      }
    }

    if (totalInvertido == 0) return 0;

    return ((valorActualTotal - totalInvertido) / totalInvertido) * 100;
  }

  Future<void> cambiarActualizacionAutomatica({required int id, required bool nuevoEstado}) async {
    final activo = await obtenerActivoPorId(id);

    activo.autoActualizar = nuevoEstado;
    await actualizarActivo(activo);
    notifyListeners();
    }

  Future<double> calcularTotalActualPorTipo(TipoActivo tipo) async {
    final activos = await obtenerActivosPorTipo(tipo);
    double total = 0.0;

    for (var a in activos) {
      total += a.valorActual * a.cantidad;
    }

    return total;
  }


  Future<void> navigateToAccionesEtfs(BuildContext context) async {
    final rentabilidad = await calcularRentabilidadPorTipo(TipoActivo.accionesEtfs);
    final totalActual = await calcularTotalActualPorTipo(TipoActivo.accionesEtfs);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccionesEtfsView(
          rentabilidadTotal: rentabilidad,
          totalActual: totalActual,
        ),
      ),
    );
  }

  Future<void> navigateToFondosInversion(BuildContext context) async {
    final rentabilidad = await calcularRentabilidadPorTipo(TipoActivo.fondosInversion);
    final totalActual = await calcularTotalActualPorTipo(TipoActivo.fondosInversion);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FondosinversionView(
          rentabilidadTotal: rentabilidad,
          totalActual: totalActual,
        ),
      ),
    );
  }

  Future<void> navigateToCriptomonedas(BuildContext context) async {
    final rentabilidad = await calcularRentabilidadPorTipo(TipoActivo.criptomonedas);
    final totalActual = await calcularTotalActualPorTipo(TipoActivo.criptomonedas);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CriptomonedasView(
          rentabilidadTotal: rentabilidad,
          totalActual: totalActual,
        ),
      ),
    );
  }

  Future<void> navigateToInmobiliario(BuildContext context) async {
    final rentabilidad = await calcularRentabilidadInmobiliariaGlobal();
    final totalActual = await calcularTotalActualPorTipo(TipoActivo.inmobiliario);
    final totalCatastral = await calcularTotalCatastralPorTipo(TipoActivo.inmobiliario);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InmobiliarioView(
          rentabilidadTotal: rentabilidad,
          totalActual: totalActual,
          totalCatastral: totalCatastral,
        ),
      ),
    );
  }

  Future<double> calcularRentabilidadInmobiliariaGlobal() async {
    final activosInmobiliarios = await _dao.obtenerActivosPorTipo(TipoActivo.inmobiliario);

    double totalIngresosNetosAnuales = 0;
    double totalCapitalInvertido = 0;

    for (var activo in activosInmobiliarios) {
      double ingresosAnuales = (activo.ingresoMensual ?? 0) * 12;
      double gastosAnuales = (activo.gastoMensual ?? 0) * 12 +
          (activo.gastosMantenimientoAnual ?? 0) +
          (activo.impuestoAnual ?? 0);

      double ingresoNetoAnual = ingresosAnuales - gastosAnuales;

      double hipoteca = activo.hipotecaPendiente ?? 0;
      double capitalInvertido = activo.valorActual - hipoteca;

      if (capitalInvertido <= 0) continue;

      totalIngresosNetosAnuales += ingresoNetoAnual;
      totalCapitalInvertido += capitalInvertido;
    }

    if (totalCapitalInvertido == 0) {
      return 0;
    }

    return (totalIngresosNetosAnuales / totalCapitalInvertido) * 100;
  }



  Future<double> calcularTotalCatastralPorTipo(TipoActivo tipo) async {
    final activos = await obtenerTodosLosActivos();
    final inmobiliarios = activos.where((a) => a.tipo == tipo).toList();

    double totalCatastral = 0.0;
    for (var activo in inmobiliarios) {
      totalCatastral += activo.valorCatastral ?? 0.0;
    }

    return totalCatastral;
  }



  Future<double> calcularRentabilidadPorTipo(TipoActivo tipo) async {
    final activos = await _dao.obtenerActivosPorTipo(tipo);

    double totalInvertido = 0;
    double gananciaTotal = 0;

    for (var activo in activos) {
      final invertido = activo.valorCompraPromedio * activo.cantidad;
      final ganancia = activo.rentabilidadAbsoluta;

      if (invertido > 0) {
        totalInvertido += invertido;
        gananciaTotal += ganancia;
      }
    }

    if (totalInvertido == 0) return 0;
    return (gananciaTotal / totalInvertido) * 100;
  }


  Future<double> calcularRentabilidadTotal() async {
    final activos = await _dao.obtenerTodosLosActivos();

    double totalInvertido = 0;
    double gananciaTotal = 0;

    for (var activo in activos) {
      double invertido = 0;
      double ganancia = 0;

      if (activo.tipo == TipoActivo.inmobiliario) {
        final hipoteca = activo.hipotecaPendiente ?? 0;
        final capitalInvertido = activo.valorActual - hipoteca;

        if (capitalInvertido > 0) {
          invertido = capitalInvertido;
          final ingresosAnuales = (activo.ingresoMensual ?? 0) * 12;
          final gastosAnuales = (activo.gastoMensual ?? 0) * 12 +
              (activo.gastosMantenimientoAnual ?? 0) +
              (activo.impuestoAnual ?? 0);

          final ingresoNetoAnual = ingresosAnuales - gastosAnuales;
          ganancia = ingresoNetoAnual;
        }

      } else {
        invertido = activo.valorCompraPromedio * activo.cantidad;
        ganancia = activo.rentabilidadAbsoluta;
      }

      if (invertido > 0) {
        totalInvertido += invertido;
        gananciaTotal += ganancia;
      }
    }

    if (totalInvertido == 0) return 0;
    return (gananciaTotal / totalInvertido) * 100;
  }

}

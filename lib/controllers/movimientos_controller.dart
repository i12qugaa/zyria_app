import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../views/gastos/gastos_view.dart';
import '../views/home_view.dart';
import '../views/ingresos/ingresos_view.dart';
import '../models/movimiento_class.dart';
import '../db/movimientos_dao.dart';
import 'home_controller.dart';

class MovimientosController extends ChangeNotifier{
  final MovimientosDao _movimientosDao = MovimientosDao.instance;

  Future<void> confirmarEliminarMovimiento({
    required BuildContext context,
    required Movimiento movimiento,
    required VoidCallback onSuccess,
  }) async {
    String tipo = movimiento.tipo.toLowerCase();

    // Determinar el tipo de mensaje según el tipo de movimiento
    String titulo = "Eliminar "+ tipo;
    String contenido = "¿Estás seguro de que quieres eliminar este "+ tipo + "?";

    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(
          child: Text(titulo),
        ),
        content: Text(contenido),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      await deleteMovimiento(movimiento.id);
      onSuccess();
    }
  }

  double _totalIngresos = 0.0;

  // Getter para el total de ingresos
  double get totalIngresos => _totalIngresos;

  List<Movimiento> _ingresosList = [];

  // Getter para acceder a la lista de movimientos
  List<Movimiento> get ingresosList => _ingresosList;


  double _totalGastos = 0.0;

  // Getter para el total de ingresos
  double get totalGastos => _totalGastos;

  List<Movimiento> _gastosList = [];

  // Getter para acceder a la lista de movimientos
  List<Movimiento> get gastosList => _gastosList;

  //Ahorros
  double _totalAhorros = 0.0;

  // Getter para el total de ingresos
  double get totalAhorros => _totalAhorros;

  List<Movimiento> _ahorrosList = [];

  // Getter para acceder a la lista de movimientos
  List<Movimiento> get ahorrosList => _ahorrosList;

  // Función para cargar movimientos
  Future<void> cargarMovimientos({
    required int day,
    required int month,
    required int year,
    required String tipo, // 'ingreso', 'gasto', 'ahorro'
    required TimeRangeMode selectedMode,
  }) async {
    try {
      double total = 0.0;
      List<Movimiento> lista = [];

      // 1. Obtener datos según el rango de tiempo
      switch (selectedMode) {
        case TimeRangeMode.day:
          total = await getTotalMovimientosByDay(year: year, month: month, day: day, tipo: tipo);
          lista = await getMovimientosByDay(year: year, month: month, day: day, tipo: tipo);
          break;
        case TimeRangeMode.month:
          total = await getTotalMovimientosByMonth(year: year, month: month, tipo: tipo);
          lista = await getMovimientosByMonth(year: year, month: month, tipo: tipo);
          break;
        case TimeRangeMode.year:
          total = await getTotalMovimientosByYear(year: year, tipo: tipo);
          lista = await getMovimientosByYear(year: year, tipo: tipo);
          break;
        case TimeRangeMode.all:
          total = await getTotalAllMovimientos(tipo: tipo);
          lista = await getMovimientos(tipo: tipo);
          break;
      }

      // 2. Guardar en la lista y total correspondientes
      switch (tipo) {
        case 'ingreso':
          _totalIngresos = total;
          _ingresosList = lista;
          break;

        case 'gasto':
          _totalGastos = total;
          _gastosList = lista;
          break;

        case 'ahorro':
          _totalAhorros = total;
          _ahorrosList = lista;
          break;

        default:
          throw Exception("Tipo no reconocido: $tipo");
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error al cargar movimientos ($tipo): $e");
    }
  }


  Future<void> cargarMovimientosByMonth({
    required int year,
    required int month,
    required String tipo,
    required Function(double total, List<Movimiento> lista) onSuccess,
    Function(Exception e)? onError,
  }) async {
    try {
      final total = await getTotalMovimientosByMonth(
        year: year,
        month: month,
        tipo: tipo,
      );

      final lista = await getMovimientosByMonth(
        year: year,
        month: month,
        tipo: tipo,
      );

      onSuccess(total, lista);
    } catch (e) {
      if (onError != null) onError(e as Exception);
    }
  }

  Future<void> cargarMovimientosByDay({
    required int day,
    required int month,
    required int year,
    required String tipo,
    required TimeRangeMode selectedMode,  // Agregar el parámetro de modo
    required Function(double total, List<Movimiento> lista) onSuccess,
    Function(Exception e)? onError,
  }) async {
    try {
      double total = 0.0;
      List<Movimiento> lista = [];

      // Dependiendo del modo, cargamos los movimientos correspondientes
      switch (selectedMode) {
        case TimeRangeMode.day:
          // Llamar a los métodos para el total y lista de movimientos por día
          total = await getTotalMovimientosByDay(year: year, month: month, day: day, tipo: tipo);
          lista = await getMovimientosByDay(year: year, month: month, day: day, tipo: tipo);
                  break;
        case TimeRangeMode.month:
        // Llamar a los métodos para el total y lista de movimientos por mes
          total = await getTotalMovimientosByMonth(year: year, month: month, tipo: tipo);
          lista = await getMovimientosByMonth(year: year, month: month, tipo: tipo);
          break;
        case TimeRangeMode.year:
        // Llamar a los métodos para el total y lista de movimientos por año
          total = await getTotalMovimientosByYear(year: year, tipo: tipo);
          lista = await getMovimientosByYear(year: year, tipo: tipo);
          break;
        default:
          throw Exception("Modo no válido.");
      }

      // Retornar el total y la lista mediante el callback onSuccess
      onSuccess(total, lista);
    } catch (e) {
      if (onError != null) onError(e as Exception);
    }
  }


  Future<void> navigateToIngresos(BuildContext context, int selectedDay, int selectedMonth, int selectedYear, TimeRangeMode mode) async {
    try {
      // Obtener el total de gastos desde el controlador
      final totalIngresos = await getTotalMovimiento('ingreso');

      // Navegar a la vista de ingresos y pasar el dato
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IngresosView(totalIngresos: totalIngresos, selectedMonth: selectedMonth,selectedYear: selectedYear, selectedDay: selectedDay, selectedMode: mode,),
        ),
      );
    } catch (error) {
      // Manejar posibles errores al cargar los ingresos
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los ingresos: $error')),
      );
    }
  }

  Future<void> navigateToGastos(BuildContext context, int selectedDay, int selectedMonth, int selectedYear, TimeRangeMode mode) async {
    try {
      final totalGastos = await getTotalMovimiento('gasto');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GastosView(totalGastos: totalGastos,selectedMonth: selectedMonth,selectedYear: selectedYear, selectedDay: selectedDay, selectedMode: mode,),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los gastos: $error')),
      );
    }
  }


  Future<void> addMovimiento(
      double amount,
      String description,
      String tipo,
      int categoriaId,
      int day,
      int month,
      int year,
      ) async {
    // Fecha actual con hora y minuto para el campo 'date'
    final now = DateTime.now();
    final formattedDate = DateFormat("d/M/yyyy HH:mm:ss").format(now);

    // Fecha pasada desde la vista → solo día/mes/año para 'occurrenceDate'
    final occurrenceDateTime = DateTime(year, month, day, now.hour, now.minute, now.second);

    // Guarda 'occurrenceDate' en formato ISO 8601 para que sea compatible con la base de datos
    final iso8601FormattedOccurrenceDate = occurrenceDateTime.toIso8601String();

    // Crea el objeto Movimiento
    final movimiento = Movimiento(
      amount: amount,
      description: description,
      date: formattedDate,
      occurrenceDate: iso8601FormattedOccurrenceDate,
      tipo: tipo,
      categoriaId: categoriaId,
    );

    // Inserta el movimiento en la base de datos
    await _movimientosDao.insertMovimiento(movimiento);
    notifyListeners();
  }


  Future<void> validateAndAddMovimiento(
      BuildContext context,
      String? amountText,
      String description,
      int? categoriaId,
      int day,
      int month,
      int year,
      String tipo,
      ) async {
    if (amountText == null || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, introduce una cantidad')),
      );
      return;
    }

    final amountTextNormalized = amountText.replaceAll(',', '.');
    final amount = double.tryParse(amountTextNormalized);
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, introduce una cantidad válida')),
      );
      return;
    }

    if (categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, selecciona una categoría')),
      );
      return;
    }

    // Añadir el movimiento
    await addMovimiento(amount, description, tipo,categoriaId, day, month, year);

    notifyListeners();

    // Mostrar mensaje de éxito
    String mensaje = tipo == 'ingreso'
        ? 'Ingreso añadido: ${amount}€'
        : tipo == 'ahorro'
        ? 'Ahorro añadido: ${amount}€'
        : 'Gasto añadido: ${amount}€';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );

    // Volver al HomeView y actualizar
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeView()),
    );
  }

  Future<double> getTotalMovimientosByMonth({required int year, required int month, required String tipo}) async {
    final List<Movimiento> gastos = await MovimientosDao.instance.getMovimiento(tipo);
    double total = 0.0;

    for (var gasto in gastos) {
      final gastoDate = DateTime.parse(gasto.occurrenceDate);
      if (gastoDate.year == year && gastoDate.month == month) {
        total += gasto.amount;
      }
    }
    notifyListeners();

    return total;
  }

  Future<double> getTotalMovimientosByDay({required int year, required int month, required int day,required String tipo}) async {
    final List<Movimiento> gastos = await MovimientosDao.instance.getMovimiento(tipo);
    double total = 0.0;

    for (var gasto in gastos) {
      final gastoDate = DateTime.parse(gasto.occurrenceDate);
      if (gastoDate.year == year && gastoDate.month == month && gastoDate.day == day) {
        total += gasto.amount;
      }
    }
    notifyListeners();

    return total;
  }


  Future<double> getTotalMovimientosByYear({required int year, required String tipo}) async {
    final List<Movimiento> gastos = await MovimientosDao.instance.getMovimiento(tipo);
    double total = 0.0;

    for (var gasto in gastos) {
      final gastoDate = DateTime.parse(gasto.occurrenceDate);
      if (gastoDate.year == year) {
        total += gasto.amount;
      }
    }
    notifyListeners();

    return total;
  }

  Future<double> getTotalAllMovimientos({required String tipo}) async {
    final List<Movimiento> gastos = await MovimientosDao.instance.getMovimiento(tipo);
    double total = 0.0;

    for (var gasto in gastos) {
        total += gasto.amount;
    }
    notifyListeners();

    return total;
  }


  Future<List<Movimiento>> getMovimientos({required String tipo}) async {
    return await _movimientosDao.getMovimiento(tipo);
  }


  Future<List<Movimiento>> getMovimientosByMonth({required int year, required int month, required String tipo}) async {
    return await _movimientosDao.getMovimientoByMonth(year: year, month: month, tipo: tipo);
  }

  Future<List<Movimiento>> getMovimientosByDay({required int year, required int month, required int day, required String tipo}) async {
    return await _movimientosDao.getMovimientoByDay(year: year, month: month, day: day, tipo: tipo);
  }

  Future<List<Movimiento>> getMovimientosByYear({required int year, required String tipo}) async {
    return await _movimientosDao.getMovimientoByYear(year: year, tipo: tipo);
  }


  Future<double> getTotalMovimiento(String tipo) async {
    try {
      final List<Movimiento> movimientos = await getMovimientos(tipo: tipo);
      if (movimientos.isEmpty) {
        return 0.0;
      }
      double total = 0.0;
      for (var movimiento in movimientos) {
        total += movimiento.amount;
      }
      return total;
    } catch (error) {
      print('Error al calcular el total de ingresos: $error');
      return 0.0;
    }
  }

  Future<Movimiento> getMovimientoDetails(int? movimientoId) async {
    if (movimientoId == null) {
      throw Exception('ID no válido');
    }

    final movimiento = await MovimientosDao.instance.getMovimientoById(movimientoId);
    if (movimiento == null) {
      throw Exception('Detalles no encontrados');
    }

    return movimiento;
  }

  Future<void> deleteMovimiento(int? movimientoId) async {
    if (movimientoId == null) {
      print("Error: El ID del movimiento es nulo");
      return;
    }
    try {
      await _movimientosDao.deleteMovimiento(movimientoId);
      print("Eliminado con éxito");
    } catch (error) {
      print("Error al eliminar: $error");
    }
  }

  Future<void> updateMovimiento(Movimiento movimiento) async {
    if (movimiento.id == null) {
      print("Error: El ID del movimiento es nulo");
      return;
    }
    try {
      await _movimientosDao.updateMovimiento(movimiento);
      print("Actualizado con éxito");
    } catch (error) {
      print("Error al actualizar: $error");
    }
  }
}
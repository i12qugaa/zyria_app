import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/google_signin.dart';
import 'movimientos_controller.dart';

enum TimeRangeMode {
  day,
  month,
  year,
  all,
}

class HomeController with ChangeNotifier {
  final GoogleSignInProvider _googleSignInProvider = GoogleSignInProvider();

  final MovimientosController _movimientosController = MovimientosController();

  DateTime selectedDate = DateTime.now();

  double _totalGastos = 0.0;
  double _totalIngresos = 0.0;
  bool _isLoading = false;

  GoogleSignInAccount? _currentUser;

  double get totalGastos => _totalGastos;
  double get totalIngresos => _totalIngresos;

  bool get isLoading => _isLoading;

  GoogleSignInAccount? get currentUser => _currentUser;

  // Valor seleccionado del modo (por defecto, mes)
  TimeRangeMode selectedMode = TimeRangeMode.month;

  // Metodo para cargar la preferencia del modo desde SharedPreferences
  Future<void> loadSelectedMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('selectedMode');

    if (savedMode != null) {
      selectedMode = TimeRangeMode.values.firstWhere(
            (e) => e.toString() == 'TimeRangeMode.$savedMode',
        orElse: () => TimeRangeMode.month, // Default mode
      );
    } else {
      selectedMode = TimeRangeMode.month; // Default mode
    }
    notifyListeners();
  }

  // Metodo para guardar la preferencia del modo en SharedPreferences
  Future<void> saveSelectedMode() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedMode', selectedMode.toString().split('.').last);
  }


  // Mwtodo para actualizar el usuario actual y notificar a la vista
  void updateCurrentUser(GoogleSignInAccount? user) {
    _currentUser = user;
    notifyListeners();
  }

  // Metodo público para iniciar sesión
  Future<void> signIn() async {
    await _googleSignInProvider.signIn();
    updateCurrentUser(_googleSignInProvider.currentUser);
  }

  // Metodo público para cerrar sesión
  Future<void> signOut() async {
    await _googleSignInProvider.signOut();
    updateCurrentUser(null);
  }


  Future<void> fetchTotals() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (selectedMode == TimeRangeMode.day) {
        _totalGastos = await _movimientosController.getTotalMovimientosByDay(
          year: selectedDate.year,
          month: selectedDate.month,
          day: selectedDate.day,
          tipo: 'gasto',
        );
        _totalIngresos = await _movimientosController.getTotalMovimientosByDay(
          year: selectedDate.year,
          month: selectedDate.month,
          day: selectedDate.day,
          tipo: 'ingreso',
        );
      } else if (selectedMode == TimeRangeMode.month) {
        _totalGastos = await _movimientosController.getTotalMovimientosByMonth(
          year: selectedDate.year,
          month: selectedDate.month,
          tipo: 'gasto',
        );
        _totalIngresos = await _movimientosController.getTotalMovimientosByMonth(
          year: selectedDate.year,
          month: selectedDate.month,
          tipo: 'ingreso',
        );
      } else if (selectedMode == TimeRangeMode.year) {
        _totalGastos = await _movimientosController.getTotalMovimientosByYear(
          year: selectedDate.year,
          tipo: 'gasto',
        );
        _totalIngresos = await _movimientosController.getTotalMovimientosByYear(
          year: selectedDate.year,
          tipo: 'ingreso',
        );
      } else if (selectedMode == TimeRangeMode.all) {
        _totalGastos = await _movimientosController.getTotalAllMovimientos(
          tipo: 'gasto',
        );
        _totalIngresos = await _movimientosController.getTotalAllMovimientos(
          tipo: 'ingreso',
        );
      }
    } catch (e) {
      print('Error al obtener totales: $e');
    }

    _isLoading = false;
    notifyListeners();
  }


  void changeDay(int increment) {
    if (selectedMode == TimeRangeMode.day) {
      selectedDate = selectedDate.add(Duration(days: increment));
      fetchTotals();
    }
  }

  void changeMonth(int increment) {
    if (selectedMode == TimeRangeMode.month) {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + increment);
      fetchTotals();
    }
  }

  void changeYear(int increment) {
    if (selectedMode == TimeRangeMode.year) {
      selectedDate = DateTime(selectedDate.year + increment, selectedDate.month);
      fetchTotals();
    }
  }

  void changeTimeRangeMode(TimeRangeMode mode) {
    selectedMode = mode;
    saveSelectedMode();
    notifyListeners();
    fetchTotals();
  }
}
